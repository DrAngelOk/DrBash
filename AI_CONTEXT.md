# AI CONTEXT — Z:\DOC\СЕРВЕРА\Scripts

Якорь контекста. Детали проекта, история сессий, инфраструктура,
процедуры. Для точки входа в сессию — см. AI_START.md.

## 🔗 АКТУАЛЬНЫЙ ИСТОЧНИК — GitHub-РЕПОЗИТОРИЙ

Репозиторий: DrAngelOk/DrBash
URL: https://github.com/DrAngelOk/DrBash
Raw-база: https://raw.githubusercontent.com/DrAngelOk/DrBash/main/
Тип: публичный
Дата последней загрузки: 2026-10-23

Файлы в репозитории (13 шт.):

- AI_START.md — короткая точка входа (правила, процедура)
- AI_MAP.md — карта проекта (структура, модули, статус разбора)
- AI_CONTEXT.md — этот файл (детали проекта)
- AI_TASKS.md — чек-лист задач
- AI_FUNCTIONS.tsv — индекс функций (TSV: файл, номер, название, описание, статус, ключи)
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
- Модули пронумерованы: 01_Config, 02_Backup, ..., 11_Check, 12_Deploy.
- Файлы внутри модулей: NN_funcName.sh.

Карта проекта — в AI_MAP.md.

Статус проекта: **T-001 (первичный разбор кода) — ЗАКРЫТА (100%)**.
**T-030 (развёртывание и синхронизация конфигов) — В РАБОТЕ (~50%)**.

**Разобраны / переработаны в этой и прошлых сессиях:**
- startMain.sh, Conf/ (7 файлов), Func/Scripts (2 файла),
  Func/Menu/funcMenu.sh, Func/05_Disks/ (6 файлов),
  Func/01_Config (9/9), Func/02_Backup (8/8),
  Func/06_Logs (3/3), Func/07_Mon (9/9),
  Func/08_VM (2/2), Func/09_System (4/4), Func/10_Sites (2/2),
  Func/11_Check (11.1.x–11.4.2).
- Func/Watch/ — закрыт (T-018, поглощён модулем 11).
- Func/12_Deploy/ — создан (T-030): 120 common, 121 audit, 122 pull, 123 push.
- `81_funcEsxi.sh`: добавлены `esxiCopyScripts` (8.1.12), исправлена
  `esxiDiskAttachPhysicalRDM` (8.1.3) — RDM через SSH.

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
- `vfs.zfs.vdev.min_auto_ashift=12` — добавлено в `sysctl.conf` (для новых пулов).
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
- **[FIX] Кэш rclone:** добавлен `NC_CACHE_DIR` и флаг `--cache-dir`
  (раньше кэш уходил в `/.cache/rclone` — корень zpool).

**dma (mail):**
- `dma` падает с `stack overflow` (FreeBSD Bug 281936) —
  mail loop без SMARTHOST.
- Временно: periodic-отчёты отключены (`daily_output="/dev/null"` и т.д.)
  в `/etc/periodic.conf` на обоих серверах. **Важно:** пустая строка
  `daily_output=""` НЕ отключает отчёты (означает «в stdout»), нужно
  `/dev/null`.
- TODO: настроить SMARTHOST.

**Restic / rest-server / Backrest (WS2):**
- Админ: `angelrs`, хранилище `/mnt/BS07_MY/BACK_RS`
  (симлинк `/ARC/BACK_RS`).
- rest-server: порт 48800 (TLS, htpasswd).
- Backrest: порт 48898.
- Клиенты: `back_wsw` (WSW), `back_noutd` (Windows).
- Манифест: `Def/restic_clients.list`, парсер
  `Conf/ConfResticClients.sh`.
- **На WSW** `restserver_enable="NO"`, `backrest_enable="NO"`
  (они на WS2).

**zrepl (работает):**
- WSW `zroot` → WS2 (сетевая репликация).
- WS2 `zroot`/`www2`/`BS07_MY` — локальные push.
- Префиксы уникализированы.
- **ВАЖНО:** в sink-джобах путь формируется как
  `root_fs/${client_identity}/${source_path}`. Поэтому `root_fs`
  НЕ должен содержать `client_identity`, иначе получаются дубли
  (`wsw/wsw`, `ws2_local/.../ws2_local`).
