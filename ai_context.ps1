<#
.SYNOPSIS
    Управляющий центр переноса контекста между сессиями ИИ.

.DESCRIPTION
    Единый инструмент для работы с папкой Z:\DOC\СЕРВЕРА\Scripts\AI.
    Команды:
      status         — состояние AI-папки.
      pack           — собрать zip-пакет для новой сессии.
      unpack         — распаковать пакет из буфера в файлы.
      save           — сохранить текущий чат в Markdown.
      repo-push      — залить файлы контекста в GitHub-репозиторий.
      repo-pull      — скачать файлы из GitHub-репозитория в _repo\.
      session-close  — закрытие сессии: unpack + опционально repo-push.
      help           — справка.

.PARAMETER Command
    status | pack | unpack | save | repo-push | repo-pull | session-close | help

.PARAMETER Root
    Корневая папка AI. По умолчанию Z:\DOC\СЕРВЕРА\Scripts\AI.

.PARAMETER LastPatches
    (pack) Сколько последних патчей включить. По умолчанию 30.

.PARAMETER LastChats
    (pack) Сколько последних резюме чатов включить. По умолчанию 5.

.PARAMETER DryRun
    (unpack, repo-push) Показать, что будет сделано, без записи.

.PARAMETER FromClipboard
    (save) Форсировать чтение чата из буфера, не открывать Notepad.

.PARAMETER SkipRepo
    (session-close) Не запускать repo-push, только unpack.

.PARAMETER NoLog
    Отключить запись в logs\ai_context.log.

.EXAMPLE
    .\ai_context.ps1 status
    .\ai_context.ps1 pack
    .\ai_context.ps1 unpack
    .\ai_context.ps1 unpack -DryRun
    .\ai_context.ps1 session-close
    .\ai_context.ps1 session-close -SkipRepo
    .\ai_context.ps1 repo-push
    .\ai_context.ps1 repo-pull
    .\ai_context.ps1 save -FromClipboard

.NOTES
    Требуется PowerShell 5.1+ или PowerShell 7+ (рекомендуется).
    Для команд repo-* требуется gh CLI + авторизация (scope: repo).
    Используется публичный репозиторий DrAngelOk/DrBash.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('pack','unpack','save','status','repo-push','repo-pull','session-close','help','')]
    [string]$Command = '',

    [string]$Root        = "Z:\DOC\СЕРВЕРА\Scripts\AI",
    [int]   $LastPatches = 30,
    [int]   $LastChats   = 5,
    [switch]$DryRun,
    [switch]$FromClipboard,
    [switch]$SkipRepo,
    [switch]$NoLog
)

$ErrorActionPreference = 'Stop'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# =====================================================================
#  ОБЩИЕ ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
# =====================================================================

function Show-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host ("=" * 60) -ForegroundColor DarkCyan
    Write-Host ("  $Title") -ForegroundColor Cyan
    Write-Host ("=" * 60) -ForegroundColor DarkCyan
}

function Ensure-Dir {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Write-FileUtf8 {
    param([string]$Path, [string]$Content)
    $dir = Split-Path $Path -Parent
    if ($dir) { Ensure-Dir $dir }
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

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

function Get-Config {
    param([string]$RootPath)
    $cfgPath = Join-Path $RootPath 'config.json'
    if (-not (Test-Path $cfgPath)) {
        throw "config.json не найден: $cfgPath"
    }
    $cfgText = [System.IO.File]::ReadAllText($cfgPath, [System.Text.Encoding]::UTF8)
    return $cfgText | ConvertFrom-Json
}

function Save-Config {
    param([string]$RootPath, $Config)
    $cfgPath = Join-Path $RootPath 'config.json'
    $json = $Config | ConvertTo-Json -Depth 10
    Write-FileUtf8 -Path $cfgPath -Content $json
}

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

function Get-FileDiffSummary {
    param([string]$Path, [string]$NewContent)

    if (-not (Test-Path $Path)) {
        return "новый файл ($($NewContent.Length) симв.)"
    }

    $oldContent = ''
    try {
        $oldContent = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::UTF8)
    } catch {
        return "старый файл не читается, перезаписан"
    }

    $oldLines = @($oldContent -split "`r?`n")
    $newLines = @($NewContent -split "`r?`n")

    $oldSet = @{}
    foreach ($l in $oldLines) { $oldSet[$l] = ($oldSet[$l] + 1) }
    $newSet = @{}
    foreach ($l in $newLines) { $newSet[$l] = ($newSet[$l] + 1) }

    $added = 0
    foreach ($k in $newSet.Keys) {
        $oldCount = if ($oldSet.ContainsKey($k)) { $oldSet[$k] } else { 0 }
        if ($newSet[$k] -gt $oldCount) { $added += ($newSet[$k] - $oldCount) }
    }
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

    $keyFiles = @(
        'ai_context.ps1',
        'config.json',
        'AI_CONTEXT.md',
        'AI_TASKS.md',
        '_END_OF_SESSION_PROMPT.txt'
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
                    Write-Host ("  files    : {0}" -f ($cfg.files -join ', ')) -ForegroundColor Cyan
                }
            }
            Write-Host ""
        } catch {
            Write-Host "[WARN] config.json повреждён: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }

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
    Write-Host "Подсказка: pack — собрать пакет | session-close — закрыть сессию" -ForegroundColor DarkGray
}

