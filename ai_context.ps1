<#
.SYNOPSIS
    Управляющий центр переноса контекста между сессиями ИИ.

.DESCRIPTION
    Единый инструмент для работы с папкой Z:\DOC\СЕРВЕРА\Scripts\AI.
    Команды:
      status         — состояние AI-папки.
      zip            — собрать zip-пакет для новой сессии.
      down           — распаковать пакет из буфера в файлы.
      repo-push      — залить файлы контекста в GitHub-репозиторий.
      repo-pull      — скачать файлы из GitHub-репозитория в _repo\.
      session-close  — закрытие сессии: down + zip + repo-push.
      help           — справка.

.PARAMETER Command
    status | zip | down | repo-push | repo-pull | session-close | help

.PARAMETER Root
    Корневая папка AI. По умолчанию Z:\DOC\СЕРВЕРА\Scripts\AI.

.PARAMETER LastPatches
    (zip) Сколько последних патчей включить. По умолчанию 30.

.PARAMETER LastChats
    (zip) Сколько последних резюме чатов включить. По умолчанию 5.

.PARAMETER DryRun
    (down, repo-push) Показать, что будет сделано, без записи.

.PARAMETER NoLog
    Отключить запись в logs\ai_context.log.

.EXAMPLE
    .\ai_context.ps1 status
    .\ai_context.ps1 zip
    .\ai_context.ps1 down
    .\ai_context.ps1 down -DryRun
    .\ai_context.ps1 session-close
    .\ai_context.ps1 repo-push
    .\ai_context.ps1 repo-pull

.NOTES
    Требуется PowerShell 5.1+ или PowerShell 7+ (рекомендуется).
    Для команд repo-* требуется gh CLI + авторизация (scope: repo).
    Используется публичный репозиторий DrAngelOk/DrBash.

    АРХИТЕКТУРА ВКРАТЦЕ:
      - Маркеры пакета и список файлов хранятся в config.json
        (секции package и files). Скрипт их НЕ дублирует.
      - down читает маркеры из config.json, а не из кода — так
        формат пакета можно менять, не трогая скрипт.
      - При закрытии сессии пакет содержит: AI_CONTEXT.md,
        AI_TASKS.md, AI_MAP.md, свежий chat-файл, патчи.
      - repo-push заливает ВСЕ файлы из config.json -> files,
        включая AI_MAP.md.
#>

[CmdletBinding()]
param(
    # Имя команды. Пустое значение = показать справку.
    [Parameter(Position = 0)]
    [ValidateSet('zip','down','status','repo-push','repo-pull','session-close','help','')]
    [string]$Command = '',

    # Корневая папка AI. Все операции идут относительно неё.
    [string]$Root        = "Z:\DOC\СЕРВЕРА\Scripts\AI",

    # Сколько последних патчей включать в zip-пакет.
    [int]   $LastPatches = 30,

    # Сколько последних chat-файлов включать в zip-пакет.
    [int]   $LastChats   = 5,

    # Предпросмотр без записи (down, repo-push).
    [switch]$DryRun,

    # Отключить логирование в logs\ai_context.log.
    [switch]$NoLog
)

# Любая ошибка — стоп. Скрипт управляющий, тихие падения недопустимы.
$ErrorActionPreference = 'Stop'

# UTF-8 без BOM — стандарт для всех текстовых файлов проекта.
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# =====================================================================
#  ОБЩИЕ ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
# =====================================================================

# Печатает заголовок команды в едином стиле: пустая строка,
# две линии "=" и название. Используется всеми командами.
function Show-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor DarkCyan
    Write-Host ("  $Title") -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor DarkCyan
}

