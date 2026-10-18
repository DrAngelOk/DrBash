# =====================================================================
#  merge_project.ps1
#  Пакетный сбор исходного кода проекта в один или несколько
#  текстовых файлов для анализа нейросетью (AI).
#
#  Описание:
#    Скрипт лежит в подпапке \Win корня проекта.
#    Корень проекта — РОДИТЕЛЬСКАЯ папка от места расположения скрипта.
#
#    Собираются:
#      1) файлы ПРЯМО в корне проекта (без рекурсии);
#      2) ВСЕ файлы (рекурсивно) из папок, перечисленных в
#         <корень>\Def\scriptpaths.list.
#
#    ПО УМОЛЧАНИЮ (без ключей) режет дамп на части ~250 КБ,
#    группируя файлы по верхнеуровневым папкам. Каждая часть
#    самодостаточна: шапка + оглавление + маркер "END OF PART N/M".
#
#    С ключом -NoSplit — один файл merge_project_dump.txt.
#
#    ВСЕ результаты складываются в Win\MergeProjectOut\
#
#  Параметры:
#    -DryRun         Показать, что будет собрано, без записи файла.
#    -NoSanitize     Не запускать обезличиватель.
#    -NoSplit        Не резать: один файл merge_project_dump.txt.
#    -SplitSizeKB N  Размер части в КБ (по умолчанию 250).
#    -Part N         Записать только N-ю часть (1..M). 0 — все части.
#
#  Запуск:
#    .\merge_project.ps1                              # нарезка ~250 КБ
#    .\merge_project.ps1 -SplitSizeKB 300             # нарезка ~300 КБ
#    .\merge_project.ps1 -Part 1                      # только часть 1
#    .\merge_project.ps1 -NoSplit                     # один файл
#    .\merge_project.ps1 -DryRun
#    .\merge_project.ps1 -NoSanitize
# =====================================================================

