$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$jsonFile = Join-Path $root "news.json"

# Получаем все папки
$folders = Get-ChildItem -Path $root -Directory | Sort-Object Name

# Загружаем существующий JSON
$news = @()

if (Test-Path $jsonFile) {
    $content = Get-Content $jsonFile -Raw

    if (![string]::IsNullOrWhiteSpace($content)) {
        $news = $content | ConvertFrom-Json
    }
}

# Если одна запись, превращаем в массив
if ($news -isnot [System.Collections.IEnumerable] -or $news -is [string]) {
    $news = @($news)
}

# Создаем словарь существующих записей
$map = @{}
foreach ($item in $news) {
    $map[$item.newsId] = $item
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
            newsId = $folder.Name
            path   = $folder.Name
        }
    }
}

# Сохраняем красиво отформатированный JSON
$result |
    ConvertTo-Json -Depth 10 |
    Set-Content $jsonFile -Encoding UTF8

Write-Host "news.json обновлен."