# Гарантирует существование папки. Аналог mkdir -p.
# Молча ничего не делает, если папка уже есть.
function Ensure-Dir {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

# Запись текста в файл в UTF-8 без BOM.
# Создаёт родительскую папку, если её нет.
# Использует .NET WriteAllText — корректно работает в PS 5.1.
function Write-FileUtf8 {
    param([string]$Path, [string]$Content)
    $dir = Split-Path $Path -Parent
    if ($dir) { Ensure-Dir $dir }
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

# Запись в лог logs\ai_context.log.
# Логи НЕ должны ломать основную работу — все ошибки глушатся.
# Отключается флагом -NoLog.
function Write-AiLog {
    param([string]$Message)
    if ($NoLog) { return }
    try {
        $logDir = Join-Path $Root 'logs'
        Ensure-Dir $logDir
        $logFile = Join-Path $logDir 'ai_context.log'
        $stamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Add-Content -LiteralPath $logFile -Value "[$stamp] $Message" -Encoding UTF8
    } catch {
        # логи не должны ломать основную работу
    }
}

# Чтение config.json. Бросает исключение, если файла нет.
# Читает через ReadAllText с явной UTF-8 — так корректно
# работают русские пути и не ломается PS 5.1.
function Get-Config {
    param([string]$RootPath)
    $cfgPath = Join-Path $RootPath 'config.json'
    if (-not (Test-Path $cfgPath)) {
        throw "config.json не найден: $cfgPath"
    }
    $cfgText = [System.IO.File]::ReadAllText($cfgPath, [System.Text.Encoding]::UTF8)
    return $cfgText | ConvertFrom-Json
}

# Сохранение config.json. Сейчас нигде не вызывается, но
# оставлено для будущих правок конфига из скрипта.
# Пишет через Write-FileUtf8 (UTF-8 без BOM).
function Save-Config {
    param([string]$RootPath, $Config)
    $cfgPath = Join-Path $RootPath 'config.json'
    $json = $Config | ConvertTo-Json -Depth 10
    Write-FileUtf8 -Path $cfgPath -Content $json
}

# Проверка наличия и авторизации gh CLI.
# Нужна перед repo-push / repo-pull.
function Assert-GhCli {
    $gh = Get-Command gh -ErrorAction SilentlyContinue
    if (-not $gh) {
        throw "gh CLI не найден. Установите: winget install --id GitHub.cli --source winget"
    }
    $auth = & gh auth status 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
        throw "gh не авторизован. Выполните: gh auth login (scope: repo)."
    }
}

# Сводка различий файла до и после распаковки.
# Считает добавленные/удалённые строки (по содержимому, не по позиции)
# и изменение размера в байтах. Используется в down для отчёта.
function Get-FileDiffSummary {
    param([string]$Path, [string]$NewContent)

    # Файла нет — это новый файл.
    if (-not (Test-Path $Path)) {
        return "новый файл ($($NewContent.Length) симв.)"
    }

    $oldContent = ''
    try {
        $oldContent = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    } catch {
        return "старый файл не читается, перезаписан"
    }

    # Разбиваем на строки. Сравниваем как мультимножества: важен
    # не порядок, а сколько раз какая строка встречается.
    $oldLines = @($oldContent -split "`r?`n")
    $newLines = @($NewContent -split "`r?`n")

    $oldSet = @{}
    foreach ($l in $oldLines) { $oldSet[$l] = ($oldSet[$l] + 1) }
    $newSet = @{}
    foreach ($l in $newLines) { $newSet[$l] = ($newSet[$l] + 1) }

    # Считаем добавленные строки: те, что в новом встречаются чаще.
    $added = 0
    foreach ($k in $newSet.Keys) {
        $oldCount = if ($oldSet.ContainsKey($k)) { $oldSet[$k] } else { 0 }
        if ($newSet[$k] -gt $oldCount) { $added += ($newSet[$k] - $oldCount) }
    }

    # Считаем удалённые строки: те, что в старом встречались чаще.
    $removed = 0
    foreach ($k in $oldSet.Keys) {
        $newCount = if ($newSet.ContainsKey($k)) { $newSet[$k] } else { 0 }
        if ($oldSet[$k] -gt $newCount) { $removed += ($oldSet[$k] - $newCount) }
    }

    $oldSize = (Get-Item $Path).Length
    $newSize = $NewContent.Length

    return "+$added / -$removed строк, $oldSize -> $newSize байт"
}

# =====================================================================
#  КОМАНДА: status
#  Показывает состояние AI-папки:
#    - ключевые файлы (есть / нет, размер, дата);
#    - папки данных (chats, patches, dumps, _repo, _transfer, logs);
#    - репозиторий и число файлов из config.json;
#    - статистика по патчам и чатам;
#    - последние zip-пакеты в _transfer.
#  Ничего не пишет на диск (кроме лога).
# =====================================================================
function Invoke-Status {
    Show-Header "СОСТОЯНИЕ AI-ПАПКИ"

    if (-not (Test-Path $Root)) {
        Write-Host "[ERROR] Корень не найден: $Root" -ForegroundColor Red
        return
    }

    $rootResolved = (Resolve-Path -LiteralPath $Root).Path
    Write-Host "Корень: $rootResolved" -ForegroundColor Gray
    Write-Host ""

    # Список ключевых файлов. AI_MAP.md добавлен, чтобы status
    # показывал карту проекта наравне с остальными.
    $keyFiles = @(
        'ai_context.ps1',
        'config.json',
        'AI_CONTEXT.md',
        'AI_TASKS.md',
        'AI_MAP.md',
        '_END_OF_SESSION_PROMPT.txt',
        'sanitize_for_repo.ps1',
        'sanitize_patterns.json'
    )
    Write-Host "-- Ключевые файлы --" -ForegroundColor Yellow
    foreach ($f in $keyFiles) {
        $path = Join-Path $Root $f
        if (Test-Path $path) {
            $item = Get-Item $path
            Write-Host ("  [OK]  {0,-28} {1,8} байт  {2}" -f `
                $f, $item.Length, $item.LastWriteTime.ToString('yyyy-MM-dd HH:mm')) -ForegroundColor Green
        } else {
            Write-Host ("  [--]  {0,-28} отсутствует" -f $f) -ForegroundColor Red
        }
    }
    Write-Host ""

    # Папки данных: chats (резюме сессий), patches (правки),
    # dumps (оригинальные дампы), _repo (копии из репозитория),
    # _transfer (готовые zip), logs (журнал).
    Write-Host "-- Папки данных --" -ForegroundColor Yellow
    foreach ($d in 'chats','patches','dumps','_repo','_transfer','logs') {
        $path = Join-Path $Root $d
        if (Test-Path $path) {
            $cnt = @(Get-ChildItem $path -File -ErrorAction SilentlyContinue).Count
            Write-Host ("  [OK]  {0,-28} {1} файлов" -f "$d\", $cnt) -ForegroundColor Green
        } else {
            Write-Host ("  [--]  {0,-28} отсутствует" -f "$d\") -ForegroundColor Red
        }
    }
    Write-Host ""

    # Блок репозитория — читается из config.json.
    $cfgPath = Join-Path $Root 'config.json'
    if (Test-Path $cfgPath) {
        try {
            $cfg = Get-Config -RootPath $Root
            Write-Host "-- Repository --" -ForegroundColor Yellow
            if ([string]::IsNullOrWhiteSpace($cfg.repo_owner) -or [string]::IsNullOrWhiteSpace($cfg.repo_name)) {
                Write-Host "  [--]  repo_owner/repo_name пусты — проверьте config.json" -ForegroundColor DarkYellow
            } else {
                Write-Host ("  repo     : {0}/{1}" -f $cfg.repo_owner, $cfg.repo_name) -ForegroundColor Cyan
                Write-Host ("  url      : {0}" -f $cfg.repo_url) -ForegroundColor Cyan
                Write-Host ("  raw_base : {0}" -f $cfg.raw_base) -ForegroundColor Cyan
                if ($cfg.files) {
                    Write-Host ("  files    : {0}" -f $cfg.files.Count) -ForegroundColor Cyan
                }
            }
            Write-Host ""
        } catch {
            Write-Host "[WARN] config.json повреждён: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

    # Статистика по патчам: сколько всего .md и когда последний.
    $patchesDir = Join-Path $Root 'patches'
    $patchesCount = 0
    $patchesLast = $null
    if (Test-Path $patchesDir) {
        $p = @(Get-ChildItem $patchesDir -Filter *.md -ErrorAction SilentlyContinue)
        $patchesCount = $p.Count
        if ($patchesCount -gt 0) {
            $patchesLast = ($p | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
        }
    }
    Write-Host "-- Патчи --" -ForegroundColor Yellow
    Write-Host ("  Всего .md: {0}" -f $patchesCount) -ForegroundColor Gray
    if ($patchesLast) {
        Write-Host ("  Последний: {0}" -f $patchesLast.ToString('yyyy-MM-dd HH:mm')) -ForegroundColor Gray
    }
    Write-Host ""

    # Статистика по чатам: сколько всего .md и когда последний.
    $chatsDir = Join-Path $Root 'chats'
    $chatsCount = 0
    $chatsLast = $null
    if (Test-Path $chatsDir) {
        $c = @(Get-ChildItem $chatsDir -Filter *.md -ErrorAction SilentlyContinue)
        $chatsCount = $c.Count
        if ($chatsCount -gt 0) {
            $chatsLast = ($c | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime
        }
    }
    Write-Host "-- Чаты --" -ForegroundColor Yellow
    Write-Host ("  Всего .md: {0}" -f $chatsCount) -ForegroundColor Gray
    if ($chatsLast) {
        Write-Host ("  Последний: {0}" -f $chatsLast.ToString('yyyy-MM-dd HH:mm')) -ForegroundColor Gray
    }
    Write-Host ""

    # Последние zip-пакеты в _transfer (до 3 штук).
    $transferDir = Join-Path $Root '_transfer'
    if (Test-Path $transferDir) {
        $zips = @(Get-ChildItem $transferDir -Filter *.zip -ErrorAction SilentlyContinue |
                  Sort-Object LastWriteTime -Descending | Select-Object -First 3)
        if ($zips.Count -gt 0) {
            Write-Host "-- Последние пакеты для новой сессии --" -ForegroundColor Yellow
            foreach ($z in $zips) {
                Write-Host ("  {0,-45} {1,7} КБ  {2}" -f `
                    $z.Name, [math]::Round($z.Length/1KB,1), $z.LastWriteTime.ToString('yyyy-MM-dd HH:mm')) -ForegroundColor Cyan
            }
        } else {
            Write-Host "-- Последние пакеты для новой сессии --" -ForegroundColor Yellow
            Write-Host "  пока нет ни одного zip" -ForegroundColor DarkGray
        }
    }
    Write-Host ""
    Write-Host "Подсказка: zip — собрать пакет | session-close — закрыть сессию" -ForegroundColor DarkGray
}

