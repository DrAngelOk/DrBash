<#
.SYNOPSIS
    Обезличивает дамп проекта перед загрузкой в GitHub-репозиторий.

.DESCRIPTION
    Читает указанный файл (обычно merge_project_dump.txt), заменяет
    значения, похожие на пароли/токены/секреты, на ***,
    и сохраняет результат в отдельный файл.

    Паттерны берутся СТРОГО из sanitize_patterns.json.
    Если файл отсутствует, пуст или повреждён — скрипт завершается
    с ошибкой. Никаких встроенных fallback-наборов нет —
    единственный источник правды = sanitize_patterns.json.

    После замены выполняется АВТО-ПРОВЕРКА: те же паттерны прогоняются
    по выходному содержимому. Паттерны с (?!\*\*\*) не матчат уже
    обезличенные значения, поэтому автопроверка корректна.
    Если найдены реальные остаточные совпадения — отказ от записи
    (без -Force).

.PARAMETER InputFile
    Путь к оригинальному файлу (содержит пароли).

.PARAMETER OutputFile
    Путь к обезличенной копии (без паролей).

.PARAMETER PatternsPath
    Путь к sanitize_patterns.json. По умолчанию — рядом со скриптом.

.PARAMETER DryRun
    Не сохранять, только показать, сколько замен сделано.

.PARAMETER Force
    Сохранить файл, даже если автопроверка нашла остаточные совпадения.

.EXAMPLE
    .\sanitize_for_repo.ps1 -InputFile "Z:\DOC\СЕРВЕРА\Scripts\Win\merge_project_dump.txt" `
                             -OutputFile "Z:\DOC\СЕРВЕРА\Scripts\AI\_repo\merge_project_dump.txt"
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InputFile,

    [Parameter(Mandatory = $true)]
    [string]$OutputFile,

    [string]$PatternsPath = "",

    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# =====================================================================
#  Определение пути к sanitize_patterns.json
# =====================================================================
if ([string]::IsNullOrWhiteSpace($PatternsPath)) {
    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
    $PatternsPath = Join-Path $scriptDir 'sanitize_patterns.json'
}

# =====================================================================
#  Проверка входного файла
# =====================================================================
if (-not (Test-Path $InputFile)) {
    throw "Входной файл не найден: $InputFile"
}

# =====================================================================
#  Чтение паттернов (строго из sanitize_patterns.json)
# =====================================================================
if (-not (Test-Path $PatternsPath)) {
    throw "Файл паттернов не найден: $PatternsPath"
}

$patterns = $null
try {
    $json = [System.IO.File]::ReadAllText($PatternsPath, [System.Text.Encoding]::UTF8)
    $obj  = $json | ConvertFrom-Json
    $patterns = @($obj.patterns)
} catch {
    throw "Ошибка чтения $PatternsPath : $($_.Exception.Message)"
}

if ($patterns.Count -eq 0) {
    throw "Массив patterns пуст в $PatternsPath"
}

Write-Host "[INFO] Файл паттернов : $PatternsPath" -ForegroundColor Cyan
Write-Host "[INFO] Паттернов всего : $($patterns.Count)" -ForegroundColor Cyan

# =====================================================================
#  ФУНКЦИЯ: применение паттернов
#  Возвращает @{ Content; TotalReplacements; PerPattern; Remaining }
# =====================================================================
function Invoke-Sanitize {
    param([string]$Content, [string[]]$Patterns)

    # FIX: IgnoreCase — иначе 'PASSWORD=' (uppercase) не матчится 'password'.
    # FIX: чтобы корректно работала и замена, и автопроверка, компилируем regex
    #      с опцией IgnoreCase и используем его и для Matches, и для Replace.
	# FIX: Multiline для корректной работы ^ и $ в начале/конце КАЖДОЙ строки.
	$opts = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor `
			[System.Text.RegularExpressions.RegexOptions]::Multiline

    $totalReplacements = 0
    $perPattern = @{}

    foreach ($p in $Patterns) {
        $regex = [regex]::new($p, $opts)
        $cnt = $regex.Matches($Content).Count
        if ($cnt -gt 0) {
            $perPattern[$p] = $cnt
            $totalReplacements += $cnt

            # Паттерн для ключ=значение — оставляем ключ и разделитель.
            if ($p -match '^(pwd|password|passwd|pass|api[_-]?key|token|secret|user|username|login)') {
                $Content = $regex.Replace($Content, {
                    param($m)
                    if ($m.Value -match '^([^:=]+)\s*([:=])\s*(.+)$') {
                        "$($Matches[1])$($Matches[2])***"
                    } else {
                        '***'
                    }
                })
            }
            # URL с basic-auth — скрываем только user:pass, оставляя схему и хост.
            elseif ($p -like '://*') {
                $Content = $regex.Replace($Content, '://***@')
            }
            # Комментарий-пароль — заменяем весь комментарий на #***.
            elseif ($p -like '^\s*#*') {
                $Content = $regex.Replace($Content, '#***')
            }
            else {
                $Content = $regex.Replace($Content, '***')
            }
        }
    }

    # Автопроверка — те же опции IgnoreCase.
    $remaining = 0
    foreach ($p in $Patterns) {
        try {
            $remaining += ([regex]::new($p, $opts)).Matches($Content).Count
        } catch {
            # некорректный паттерн — пропускаем
        }
    }

    return @{
        Content           = $Content
        TotalReplacements = $totalReplacements
        PerPattern        = $perPattern
        Remaining         = $remaining
    }
}

