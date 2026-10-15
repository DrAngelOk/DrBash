# AI CONTEXT — Z:\DOC\СЕРВЕРА\Scripts

Якорь контекста. Детали проекта, история сессий, инфраструктура,
процедуры. Для точки входа в сессию — см. AI_START.md.

## 🔗 АКТУАЛЬНЫЙ ИСТОЧНИК — GitHub-РЕПОЗИТОРИЙ

Репозиторий: DrAngelOk/DrBash
URL: https://github.com/DrAngelOk/DrBash
Raw-база: https://raw.githubusercontent.com/DrAngelOk/DrBash/main/
Тип: публичный
Дата последней загрузки: 2026-10-15

Файлы в репозитории (12 шт.):

- AI_START.md — короткая точка входа (правила, процедура)
- AI_MAP.md — карта проекта (структура, модули, статус разбора)
- AI_CONTEXT.md — этот файл (детали проекта)
- AI_TASKS.md — чек-лист задач
- _END_OF_SESSION_PROMPT.txt — промпт-триггер (описание формата пакета)
- ai_context.ps1 — управляющий скрипт
- merge_project_dump.txt — обезличенный дамп кода проекта
- merge_project.ps1 — сборщик дампа (оригинал в Win)
- sanitize_for_repo.ps1 — обезличиватель
- sanitize_patterns.json — паттерны обезличивания
- config.json — конфигурация скрипта
- chats/, patches/ — подпапки

Правила для ИИ (что читать, в каком порядке, чего не делать) —
в AI_START.md.

## 🧭 О ПРОЕКТЕ

Название: Enterprise-панель автоматизации серверов RedOS / FreeBSD.
Язык: Bash, ~30 000 строк, 60+ модулей.
Рабочая папка (оригинал): Z:\DOC\СЕРВЕРА\Scripts
Целевой путь на сервере: /ARC/Scripts/
Точка входа: startMain.sh

Архитектура:

- Меню-фреймворк с регистрацией функций через MenuRegister.
- Диспетчер запуска: единая функция MenuStart (интерактив + CLI/Cron).
- Двухплатформенная абстракция через переменную ${OSType} (RedOS / FreeBSD).
- Модули пронумерованы: 01_Config, 02_Backup, ..., 11_Check.
- Файлы внутри модулей: NN_funcName.sh.

Карта проекта — в AI_MAP.md.

Статус проекта: идёт первичный разбор кода (T-001).

**Разобраны / переработаны в этой и прошлых сессиях:**
- startMain.sh, Conf/ (7 файлов), Func/Scripts (2 файла),
  Func/Menu/funcMenu.sh, Func/05_Disks/ (6 файлов),
  Func/01_Config (15, 16, 17),
  Func/02_Backup/22_funcRestic.sh, 23_funcBackrest.sh,
  24_funcZrepl.sh.

**Новые модули:**
- Func/11_Check/ — мониторинг (ZFS, память, веб-стек, пост-мортем).
- Func/09_System/92_funcSystem.sh — добавлена 9.2.8 (drbash).

**Серверы (из Def/server.list):**
- WSW (192.168.1.21, ens160, root, FreeBSD 15.1-RELEASE-p2) —
  рабочий веб-сервер: apache, mysql, certbot. Мультисайт WordPress
  (24 блога). SSH-порт 22.
- WS2 (192.168.1.41, root, FreeBSD 15.1-RELEASE-p2) — АКТИВНЫЙ
  архивный сервер (restic/rest-server/backrest, zrepl-приёмник).
  SSH-порт 40022.
- WSD (192.168.2.11, root), GSW (192.168.1.25, drangel),
  GSD (192.168.2.15, drangel), WS (192.168.1.11, root),
  sv-website (192.168.1.15, apache, порт 2222).

**Роли серверов (уточнено):**
- WSW — веб-сервер (apache/mysql), роль архива установлена,
  но не активна. Мультисайт WordPress.
- WS2 — активный архивный сервер.