# =====================================================================
#  КОМАНДА: zip
#  Собирает zip-пакет для следующей сессии.
#  Состав пакета:
#    1. AI_CONTEXT.md          (контекст и история)
#    2. AI_TASKS.md            (чек-лист задач)
#    3. AI_MAP.md              (карта проекта)      <- [FIX]
#    4. до LastPatches патчей  (patches\*.md)
#    5. до LastChats чатов     (chats\*.md)
#  Пакет кладётся в _transfer\ai_package_<stamp>.zip.
#  Сборка идёт через временную папку %TEMP%\ai_pack_<stamp>,
#  чтобы Compress-Archive не тянул лишние пути.
# =====================================================================
function Invoke-Zip {
    Show-Header "СБОРКА ПАКЕТА ДЛЯ НОВОЙ СЕССИИ"

    if (-not (Test-Path $Root)) {
        Write-Host "[ERROR] Корень не найден: $Root" -ForegroundColor Red
        return
    }

    $stamp  = Get-Date -Format "yyyy-MM-dd_HHmm"
    $outDir = Join-Path $Root "_transfer"
    $zip    = Join-Path $outDir "ai_package_$stamp.zip"

    # Готовим выходную папку и чистим возможный старый zip с тем же именем.
    Ensure-Dir $outDir
    if (Test-Path $zip) { Remove-Item $zip -Force }

    # Временная папка сборки. Чистится после упаковки.
    $tmp = Join-Path $env:TEMP "ai_pack_$stamp"
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
    Ensure-Dir $tmp

    # Шаг 1: статичные файлы контекста.
    # [FIX] добавлен AI_MAP.md — карта проекта должна попадать
    #       в zip для новой сессии наравне с контекстом и чек-листом.
    foreach ($f in 'AI_CONTEXT.md','AI_TASKS.md','AI_MAP.md') {
        $src = Join-Path $Root $f
        if (Test-Path $src) {
            Copy-Item $src -Destination $tmp -Force
            Write-Host "[OK] + $f" -ForegroundColor Green
        } else {
            Write-Host "[WARN] нет файла: $f" -ForegroundColor Yellow
        }
    }

    # Шаг 2: патчи. Берём не больше LastPatches, самые свежие.
    $patchesDir = Join-Path $Root 'patches'
    Ensure-Dir (Join-Path $tmp 'patches')
    if (Test-Path $patchesDir) {
        $patches = @(Get-ChildItem $patchesDir -Filter *.md -ErrorAction SilentlyContinue |
                     Sort-Object LastWriteTime -Descending |
                     Select-Object -First $LastPatches)
        foreach ($p in $patches) {
            Copy-Item $p.FullName -Destination (Join-Path $tmp 'patches') -Force
        }
        Write-Host "[OK] + patches: $($patches.Count) файлов" -ForegroundColor Green
    }

    # Шаг 3: чаты. Берём не больше LastChats, самые свежие.
    $chatsDir = Join-Path $Root 'chats'
    Ensure-Dir (Join-Path $tmp 'chats')
    if (Test-Path $chatsDir) {
        $chats = @(Get-ChildItem $chatsDir -Filter *.md -ErrorAction SilentlyContinue |
                   Sort-Object LastWriteTime -Descending |
                   Select-Object -First $LastChats)
        foreach ($c in $chats) {
            Copy-Item $c.FullName -Destination (Join-Path $tmp 'chats') -Force
        }
        Write-Host "[OK] + chats: $($chats.Count) файлов" -ForegroundColor Green
    }

    # Упаковка и уборка временной папки.
    Compress-Archive -Path (Join-Path $tmp '*') -DestinationPath $zip -Force
    Remove-Item $tmp -Recurse -Force

    Write-Host ""
    Write-Host "[DONE] Пакет: $zip" -ForegroundColor Cyan
    Write-Host "[INFO] Размер: $([math]::Round((Get-Item $zip).Length/1KB,1)) КБ" -ForegroundColor Cyan
    Write-Host "[NEXT] Прикрепите этот zip первым сообщением в новую сессию." -ForegroundColor Yellow

    Write-AiLog "[zip] $zip"
}

