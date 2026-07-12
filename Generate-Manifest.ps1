param(
    [string]$RootDir = "./resources",
    [string]$OutputFile = "./manifest.json"
)

$root = (Resolve-Path $RootDir).Path
$outputPath = $OutputFile

$files = Get-ChildItem $root -Recurse -File |
    Where-Object { $_.FullName -ne $outputPath } |
    ForEach-Object {

        $relativePath = $_.FullName.Substring($root.Length + 1).Replace('\', '/')

        [PSCustomObject]@{
            Path = $relativePath
            Sha256 = (Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLower()
        }
    }

@{
    Files = $files
} |
ConvertTo-Json -Depth 10 |
Set-Content $outputPath -Encoding UTF8

Write-Host "Manifest saved to $outputPath"