param(
    [string]$RootDir = "./resources",
    [string]$OutputFile = "./manifest.json"
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
        # Если это не Fabric-мод или архив поврежден,
        # оставляем имя файла без расширения.
    }

    return $id
}

$root = (Resolve-Path $RootDir).Path

$files = Get-ChildItem $root -Recurse -File | ForEach-Object {

    $relativePath = $_.FullName.Substring($root.Length + 1).Replace('\', '/')

    $id = [System.IO.Path]::GetFileNameWithoutExtension($_.Name)
    $category = "file"

    if ($relativePath.StartsWith("mods/"))
    {
        $category = "mod"
        $id = Get-ModId $_.FullName
    }
    elseif ($relativePath.StartsWith("resourcepacks/"))
    {
        $category = "resourcepack"
    }
    elseif ($relativePath.StartsWith("shaderpacks/"))
    {
        $category = "shaderpack"
    }
    elseif ($relativePath.StartsWith("config/"))
    {
        $category = "config"
    }

    [PSCustomObject]@{
        Id            = $id
        Name          = $id
        Version       = ""
        Category      = $category
        Required      = $false
        DefaultEnable = $false
        Description   = ""
        Path          = $relativePath
        Sha256        = (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower()
    }
}

@{
    Files = $files
} |
ConvertTo-Json -Depth 10 |
Set-Content $OutputFile -Encoding UTF8

Write-Host "Manifest generated: $OutputFile"