- **zrepl-миграция ЗАВЕРШЕНА (21.10):**
  - `ws2_local/zroot` → `ws2/zroot` — СДЕЛАНО
  - `ws2_local/www2` → `ws2/www2` — СДЕЛАНО
  - `ws2_local/BS07_MY/.../BS07_MY` → `ws2/BS07_MY` (2.03T) — СДЕЛАНО
  - `wsw/wsw/zroot` → `wsw/zroot` (252G) — СДЕЛАНО
  - `ws2_local` — удалён (recursive)
  - `wsw/wsw` — удалён (recursive), holds сняты (`zrepl_last_received_J_sink_wsw`,
    `zrepl_wsw_*`), через `zfs release` по каждому снапшоту
  - `root_fs` на WS2: `sink_wsw` → `BS07_MY/ZREPL` (без `/wsw`),
    `local_sink_*` → `BS07_MY/ZREPL` (без `/ws2_local/...`)
  - `client_identity: ws2_local` → `ws2` (в `push_ws2_*`)
  - `zrepl configcheck` — OK, `service zrepl restart` — OK
- **Конфиг WSW — не трогаем.** `client_identity: wsw` задаётся
  через `authorized_keys` на WS2:
  `command="zrepl stdinserver wsw",restrict ssh-ed25519 ...`
- **`zrepl status --mode raw`** — неинтерактивный статус (JSON).
  `zrepl status` (TUI) на FreeBSD может не работать без TTY/TERM.
- **`zrepl zfs-abstraction release-all --fs <dataset>`** — не снимает
  holds, если job удалён из конфига. Тогда — вручную:
  `zfs list -H -t snapshot -r -o name <ds> | while read s; do
   zfs holds -H "$s" 2>/dev/null; done` → `zfs release <tag> <snap>`.
  **`zfs release`/`zfs holds` требуют снапшот, не датасет.**

## 🖥 ИНФРАСТРУКТУРА

**Особенности:**
- **FreeBSD 15.1: нет `mountpoint`** → `mount | grep` или
  `is_mounted` (в модуле 57).
- **FreeBSD 15.1: `mountpoint=inherit` НЕ поддерживается.**
- **SSH-порты:** WSW — 22, WS2 — 40022.
- **CLICOLOR/GREP_OPTIONS** — убраны из профиля root (T-022).
- **NFS `192.168.1.19:/nfs_01` не работает — норма**
  (сервер ещё не настроен). Аналогично `192.168.2.5:/nfs_d`.
  В `/etc/fstab` добавлен `noauto` (чтобы `df -h` не зависал).

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

**ESXi (11, 12, 13 — 192.168.1.28, .38, .48):**
- **SSH между хостами:** для входящих — `sshServer: true`, для
  исходящих — `sshClient: true` (на ESXi12/13 был `false` —
  включили: `esxcli network firewall ruleset set --ruleset-id sshClient --enabled=true`).
- **Ключи:** ed25519 ESXi НЕ поддерживает. Только RSA 4096.
  - На WSW: `/root/.ssh/id_rsa_esxi` (RSA), публичная часть —
    в `/etc/ssh/keys-root/authorized_keys` на ESXi.
  - Между ESXi: host key (`/etc/ssh/ssh_host_rsa_key`), публичная
    часть — в `authorized_keys` друг у друга.
- **`known_hosts`:** ESXi не может нормально писать (`hostfile_replace_entries:
  Function not implemented`). Симлинк `ln -s /etc/ssh/keys-root /.ssh`
  помогает: первый раз ошибка, файл создаётся, второй раз — OK.
  Радикальный обход — `-o UserKnownHostsFile=/dev/null`.
- **`esxiCopyScripts` (8.1.12):** копирует `startMain.sh` + папки из
  `scriptpaths.list` на ESXi через `sftp` (не `scp` — SCP на ESXi
  ломается из-за «шумного» shell). Ключ — `/root/.ssh/id_rsa_esxi`.
- **`esxiDiskAttachPhysicalRDM` (8.1.3):** RDM через SSH с WSW.
  `esxcli storage core device list` — устройства `t10.`/`naa.`/`eui.`.
  `esxcli storage core device get` — НЕТ в этой версии; использовать
  `list -d <device>`. `Display Name` для локальных дисков бесполезен
  (повторяет `t10.ATA...`); имя RDM — из `t10.ATA...`
  (`WDC_WD5000LPSX_WD2DWXD2A6385AFE.vmdk`).
- **`sshClient` на ESXi11 был true, на ESXi12/13 — false.**
  Включили на 12/13.

**GSW (192.168.1.25) — Nextcloud + OnlyOffice (Docker):**
- **Рабочая директория:** `/opt/nextcloud-gsw/` (не `/ARC/_Docker/` —
  удалена).
  - `docker-compose.yml` — восстановлен из `docker inspect`
    (через `docker-autocompose`), очищен, `nginx.conf` →
    `/opt/nextcloud-gsw/nginx.conf`.
  - `nginx.conf` — извлечён из работающего контейнера
    (`docker exec nginx-server cat /etc/nginx/nginx.conf`).
