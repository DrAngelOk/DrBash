<#
=====================================================================
 SYNOPSIS:
    Пакетный сбор исходного кода проекта в один текстовый файл
    для последующего анализа нейросетью (AI).

 DESCRIPTION:
    Скрипт лежит в подпапке \Win корня проекта.
    Корень проекта вычисляется автоматически как РОДИТЕЛЬСКАЯ
    папка от места расположения скрипта.

    Собираются:
      1) файлы, лежащие ПРЯМО в корне проекта (без рекурсии);
      2) ВСЕ файлы (рекурсивно) из папок, перечисленных в
         <корень>\Def\scriptpaths.list.

    Дамп содержит:
      - ШАПКА (метаданные, версия по дате самого свежего файла);
      - ОГЛАВЛЕНИЕ (все файлы + номера строк для перехода);
      - ДАМП СОДЕРЖИМОГО.

    ДОПОЛНИТЕЛЬНО (если найден sanitize_for_repo.ps1):
      - автоматическое обезличивание паролей/токенов;
      - результат кладётся в AI\_repo\merge_project_dump.txt.

 PARAMETERS:
    -DryRun       Показать, что будет собрано, без записи файла.
    -NoSanitize   Не запускать обезличиватель.

 ЗАПУСК:
    .\merge_project.ps1
    .\merge_project.ps1 -DryRun
    .\merge_project.ps1 -NoSanitize
=====================================================================
#>

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$NoSanitize
)

$ErrorActionPreference = 'Stop'


# ---------------------------------------------------------------------
# ШАГ 1. ОПРЕДЕЛЕНИЕ РАСПОЛОЖЕНИЯ СКРИПТА И КОРНЯ ПРОЕКТА
# ---------------------------------------------------------------------
$ScriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($ScriptDir)) {
    $ScriptDir = (Get-Location).Path
}
$ScriptDir = (Resolve-Path -LiteralPath $ScriptDir).Path

$SourceDir = Split-Path -Path $ScriptDir -Parent
if (-not (Test-Path -LiteralPath $SourceDir -PathType Container)) {
    throw "Корень проекта не найден: $SourceDir"
}
$SourceDir = (Resolve-Path -LiteralPath $SourceDir).Path


# ---------------------------------------------------------------------
# ШАГ 2. ФИКСИРОВАННЫЕ ПУТИ
# ---------------------------------------------------------------------
$OutputFile = Join-Path $ScriptDir 'merge_project_dump.txt'
$OutputFile = [System.IO.Path]::GetFullPath($OutputFile)

$ListFile = Join-Path $SourceDir 'Def\scriptpaths.list'
$ListFile = [System.IO.Path]::GetFullPath($ListFile)


# ---------------------------------------------------------------------
# ШАГ 3. СПИСКИ ИСКЛЮЧЕНИЙ
# ---------------------------------------------------------------------
$ExcludeDirs = @(
    '_archive', '_tmp', 'node_modules', '.git',
    '.vs', 'bin', 'obj', '__pycache__', 'venv',
    '.venv', 'dist', 'build', '.idea'
)

$BinaryExtensions = @(
    '.png','.jpg','.jpeg','.gif','.bmp','.ico','.svg','.webp',
    '.exe','.dll','.so','.dylib','.bin','.obj','.o','.a','.lib',
    '.zip','.rar','.7z','.tar','.gz','.bz2','.xz',
    '.pdf','.doc','.docx','.xls','.xlsx','.ppt','.pptx',
    '.mp3','.mp4','.avi','.mkv','.mov','.wav','.flac',
    '.ttf','.otf','.woff','.woff2','.eot',
    '.sqlite','.db','.pyc','.pyo','.class','.jar'
)


