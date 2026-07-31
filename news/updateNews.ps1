$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$jsonFile = Join-Path $root "news.json"

# Получаем все папки
$folders = Get-ChildItem -Path $root -Directory | Sort-Object Name

# Загружаем существующий JSON
$news = @()

if (Test-Path $jsonFile) {
    $content = Get-Content $jsonFile -Raw

    if (![string]::IsNullOrWhiteSpace($content)) {
        $parsed = $content | ConvertFrom-Json

        # ConvertFrom-Json возвращает объект при одной записи
        if ($parsed -is [System.Array]) {
            $news = $parsed
        }
        else {
            $news = @($parsed)
        }
    }
}

# Создаем словарь существующих записей
$map = @{}
foreach ($item in $news) {
    $map[$item.NewsId] = $item
}

# Итоговый массив
$result = @()

foreach ($folder in $folders) {

    if ($map.ContainsKey($folder.Name)) {
        # Оставляем существующую запись
        $result += $map[$folder.Name]
    }
    else {
        # Добавляем новую
        $result += [PSCustomObject]@{
            NewsId = $folder.Name
            Path   = $folder.Name
        }
    }
}

# Всегда сериализуем как массив
$json = if ($result.Count -eq 1) {
    "[`n$((ConvertTo-Json $result[0] -Depth 10))`n]"
}
else {
    ConvertTo-Json $result -Depth 10
}

Set-Content -Path $jsonFile -Value $json -Encoding UTF8

Write-Host "news.json обновлен."