# =====================================================================
#  КОМАНДА: pack
# =====================================================================
function Invoke-Pack {
    Show-Header "СБОРКА ПАКЕТА ДЛЯ НОВОЙ СЕССИИ"

    if (-not (Test-Path $Root)) {
        Write-Host "[ERROR] Корень не найден: $Root" -ForegroundColor Red
        return
    }

    $stamp  = Get-Date -Format "yyyy-MM-dd_HHmm"
    $outDir = Join-Path $Root "_transfer"
    $zip    = Join-Path $outDir "ai_package_$stamp.zip"

    Ensure-Dir $outDir
    if (Test-Path $zip) { Remove-Item $zip -Force }

    $tmp = Join-Path $env:TEMP "ai_pack_$stamp"
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
    Ensure-Dir $tmp

    foreach ($f in 'AI_CONTEXT.md','AI_TASKS.md') {
        $src = Join-Path $Root $f
        if (Test-Path $src) {
            Copy-Item $src -Destination $tmp -Force
            Write-Host "[OK] + $f" -ForegroundColor Green
        } else {
            Write-Host "[WARN] нет файла: $f" -ForegroundColor Yellow
        }
    }

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

    Compress-Archive -Path (Join-Path $tmp '*') -DestinationPath $zip -Force
    Remove-Item $tmp -Recurse -Force

    Write-Host ""
    Write-Host "[DONE] Пакет: $zip" -ForegroundColor Cyan
    Write-Host "[INFO] Размер: $([math]::Round((Get-Item $zip).Length/1KB,1)) КБ" -ForegroundColor Cyan
    Write-Host "[NEXT] Прикрепите этот zip первым сообщением в новую сессию." -ForegroundColor Yellow

    Write-AiLog "[pack] $zip"
}