# =====================================================================
# ФУНКЦИЯ: Test-ExcludedPath
# НАЗНАЧЕНИЕ:
#   Проверить, нужно ли исключить файл/папку из обхода.
# =====================================================================
function Test-ExcludedPath {
    param([Parameter(Mandatory = $true)][string] $FullPath)

    $relative = $FullPath.Substring($SourceDir.Length).TrimStart('\','/')
    if ([string]::IsNullOrEmpty($relative)) { return $false }

    $parts = $relative -split '[\\/]'
    foreach ($part in $parts) {
        if ($ExcludeDirs -contains $part) { return $true }
        if ($part.StartsWith('_'))        { return $true }
    }
    return $false
}


# =====================================================================
# ФУНКЦИЯ: Test-TextFile
# НАЗНАЧЕНИЕ:
#   Определить, пригоден ли файл для дампа (текстовый / не бинарный).
# =====================================================================
function Test-TextFile {
    param([Parameter(Mandatory = $true)][System.IO.FileInfo] $File)

    $ext = $File.Extension.ToLower()
    return -not ($BinaryExtensions -contains $ext)
}


# =====================================================================
# ФУНКЦИЯ: Read-ScriptPathsList
# НАЗНАЧЕНИЕ:
#   Прочитать манифест scriptpaths.list.
#   FIX (пункт 9): отсекаем пробелы, табы, \r и BOM в начале строки.
# =====================================================================
function Read-ScriptPathsList {
    param([Parameter(Mandatory = $true)][string] $Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Список подпапок не найден: $Path"
    }

    $names = New-Object System.Collections.Generic.List[string]
    foreach ($raw in Get-Content -LiteralPath $Path -Encoding UTF8) {
        $line = $raw.Replace("`r", "").Replace("`t", "").Trim()
        $line = $line.Trim([char]0xFEFF).Trim()

        if ([string]::IsNullOrEmpty($line)) { continue }
        if ($line.StartsWith('#'))          { continue }

        [void]$names.Add($line)
    }
    return $names.ToArray()
}


# =====================================================================
# ФУНКЦИЯ: Get-RootFiles
# НАЗНАЧЕНИЕ:
#   Файлы, лежащие ПРЯМО в корне проекта (без рекурсии).
# =====================================================================
function Get-RootFiles {
    return Get-ChildItem -LiteralPath $SourceDir -File -Force -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FullName -ne $OutputFile -and
            -not (Test-ExcludedPath -FullPath $_.FullName) -and
            (Test-TextFile $_)
        }
}


# =====================================================================
# ФУНКЦИЯ: Get-FilesFromSubfolders
# НАЗНАЧЕНИЕ:
#   Рекурсивно собрать файлы из подпапок scriptpaths.list.
# =====================================================================
function Get-FilesFromSubfolders {
    param([Parameter(Mandatory = $true)][string[]] $FolderNames)

    $result = New-Object System.Collections.Generic.List[System.IO.FileInfo]
    $seen   = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)

    $scriptDirName = Split-Path -Leaf $ScriptDir
    $sourcePrefix  = $SourceDir + [System.IO.Path]::DirectorySeparatorChar

    foreach ($name in $FolderNames) {
        $subPath = Join-Path $SourceDir $name
        $subPath = [System.IO.Path]::GetFullPath($subPath)

        if ($subPath -eq $SourceDir) {
            Write-Host "[WARN] Пустая запись в манифесте — пропуск" -ForegroundColor DarkYellow
            continue
        }

        if (-not $subPath.StartsWith($sourcePrefix, [StringComparison]::OrdinalIgnoreCase)) {
            Write-Host "[WARN] Путь вне корня — пропуск: $name" -ForegroundColor DarkYellow
            continue
        }

        $subName = Split-Path -Leaf $subPath
        if ($subName -ieq $scriptDirName) {
            Write-Host "[SKIP] Папка со скриптом исключена: $name" -ForegroundColor DarkGray
            continue
        }

        if (-not (Test-Path -LiteralPath $subPath -PathType Container)) {
            Write-Host "[WARN] Подпапка не найдена: $name" -ForegroundColor DarkYellow
            continue
        }

        Write-Host "[SCAN] Рекурсивный обход: $name" -ForegroundColor Cyan

        $items = Get-ChildItem -LiteralPath $subPath -Recurse -File -Force -ErrorAction SilentlyContinue |
            Where-Object {
                $_.FullName -ne $OutputFile -and
                -not (Test-ExcludedPath -FullPath $_.FullName) -and
                (Test-TextFile $_)
            }

        foreach ($it in $items) {
            if ($seen.Add($it.FullName)) {
                [void]$result.Add($it)
            }
        }
    }

    return $result
}


# =====================================================================
# ФУНКЦИЯ: Get-LastChangedFile
# =====================================================================
function Get-LastChangedFile {
    param([Parameter(Mandatory = $true)] $Files)

    if ($null -eq $Files -or $Files.Count -eq 0) { return $null }
    return ($Files | Sort-Object LastWriteTime -Descending | Select-Object -First 1)
}