[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$NoSanitize,
    [switch]$NoSplit,
    [int]$SplitSizeKB = 250,
    [int]$Part = 0
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
$OutDir = Join-Path $ScriptDir 'MergeProjectOut'
$OutDir = [System.IO.Path]::GetFullPath($OutDir)

$OutputFile = Join-Path $OutDir 'merge_project_dump.txt'
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
# =====================================================================
function Test-TextFile {
    param([Parameter(Mandatory = $true)][System.IO.FileInfo] $File)

    $ext = $File.Extension.ToLower()
    return -not ($BinaryExtensions -contains $ext)
}


# =====================================================================
# ФУНКЦИЯ: Read-ScriptPathsList
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
# =====================================================================
function Read-FileAsUtf8 {
    param([Parameter(Mandatory = $true)][string] $Path)

    return [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
}


# =====================================================================
# ФУНКЦИЯ: Test-BrokenEncoding
# =====================================================================
function Test-BrokenEncoding {
    param([Parameter(Mandatory = $true)][string] $Text)

    if ($Text.Length -eq 0) { return $false }

    $badCount = ([regex]::Matches($Text, [char]0xFFFD)).Count
    $ratio = $badCount / $Text.Length

    return ($ratio -gt 0.005)
}


# =====================================================================
# ФУНКЦИЯ: Get-TopFolder
# =====================================================================
function Get-TopFolder {
    param([Parameter(Mandatory = $true)][string] $RelPath)

    $parts = $RelPath -split '[\\/]'
    if ($parts.Count -le 1) { return 'ROOT' }

    if ($parts[0] -ieq 'Func' -and $parts.Count -ge 3) {
        return "$($parts[0])/$($parts[1])"
    }

    return $parts[0]
}


# =====================================================================
# ФУНКЦИЯ: New-DumpHeader
# =====================================================================
function New-DumpHeader {
    param(
        [Parameter(Mandatory = $true)] $TocEntries,
        [Parameter(Mandatory = $true)] $BrokenEncodingFiles,
        [Parameter(Mandatory = $true)] $LastFile,
        [string]$PartLabel = '',
        [string]$PartHint  = ''
    )

    $bar = '=' * 69
    $header = [System.Text.StringBuilder]::new()

    [void]$header.AppendLine($bar)
    [void]$header.AppendLine(' GLOBAL PROJECT TREE AND ARCHITECTURE MAP')
    [void]$header.AppendLine($bar)
    [void]$header.AppendLine("Root         : $SourceDir")
    [void]$header.AppendLine("Script dir   : $ScriptDir")
    [void]$header.AppendLine("Manifest     : $ListFile")
    [void]$header.AppendLine("Generated    : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
    if (-not [string]::IsNullOrEmpty($PartLabel)) {
        [void]$header.AppendLine("Part         : $PartLabel")
    }
    if (-not [string]::IsNullOrEmpty($PartHint)) {
        [void]$header.AppendLine("Hint         : $PartHint")
    }
    [void]$header.AppendLine($bar)
    [void]$header.AppendLine(' VERSION INFO (по дате самого свежего файла)')
    [void]$header.AppendLine($bar)
    if ($null -ne $LastFile) {
        $lastRel = $LastFile.FullName.Substring($SourceDir.Length).TrimStart('\','/')
        [void]$header.AppendLine("Last change  : $($LastFile.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))")
        [void]$header.AppendLine("Last file    : $lastRel")
    } else {
        [void]$header.AppendLine('Last change  : (нет файлов)')
    }
    [void]$header.AppendLine($bar)
    [void]$header.AppendLine()

    if ($BrokenEncodingFiles.Count -gt 0) {
        [void]$header.AppendLine($bar)
        [void]$header.AppendLine(' WARNING: ФАЙЛЫ С ПОДОЗРИТЕЛЬНОЙ КОДИРОВКОЙ')
        [void]$header.AppendLine($bar)
        foreach ($bf in $BrokenEncodingFiles) {
            [void]$header.AppendLine("  - $bf")
        }
        [void]$header.AppendLine($bar)
        [void]$header.AppendLine()
    }

    [void]$header.AppendLine($bar)
    [void]$header.AppendLine(' TABLE OF CONTENTS (номер строки = переход в дампе)')
    [void]$header.AppendLine($bar)

    $dash60 = '-' * 60
    [void]$header.AppendLine(("{0,4}  {1,-60}  {2,6}" -f '#',   'FILE', 'LINE'))
    [void]$header.AppendLine(("{0,4}  {1,-60}  {2,6}" -f '---', $dash60, '------'))

    $hasRoot     = ($TocEntries | Where-Object { $_.Section -eq 'ROOT' }).Count -gt 0
    $hasManifest = ($TocEntries | Where-Object { $_.Section -eq 'MANIFEST' }).Count -gt 0

    if ($hasRoot) {
        [void]$header.AppendLine()
        [void]$header.AppendLine('--- ROOT FILES (без рекурсии) ---')
        $n = 0
        foreach ($entry in ($TocEntries | Where-Object { $_.Section -eq 'ROOT' } | Sort-Object File)) {
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
        foreach ($entry in ($TocEntries | Where-Object { $_.Section -eq 'MANIFEST' } | Sort-Object File)) {
            $n++
            $name = $entry.File
            if ($name.Length -gt 60) { $name = '...' + $name.Substring($name.Length - 57) }
            [void]$header.AppendLine(("{0,4}  {1,-60}  {2,6}" -f $n, $name, $entry.Line))
        }
    }

    [void]$header.AppendLine()
    [void]$header.AppendLine($bar)
    [void]$header.AppendLine()

    return $header.ToString()
}


# =====================================================================
# ФУНКЦИЯ: New-DumpBlock
# =====================================================================
function New-DumpBlock {
    param([Parameter(Mandatory = $true)][System.IO.FileInfo] $File)

    $bar = '=' * 69
    $rel = $File.FullName.Substring($SourceDir.Length).TrimStart('\','/')

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine($bar)
    [void]$sb.AppendLine(" FILE START : $rel")
    [void]$sb.AppendLine(" FULL PATH  : $($File.FullName)")
    [void]$sb.AppendLine(" SIZE       : $($File.Length) bytes")
    [void]$sb.AppendLine(" MODIFIED   : $($File.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss'))")
    [void]$sb.AppendLine($bar)
    [void]$sb.AppendLine('--- FILE CONTENT ---')

    $broken = $false
    try {
        $content = Read-FileAsUtf8 -Path $File.FullName

        if (Test-BrokenEncoding -Text $content) {
            $broken = $true
            [void]$sb.AppendLine("<<< WARNING: подозрительная кодировка файла >>>")
        }

        if ($null -ne $content) { [void]$sb.AppendLine($content) }
    }
    catch {
        [void]$sb.AppendLine("<<< READ FAILED: $($_.Exception.Message) >>>")
    }

    [void]$sb.AppendLine()
    [void]$sb.AppendLine($bar)
    [void]$sb.AppendLine(" FILE END : $rel")
    [void]$sb.AppendLine($bar)
    [void]$sb.AppendLine()
    [void]$sb.AppendLine()

    return @{
        Content = $sb.ToString()
        Broken  = $broken
    }
}


# ---------------------------------------------------------------------
# ШАГ 4. ЧТЕНИЕ МАНИФЕСТА И СБОР ФАЙЛОВ
# ---------------------------------------------------------------------
Write-Host "[INFO] Скрипт запущен из : $ScriptDir"  -ForegroundColor Cyan
Write-Host "[INFO] Корень проекта    : $SourceDir"  -ForegroundColor Cyan
Write-Host "[INFO] Манифест подпапок : $ListFile"   -ForegroundColor Cyan
Write-Host "[INFO] Каталог вывода    : $OutDir"     -ForegroundColor Cyan
Write-Host "[INFO] Режим             : $(if ($DryRun) {'DRY-RUN'} else {'WRITE'})" -ForegroundColor Cyan
if ($NoSplit) {
    Write-Host "[INFO] Нарезка           : ОТКЛЮЧЕНА (-NoSplit), один файл" -ForegroundColor Cyan
} else {
    Write-Host "[INFO] Нарезка           : по $SplitSizeKB КБ$(if ($Part -gt 0) {", часть $Part"} else {' (все части)'})" -ForegroundColor Cyan
}

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

$rootSet = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
foreach ($rf in $rootFiles) { [void]$rootSet.Add($rf.FullName) }


# ---------------------------------------------------------------------
# ШАГ 5. ПРОХОД ПО ФАЙЛАМ: генерация блоков
# ---------------------------------------------------------------------
$blocks = New-Object System.Collections.Generic.List[object]

$index = 0
foreach ($file in $files) {
    $index++
    $rel = $file.FullName.Substring($SourceDir.Length).TrimStart('\','/')

    Write-Host ("[{0,4}/{1}] {2}" -f $index, $files.Count, $rel) -ForegroundColor Yellow

    $section = if ($rootSet.Contains($file.FullName)) { 'ROOT' } else { 'MANIFEST' }

    $res = New-DumpBlock -File $file
    if ($res.Broken) {
        Write-Host ("      [WARN] Подозрительная кодировка: {0}" -f $rel) -ForegroundColor Yellow
    }

    [void]$blocks.Add([pscustomobject]@{
        File    = $rel
        Section = $section
        Content = $res.Content
        Broken  = $res.Broken
        Top     = (Get-TopFolder -RelPath $rel)
    })
}


# ---------------------------------------------------------------------
# ШАГ 6. НАРЕЗКА НА ЧАСТИ
# ---------------------------------------------------------------------
$parts = New-Object System.Collections.Generic.List[object]

if ($NoSplit) {
    [void]$parts.Add(@{ Label = ''; Blocks = $blocks })
} else {
    $limitBytes = [int64]$SplitSizeKB * 1024

    $groupOrder = New-Object System.Collections.Generic.List[string]
    $groups     = @{}

    foreach ($b in $blocks) {
        $g = $b.Top
        if (-not $groups.ContainsKey($g)) {
            $groups[$g] = New-Object System.Collections.Generic.List[object]
            [void]$groupOrder.Add($g)
        }
        [void]$groups[$g].Add($b)
    }

    $groupSizes = @{}
    foreach ($g in $groupOrder) {
        $sz = [int64]0
        foreach ($b in $groups[$g]) { $sz += [int64]$b.Content.Length }
        $groupSizes[$g] = $sz
    }

    Write-Host ""
    Write-Host "[INFO] Оценка по верхнеуровневым папкам:" -ForegroundColor Cyan
    foreach ($g in $groupOrder) {
        Write-Host ("       {0,-40} {1,8} КБ ({2} файлов)" -f `
            $g, [math]::Round($groupSizes[$g]/1KB,1), $groups[$g].Count) -ForegroundColor DarkGray
    }
    Write-Host ""

    $curBlocks = New-Object System.Collections.Generic.List[object]
    $curSize   = [int64]0

    foreach ($g in $groupOrder) {
        $gsz = $groupSizes[$g]

        if ($gsz -gt $limitBytes) {
            if ($curBlocks.Count -gt 0) {
                [void]$parts.Add(@{ Label = ''; Blocks = $curBlocks })
                $curBlocks = New-Object System.Collections.Generic.List[object]
                $curSize   = [int64]0
            }

            $innerBlocks = New-Object System.Collections.Generic.List[object]
            $innerSize   = [int64]0

            foreach ($b in $groups[$g]) {
                $bLen = [int64]$b.Content.Length
                if ($innerBlocks.Count -gt 0 -and ($innerSize + $bLen) -gt $limitBytes) {
                    [void]$parts.Add(@{ Label = ''; Blocks = $innerBlocks })
                    $innerBlocks = New-Object System.Collections.Generic.List[object]
                    $innerSize   = [int64]0
                }
                [void]$innerBlocks.Add($b)
                $innerSize += $bLen
            }
            if ($innerBlocks.Count -gt 0) {
                [void]$parts.Add(@{ Label = ''; Blocks = $innerBlocks })
            }
            continue
        }

        if ($curBlocks.Count -gt 0 -and ($curSize + $gsz) -gt $limitBytes) {
            [void]$parts.Add(@{ Label = ''; Blocks = $curBlocks })
            $curBlocks = New-Object System.Collections.Generic.List[object]
            $curSize   = [int64]0
        }

        foreach ($b in $groups[$g]) {
            [void]$curBlocks.Add($b)
        }
        $curSize += $gsz
    }

    if ($curBlocks.Count -gt 0) {
        [void]$parts.Add(@{ Label = ''; Blocks = $curBlocks })
    }

    for ($i = 0; $i -lt $parts.Count; $i++) {
        $parts[$i].Label = "PART $($i+1) of $($parts.Count)"
    }
}


# ---------------------------------------------------------------------
# ШАГ 7. ФИЛЬТР ЧАСТЕЙ (-Part N)
# ---------------------------------------------------------------------
if ($Part -gt 0) {
    if ($Part -gt $parts.Count) {
        throw "Запрошена часть $Part, но доступно только $($parts.Count)."
    }
    $selectedParts = @($parts[$Part - 1])
} else {
    $selectedParts = $parts
}


# ---------------------------------------------------------------------
# ШАГ 8. СБОРКА КАЖДОЙ ЧАСТИ И ЗАПИСЬ В MergeProjectOut
# ---------------------------------------------------------------------
function Get-PartContent {
    param(
        [Parameter(Mandatory = $true)] $Blocks,
        [Parameter(Mandatory = $true)] $BrokenEncodingFiles,
        [Parameter(Mandatory = $true)] $LastFile,
        [string]$PartLabel = '',
        [string]$PartHint  = '',
        [string]$Footer    = ''
    )

    $tocDummy = New-Object System.Collections.Generic.List[object]
    foreach ($b in $Blocks) {
        [void]$tocDummy.Add([pscustomobject]@{
            File    = $b.File
            Line    = 0
            Section = $b.Section
        })
    }

    $headerDummy = New-DumpHeader -TocEntries $tocDummy `
                                 -BrokenEncodingFiles $BrokenEncodingFiles `
                                 -LastFile $LastFile `
                                 -PartLabel $PartLabel `
                                 -PartHint  $PartHint

    $headerLines = ($headerDummy -split "`n").Count

    $toc = New-Object System.Collections.Generic.List[object]
    $runningLine = $headerLines
    foreach ($b in $Blocks) {
        [void]$toc.Add([pscustomobject]@{
            File    = $b.File
            Line    = $runningLine
            Section = $b.Section
        })
        $runningLine += ($b.Content -split "`n").Count
    }

    $header = New-DumpHeader -TocEntries $toc `
                             -BrokenEncodingFiles $BrokenEncodingFiles `
                             -LastFile $LastFile `
                             -PartLabel $PartLabel `
                             -PartHint  $PartHint

    $body = [System.Text.StringBuilder]::new()
    foreach ($b in $Blocks) {
        [void]$body.Append($b.Content)
    }

    if (-not [string]::IsNullOrEmpty($Footer)) {
        [void]$body.Append($Footer)
    }

    return $header + $body.ToString()
}


$brokenEncodingFiles = @()
foreach ($b in $blocks) {
    if ($b.Broken) { $brokenEncodingFiles += $b.File }
}

$totalParts   = $parts.Count
$writtenFiles = New-Object System.Collections.Generic.List[string]

if (-not $DryRun) {
    if (-not (Test-Path -LiteralPath $OutDir -PathType Container)) {
        New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
        Write-Host "[OK] Создан каталог вывода: $OutDir" -ForegroundColor Green
    }
}

for ($pi = 0; $pi -lt $selectedParts.Count; $pi++) {
    $p = $selectedParts[$pi]

    $globalPartIdx = if ($Part -gt 0) { $Part } else { $pi + 1 }

    $partHint = ''
    $footer   = ''
    if ($totalParts -gt 1) {
        $partHint = "Часть $globalPartIdx из $totalParts. Файлы сгруппированы по верхнеуровневым папкам."
        $footer   = ""
        $footer  += ("`n" + ('=' * 69) + "`n")
        $footer  += " === END OF PART $globalPartIdx OF $totalParts ===`n"
        $footer  += " Часть прочитана до конца. Следующая часть: $($globalPartIdx + 1) из $totalParts.`n"
        $footer  += ('=' * 69) + "`n"
    }

    $partContent = Get-PartContent -Blocks $p.Blocks `
                                   -BrokenEncodingFiles $brokenEncodingFiles `
                                   -LastFile $lastFile `
                                   -PartLabel $p.Label `
                                   -PartHint  $partHint `
                                   -Footer    $footer

    if ($totalParts -le 1) {
        $partOutFile = Join-Path $OutDir 'merge_project_dump.txt'
    } else {
        $partOutFile = Join-Path $OutDir ("merge_project_dump.part{0}.txt" -f $globalPartIdx)
    }

    if ($DryRun) {
        Write-Host ""
        Write-Host ("[DRY] Часть {0}: {1} КБ, {2} файлов → {3}" -f `
            $globalPartIdx,
            [math]::Round($partContent.Length/1KB,1),
            $p.Blocks.Count,
            $partOutFile) -ForegroundColor Yellow
        continue
    }

    try {
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($partOutFile, $partContent, $utf8NoBom)
        [void]$writtenFiles.Add($partOutFile)
        Write-Host ("[OK] Часть {0}/{1}: {2} ({3} файлов, {4} КБ)" -f `
            $globalPartIdx, $totalParts, $partOutFile, $p.Blocks.Count,
            [math]::Round($partContent.Length/1KB,1)) -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] Не удалось записать $partOutFile : $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

if ($DryRun) {
    Write-Host ""
    Write-Host "[DRY] Реального сохранения не было." -ForegroundColor Yellow
    return
}

if ($null -ne $lastFile) {
    Write-Host ("[OK] Самый свежий файл: {0} ({1})" -f `
        $lastFile.Name, $lastFile.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')) -ForegroundColor Green
}
if ($brokenEncodingFiles.Count -gt 0) {
    Write-Host ("[WARN] Файлов с подозрительной кодировкой: {0}" -f $brokenEncodingFiles.Count) -ForegroundColor Yellow
}

Write-Host "[OK] Все части записаны в: $OutDir" -ForegroundColor Green


# ---------------------------------------------------------------------
# ШАГ 9. АВТООБЕЗЛИЧИВАНИЕ
# ---------------------------------------------------------------------
if ($NoSanitize) {
    Write-Host "[SKIP] Автообезличивание отключено (-NoSanitize)." -ForegroundColor DarkGray
    return
}

$aiRoot     = Join-Path $SourceDir 'AI'
$sanitizer  = Join-Path $aiRoot 'sanitize_for_repo.ps1'
$repoDir    = Join-Path $aiRoot '_repo'
$patterns   = Join-Path $aiRoot 'sanitize_patterns.json'

if (-not (Test-Path $sanitizer) -or -not (Test-Path $patterns)) {
    Write-Host "[SKIP] sanitize_for_repo.ps1 или sanitize_patterns.json не найдены — обезличивание пропущено." -ForegroundColor DarkGray
    return
}

if (-not (Test-Path $repoDir)) {
    New-Item -ItemType Directory -Path $repoDir -Force | Out-Null
}

Write-Host ""
Write-Host "[SANITIZE] Запуск автообезличивания..." -ForegroundColor Cyan

foreach ($src in $writtenFiles) {
    $leaf    = Split-Path -Leaf $src
    $dstPath = Join-Path $repoDir $leaf

    try {
        & $sanitizer -InputFile $src -OutputFile $dstPath -PatternsPath $patterns
        Write-Host "[SANITIZE] Готово: $dstPath" -ForegroundColor Green
    } catch {
        Write-Host "[SANITIZE] Ошибка для $src : $($_.Exception.Message)" -ForegroundColor Red
    }
}