**Реверс-прокси (ADMLR):**
- Сайт `cszn.admlr.lipetsk.ru` (blog_id=17) ходит через ADMLR.
- ADMLR терминирует HTTPS, передаёт на WSW по HTTP.
- ADMLR передаёт `X-Forwarded-Proto: https`, `X-Forwarded-Host`,
  `X-Real-IP`.
- Основной домен мультисети — `inward.su` (blog_id=1), на WSW.
  DNS `inward.su` — на другом сервере.
- Правка `wp-config.php` — блок `HTTP_X_FORWARDED_PROTO`
  раскомментирован (был закомментирован).

**ZFS / ARC:**
- `vfs.zfs.arc.max` и `vfs.zfs.arc.min` — формат с точками.
- WSW: `arc.max="3G"`, `arc.min="1G"`.
- WS2: `arc.max="8G"`, `arc.min="2G"`.
- `arc.min` может не применяться в рантайме (read-only).
- `vfs.unmapped_buf_allowed="0"` — отключено на обоих
  (документированная проблема FreeBSD на виртуалках).
- `vfs.zfs.min_auto_ashift="12"` — для будущих пулов.
- `ashift=9` на `www2`/`zroot` (из-за 512e на vmdk) — пересоздание
  отложено.
- ESXi показывает «Consumed ~100%» — норма для ZFS.
- На WS2 — RDM-диск `/dev/da2` (WDC16), SMART работает.
  vmdk-диски (`da0`, `da1`, `cd0`) — SMART недоступен.

**Nextcloud (rclone mount):**
- `/mnt/scripts` ← rclone mount (WebDAV).
- `--dir-cache-time 10s`, `--poll-interval 5s` — для быстрого
  обнаружения изменений.
- `syncNextcloud` (5.7.5) — rsync с выводом `-i --stats`.

**dma (mail):**
- `dma` падает с `stack overflow` (FreeBSD Bug 281936) —
  mail loop без SMARTHOST.
- Временно: periodic-отчёты отключены (`daily_output=""` и т.д.)
  в `/etc/periodic.conf` на обоих серверах.
- TODO: настроить SMARTHOST.

**Restic / rest-server / Backrest (WS2):**
- Админ: `angelrs`, хранилище `/mnt/BS07_MY/BACK_RS`
  (симлинк `/ARC/BACK_RS`).
- rest-server: порт 48800 (TLS, htpasswd).
- Backrest: порт 48898.
- Клиенты: `back_wsw` (WSW), `back_noutd` (Windows).
- Манифест: `Def/restic_clients.list`, парсер
  `Conf/ConfResticClients.sh`.

**zrepl (работает):**
- WSW `zroot` → WS2 (сетевая репликация).
- WS2 `zroot`/`www2`/`BS07_MY` — локальные push.
- Префиксы уникализированы.
- **ВАЖНО (15.10):** в sink-джобах путь формируется как
  `root_fs/${client_identity}/${source_path}`. Поэтому `root_fs`
  НЕ должен содержать `client_identity`, иначе получаются дубли
  (`wsw/wsw`, `ws2_local/.../ws2_local`).
- **15.10:** обнаружена сломанная структура приёмника
  (`BS07_MY/ZREPL/ws2_local/.../ws2_local`, `.../wsw/wsw`).
  Идёт миграция в правильную структуру:
  - `ws2_local/zroot` → `ws2/zroot` — СДЕЛАНО
  - `ws2_local/www2` → `ws2/www2` — СДЕЛАНО
  - `ws2_local/BS07_MY` → `ws2/BS07_MY` — В РАБОТЕ
  - `wsw/wsw/zroot` → `wsw/zroot` — В РАБОТЕ
- **Правка конфига WS2 (после миграции):**
  - `client_identity: ws2_local` → `ws2`
  - `root_fs: BS07_MY/ZREPL` (без последнего сегмента)
  - `sink_wsw`: `root_fs: BS07_MY/ZREPL` (без `/wsw`)
- **Конфиг WSW — не трогаем.** `client_identity: wsw` задаётся
  через `authorized_keys` на WS2:
  `command="zrepl stdinserver wsw",restrict ssh-ed25519 ...`