# =====================================================================
# ФУНКЦИЯ: Read-FileAsUtf8
# НАЗНАЧЕНИЕ:
#   FIX (пункт 8): Чтение через .NET ReadAllText с явной UTF-8.
#   Get-Content -Encoding UTF8 в PS 5.1 читает UTF-8 только при BOM.
# =====================================================================
function Read-FileAsUtf8 {
    param([Parameter(Mandatory = $true)][string] $Path)

    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}


# =====================================================================
# ФУНКЦИЯ: Test-BrokenEncoding
# НАЗНАЧЕНИЕ:
#   FIX (пункт 2): Проверка кодировки.
#   Если в тексте много replacement-символов (U+FFFD), значит
#   файл не UTF-8 или содержит битые байты.
# =====================================================================
function Test-BrokenEncoding {
    param([Parameter(Mandatory = $true)][string] $Text)

    if ($Text.Length -eq 0) { return $false }

    $badCount = ([regex]::Matches($Text, [char]0xFFFD)).Count
    $ratio = $badCount / $Text.Length

    # Порог 0.5% — если больше, это явно битая кодировка
    return ($ratio -gt 0.005)
}


# ---------------------------------------------------------------------
# ШАГ 4. ЧТЕНИЕ МАНИФЕСТА И СБОР ФАЙЛОВ
# ---------------------------------------------------------------------
Write-Host "[INFO] Скрипт запущен из : $ScriptDir"  -ForegroundColor Cyan
Write-Host "[INFO] Корень проекта    : $SourceDir"  -ForegroundColor Cyan
Write-Host "[INFO] Манифест подпапок : $ListFile"   -ForegroundColor Cyan
Write-Host "[INFO] Итоговый файл     : $OutputFile" -ForegroundColor Cyan
Write-Host "[INFO] Режим             : $(if ($DryRun) {'DRY-RUN'} else {'WRITE'})" -ForegroundColor Cyan

$folderNames = Read-ScriptPathsList -Path $ListFile
Write-Host "[INFO] Из манифеста получено подпапок: $($folderNames.Count)" -ForegroundColor DarkGray

$rootFiles = Get-RootFiles
$subFiles  = Get-FilesFromSubfolders -FolderNames $folderNames

$seenFinal = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
$files     = New-Object System.Collections.Generic.List[System.IO.FileInfo]

foreach ($f in $rootFiles) {
    if ($seenFinal.Add($f.FullName)) { [void]$files.Add($f) }
}
foreach ($f in $subFiles) {
    if ($seenFinal.Add($f.FullName)) { [void]$files.Add($f) }
}

$files = @($files) | Sort-Object FullName

Write-Host "[INFO] Файлов всего     : $($files.Count)" -ForegroundColor DarkGray

$lastFile = Get-LastChangedFile -Files $files


# ---------------------------------------------------------------------
# ШАГ 5. ПЕРВЫЙ ПРОХОД: СОДЕРЖИМОЕ + НОМЕРА СТРОК ДЛЯ ОГЛАВЛЕНИЯ
# ---------------------------------------------------------------------
$body = [System.Text.StringBuilder]::new()
$bar  = '=' * 69

$toc = New-Object System.Collections.Generic.List[object]

$rootSet = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
foreach ($rf in $rootFiles) { [void]$rootSet.Add($rf.FullName) }

# FIX (пункт 2): список файлов с подозрительной кодировкой
$brokenEncodingFiles = @()