# =====================================================================
#  ФУНКЦИЯ: лог
# =====================================================================
function Write-SanitizeLog {
    param([string]$Message)

    try {
        $logDir = Join-Path (Split-Path $OutputFile -Parent) 'logs'
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        $logFile = Join-Path $logDir 'sanitize.log'
        $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Add-Content -LiteralPath $logFile -Value "[$stamp] $Message" -Encoding UTF8
    } catch {
        # не должно ломать основную работу
    }
}

# =====================================================================
#  MAIN
# =====================================================================

$utf8 = New-Object System.Text.UTF8Encoding($false)
$content = [System.IO.File]::ReadAllText($InputFile, [System.Text.Encoding]::UTF8)
$originalLength = $content.Length

# --- Обезличивание ---
$result = Invoke-Sanitize -Content $content -Patterns $patterns

# --- Отчёт ---
Write-Host ""
Write-Host "=== SANITIZE REPORT ===" -ForegroundColor Cyan
Write-Host "Входной файл : $InputFile" -ForegroundColor Gray
Write-Host "Выходной файл: $OutputFile" -ForegroundColor Gray
Write-Host "Размер до    : $([math]::Round($originalLength/1KB,1)) КБ" -ForegroundColor Gray
Write-Host "Размер после : $([math]::Round($result.Content.Length/1KB,1)) КБ" -ForegroundColor Gray
Write-Host "Всего замен  : $($result.TotalReplacements)" -ForegroundColor Yellow
Write-Host "Осталось     : $($result.Remaining)" -ForegroundColor $(if ($result.Remaining -eq 0) {'Green'} else {'Red'})
Write-Host ""

if ($result.PerPattern.Count -gt 0) {
    Write-Host "Разбивка по паттернам (ТОП-20):" -ForegroundColor Yellow
    $i = 0
    foreach ($kv in $result.PerPattern.GetEnumerator() | Sort-Object Value -Descending) {
        $i++
        if ($i -gt 20) { break }
        $short = if ($kv.Key.Length -gt 55) { $kv.Key.Substring(0, 52) + '...' } else { $kv.Key }
        Write-Host ("  {0,5}  {1}" -f $kv.Value, $short) -ForegroundColor DarkGray
    }
    Write-Host ""
}

# --- Автопроверка ---
if ($result.Remaining -gt 0) {
    Write-Host "[WARN] ОСТАТОЧНЫЕ СОВПАДЕНИЯ: $($result.Remaining)" -ForegroundColor Red
    if (-not $Force) {
        Write-Host "[ABORT] Запись отменена. Используйте -Force для принудительной записи." -ForegroundColor Red
        Write-SanitizeLog "[sanitize] ABORT remaining=$($result.Remaining) input=$InputFile"
        return
    }
    Write-Host "[FORCE] Продолжаю с -Force..." -ForegroundColor Yellow
}

# --- Сохранение ---
if ($DryRun) {
    Write-Host "[DRY] Реального сохранения не было." -ForegroundColor Yellow
    Write-SanitizeLog "[sanitize] DRY-RUN total=$($result.TotalReplacements) input=$InputFile"
    return
}

$outDir = Split-Path $OutputFile -Parent
if ($outDir -and -not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir -Force | Out-Null
}
[System.IO.File]::WriteAllText($OutputFile, $result.Content, $utf8)

Write-Host "[OK] Обезличенная копия сохранена: $OutputFile" -ForegroundColor Green
Write-Host ""
Write-Host "Дальше: .\ai_context.ps1 repo-push" -ForegroundColor Cyan

Write-SanitizeLog "[sanitize] OK total=$($result.TotalReplacements) remaining=$($result.Remaining) input=$InputFile output=$OutputFile"