- **Контейнеры:** `app-server` (nextcloud:fpm), `nginx-server` (80/443),
  `onlyoffice-document-server`.
- **Volume'ы (external):** `docker-onlyoffice-nextcloud_app_data`,
  `_document_data`, `_document_log`, `3b86ae...` (postgresql),
  `04bbaaa...` (onlyoffice), `38e6669...` (rabbitmq), `14f5ce4...`
  (redis), `92f5f8f...` (шрифты).
- **`JWT_SECRET=secret`** — слабый, оставлен с `[FIX]`.
- **Сеть:** `docker-onlyoffice-nextcloud_default` (external).
- **Запуск:** `cd /opt/nextcloud-gsw && docker compose up -d`.

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
  - Добавлен `zfs list -t all`.
  - Добавлен `mount` (полный список).
- `pmAnalyze` (11.4.2) — НОВАЯ функция:
  - Автопарсер свежего дампа, вывод только проблем.
  - `_pm_section` через `grep -n` + `sed` (устойчиво к юникоду).
  - Проверки: load, TOP, memory, disks, ZFS pools, ARC, D/Z-state,
    netstat, Apache/PHP-FPM, dmesg/messages, crashes.
  - Пороги через `ConfManual.sh` (fallback в коде).
- Обнаружена проблема структуры zrepl-приёмника (формула пути).
- Начата миграция: `ws2_local/zroot` → `ws2/zroot`,
  `ws2_local/www2` → `ws2/www2` — СДЕЛАНО.

**Обнаружено:**
- Формула zrepl sink: `root_fs/${client_identity}/${source_path}`.
- Неправильные `root_fs` в конфиге WS2 → дубли в структуре.

**Правки конфигов:**
- (после миграции) WS2 `zrepl.yml` — `root_fs`, `client_identity`.
- WSW `zrepl.yml` — НЕ трогаем.

### Сессия 2026-10-16 — zrepl-миграция (продолжение)

**Сделано:**
- `ws2_local/BS07_MY/ws2_local/BS07_MY` → `ws2/BS07_MY` (2.03T) —
  СДЕЛАНО через `zfs send -R -s | zfs recv -F -s`.
- Диагноз корня `ws2_local/BS07_MY`: `REFER 297G` — артефакт
  прерванного `zfs receive`, реальных файлов нет.
  `@migrate` на корне отсутствовал — есть только на глубоком.
- Обнаружено, что `zfs snapshot -rn` (dry-run) не поддерживается
  на FreeBSD.
- Обнаружено, что `zfs snapshot -r` не сработал на корне
  (`already exists` на вложенных — норма, корень не создавался).

**Не сделано (перенесено):**
- `wsw/wsw/zroot` → `wsw/zroot` (252G) — НЕ ЗАПУЩЕНО.
- Снять `@migrate`.
- Destroy `ws2_local`, `wsw/wsw`.
- Правка `zrepl.yml` WS2.
- Перезапуск zrepl.

**Проверки:**
- `ws2/BS07_MY` — 2.03T, снапшоты на месте.
- `wsw/wsw/zroot@migrate` — **есть** (готов к переносу).

### Сессия 2026-10-18 — T-001 (100%), T-018, T-003, ревизия всех модулей

**Закрыто:**
- **T-001 — первичный разбор кода (100%).** Разобраны/переработаны:
  - `Func/01_Config/` — 9/9 (11–19).
  - `Func/02_Backup/` — 8/8 (21–28).
  - `Func/03_Servers/` — завершено (31–39).
  - `Func/04_FW/` — завершено (41, 42, 44).
  - `Func/05_Disks/` — 6/6 (51–58).
  - `Func/06_Logs/` — 3/3 (61, 62, 66).
  - `Func/07_Mon/` — 9/9 (71–79).
  - `Func/08_VM/` — 2/2 (81, 82).
  - `Func/09_System/` — 4/4 (91, 92, 93, 99).
  - `Func/10_Sites/` — 2/2 (101, 102).
  - `Func/11_Check/` — ГОТОВО (11.1.x–11.4.2).
- **T-018 — ревизия `Func/Watch/`.** 5 «сырых» файлов поглощены
  модулем 11. Добавлена `monSystemLoad` (11.2.6), обновлена
  `monWebStackSummary` (11.3.5) — запись инцидентов.
- **T-003 — `ConfManual.sh`.** Убраны дубли (Nextcloud, Samba,
  `WpConfigPath`/`WpTestDir`), устаревшие (`WebStackExternalUrl`,
  `WebStackLocalHost`), `SRVNeedName="${SRVCurrName}"`,
  `DirZreplBackup` — export.
- **T-021 — миграция логгера.** ~98 вызовов `info`/`warn`/`err`
  → `logsMsg`.