## 🖥 ИНФРАСТРУКТУРА

**Особенности:**
- **FreeBSD 15.1: нет `mountpoint`** → `mount | grep` или
  `is_mounted` (в модуле 57).
- **FreeBSD 15.1: `mountpoint=inherit` НЕ поддерживается.**
- **SSH-порты:** WSW — 22, WS2 — 40022.
- **CLICOLOR/GREP_OPTIONS** — убраны из профиля root (T-022).
- **NFS `192.168.1.19:/nfs_01` не работает — норма**
  (сервер ещё не настроен). Аналогично `192.168.2.5:/nfs_d`.

**ZFS / ARC:**
- WSW: `zroot`, `www2`. `www2/sql2` — БД MySQL (recordsize=16K,
  primarycache=metadata, lz4). `www2/www2` — файлы сайтов
  (recordsize=1M, lz4).
- WS2: `zroot`, `www2`, `BS07_MY` (16.4T).
- Все VM в ESXi, диски — vmdk (кроме RDM `/dev/da2` на WS2).

**WordPress мультисайт:**
- 24 блога (`wp_blogs`), основной — `inward.su` (blog_id=1).
- Документы: `/usr/local/www/wp_new/`.
- База: `wp_new`.
- Плагины: Really Simple SSL, Real Media Library, Wordfence
  (отключён), Spectra.
- Картинки сайта 17 лежат в `uploads/sites/10/ASC_10/...`
  (нестандартная структура, петля `AH00124` при запросе
  несуществующих — отложено).

## 📜 ИСТОРИЯ СЕССИЙ

Каждая новая сессия добавляет секцию ### Сессия <дата> в конец.

### Сессия 2026-09-26 — Инфраструктура переноса контекста
- Создали папку Z:\DOC\СЕРВЕРА\Scripts\AI.
- Разработали ai_context.ps1.
- Создали AI_CONTEXT.md, AI_TASKS.md, _END_OF_SESSION_PROMPT.txt,
  config.json.

### Сессия 2026-09-27 — Улучшения ai_context.ps1 и переезд на GitHub
- Добавили 4 улучшения.
- Обнаружили: DeepSeek не парсит gist.
- Создали публичный репозиторий DrAngelOk/DrBash.

### Сессия 2026-09-28 — Обезличиватель и пересоздание репозитория
- Разработали sanitize_for_repo.ps1 (26 паттернов).

### Сессия 2026-09-28 (продолжение) — Модернизация формата пакета
- pack → zip, unpack → down.
- Маркеры пакета (тройка процентов).
- Создали AI_START.md.

### Сессия 2026-09-28 (продолжение 2) — Защита down, merge_project.ps1
- Усилили защиту в down: парность BEGIN/END.

### Сессия 2026-09-28 2357 — Начало разбора T-001: Conf/ + утилиты
- Разобрали 6 файлов Conf/, funcUtil.sh, funcCheck.sh, startMain.sh.

### Сессия 2026-09-29 — Карта проекта AI_MAP.md
- Создали AI_MAP.md.

### Сессия 2026-09-30 — config.json через прямые слеши
- Перевели пути config.json на прямые слеши.

### Сессия 2026-09-30 0017 — Правки пути funcMenu.sh, Def/, Nextcloud
- Разобрали 5 файлов Def/.
- Смонтировали Nextcloud через rclone на WSW.

### Сессия 2026-10-09 0008 — Модуль 57_funcDiskMount.sh, createDir
- Спроектировали `57_funcDiskMount.sh`.
- Добавили `createDir`.

### Сессия 2026-10-09 (продолжение) — Рассинхрон AI_MAP, T-013, funcMenu
- T-013 закрыта.
- Рефакторинг funcMenu.sh.

### Сессия 2026-10-11 — T-019, T-016, T-015 (FreeBSD)
- T-019, T-016, T-015 (FreeBSD) закрыты.

### Сессия 2026-10-12 — Логгер, WS2, раздел 5 (Disks), zrepl (начало)
- Логгер унифицирован (`logsMsg`).
- WS2 введён в строй.
- Раздел 5 (Disks) завершён.
- zrepl — начало.

