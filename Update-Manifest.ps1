param(
    [string]$RootDir = "./resources",
    [string]$Manifest = "./manifest.json"
)

Add-Type -AssemblyName System.IO.Compression.FileSystem

function Get-ModId([string]$filePath)
{
    $id = [System.IO.Path]::GetFileNameWithoutExtension($filePath)

    try
    {
        $zip = [System.IO.Compression.ZipFile]::OpenRead($filePath)

        try
        {
            $entry = $zip.GetEntry("fabric.mod.json")

            if ($entry)
            {
                $reader = New-Object System.IO.StreamReader($entry.Open())

                try
                {
                    $json = $reader.ReadToEnd() | ConvertFrom-Json

                    if ($json.id)
                    {
                        $id = $json.id
                    }
                }
                finally
                {
                    $reader.Dispose()
                }
            }
        }
        finally
        {
            $zip.Dispose()
        }
    }
    catch
    {
    }

    return $id
}

function Get-Category([string]$relativePath)
{
    if ($relativePath.StartsWith("mods/")) { return "mod" }
    elseif ($relativePath.StartsWith("resourcepacks/")) { return "resourcepack" }
    elseif ($relativePath.StartsWith("shaderpacks/")) { return "shaderpack" }
    elseif ($relativePath.StartsWith("config/")) { return "config" }

    return "file"
}

$root = (Resolve-Path $RootDir).Path

if (!(Test-Path $Manifest))
{
    Write-Error "Manifest not found."
    exit
}

$manifestObj = Get-Content $Manifest -Raw | ConvertFrom-Json

# Для поиска существующих записей
$existing = @{}

foreach ($item in $manifestObj.Files)
{
    $existing[$item.Path] = $item
}

# Какие файлы реально существуют
$diskFiles = @{}

Get-ChildItem $root -Recurse -File | ForEach-Object {

    $relativePath = $_.FullName.Substring($root.Length + 1).Replace('\','/')

    $diskFiles[$relativePath] = $true

    $hash = (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower()

    if ($existing.ContainsKey($relativePath))
    {
        $existing[$relativePath].Sha256 = $hash
        Write-Host "[OK] $relativePath"
    }
    else
    {
        $category = Get-Category $relativePath

        $id = if ($category -eq "mod")
        {
            Get-ModId $_.FullName
        }
        else
        {
            [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
        }

        $manifestObj.Files += [PSCustomObject]@{

            Id            = $id
            Name          = $id
            Version       = ""
            Category      = $category
            Required      = $false
            DefaultEnable = $false
            Description   = ""
            Path          = $relativePath
            Sha256        = $hash
        }

        Write-Host "[NEW] $relativePath"
    }
}

# Удаляем отсутствующие файлы
$manifestObj.Files = @(
    foreach ($item in $manifestObj.Files)
    {
        if ($diskFiles.ContainsKey($item.Path))
        {
            $item
        }
        else
        {
            Write-Host "[REMOVED] $($item.Path)"
        }
    }
)

# Сортировка
$manifestObj.Files = $manifestObj.Files | Sort-Object Category, Path

$manifestObj |
ConvertTo-Json -Depth 10 |
Out-File -FilePath $Manifest -Encoding utf8

Write-Host ""
Write-Host "Manifest updated successfully."