- **Сканеры** — блокировка IP.
- **dma** — SMARTHOST, periodic-отчёты.
- **Картинки WordPress** — `sites/10/ASC_10` vs `uploads/ASC_10`.
- **WS2 SSH** — `kex_exchange_identification`.
- **T-015 (RedOS)** — systemd-юнит.
- **T-017** — универсальный механизм монтирования.
- **T-005** — мёртвые переменные `ConfPaths.sh`.
- **T-020** — тестирование `53_funcGpart.sh`.
- **monPhpFpm** — пул (`pm.status_path`).
- **monReverseProxyHeaders/Fix** — проверка на сервере.

**Ключевые правки (безопасность):**
- `13_funcSsh.sh`: `StrictHostKeyChecking no` → `accept-new`,
  `sshpass -p` → `-e`, `ed25519`, `trap` для `ssh-agent -k`,
  `sshd -t` перед restart.
- `12_funcUsers.sh`: `usersSudo` — `visudo -cf` + бэкап,
  `usersSecureSshRoot` — `sshd -t`, `usersChrootLiveCD` —
  `mount devfs`, `zpool import -N`.
- `15_funcSslRsa.sh`: `logsMsg"ERROR"` → `logsMsg "ERROR"`,
  `--batch` перед Easy-RSA, `sslUpdateRootCertValidity` —
  подтверждение `YES`.
- `16_funcCertbot.sh`: `certRenew` — только `renew` (без
  `--force-renewal`), `certForceRenew` — отдельная.
- `17_funcDocker.sh`: `${48emk@!SQL}` → `MariaDBRootPassword`,
  `docker image prune -a -f` вместо `rmi $(docker images -q)`.
- `26_funcSyncArc.sh`: `syncArcSqlRestoreToServer` — переписан,
  `syncArcSqlFromServerToArc` — динамический выбор клиента/флага.
- `31_funcWeb.sh`: `webPatchWordPressConfig` — вставка после
  `<?php`, `webRestartService` — `-t` перед restart.
- `36_funcSamba.sh`: пароль/IP/шара → `ConfManual.sh`,
  `chmod 755` вместо `777`, `valid users=@wheel`.
- `38_funcNextcloud.sh`: `nc_pass` объявлена, `sed` оставлен.
- `42_funcFirewall2.sh`: `--add-service=ssh` (SSH 22/tcp).
- `44_funcSeLinux.sh`: `httpd_sys_content_t`/`rw_content_t`
  разделены.
- `57_funcDiskMount.sh`: `NC_CACHE_DIR` + `--cache-dir`.
- `62_funcTelegram.sh`: секреты → `ConfManual.sh`, `parse_mode=HTML`,
  `curl -f`, `createDir`.
- `101_funcWordPress.sh`: `latest_version` через `api.github.com`,
  URL автодополнения, `php${v}-phar`, `wp_users` не пропускать.
- `102_funcSiteMonit.sh`: `MONIT_AUTO_REBOOT`, `accept-new`,
  Telegram `$'\n'`.