# =====================================================================
#  КОМАНДА: unpack
# =====================================================================
function Invoke-Unpack {
    Show-Header "РАСПАКОВКА ПАКЕТА ИЗ БУФЕРА"

    try {
        $text = Get-Clipboard -Raw
    } catch {
        Write-Host "[ERROR] Не удалось прочитать буфер: $($_.Exception.Message)" -ForegroundColor Red
        Write-AiLog "[unpack] ERROR: буфер не читается"
        return
    }

    if ([string]::IsNullOrWhiteSpace($text)) {
        Write-Host "[ERROR] Буфер обмена пуст. Скопируйте ответ ИИ и повторите." -ForegroundColor Red
        Write-AiLog "[unpack] ERROR: буфер пуст"
        return
    }

    Write-Host "[INFO] Прочитано из буфера: $($text.Length) символов" -ForegroundColor Cyan

    $endMarker = "=== END OF PACKAGE ==="
    if ($text -notmatch [regex]::Escape($endMarker)) {
        Write-Host "[WARN] В буфере НЕ найден маркер '$endMarker'." -ForegroundColor Yellow
        Write-Host "[WARN] Возможно, скопировали не весь ответ ИИ." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Продолжить распаковку? (y/N): " -ForegroundColor Yellow -NoNewline
        $ans = Read-Host
        if ($ans -ne 'y' -and $ans -ne 'Y') {
            Write-Host "[CANCEL] Отменено пользователем." -ForegroundColor DarkYellow
            Write-AiLog "[unpack] CANCEL: маркер не найден"
            return
        }
    } else {
        Write-Host "[OK] Маркер конца пакета найден." -ForegroundColor Green
    }

    $pattern = '(?ms)^===\s*FILE:\s*(?<path>.+?)\s*===\s*\r?\n```[^\r\n]*\r?\n(?<body>.*?)\r?\n```'

    $matches = [regex]::Matches($text, $pattern)

    if ($matches.Count -eq 0) {
        Write-Host "[WARN] Не найдено ни одного блока === FILE: ... ===" -ForegroundColor Yellow
        Write-Host "[HINT] Возможно, при копировании из чата потерялись обратные кавычки." -ForegroundColor Yellow
        Write-Host "[HINT] Сохраните файлы вручную через Notepad++ (Ctrl+A, вставить, Ctrl+S)." -ForegroundColor Yellow
        Write-AiLog "[unpack] WARN: 0 блоков"
        return
    }

    Write-Host "[INFO] Найдено блоков: $($matches.Count)" -ForegroundColor Cyan
    Write-Host ""

    $saved = 0
    $failed = 0
    $diffs = @()

    foreach ($m in $matches) {
        $rawPath = $m.Groups['path'].Value.Trim()
        $body    = $m.Groups['body'].Value

        if (-not [System.IO.Path]::IsPathRooted($rawPath)) {
            $rawPath = Join-Path $Root $rawPath
        }

        if ($DryRun) {
            Write-Host "[DRY] $rawPath ($($body.Length) симв.)" -ForegroundColor DarkGray
            continue
        }

        $diffSummary = Get-FileDiffSummary -Path $rawPath -NewContent $body

        try {
            Write-FileUtf8 -Path $rawPath -Content $body
            Write-Host "[OK]  $rawPath" -ForegroundColor Green
            Write-Host "      $diffSummary" -ForegroundColor DarkGray
            $diffs += "$rawPath : $diffSummary"
            $saved++
        } catch {
            Write-Host "[ERR] $rawPath — $($_.Exception.Message)" -ForegroundColor Red
            $failed++
        }
    }

    if (-not $DryRun) {
        Write-Host ""
        Write-Host "[DONE] Сохранено: $saved, ошибок: $failed" -ForegroundColor Cyan
        Write-AiLog "[unpack] saved=$saved failed=$failed"
    } else {
        Write-Host ""
        Write-Host "[DRY] Реального сохранения не было." -ForegroundColor Yellow
        Write-AiLog "[unpack] DRY-RUN, блоков=$($matches.Count)"
    }
}