### Сессия 2026-10-13 — zrepl: полный сброс и рабочая схема
- Полный сброс zrepl.
- Префиксы снапшотов уникализированы.
- `source_wsw` → `sink_wsw`.
- zrepl заработал.
- T-024: ротация `/var/log/zrepl.log`.

### Сессия 2026-10-13 (продолжение) — T-022, T-025, T-026, Restic, Backrest
- T-022 закрыта (CLICOLOR/GREP_OPTIONS).
- T-025 закрыта (полный send 273 GiB).
- T-026 закрыта (holds zrepl).
- T-023 — правила диалога.
- Restic / Backrest — переработка.

### Сессия 2026-10-14 — Мониторинг, память, веб-стек, реверс-прокси, WS2 SSH

**Закрыто:**
- `installDrbashWrapper` (funcUtil.sh) + `systemInstallDrbash` (9.2.8).
- `zfsShowArcStats` (5.1.14), `zfsSetArcLimit` (5.1.15),
  `zfsSetPrimaryCache` (5.1.16), `zfsSetRecordsize` (5.1.17),
  `zfsTuneVirtualization` (5.1.18).
- `syncNextcloud` (5.7.5) — вывод хода синхронизации.
- `monZfsToolsInstall` (11.1.1), `monSmartInstall` (11.1.2)
  с созданием `smartd.conf`, `monZpoolStatusParsed` (11.1.3),
  `monZpoolIostat` (11.1.4) — bandwidth, `monArcHitRate` (11.1.5),
  `monZfsSnapshotsSummary` (11.1.6), `monSwapInfo` (11.1.7),
  `monSmartStatus` (11.1.8).
- `monMemory` (11.2.1) — два значения свободной памяти,
  `monMemoryErrors` (11.2.2), `monMemoryKernel` (11.2.3),
  `monNetstatMbuf` (11.2.4), `monMemoryErrorsDeep` (11.2.5).
- `monMysqlCreateMonitor` (11.3.1), `monApache` (11.3.2) —
  расширенные паттерны + сканеры + local/external,
  `monMysql` (11.3.3), `monOpenvpn` (11.3.4) — исправлен баг,
  `monWebStackSummary` (11.3.5), `monPhpFpm` (11.3.6),
  `monReverseProxyHeaders` (11.3.7), `monReverseProxyFix` (11.3.8).
- `monPostmortem` (11.4.1) — слепок состояния.
- `_webstack_http_check` — универсальная HTTP-проверка
  (local/external/remote).

**Правки конфигов:**
- `/boot/loader.conf` — `arc.max`/`arc.min` (формат с точками),
  `unmapped_buf_allowed="0"`, `min_auto_ashift="12"`.
- `.bashrc` — PS1, bash-completion.
- `.aliases.conf` — `dr='bash /ARC/Scripts/startMain.sh'`.
- `smartd.conf` — создан для `/dev/da2`.
- `periodic.conf` — отключены отчёты, `daily_status_smart_devices`.
- Nextcloud — `--dir-cache-time 10s`.
- MySQL — пользователь `monitor` (пароль `MTr9kLp2Xw7qNv`).
- `wp-config.php` — раскомментирован `HTTP_X_FORWARDED_PROTO`.
- `.htaccess` — закомментировано `^wp-admin$` (не помогло,
  безвредно).

**Разобрано попутно:**
- `dma` stack overflow — mail loop, отключено временно.
- `ashift=9` — причина (512e), исправлено `min_auto_ashift=12`.
- `vfs.unmapped_buf_allowed` — отключено.
- `arc.max` на WSW (3G) — применено.
- `arc.min` — не поддерживается в рантайме.
- Nextcloud sync — `--dir-cache-time 10s`.
- **Реверс-прокси (ADMLR):** петля `AH00124` на `cszn` —
  исправлено `HTTP_X_FORWARDED_PROTO` в `wp-config.php`.
- **WordPress мультисайт:** петля при заходе через `hosts` —
  ожидаемое поведение (обход ADMLR).