**`merge_project.ps1` (обновлён):**
- По умолчанию режет на части ~250 КБ по верхнеуровневым папкам.
- `-NoSplit` — один файл.
- `-SplitSizeKB N`, `-Part N`.
- Вывод в `Win\MergeProjectOut\`.
- Маркер `=== END OF PART N/M ===` в конце каждой части.

### Сессия 2026-10-19 — Проверка разбивки дампа, баги кода, T-030 (архитектура + модуль 12_Deploy)

**Проверка разбивки дампа (5 частей):**
- PART 1–5 прочитаны полностью, обрывов нет. Разбивка ~250 КБ рабочая.
- Найдены 2 бага `merge_project.ps1`:
  - футер последней части печатал «Следующая часть: 6 из 5»;
  - `startMain.sh` не попадал в TOC PART 5 (секция `ROOT` не выводилась).
- Исправлено: футер для последней части — «Это последняя часть (N из M)»;
  `Section` теперь определяется и по `Top -eq 'ROOT'`, а не только по `$rootSet`.

**Баги кода (починены):**
- `61_funcLogs.sh`: `logsShowMessages` (6.1.3) и `logsShowConsole` (6.1.4) —
  сломанный heredoc. Восстановлено, добавлен `timeout`, `mkdir -p` → `createDir`
  в `logsSnapshotDmesgBoot`.
- `funcCheck.sh`: вызов несуществующей `warn` → `logsMsg "WARN"`.
- `114_funcPostMortem.sh`: `logsMsg "ERR"` → `logsMsg "ERROR"` (2 места);
  добавлен `MenuRegister "11"` перед `"11.4"`.

**T-030 — Развёртывание серверов и синхронизация файлов настроек:**
- Архитектура (5 решений):
  1. Источник истины — GitHub `DrAngelOk/DrBash` (`Def/`, `Sample/`).
  2. Синхронизируются ВСЕ конфиги; роли в `server.list` (`functions`) —
     переключатели активности служб, не фильтр синхронизации.
  3. Направление — pull + push с ревью.
  4. Конфликты — эталон всегда побеждает (force pull), бэкап
     `.bak.YYYY-MM-DD_HHMM`; push — единственный способ изменить эталон.
  5. Область — `Def/sync.<ostype>.list` (строгий INI, секция
     `[OSType:путь]`), эталон в `Sample/<OSType>/<rel>`.
- Статусы: `ready` / `manual` / `do-not-touch`. Пока `Sample/` пуст —
  ВСЕ пути `do-not-touch`.
- Процедура перевода в `ready`/`manual`: сравнить WSW↔WS2 →
  проанализировать расхождения → согласовать с ИИ → положить эталон
  в `Sample/` → перевести статус.
- Эталон — **Nextcloud-моунт** (`DirScriptsSampleNet =
  ${NC_MOUNT_POINT:-/mnt/scripts}/Sample`), виден всем серверам и Windows.
  `DirScriptsSample` (локальная) — «на потом».
- Цепочка: push (сервер → `/mnt/scripts/Sample/`) → Nextcloud → Windows →
  `sanitize_for_repo.ps1` → `git push` → GitHub → pull.

**Создано:**
- `Def/sync.freebsd.list` — 39 путей, все `do-not-touch`, кроме
  `wp-config.php` (`do-not-touch` — патч, не зеркало). Исправлены пути
  по факту WSW: `/etc/sudoers` → `/usr/local/etc/sudoers`,
  `/usr/local/etc/zrepl.yml` → `/usr/local/etc/zrepl/zrepl.yml`,
  `/var/db/mysql/my.cnf` удалён. Добавлены `boot`-пути.
- `Def/sync.redos.list` — 24 пути, все `do-not-touch`, кроме
  `/etc/default/grub` (`manual`) и `/boot/grub2/custom.cfg` (`manual`);
  `/boot/grub2/grub.cfg` — `do-not-touch` (генерируется).
- `Func/12_Deploy/120_funcSyncCommon.sh` — парсер `sync.list`
  (`_sync_parse_list`), хелперы `_sync_ostype_lc`, `_sync_list_path`,
  `_sync_sample_path`, `_sync_status_of`.
- `Func/12_Deploy/121_funcSyncAudit.sh` — аудит (12.1.1), read-only,
  TXT + TSV.
- `Func/12_Deploy/122_funcSyncPull.sh` — pull (12.1.2), режимы
  dry-run / `--yes` / `--force`, бэкап, `rsync -a --delete` для dir.
- `Func/12_Deploy/123_funcSyncPush.sh` — push (12.1.3), режимы
  dry-run / `--yes`/`--force`, бэкап эталона, WARN про
  `sanitize_for_repo.ps1`.

**Правки `ConfPaths.sh`:**
- `DirScriptsDeploy="${DirScripts}/Func/12_Deploy"`.
- `DirSyncListPrefix="${DirScriptsDef}/sync"`.
- `DirScriptsSampleNet="${NC_MOUNT_POINT:-/mnt/scripts}/Sample"` (основная),
  `DirScriptsSample` оставлена (локальная).

**Аудит на WSW (12.1.1) — результат:**
- 39 путей: 28 существует, 11 отсутствует, тип не совпал 0.
- `Sample/` = 0 (эталонов ещё нет — ожидаемо).
- 11 отсутствующих — роли не активны на WSW (`namedb`, `exports`,
  `smb4.conf`, `rest-server`, `smartd.conf`), либо пути неверны
  (исправлены), либо файла нет (`aliases.conf`).

**Согласовано:**
- `.profile` — эталон = живой WSW (с `EASYRSA_VARS_FILE`, `resizewin`,
  `source ${ENV}`).
- `.bashrc` — согласован.
- `.bashrc.d/` — нужна как папка; содержимое: `.aliases.conf`,
  `.colors.conf`, `.wp-completion.conf` (общие для всех).

### Сессия 2026-10-23 — zrepl завершён, GSW, ESXi (SSH/RDM/копирование), конфиги, T-030

**zrepl-миграция ЗАВЕРШЕНА:**
- `wsw/wsw/zroot` → `wsw/zroot` (252G) — перенесён.
- `@migrate` снят с `ws2/*` и `wsw/zroot`.
- `ws2_local` — удалён (holds: `zrepl_last_received_J_sink_wsw` на всех
  снапшотах; сняты через `zfs release` по каждому снапшоту циклом).
- `wsw/wsw` — удалён (holds сняты тем же циклом).
- `zrepl.yml` на WS2: `sink_wsw.root_fs: BS07_MY/ZREPL` (без `/wsw`),
  `local_sink_*.root_fs: BS07_MY/ZREPL` (без `/ws2_local`),
  `push_ws2_*.client_identity: ws2`. `configcheck` — OK, restart — OK.
- `zrepl status --mode raw` — все jobs живы, snap-джобы отработали
  на новой структуре, push-джобы в `Replication: null` (ручной
  snapshotting — запустятся по сигналу).

**GSW — Nextcloud + OnlyOffice (Docker):**
- `/ARC/_Docker/` удалена (была рабочая директория compose).
- Восстановлено в `/opt/nextcloud-gsw/`:
  - `docker-compose.yml` — из `docker-autocompose` (3 контейнера),
    очищен: убраны `hostname`/`mac_address`/`labels`/`environment`
    из образов, `nginx.conf` → `/opt/nextcloud-gsw/nginx.conf`.
  - `nginx.conf` — извлечён из работающего контейнера
    (`docker exec nginx-server cat /etc/nginx/nginx.conf`).
- Контейнеры пересозданы под новым Compose (`docker compose up -d`),
  данные в external volume'ах сохранены. Снаружи работает.
- `JWT_SECRET=secret` — оставлен с `[FIX]` (менять только синхронно
  с плагином Nextcloud).

**ESXi (11, 12, 13 — 192.168.1.28, .38, .48):**
- SSH между хостами: `sshServer` везде true; `sshClient` на 12/13
  был false → включили (`esxcli network firewall ruleset set
  --ruleset-id sshClient --enabled=true`).
- Ключи: ed25519 ESXi НЕ поддерживает → RSA 4096.
  - WSW → ESXi: `/root/.ssh/id_rsa_esxi`, публичная часть —
    в `/etc/ssh/keys-root/authorized_keys` на ESXi.
  - ESXi ↔ ESXi: host key (`/etc/ssh/ssh_host_rsa_key`), публичные
    части — друг у друга в `authorized_keys`.
- `known_hosts`: ESXi не пишет (`hostfile_replace_entries: Function
  not implemented`). Симлинк `ln -s /etc/ssh/keys-root /.ssh` —
  первый раз ошибка, файл создаётся, второй — OK. Радикально —
  `-o UserKnownHostsFile=/dev/null`.
- `esxiCopyScripts` (8.1.12): копирует `startMain.sh` + папки из
  `scriptpaths.list` на ESXi через `sftp` (SCP на ESXi ломается).
  Ключ — `/root/.ssh/id_rsa_esxi`. Скопировано в
  `/vmfs/volumes/DS11/Scripts`.
- `esxiDiskAttachPhysicalRDM` (8.1.3): переписана — RDM через SSH
  с WSW. `esxcli storage core device list` (устройства `t10.`/`naa.`/`eui.`),
  `esxcli storage core device get` — НЕТ, использовать `list -d`.
  `Display Name` для локальных дисков бесполезен → имя RDM из
  `t10.ATA...` (`WDC_WD5000LPSX_WD2DWXD2A6385AFE.vmdk`). Создан
  тестовый RDM `rdm_20261021_1409.vmdk` на DS12 (старое автоимя).
  **Осталось:** вставить блок имени из `t10.ATA...` и перезапустить.

**Конфиги (правки):**
- `loader.conf` — комментарии (arc.max/min, unmapped_buf_allowed,
  min_auto_ashift, fusefs_load, if_ovpn_load).
- `sysctl.conf` — убрана слипшаяся строка, добавлены комментарии,
  `vfs.zfs.vdev.min_auto_ashift=12` (для новых пулов).
- `periodic.conf` — `daily_output="/dev/null"` (было `""` — не
  отключало отчёты), `daily_ntpd_leapfile_enable="YES"`.
- `rc.conf` — `zpool_reguid`/`zpool_upgrade` закомментированы
  (firstboot), `restserver_enable="NO"`, `backrest_enable="NO"`,
  `powerd_enable="NO"`, NTP включён (`ntpd_enable`,
  `ntpd_sync_on_start`), комментарии к каждой строке.
- `crontab` — `certbot renew` → `startMain.sh 1.6.3`, устаревшие ID
  (`2 6`, `2 3`) закомментированы с пометкой, таблица задач
  в комментариях.
- `syslog.conf` — `local0` → `local1` для zrepl (`zrepl.yml` тоже
  `facility: local1`), `*.emerg root` (было `*`), `debug.log`
  закомментирован.
- `fstab` — `noauto` на NFS (`/media/NFS01`, `/media/NFS_D`).
- `motd.template` — создан (`\s`), `ready` в `sync.list`.
- `hosts`, `resolv.conf` — `do-not-touch` (per-server).
- `ntp.conf` — создан (пул FreeBSD, `restrict`, `driftfile`,
  `leapfile /var/db/ntpd.leap-seconds.list`).

**T-030 (продолжение):**
- `sync.freebsd.list` — добавлены: `/etc/ipfw.rules` (`do-not-touch`),
  `/etc/make.conf` (`do-not-touch`), `/etc/crontab` (`manual`),
  `/etc/motd.template` (`ready`), `/etc/newsyslog.conf.d` (`ready`),
  `/usr/local/etc/newsyslog.conf.d` (`ready`), `/etc/syslog.d` (`ready`),
  `/usr/local/etc/syslog.d` (`ready`).
- Push профилей root: `.profile`, `.bashrc`, `.bashrc.d` переведены
  в `manual`, push `12.1.3 --yes` → `Sample/FreeBSD/root/...`.
  Аудит WS2: `diff=same` (совпадает) — можно в `ready`, но сначала
  сравнить с WS2 (сделано, совпадает).
- `122_funcSyncPull.sh` / `123_funcSyncPush.sh` — аргументы
  (`--yes`/`--force`, OSType) разбираются в любом порядке.
- `121_funcSyncAudit.sh` — вывод выровнен через `printf` (plain+color),
  разделение `_plain`/`_color`.

**AI_FUNCTIONS.tsv — создан:**
- Индекс функций (TSV: файл, номер, название, описание, статус, ключи).
- 15 модулей: Conf/, Func/Scripts/, startMain, 01_Config, 02_Backup,
  03_Servers, 04_FW, 05_Disks, 06_Logs, 07_Mon, 08_VM, 09_System,
  10_Sites, 11_Check, 12_Deploy.
- Статусы: `ГОТОВО` / `НЕ ПРОВЕРЕНО` / `T-030` / `ОТЛОЖЕНО`.

## ❓ ОТКРЫТЫЕ ВОПРОСЫ

1. **T-030.4** — наполнить `Sample/` эталонами (push с WSW и WS2,
   сравнение, согласование). Начать с профилей root (push сделан,
   аудит WS2 `diff=same` — перевести в `ready`).
2. **T-030.5–.9** — pull/push написаны, но не тестированы; роли
   (`server.list` → вкл/выкл служб), развёртывание нового сервера,
   `Def/disks.list`, `rsInitRepository` — не начаты.
3. **`esxiDiskAttachPhysicalRDM` (8.1.3)** — вставить блок имени RDM
   из `t10.ATA...` (`WDC_WD5000LPSX_WD2DWXD2A6385AFE.vmdk`) и
   перезапустить. Тестовый RDM `rdm_20261021_1409.vmdk` — удалить.
4. **GSW-диск** — добавить второй vmdk в ESXi, разметить, перенести
   `/var/lib/docker` (46G) или volumes Nextcloud/OnlyOffice.
5. **SMART** — `/dev/da2` self-test failed (WDC16). Нужно
   `smartctl -a /dev/da2`.
6. **T-004** — `source_required` (отложено).
7. **`39_funcDns.sh`** (`dnsSetup`) → `DirScriptsSampleNet` (отложено).
8. **`server.list` под роли**, **скрипт вкл/выкл ролей**,
   **`Def/disks.list`**, **`rsInitRepository`** от `angelrs`.
9. **Секреты в `ConfManual.sh`/`server.list`** — открытым текстом,
   маскируются `sanitize` при repo-push. Отдельная тема — вынести
   в `.env` или зашифровать.
10. **`AI_FUNCTIONS.tsv`** — добавить в `config.json` (секция `files`),
    чтобы читался при старте.

## 🛠 КОМАНДЫ ai_context.ps1

| Команда | Что делает |

| status | Показать состояние AI-папки. |
| zip | Собрать zip-пакет. |
| down | Распаковать пакет из буфера. |
| repo-push | Залить в GitHub. |
| repo-pull | Скачать из GitHub. |
| session-close | down + zip + repo-push. |
| help | Справка. |

## 🛠 ИНСТРУМЕНТЫ (файлы и папки)

| Файл / папка | Назначение |

| AI_START.md | Короткая точка входа. |
| AI_MAP.md | Карта проекта. |
| AI_CONTEXT.md | Этот файл. |
| AI_TASKS.md | Чек-лист. |
| AI_FUNCTIONS.tsv | Индекс функций (TSV). |
| _END_OF_SESSION_PROMPT.txt | Промпт-триггер. |
| ai_context.ps1 | Управляющий скрипт. |
| merge_project.ps1 | Сборщик дампа. |
| sanitize_for_repo.ps1 | Обезличиватель. |
| config.json | Конфигурация. |
| chats/ | Резюме сессий. |
| patches/ | Патчи. |
| _repo/ | Локальные копии. |
| _transfer/ | Готовые zip-пакеты. |
| Def/sync.freebsd.list | Манифест синхронизации конфигов FreeBSD (T-030). |
| Def/sync.redos.list | Манифест синхронизации конфигов RedOS (T-030). |
| Func/12_Deploy/ | Модуль развёртывания и синхронизации (120 common, 121 audit, 122 pull, 123 push). |

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
- **`zfs send -R` требует снапшот на КОРНЕ дерева**, иначе
  промежуточные уровни приедут как placeholder'ы.
- **`zfs release` / `zfs holds`** — только со снапшотом, не с датасетом.
- **`zrepl zfs-abstraction release-all --fs`** — не снимает holds,
  если job удалён из конфига.
- **`StrictHostKeyChecking=no` запрещён** — только `accept-new`.
  (Исключение: ESXi, где `known_hosts` не работает — `no` +
  `UserKnownHostsFile=/dev/null`.)
- **`sshpass -p` запрещён** — только `sshpass -e` (пароль в `SSHPASS`).
  Для ESXi — ключ RSA 4096 (ed25519 не поддерживается).
- **`visudo -cf` / `sshd -t` перед restart** — обязательно.
- **Бэкап `.bak.YYYY-MM-DD_HHMM`** перед правкой `sudoers`/`sshd_config`/
  `fstab`/`loader.conf`/`wp-config.php`.
- **Все пути — только через `ConfPaths.sh`.** В коде модулей не должно
  быть хардкодов путей (`/ARC/...`, `/var/log/my`, `Def/...`). Если нужен
  новый путь — заводится переменная `Dir*`/`Cfg*` в `ConfPaths.sh` и
  используется через `${...}`.
- **Эталон конфигов — Nextcloud-моунт** (`DirScriptsSampleNet`), не
  локальная папка. `DirScriptsSample` — резервная, «на потом».
- **`periodic.conf`: `*_output=""` НЕ отключает отчёты** (означает
  «в stdout»). Для отключения — `/dev/null`.
- **ESXi: `sshServer` — входящие, `sshClient` — исходящие.**
  Для `scp`/`ssh` с хоста нужен `sshClient: true`.
- **ESXi: `Display Name` для локальных дисков** может повторять
  `t10.ATA...` — имя RDM формировать из `t10.ATA...`.
- **ESXi: `esxcli storage core device get`** — может отсутствовать,
  использовать `list -d <device>`.

## 📁 КОДИРОВКА ФАЙЛОВ

- Bash: UTF-8 без BOM, LF.
- PowerShell: ASCII в исполняемых строках.
- JSON: UTF-8 с BOM.
- TSV: UTF-8, табуляция (Excel открывает двойным кликом).

## 🧾 ЗАМЕТКИ

- **Только raw.githubusercontent.com.**
- **Кэш raw-URL:** `?v=<уникальное>`.
- **Z: — WebDAV. Только `gh api`.**
- **Карта проекта — в AI_MAP.md.**
- **Индекс функций — в AI_FUNCTIONS.tsv.**
- **Панель:** `bash /ARC/Scripts/startMain.sh`.
- **createDir** — утилита в funcUtil.sh.
- **MenuStart — единая точка входа.**
- **Единый логгер — `logsMsg`.**
- **`monPostmortem`** — слепок в `/var/log/postmortem/` (dump-*.txt.gz).
- **`pmAnalyze`** — анализ свежего слепка, только проблемы.
- **HTTP-проверка:** `_webstack_http_check` (local/external/remote).
- **MySQL-монитор:** пользователь `monitor`, пароль
  `MTr9kLp2Xw7qNv`.
- **NFS не работает — норма** (`192.168.1.19`, `192.168.2.5` —
  серверы ещё не настроены). В `fstab` — `noauto`.
- **zrepl sink:** `root_fs/${client_identity}/${source_path}`.
- **zrepl-миграция:** завершена (см. историю 2026-10-23).
- **`merge_project.ps1`** — по умолчанию режет на части
  ~250 КБ в `Win\MergeProjectOut\`.
- **T-030:** эталон конфигов — `DirScriptsSampleNet`
  (`/mnt/scripts/Sample`), манифест — `Def/sync.<ostype>.list`.
- **GSW:** `/opt/nextcloud-gsw/` (compose + nginx.conf), данные —
  в external volume'ах.
- **ESXi:** ключ `/root/.ssh/id_rsa_esxi` (RSA 4096) на WSW,
  host key на ESXi; `sshClient: true` для исходящих.