# =====================================================================
#  КОМАНДА: down
#  Распаковывает ответ ИИ из буфера обмена в файлы.
#
#  КЛЮЧЕВОЕ: маркеры пакета читаются из config.json (секция package),
#  а не из кода. Так формат пакета можно менять в одном месте,
#  не трогая скрипт.
#
#  ЗАЩИТНЫЕ МЕХАНИЗМЫ (см. FIX T-006):
#    - проверка наличия START и END маркеров; при отсутствии
#      спрашивает подтверждение y/N;
#    - проверка парности BEGIN-FILE и END-FILE во всём буфере;
#      при несовпадении — предупреждение и запрос y/N;
#    - отказ от конкретного блока, если внутри его тела встретился
#      маркер BEGIN-FILE (верный признак обрезки);
#    - проверка path traversal: путь обязан начинаться с корня;
#    - Repair-PathForRoot: попытка восстановить потерянный
#      разделитель пути (например, AI_test.md -> AI\_test.md);
#    - DryRun: показать план без записи;
#    - сводка по каждому файлу: сколько строк добавилось/удалилось.
# =====================================================================
function Invoke-Down {
    Show-Header "РАСПАКОВКА ПАКЕТА ИЗ БУФЕРА"

    # --- 1. Читаем маркеры из config.json ---
    # Если config.json недоступен — работать нельзя: нечем
    # разбирать буфер.
    $cfg = $null
    try {
        $cfg = Get-Config -RootPath $Root
    } catch {
        Write-Host "[ERROR] Не удалось прочитать config.json: $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    $pkg = $cfg.package
    if (-not $pkg) {
        Write-Host "[ERROR] В config.json нет секции 'package'." -ForegroundColor Red
        return
    }

    $startMarker   = $pkg.start_marker
    $beginMarker   = $pkg.begin_file_marker
    $endFileMarker = $pkg.end_file_marker
    $endMarker     = $pkg.end_marker

    # Все четыре маркера обязательны. Любой пустой — стоп.
    if ([string]::IsNullOrWhiteSpace($startMarker) -or
        [string]::IsNullOrWhiteSpace($beginMarker) -or
        [string]::IsNullOrWhiteSpace($endFileMarker) -or
        [string]::IsNullOrWhiteSpace($endMarker)) {
        Write-Host "[ERROR] В config.json секция 'package' неполная." -ForegroundColor Red
        return
    }

    # --- 2. Читаем буфер ---
    # Get-Clipboard -Raw возвращает весь текст как одну строку,
    # сохраняя \r\n внутри. Это критично для регулярки ниже.
    try {
        $text = Get-Clipboard -Raw
    } catch {
        Write-Host "[ERROR] Не удалось прочитать буфер: $($_.Exception.Message)" -ForegroundColor Red
        Write-AiLog "[down] ERROR: буфер не читается"
        return
    }

    if ([string]::IsNullOrWhiteSpace($text)) {
        Write-Host "[ERROR] Буфер обмена пуст. Скопируйте ответ ИИ и повторите." -ForegroundColor Red
        Write-AiLog "[down] ERROR: буфер пуст"
        return
    }

    Write-Host "[INFO] Прочитано из буфера: $($text.Length) символов" -ForegroundColor Cyan

    # --- 3. Проверяем START и END маркеры ---
    # Если хотя бы одного нет — спрашиваем пользователя,
    # продолжать ли. Это защита от частично скопированного пакета.
    $hasStart = $text.Contains($startMarker)
    $hasEnd   = $text.Contains($endMarker)

    if (-not $hasStart) {
        Write-Host "[WARN] Не найден маркер '$startMarker'." -ForegroundColor Yellow
    } else {
        Write-Host "[OK] Маркер START найден." -ForegroundColor Green
    }

    if (-not $hasEnd) {
        Write-Host "[WARN] Не найден маркер '$endMarker'." -ForegroundColor Yellow
    } else {
        Write-Host "[OK] Маркер END найден." -ForegroundColor Green
    }

    if (-not $hasStart -or -not $hasEnd) {
        Write-Host ""
        Write-Host "Продолжить распаковку? (y/N): " -ForegroundColor Yellow -NoNewline
        $ans = Read-Host
        if ($ans -ne 'y' -and $ans -ne 'Y') {
            Write-Host "[CANCEL] Отменено пользователем." -ForegroundColor DarkYellow
            Write-AiLog "[down] CANCEL: маркеры не найдены"
            return
        }
    }

    # --- 4. FIX (T-006): Проверка парности BEGIN и END во всём буфере ---
    # Если количество BEGIN-FILE и END-FILE не совпадает, значит
    # какой-то блок обрезан. Это типичный симптом обрыва пакета
    # при копировании. Требуем подтверждения.
    $beginCount = ([regex]::Matches($text, [regex]::Escape($beginMarker))).Count
    $endCount   = ([regex]::Matches($text, [regex]::Escape($endFileMarker))).Count

    Write-Host "[INFO] Маркеров BEGIN в буфере: $beginCount" -ForegroundColor DarkGray
    Write-Host "[INFO] Маркеров END   в буфере: $endCount"   -ForegroundColor DarkGray

    if ($beginCount -ne $endCount) {
        Write-Host "[WARN] Количество BEGIN ($beginCount) и END ($endCount) не совпадает!" -ForegroundColor Yellow
        Write-Host "[WARN] Пакет может быть неполным или сломанным." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Продолжить распаковку? (y/N): " -ForegroundColor Yellow -NoNewline
        $ans = Read-Host
        if ($ans -ne 'y' -and $ans -ne 'Y') {
            Write-Host "[CANCEL] Отменено пользователем." -ForegroundColor DarkYellow
            Write-AiLog "[down] CANCEL: BEGIN/END не парные ($beginCount/$endCount)"
            return
        }
    } else {
        Write-Host "[OK] Количество BEGIN и END совпадает." -ForegroundColor Green
    }

    # --- 5. Разбираем блоки BEGIN-FILE ... END-FILE ---
    # Регулярка с (?ms):
    #   m — ^ и $ работают построчно;
    #   s — точка матчит \n (для многострочного тела).
    # Обратная ссылка \k<path> требует, чтобы путь в END-FILE
    # совпадал с путём в BEGIN-FILE. Несовпадающий блок
    # просто не будет найден.
    $escBegin = [regex]::Escape($beginMarker)
    $escEnd   = [regex]::Escape($endFileMarker)

    $pattern = '(?ms)^' + $escBegin + '[ \t]+(?<path>.+?)[ \t]*\r?\n' +
               '(?<body>.*?)\r?\n' + $escEnd + '[ \t]+\k<path>[ \t]*$'

    $matches = [regex]::Matches($text, $pattern)

    if ($matches.Count -eq 0) {
        Write-Host "[WARN] Не найдено ни одного блока BEGIN-FILE ... END-FILE." -ForegroundColor Yellow
        Write-Host "[HINT] Проверьте формат пакета и config.json." -ForegroundColor DarkGray
        Write-AiLog "[down] WARN: 0 блоков"
        return
    }

    Write-Host "[INFO] Найдено блоков: $($matches.Count)" -ForegroundColor Cyan
    Write-Host ""

    # --- 6. Обрабатываем каждый блок ---
    # rootFull / rootPrefix — граница безопасности: любой путь
    # за пределами корня отбрасывается (path traversal guard).
    $rootFull   = (Resolve-Path -LiteralPath $Root).Path
    $rootPrefix = $rootFull + [System.IO.Path]::DirectorySeparatorChar

    $saved   = 0
    $failed  = 0
    $skipped = 0
    $broken  = 0
    $summaries = @()

    foreach ($m in $matches) {
        $rawPath = $m.Groups['path'].Value.Trim()
        $body    = $m.Groups['body'].Value

        # --- 6.1. FIX (T-006): Проверка тела на наличие маркера BEGIN-FILE ---
        # Если внутри тела встретился BEGIN-FILE (с другим путём) — это
        # верный признак обрезки файла или сломанного пакета.
        # Такой блок не сохраняем — иначе получим мусорный файл.
        if ($body -match ('(?m)^' + $escBegin + '[ \t]')) {
            Write-Host "[BROKEN] В теле файла найден маркер BEGIN-FILE — пропуск:" -ForegroundColor Red
            Write-Host "         $rawPath" -ForegroundColor Red
            Write-Host "         Файл мог быть обрезан. Проверьте пакет." -ForegroundColor DarkYellow
            $broken++
            continue
        }

        # --- 6.2. Нормализация пути ---
        # Относительные пути считаем от корня.
        $candidatePath = $rawPath
        if (-not [System.IO.Path]::IsPathRooted($candidatePath)) {
            $candidatePath = Join-Path $Root $candidatePath
        }

        # --- 6.3. Проверка и восстановление пути ---
        # Сначала пробуем как есть. Если путь вне корня —
        # пытаемся восстановить через Repair-PathForRoot.
        try {
            $fullPath = [System.IO.Path]::GetFullPath($candidatePath)
        } catch {
            $fullPath = $candidatePath
        }

        if (-not $fullPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            $recoveredPath = Repair-PathForRoot -BrokenPath $candidatePath -RootPath $rootFull
            if ($recoveredPath -and $recoveredPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
                Write-Host "[FIX] Путь восстановлен: $rawPath → $recoveredPath" -ForegroundColor Yellow
                $fullPath = $recoveredPath
            }
        }

        # --- 6.4. Финальная проверка пути ---
        # Если после всех попыток путь вне корня — пропускаем.
        if (-not $fullPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
            Write-Host "[ERR] ПУТЬ ВНЕ КОРНЯ — пропуск: $fullPath" -ForegroundColor Red
            $skipped++
            continue
        }

        # DryRun: показать, что было бы сохранено, и не писать.
        if ($DryRun) {
            Write-Host "[DRY] $fullPath ($($body.Length) симв.)" -ForegroundColor DarkGray
            continue
        }

        # Считаем diff ДО записи — нужен старый файл.
        $diffSummary = Get-FileDiffSummary -Path $fullPath -NewContent $body

        try {
            Write-FileUtf8 -Path $fullPath -Content $body
            Write-Host "[OK]  $fullPath" -ForegroundColor Green
            Write-Host "      $diffSummary" -ForegroundColor DarkGray
            $summaries += "  - $fullPath : $diffSummary"
            $saved++
        } catch {
            Write-Host "[ERR] $fullPath — $($_.Exception.Message)" -ForegroundColor Red
            $failed++
        }
    }

    # --- 7. Итоговая сводка ---
    if (-not $DryRun) {
        Write-Host ""
        Write-Host "[DONE] Обновлено: $saved, ошибок: $failed, пропущено: $skipped, сломано: $broken" -ForegroundColor Cyan

        if ($summaries.Count -gt 0) {
            Write-Host ""
            Write-Host "Сводка по файлам:" -ForegroundColor Yellow
            foreach ($s in $summaries) {
                Write-Host $s -ForegroundColor DarkGray
            }
        }

        Write-AiLog "[down] saved=$saved failed=$failed skipped=$skipped broken=$broken"
    } else {
        Write-Host ""
        Write-Host "[DRY] Реального сохранения не было." -ForegroundColor Yellow
        Write-AiLog "[down] DRY-RUN, блоков=$($matches.Count)"
    }
}

# =====================================================================
#  ВСПОМОГАТЕЛЬНАЯ ФУНКЦИЯ: Repair-PathForRoot
#  Восстанавливает путь, если потерян разделитель (например,
#  'AI_test.md' вместо 'AI\_test.md').
#
#  Три попытки, по порядку:
#    1. Родительская папка $dir уже внутри корня — просто склеиваем.
#    2. Имя листа содержит '_': пробуем вставить '\' перед '_'
#       в разных вариантах.
#    3. Ищем ближайшую существующую родительскую папку и
#       присоединяем к ней лист.
#
#  Возвращает полный путь или $null, если не удалось.
# =====================================================================
function Repair-PathForRoot {
    param(
        [string]$BrokenPath,
        [string]$RootPath
    )

    # Единый стиль разделителей — Windows-обратный слеш.
    $norm = $BrokenPath -replace '/', '\'
    $leaf = Split-Path -Leaf $norm
    $dir  = Split-Path -Parent $norm

    $rootFull   = (Resolve-Path -LiteralPath $RootPath).Path
    $rootPrefix = $rootFull + '\'

    # Вариант 1: директория $dir уже внутри $Root — просто склеиваем.
    if ($dir) {
        try {
            $dirFull = [System.IO.Path]::GetFullPath($dir)
            if ($dirFull.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
                return (Join-Path $dir $leaf)
            }
        } catch { }
    }

    # Вариант 2: пробуем вставить разделитель перед символом '_'.
    # Пример: leaf = "_test.md" -> parent = "AI", sep = "_",
    # rest = "test.md". Тогда строим кандидатов вида
    # dir + "\_test.md" или dir + "\AI\_test.md".
    if ($leaf -match '^(?<parent>.+?)(?<sep>_)(?<rest>.+)$') {
        $parentPart = $Matches['parent']
        $sepPart    = $Matches['sep']
        $restPart   = $Matches['rest']

        $candidates = @()

        if ($dir) {
            $candidates += (Join-Path $dir ($sepPart + $restPart))
            $candidates += (Join-Path (Join-Path $dir $parentPart) ($sepPart + $restPart))
        }

        foreach ($cand in $candidates) {
            try {
                $full = [System.IO.Path]::GetFullPath($cand)
                if ($full.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
                    return $full
                }
            } catch { }
        }
    }

    # Вариант 3: ищем существующую родительскую папку.
    # Идём по частям пути справа налево, на каждой итерации
    # проверяем, существует ли такая папка. Первая найденная
    # (ближайшая) — берём как родителя.
    if ($dir) {
        $parts = $dir -split '\\'
        for ($i = $parts.Length - 1; $i -ge 1; $i--) {
            $prefixCandidate = ($parts[0..($i-1)] -join '\')
            $folderCandidate = $parts[$i]
            $tryPath = Join-Path $prefixCandidate $folderCandidate
            if (Test-Path $tryPath -PathType Container) {
                $full = [System.IO.Path]::GetFullPath($tryPath)
                if ($full.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
                    return (Join-Path $full $leaf)
                }
            }
        }
    }

    # Не удалось восстановить — возвращаем $null.
    return $null
}

# =====================================================================
#  КОМАНДА: repo-push
#  Заливает ВСЕ файлы из config.json -> files в GitHub.
#  Для каждого файла:
#    1. Получить текущий SHA через gh api GET.
#    2. Прочитать локальный файл, закодировать в base64.
#    3. PUT через gh api с payload {message, content, branch, sha}.
#  SHA нужен для обновления существующего файла; для нового —
#  не передаётся. Payload пишется во временный JSON (UTF-8 без BOM),
#  чтобы не спотыкаться на экранировании.
#  Параметр -DryRun: показать список файлов и выйти без PUT.
# =====================================================================
function Invoke-RepoPush {
    Show-Header "ОБНОВЛЕНИЕ GITHUB-РЕПОЗИТОРИЯ"

    Assert-GhCli
    $cfg = Get-Config -RootPath $Root

    if ([string]::IsNullOrWhiteSpace($cfg.repo_owner) -or [string]::IsNullOrWhiteSpace($cfg.repo_name)) {
        Write-Host "[ERROR] В config.json не заданы repo_owner / repo_name." -ForegroundColor Red
        return
    }

    $owner  = $cfg.repo_owner
    $repo   = $cfg.repo_name
    $branch = if ($cfg.branch) { $cfg.branch } else { 'main' }

    if (-not $cfg.files -or $cfg.files.Count -eq 0) {
        Write-Host "[ERROR] В config.json нет поля files." -ForegroundColor Red
        return
    }

    Write-Host ("[INFO] Репозиторий: {0}/{1} (branch: {2})" -f $owner, $repo, $branch) -ForegroundColor Cyan
    Write-Host ""

    # Сначала проверяем наличие всех файлов. Если чего-то нет —
    # лучше упасть сразу, чем залить половину.
    $missing = @()
    foreach ($item in $cfg.files) {
        $localPath = $item.local
        if (-not $localPath) {
            $localPath = Join-Path $Root $item.name
        }
        if (-not (Test-Path $localPath)) {
            $missing += $item.name
        } else {
            $sz = (Get-Item $localPath).Length
            Write-Host ("[OK]  {0,-32} {1,8} байт  ← {2}" -f $item.name, $sz, $localPath) -ForegroundColor Green
        }
    }
    if ($missing.Count -gt 0) {
        Write-Host ""
        Write-Host "[ERROR] Отсутствуют файлы: $($missing -join ', ')" -ForegroundColor Red
        return
    }

    if ($DryRun) {
        Write-Host ""
        Write-Host "[DRY] Дальше был бы PUT через gh api — пропускаем из-за -DryRun." -ForegroundColor Yellow
        return
    }

    Write-Host ""
    Write-Host "[INFO] Загружаю файлы в репозиторий..." -ForegroundColor Cyan

    # gh api возвращает ненулевой код при ошибке. Мы хотим
    # продолжать по остальным файлам, поэтому локально отключаем Stop.
    $savedEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'

    try {
        foreach ($item in $cfg.files) {
            $name      = $item.name
            $localPath = if ($item.local) { $item.local } else { Join-Path $Root $name }

            # Получаем текущий SHA (нужен для обновления существующего файла).
            $sha = $null
            $shaOut = & {
                gh api "repos/$owner/$repo/contents/$name`?ref=$branch" --jq '.sha' 2>&1
            } | Out-String
            if ($LASTEXITCODE -eq 0) {
                $sha = $shaOut.Trim()
            }

            # Кодируем содержимое файла в base64 для GitHub API.
            $bytes = [System.IO.File]::ReadAllBytes($localPath)
            $b64 = [Convert]::ToBase64String($bytes)

            # Собираем payload. sha включаем только если он валиден.
            $payload = @{
                message = "Update $name"
                content = $b64
                branch  = $branch
            }
            if ($sha -and $sha -ne 'null' -and $sha.Length -ge 7) {
                $payload.sha = $sha
            }

            $payloadJson = $payload | ConvertTo-Json -Compress

            Write-Host ("  → {0}" -f $name) -ForegroundColor Gray

            # Payload передаём через временный файл: так надёжнее,
            # чем через --field / --raw-field (не надо экранировать).
            $tmpJson = [System.IO.Path]::GetTempFileName()
            try {
                [System.IO.File]::WriteAllText($tmpJson, $payloadJson, (New-Object System.Text.UTF8Encoding($false)))
                $out = & {
                    gh api -X PUT "repos/$owner/$repo/contents/$name" --input "$tmpJson" 2>&1
                } | Out-String
            } finally {
                Remove-Item $tmpJson -Force -ErrorAction SilentlyContinue
            }

            $rc = $LASTEXITCODE
            if ($rc -ne 0) {
                Write-Host "[ERROR] gh api PUT '$name' failed (rc=$rc):" -ForegroundColor Red
                Write-Host $out -ForegroundColor Red
                Write-AiLog "[repo-push] ERROR $name rc=$rc"
            }
        }

        Write-Host ""
        Write-Host "[OK] Все файлы отправлены." -ForegroundColor Green
        Write-Host ("     URL: {0}" -f $cfg.repo_url) -ForegroundColor Cyan
        Write-AiLog "[repo-push] $owner/$repo files=$($cfg.files.Count)"
    } finally {
        # Возвращаем исходный ErrorActionPreference.
        $ErrorActionPreference = $savedEAP
    }

    Write-Host ""
    Write-Host "[DONE] repo-push завершён." -ForegroundColor Cyan
}

# =====================================================================
#  КОМАНДА: repo-pull
#  Скачивает все файлы из config.json -> files в локальную папку _repo.
#  Для каждого файла: gh api GET -> .content (base64) -> декодировать
#  -> записать байты. Ничего не коммитит.
# =====================================================================
function Invoke-RepoPull {
    Show-Header "СКАЧИВАНИЕ ИЗ РЕПОЗИТОРИЯ"

    Assert-GhCli
    $cfg = Get-Config -RootPath $Root

    if ([string]::IsNullOrWhiteSpace($cfg.repo_owner) -or [string]::IsNullOrWhiteSpace($cfg.repo_name)) {
        Write-Host "[ERROR] В config.json не заданы repo_owner / repo_name." -ForegroundColor Red
        return
    }

    $owner  = $cfg.repo_owner
    $repo   = $cfg.repo_name
    $branch = if ($cfg.branch) { $cfg.branch } else { 'main' }

    $repoDir = Join-Path $Root '_repo'
    Ensure-Dir $repoDir

    if (-not $cfg.files -or $cfg.files.Count -eq 0) {
        Write-Host "[ERROR] В config.json нет поля files." -ForegroundColor Red
        return
    }

    Write-Host ("[INFO] Репозиторий: {0}/{1} (branch: {2})" -f $owner, $repo, $branch) -ForegroundColor Cyan
    Write-Host ""

    # Как и в repo-push, локально отключаем Stop, чтобы не падать
    # на первом же неудачном файле.
    $savedEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'

    try {
        foreach ($item in $cfg.files) {
            $name = $item.name
            Write-Host ("  ← {0}" -f $name) -ForegroundColor Gray
            $dest = Join-Path $repoDir $name

            # Скачиваем base64-строку содержимого.
            $content = & {
                gh api "repos/$owner/$repo/contents/$name`?ref=$branch" --jq '.content' 2>&1
            } | Out-String

            if ($LASTEXITCODE -ne 0) {
                Write-Host "[ERROR] gh api GET '$name' failed." -ForegroundColor Red
                continue
            }

            # GitHub отдаёт base64 с переносами строк — убираем их.
            $b64 = $content.Trim() -replace "`r", "" -replace "`n", ""
            try {
                $bytes = [Convert]::FromBase64String($b64)
                [System.IO.File]::WriteAllBytes($dest, $bytes)
                Write-Host ("      → {0}" -f $dest) -ForegroundColor DarkGray
            } catch {
                Write-Host "[ERROR] Не удалось декодировать base64 для '$name': $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        Write-AiLog "[repo-pull] $owner/$repo"
    } finally {
        $ErrorActionPreference = $savedEAP
    }

    Write-Host ""
    Write-Host "[DONE] Скачано в $repoDir" -ForegroundColor Cyan
}

# =====================================================================
#  КОМАНДА: session-close
#  Одна команда для закрытия сессии:
#    1. down — распаковать ответ ИИ из буфера (пакет переноса).
#    2. zip  — собрать zip для следующей сессии.
#    3. repo-push — залить обновлённые файлы контекста в GitHub.
#  Шаги выполняются последовательно, каждый печатает свой header.
# =====================================================================
function Invoke-SessionClose {
    Show-Header "ЗАКРЫТИЕ СЕССИИ"
    Write-AiLog "[session-close] START"

    Write-Host "[INFO] Шаг 1/3: down (распаковка ответа ИИ из буфера)" -ForegroundColor Cyan
    Invoke-Down

    Write-Host ""
    Write-Host "[INFO] Шаг 2/3: zip (сборка пакета для следующей сессии)" -ForegroundColor Cyan
    Invoke-Zip

    Write-Host ""
    Write-Host "[INFO] Шаг 3/3: repo-push (обновление GitHub-репозитория)" -ForegroundColor Cyan
    Invoke-RepoPush

    Write-Host ""
    Write-Host "[DONE] Сессия закрыта." -ForegroundColor Green
    Write-AiLog "[session-close] DONE"
}

# =====================================================================
#  КОМАНДА: help
#  Печатает справку по командам и параметрам.
# =====================================================================
function Invoke-Help {
    Show-Header "AI CONTEXT — УПРАВЛЯЮЩИЙ ЦЕНТР"
    Write-Host ""
    Write-Host "Корень AI-папки: $Root" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Команды:" -ForegroundColor Yellow
    Write-Host "  status                 Показать состояние AI-папки" -ForegroundColor Gray
    Write-Host "  zip                    Собрать zip для новой сессии" -ForegroundColor Gray
    Write-Host "  down                   Распаковать ответ ИИ из буфера" -ForegroundColor Gray
    Write-Host "  down -DryRun           Предпросмотр распаковки" -ForegroundColor Gray
    Write-Host "  repo-push              Залить файлы контекста в GitHub-репозиторий" -ForegroundColor Gray
    Write-Host "  repo-push -DryRun      Показать, что будет залито" -ForegroundColor Gray
    Write-Host "  repo-pull              Скачать файлы из репозитория в _repo\" -ForegroundColor Gray
    Write-Host "  session-close          Закрыть сессию: down + zip + repo-push" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Дополнительные параметры:" -ForegroundColor Yellow
    Write-Host "  -Root <путь>       Корень AI-папки" -ForegroundColor Gray
    Write-Host "  -LastPatches <N>   Сколько патчей в пакет" -ForegroundColor Gray
    Write-Host "  -LastChats <N>     Сколько чатов в пакет" -ForegroundColor Gray
    Write-Host "  -NoLog             Отключить запись в logs\ai_context.log" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Типичные сценарии:" -ForegroundColor Yellow
    Write-Host "  Начало сессии:  открыть raw-URL из репозитория, прочитать AI_CONTEXT + AI_TASKS" -ForegroundColor Gray
    Write-Host "  Конец сессии:   скопировать ответ ИИ → session-close" -ForegroundColor Gray
    Write-Host ""
}

# =====================================================================
#  ДИСПЕТЧЕР
#  Простая маршрутизация: имя команды -> вызов функции.
#  Пустая строка или 'help' -> справка.
#  Неизвестное значение -> справка (ValidateSet не пропустит,
#  но default оставлен для страховки).
# =====================================================================
switch ($Command) {
    'zip'            { Invoke-Zip }
    'down'           { Invoke-Down }
    'status'         { Invoke-Status }
    'repo-push'      { Invoke-RepoPush }
    'repo-pull'      { Invoke-RepoPull }
    'session-close'  { Invoke-SessionClose }
    'help'           { Invoke-Help }
    ''               { Invoke-Help }
    default          { Invoke-Help }
}