- **Картинки `sites/10` vs `uploads/ASC_10`** — отложено.
- **Сканеры** (`20.58.188.171`, `13.140.57.64` и др.) —
  долбят `.php`, отложено.
- **`df -h` зависает** (`D`-state) — NFS/rclone на WSW.
  В `monPostmortem` надо `timeout` + `df -t ufs,zfs`.
- **WS2 недоступен по SSH** (из Windows через WSW).

### Сессия 2026-10-15 — monPostmortem, pmAnalyze, zrepl-миграция

**Закрыто:**
- `monPostmortem` (11.4.1) — доработка:
  - `df -h` → `timeout 10 df -t ufs,zfs -h` (исключён NFS/rclone).
  - `top -b` → `timeout 10 top -b -n 1`.
  - Все внешние команды обёрнуты в `timeout 10`.
  - Добавлен `zfs list -t all` для детализации датасетов.
  - Добавлен `mount` (полный список).
- `pmAnalyze` (11.4.2) — НОВАЯ функция:
  - Автопарсер свежего дампа, вывод только проблем.
  - `_pm_section` через `grep -n` + `sed` (устойчиво к юникоду).
  - Проверки: load, TOP, memory, disks (NFS/rclone, переполнение),
    ZFS pools (errors), ARC (hit rate), D/Z-state (без ядерных
    потоков), netstat, Apache/PHP-FPM, dmesg/messages, crashes.
  - Игнорирует `minfree` в `/var/crash/`, ядерные потоки,
    секцию-заголовок.
  - Пороги через `ConfManual.sh` (fallback в коде).
- Обнаружена проблема структуры zrepl-приёмника (формула пути).
- Начата миграция: `ws2_local/zroot` → `ws2/zroot`,
  `ws2_local/www2` → `ws2/www2` — СДЕЛАНО.

**Обнаружено:**
- Формула zrepl sink: `root_fs/${client_identity}/${source_path}`.
- Неправильные `root_fs` в конфиге WS2 → дубли в структуре.
- `zrepl.yml` WS2: `root_fs` содержит последний сегмент
  (`/wsw`, `/ws2_local/zroot`), который потом дублируется.

**Правки конфигов:**
- (после миграции) WS2 `zrepl.yml` — `root_fs`, `client_identity`.
- WSW `zrepl.yml` — НЕ трогаем.

## ❓ ОТКРЫТЫЕ ВОПРОСЫ

1. **WS2 SSH** — `kex_exchange_identification: timeout`. TCP идёт,
   SSH-баннер не приходит. Отложено.
2. **Картинки WordPress** — `sites/10/ASC_10/...` vs
   `uploads/ASC_10/...`. Петля `AH00124` при запросе
   несуществующих. Отложено.
3. **Сканеры** — блокировка IP (`20.58.188.171` и др.).
4. **SMART** — `/dev/da2` self-test failed (WDC16). Нужно
   `smartctl -a /dev/da2`.
5. **dma** — настроить SMARTHOST, вернуть periodic-отчёты.
6. **T-001** — продолжить разбор `Func/01_Config` (11–14, 18, 19),
   `Func/02_Backup` (21, 25–28).
7. **T-021** — миграция `info`/`warn`/`err` на `logsMsg`.
8. **T-003** — `ConfManual.sh`.
9. **T-018 (расширено)** — ревизия `Func/Watch/` (что перенесено,
   что нет).
10. **T-015 (RedOS)** — systemd-юнит.
11. **НОВАЯ** — `server.list` под роли.
12. **НОВАЯ** — скрипт вкл/выкл ролей.
13. **НОВАЯ** — `Def/disks.list`.
14. **НОВАЯ** — `rsInitRepository` от `angelrs`.
15. **НОВАЯ** — `monPhpFpm` пул не настроен (`pm.status_path`).
16. **zrepl-миграция** — завершить: `BS07_MY`, `wsw`;
    снять `@migrate`; destroy `ws2_local`, `wsw/wsw`; правка
    конфига WS2; перезапуск zrepl.