$index = 0
foreach ($file in $files) {
    $index++
    $rel = $file.FullName.Substring($SourceDir.Length).TrimStart('\','/')

    # FIX (пункт 6): прогресс [N/M]
    Write-Host ("[{0,4}/{1}] {2}" -f $index, $files.Count, $rel) -ForegroundColor Yellow

    $startLine = (($body.ToString() -split "`n").Count)

    $section = if ($rootSet.Contains($file.FullName)) { 'ROOT' } else { 'MANIFEST' }
    [void]$toc.Add([pscustomobject]@{
        File    = $rel
        Line    = $startLine
        Section = $section
    })

    [void]$body.AppendLine($bar)
    [void]$body.AppendLine(" FILE START : $rel")
    [void]$body.AppendLine(" FULL PATH  : $($file.FullName)")
    [void]$body.AppendLine(" SIZE       : $($file.Length) bytes")
    [void]$body.AppendLine(" MODIFIED   : $($file.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))")
    [void]$body.AppendLine($bar)
    [void]$body.AppendLine('--- FILE CONTENT ---')

    try {
        # FIX (пункт 8): чтение через ReadAllText (правильная UTF-8 в PS 5.1)
        $content = Read-FileAsUtf8 -Path $file.FullName

        # FIX (пункт 2): проверка на битую кодировку
        if (Test-BrokenEncoding -Text $content) {
            $brokenEncodingFiles += $rel
            [void]$body.AppendLine("<<< WARNING: подозрительная кодировка файла >>>")
            Write-Host ("      [WARN] Подозрительная кодировка: {0}" -f $rel) -ForegroundColor Yellow
        }

        if ($null -ne $content) { [void]$body.AppendLine($content) }
    }
    catch {
        [void]$body.AppendLine("<<< READ FAILED: $($_.Exception.Message) >>>")
        Write-Host ("      [ERR] Ошибка чтения: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }

    [void]$body.AppendLine()
    [void]$body.AppendLine($bar)
    [void]$body.AppendLine(" FILE END : $rel")
    [void]$body.AppendLine($bar)
    [void]$body.AppendLine()
    [void]$body.AppendLine()
}


# ---------------------------------------------------------------------
# ШАГ 6. СБОРКА ШАПКИ: МЕТАДАННЫЕ + ОГЛАВЛЕНИЕ
#
# FIX (пункт 5): offset теперь вычисляется ПОСЛЕ генерации шапки,
# а не до неё. Это исключает ошибку в номерах строк, если шапка
# изменится.
# ---------------------------------------------------------------------

# --- Часть A: метаданные и версия ---
$header = [System.Text.StringBuilder]::new()
[void]$header.AppendLine($bar)
[void]$header.AppendLine(' GLOBAL PROJECT TREE AND ARCHITECTURE MAP')
[void]$header.AppendLine($bar)
[void]$header.AppendLine("Root         : $SourceDir")
[void]$header.AppendLine("Script dir   : $ScriptDir")
[void]$header.AppendLine("Manifest     : $ListFile")
[void]$header.AppendLine("Generated    : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$header.AppendLine($bar)
[void]$header.AppendLine(' VERSION INFO (по дате самого свежего файла)')
[void]$header.AppendLine($bar)
if ($null -ne $lastFile) {
    $lastRel = $lastFile.FullName.Substring($SourceDir.Length).TrimStart('\','/')
    [void]$header.AppendLine("Last change  : $($lastFile.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))")
    [void]$header.AppendLine("Last file    : $lastRel")
} else {
    [void]$header.AppendLine('Last change  : (нет файлов)')
}
[void]$header.AppendLine($bar)
[void]$header.AppendLine()

# FIX (пункт 2): выводим список файлов с подозрительной кодировкой
if ($brokenEncodingFiles.Count -gt 0) {
    [void]$header.AppendLine($bar)
    [void]$header.AppendLine(' WARNING: ФАЙЛЫ С ПОДОЗРИТЕЛЬНОЙ КОДИРОВКОЙ')
    [void]$header.AppendLine($bar)
    foreach ($bf in $brokenEncodingFiles) {
        [void]$header.AppendLine("  - $bf")
    }
    [void]$header.AppendLine($bar)
    [void]$header.AppendLine()
}

# --- Часть B: оглавление ---
[void]$header.AppendLine($bar)
[void]$header.AppendLine(' TABLE OF CONTENTS (номер строки = переход в дампе)')
[void]$header.AppendLine($bar)

$dash60 = '-' * 60
[void]$header.AppendLine(("{0,4}  {1,-60}  {2,6}" -f '#',   'FILE', 'LINE'))
[void]$header.AppendLine(("{0,4}  {1,-60}  {2,6}" -f '---', $dash60, '------'))

$hasRoot     = ($toc | Where-Object { $_.Section -eq 'ROOT' }).Count -gt 0
$hasManifest = ($toc | Where-Object { $_.Section -eq 'MANIFEST' }).Count -gt 0

if ($hasRoot) {
    [void]$header.AppendLine()
    [void]$header.AppendLine('--- ROOT FILES (без рекурсии) ---')
    $n = 0
    foreach ($entry in ($toc | Where-Object { $_.Section -eq 'ROOT' } | Sort-Object File)) {
        $n++
        $name = $entry.File
        if ($name.Length -gt 60) { $name = '...' + $name.Substring($name.Length - 57) }
        [void]$header.AppendLine(("{0,4}  {1,-60}  {2,6}" -f $n, $name, $entry.Line))
    }
}

if ($hasManifest) {
    [void]$header.AppendLine()
    [void]$header.AppendLine('--- MANIFEST FILES (рекурсивно из scriptpaths.list) ---')
    $n = 0
    foreach ($entry in ($toc | Where-Object { $_.Section -eq 'MANIFEST' } | Sort-Object File)) {
        $n++
        $name = $entry.File
        if ($name.Length -gt 60) { $name = '...' + $name.Substring($name.Length - 57) }
        [void]$header.AppendLine(("{0,4}  {1,-60}  {2,6}" -f $n, $name, $entry.Line))
    }
}

[void]$header.AppendLine()
[void]$header.AppendLine($bar)
[void]$header.AppendLine()


# ---------------------------------------------------------------------
# ШАГ 7. СКЛЕЙКА И ЗАПИСЬ РЕЗУЛЬТАТА (UTF-8 без BOM)
# ---------------------------------------------------------------------
$finalContent = $header.ToString() + $body.ToString()

if ($DryRun) {
    Write-Host ""
    Write-Host "[DRY] Реального сохранения не было." -ForegroundColor Yellow
    Write-Host "[DRY] Было бы записано: $([math]::Round($finalContent.Length/1KB,1)) КБ в $OutputFile" -ForegroundColor Yellow
    return
}

try {
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($OutputFile, $finalContent, $utf8NoBom)

    Write-Host "[OK] Записано: $OutputFile" -ForegroundColor Green
    Write-Host ("[OK] Обработано файлов: {0}" -f $files.Count) -ForegroundColor Green
    if ($null -ne $lastFile) {
        Write-Host ("[OK] Самый свежий файл: {0} ({1})" -f `
            $lastFile.Name, $lastFile.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')) -ForegroundColor Green
    }
    if ($brokenEncodingFiles.Count -gt 0) {
        Write-Host ("[WARN] Файлов с подозрительной кодировкой: {0}" -f $brokenEncodingFiles.Count) -ForegroundColor Yellow
    }
}
catch {
    Write-Host "[ERROR] Не удалось записать файл: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}


# ---------------------------------------------------------------------
# ШАГ 8. АВТООБЕЗЛИЧИВАНИЕ (FIX, пункт 4)
#
# Если найден sanitize_for_repo.ps1 рядом с AI-папкой — запускаем его.
# Результат кладём в AI\_repo\merge_project_dump.txt.
# ---------------------------------------------------------------------
if ($NoSanitize) {
    Write-Host "[SKIP] Автообезличивание отключено (-NoSanitize)." -ForegroundColor DarkGray
    return
}

$aiRoot     = Join-Path $SourceDir 'AI'
$sanitizer  = Join-Path $aiRoot 'sanitize_for_repo.ps1'
$repoDir    = Join-Path $aiRoot '_repo'
$repoOut    = Join-Path $repoDir 'merge_project_dump.txt'

if ((Test-Path $sanitizer) -and (Test-Path (Join-Path $aiRoot 'sanitize_patterns.json'))) {
    Write-Host ""
    Write-Host "[SANITIZE] Запуск автообезличивания..." -ForegroundColor Cyan
    if (-not (Test-Path $repoDir)) {
        New-Item -ItemType Directory -Path $repoDir -Force | Out-Null
    }

    try {
        & $sanitizer -InputFile $OutputFile -OutputFile $repoOut -PatternsPath (Join-Path $aiRoot 'sanitize_patterns.json')
        Write-Host "[SANITIZE] Готово: $repoOut" -ForegroundColor Green
    } catch {
        Write-Host "[SANITIZE] Ошибка: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "[SKIP] sanitize_for_repo.ps1 или sanitize_patterns.json не найдены — обезличивание пропущено." -ForegroundColor DarkGray
}