# =====================================================================
#  КОМАНДА: save
# =====================================================================
function Invoke-Save {
    Show-Header "СОХРАНЕНИЕ ЧАТА"

    $outDir = Join-Path $Root 'chats'
    Ensure-Dir $outDir

    $content = $null

    if ($FromClipboard) {
        $content = Get-Clipboard -Raw
        if ([string]::IsNullOrWhiteSpace($content)) {
            Write-Host "[ERROR] Буфер обмена пуст." -ForegroundColor Red
            return
        }
    } else {
        $tmp = New-TemporaryFile
        Write-Host "[INFO] Открываю Notepad. Вставьте чат (Ctrl+V), сохраните, закройте." -ForegroundColor Cyan
        Start-Process -FilePath "notepad.exe" -ArgumentList $tmp.FullName -Wait
        $content = Get-Content $tmp.FullName -Raw -ErrorAction SilentlyContinue
        Remove-Item $tmp.FullName -Force -ErrorAction SilentlyContinue

        if ([string]::IsNullOrWhiteSpace($content)) {
            Write-Host "[ERROR] Файл пуст — нечего сохранять." -ForegroundColor Red
            return
        }
    }

    $stamp = Get-Date -Format "yyyy-MM-dd_HHmmss"
    $file  = Join-Path $outDir "chat_$stamp.md"

    Write-FileUtf8 -Path $file -Content $content

    Write-Host "[OK] Сохранено: $file" -ForegroundColor Green
    Write-Host "[INFO] Размер: $($content.Length) символов" -ForegroundColor Cyan

    Write-AiLog "[save] $file ($($content.Length) симв.)"
}
# =====================================================================
#  КОМАНДА: repo-push
#  Заливает файлы контекста в публичный GitHub-репозиторий.
#  files в config.json — массив объектов {name, local}.
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

    # --- Шаг 1: проверить наличие всех файлов локально ---
    $missing = @()
    foreach ($item in $cfg.files) {
        $localPath = $item.local
        if (-not $localPath) {
            # фоллбэк на старое поведение
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

    $savedEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'

    try {
        foreach ($item in $cfg.files) {
            $name      = $item.name
            $localPath = if ($item.local) { $item.local } else { Join-Path $Root $name }

            # Получаем текущий SHA файла (если он уже существует в репозитории)
            $sha = $null
            $shaOut = & {
                gh api "repos/$owner/$repo/contents/$name`?ref=$branch" --jq '.sha' 2>&1
            } | Out-String
            if ($LASTEXITCODE -eq 0) {
                $sha = $shaOut.Trim()
            }

            # Кодируем содержимое в base64
            $bytes = [System.IO.File]::ReadAllBytes($localPath)
            $b64 = [Convert]::ToBase64String($bytes)

            # Формируем JSON для PUT
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

            $out = & {
                $payloadJson | gh api -X PUT "repos/$owner/$repo/contents/$name" --input - 2>&1
            } | Out-String

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
        $ErrorActionPreference = $savedEAP
    }

    Write-Host ""
    Write-Host "[DONE] repo-push завершён." -ForegroundColor Cyan
}

# =====================================================================
#  КОМАНДА: repo-pull
#  Скачивает файлы из репозитория в локальную папку _repo\.
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

    $savedEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'

    try {
        foreach ($item in $cfg.files) {
            $name = $item.name
            Write-Host ("  ← {0}" -f $name) -ForegroundColor Gray
            $dest = Join-Path $repoDir $name

            $content = & {
                gh api "repos/$owner/$repo/contents/$name`?ref=$branch" --jq '.content' 2>&1
            } | Out-String

            if ($LASTEXITCODE -ne 0) {
                Write-Host "[ERROR] gh api GET '$name' failed." -ForegroundColor Red
                continue
            }

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
# =====================================================================
function Invoke-SessionClose {
    Show-Header "ЗАКРЫТИЕ СЕССИИ"
    Write-Host "[INFO] Шаг 1: unpack (распаковка ответа ИИ из буфера)" -ForegroundColor Cyan
    Write-AiLog "[session-close] START"

    Invoke-Unpack

    if (-not $SkipRepo) {
        Write-Host ""
        Write-Host "[INFO] Шаг 2: repo-push (обновление GitHub-репозитория)" -ForegroundColor Cyan
        Invoke-RepoPush
    } else {
        Write-Host ""
        Write-Host "[INFO] Шаг 2: repo-push пропущен (-SkipRepo)." -ForegroundColor DarkGray
    }

    Write-Host ""
    Write-Host "[DONE] Сессия закрыта." -ForegroundColor Green
    Write-AiLog "[session-close] DONE"
}

# =====================================================================
#  КОМАНДА: help
# =====================================================================
function Invoke-Help {
    Show-Header "AI CONTEXT — УПРАВЛЯЮЩИЙ ЦЕНТР"
    Write-Host ""
    Write-Host "Корень AI-папки: $Root" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Команды:" -ForegroundColor Yellow
    Write-Host "  status                 Показать состояние AI-папки" -ForegroundColor Gray
    Write-Host "  pack                   Собрать zip для новой сессии" -ForegroundColor Gray
    Write-Host "  unpack                 Распаковать ответ ИИ из буфера" -ForegroundColor Gray
    Write-Host "  unpack -DryRun         Предпросмотр распаковки" -ForegroundColor Gray
    Write-Host "  save                   Сохранить чат через Notepad" -ForegroundColor Gray
    Write-Host "  save -FromClipboard    Сохранить чат из буфера" -ForegroundColor Gray
    Write-Host "  repo-push              Залить файлы контекста в GitHub-репозиторий" -ForegroundColor Gray
    Write-Host "  repo-push -DryRun      Показать, что будет залито" -ForegroundColor Gray
    Write-Host "  repo-pull              Скачать файлы из репозитория в _repo\" -ForegroundColor Gray
    Write-Host "  session-close          Закрыть сессию: unpack + repo-push" -ForegroundColor Gray
    Write-Host "  session-close -SkipRepo Только unpack, без repo-push" -ForegroundColor Gray
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
# =====================================================================
switch ($Command) {
    'pack'           { Invoke-Pack }
    'unpack'         { Invoke-Unpack }
    'save'           { Invoke-Save }
    'status'         { Invoke-Status }
    'repo-push'      { Invoke-RepoPush }
    'repo-pull'      { Invoke-RepoPull }
    'session-close'  { Invoke-SessionClose }
    'help'           { Invoke-Help }
    ''               { Invoke-Help }
    default          { Invoke-Help }
}