## 🛠 КОМАНДЫ ai_context.ps1

| Команда | Что делает |
|---------|-----------|
| status | Показать состояние AI-папки. |
| zip | Собрать zip-пакет. |
| down | Распаковать пакет из буфера. |
| repo-push | Залить в GitHub. |
| repo-pull | Скачать из GitHub. |
| session-close | down + zip + repo-push. |
| help | Справка. |

## 🛠 ИНСТРУМЕНТЫ (файлы и папки)

| Файл / папка | Назначение |
|--------------|-----------|
| AI_START.md | Короткая точка входа. |
| AI_MAP.md | Карта проекта. |
| AI_CONTEXT.md | Этот файл. |
| AI_TASKS.md | Чек-лист. |
| _END_OF_SESSION_PROMPT.txt | Промпт-триггер. |
| ai_context.ps1 | Управляющий скрипт. |
| merge_project.ps1 | Сборщик дампа. |
| sanitize_for_repo.ps1 | Обезличиватель. |
| config.json | Конфигурация. |
| chats/ | Резюме сессий. |
| patches/ | Патчи. |
| _repo/ | Локальные копии. |
| _transfer/ | Готовые zip-пакеты. |

## ⚙️ СОГЛАШЕНИЯ

- Правки в коде помечать `# [FIX]`.
- Файлы с паролями — маска 600.
- В содержимом файлов НЕ использовать тройной символ процента.
- В начале каждой сессии — читать файлы из config.json.
- `ai_context.ps1`, `sanitize_*`, `merge_project.ps1`,
  `merge_project_dump.txt` — НЕ читать в начале сессии.
- Разбор кода — по одному файлу прямо в чат.
- Пути в config.json — с прямыми слешами.
- Реальные IP, имена, пароли маскируются в патчах.
- **Единый логгер — `logsMsg`** (см. `61_funcLogs.sh`).
- **Заменять `mkdir -p` на `createDir`.**
- **При изменении существующего файла — выдавать целиком.**
- **Не задавать лишние подтверждающие вопросы. Доверять владельцу.**
- **Автозапуск / CLI / Cron** — только через `startMain.sh <ID>`.
- **PATH-расширение** — только в `startMain.sh`.
- **Перед парсингом вывода утилит** — `unset CLICOLOR GREP_OPTIONS`.
- **`vfs.zfs.arc.max` / `arc.min`** — формат с точками.
- **`timeout` для внешних команд** в скриптах, собирающих
  диагностику (пост-мортем).
- **`timeout` НЕ работает с bash-функциями** — только с бинарниками.
- **`zrepl sink`: `root_fs` БЕЗ `client_identity`** — иначе дубли.

## 📁 КОДИРОВКА ФАЙЛОВ

- Bash: UTF-8 без BOM, LF.
- PowerShell: ASCII в исполняемых строках.
- JSON: UTF-8 с BOM.

## 🧾 ЗАМЕТКИ

- **Только raw.githubusercontent.com.**
- **Кэш raw-URL:** `?v=<уникальное>`.
- **Z: — WebDAV. Только `gh api`.**
- **Карта проекта — в AI_MAP.md.**
- **Панель:** `bash /ARC/Scripts/startMain.sh`.
- **createDir** — утилита в funcUtil.sh.
- **MenuStart — единая точка входа.**
- **Единый логгер — `logsMsg`.**
- **`monPostmortem`** — слепок в `/var/log/postmortem/` (dump-*.txt.gz).
- **`pmAnalyze`** — анализ свежего слепка, только проблемы.
- **HTTP-проверка:** `_webstack_http_check` (local/external/remote).
- **MySQL-монитор:** пользователь `monitor`, пароль
  `MTr9kLp2Xw7qNv`.
- **WS2 SSH** — отложено (`kex_exchange_identification: timeout`).
- **NFS не работает — норма** (`192.168.1.19`, `192.168.2.5` —
  серверы ещё не настроены).
- **zrepl sink:** `root_fs/${client_identity}/${source_path}`.
- **zrepl-миграция:** см. открытые вопросы п.16.