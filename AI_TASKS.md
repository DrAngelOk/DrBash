# AI TASKS — Z:\DOC\СЕРВЕРА\Scripts

## 🎯 В РАБОТЕ

□ **zrepl `push_ws2_zroot`** — `no common snapshot`:
  - ☑ Диагноз: у отправителя `zrepl_ws2_zroot_*`, у получателя
    `zrepl_ws2_bs07_*` — общих нет.
  - □ `zfs destroy -r BS07_MY/ZREPL/ws2/zroot`
  - □ `zrepl signal wakeup push_ws2_zroot` (полный send)
  - □ Проверить, что появились `home`, `usr`, `var/audit`, `var/crash`,
    `var/mail`, `var/tmp`.

□ **T-030 — Развёртывание серверов и синхронизация файлов настроек.**
- ☑ `Def/sync.freebsd.list` (46 путей)
- ☑ `Def/sync.redos.list` (24 пути)
- ☑ `120_funcSyncCommon.sh` (парсер + хелперы)
- ☑ `121_funcSyncAudit.sh` (12.1.1, read-only, TXT+TSV)
- ☑ `122_funcSyncPull.sh` (12.1.2, dry/--yes/--force, бэкап)
- ☑ `123_funcSyncPush.sh` (12.1.3, dry/--yes, бэкап эталона)
- ☑ `ConfPaths.sh`: `DirScriptsSampleNet`, `DirScriptsDeploy`, `DirSyncListPrefix`
- ☑ Аудит WSW: 39 путей, 28 есть, 11 нет
- ☑ Push профилей root (`.profile`, `.bashrc`, `.bashrc.d`) → `Sample/`
- ☑ Аудит WS2: `diff=same` (совпадает с эталоном)
- □ **T-030.4** — перевести `.profile`/`.bashrc`/`.bashrc.d` в `ready`
- □ **T-030.5** — проверить pull на реальных эталонах
- □ **T-030.6** — проверить push на реальных эталонах
- □ **T-030.8** — скрипт вкл/выкл ролей (`server.list` → службы)
- □ **T-030.9** — развёртывание нового сервера (оркестратор)
- □ `39_funcDns.sh` (`dnsSetup`) → `DirScriptsSampleNet` (отложено)
- □ `AI_FUNCTIONS.tsv` — добавить в `config.json`

□ **ESXi / RDM** — `esxiDiskAttachPhysicalRDM` (8.1.3):
  вставить блок имени RDM из `t10.ATA...`
  (`WDC_WD5000LPSX_WD2DWXD2A6385AFE.vmdk`), удалить тестовый
  `rdm_20261021_1409.vmdk`.

□ **GSW-диск** — перенести данные Nextcloud на `/mnt/doc`:
  - □ `zpoolCreateData` (5.2.3) `doc_pool /dev/sda`
  - □ `zfs set mountpoint=/mnt/doc doc_pool`
  - □ `rsync` из volume → `/mnt/doc/`
  - □ Заменить в `docker-compose.yml` на bind-mount `/mnt/doc:/var/www/html`
    (в `app-server` и `nginx-server`)
  - □ `docker compose up -d`, `occ files:scan --all`
  - □ Удалить старый volume `docker-onlyoffice-nextcloud_app_data`

□ **`zrInstallZrepl` (2.4.1)** — проверить на GSW (RedOS).

□ **SMART** — `/dev/da2` self-test failed (WDC16). Нужно
  `smartctl -a /dev/da2`.

□ **T-004 — source_required** (отложено).

□ **НОВАЯ** — `server.list` под роли.

□ **НОВАЯ** — `Def/disks.list`.

□ **НОВАЯ** — `rsInitRepository` от `angelrs`.

□ **T-033 — crontab** — вставить сводную таблицу-комментарий,
  разнести `restic`/`periodic`, проверить устаревшие ID.

□ **T-034 — dma SMARTHOST** — настроить `/etc/dma/dma.conf`,
  вернуть periodic-отчёты (`daily_output` с `/dev/null` на почту/лог).

## ⏳ СЛЕДУЮЩЕЕ

1. **zrepl `push_ws2_zroot`** — удалить `ws2/zroot`, полный send.
2. **GSW-диск** — перенос Nextcloud на `/mnt/doc`.
3. **ESXi / RDM** — блок имени из `t10.ATA...`.
4. **T-030.4** — профили root → `ready`.
5. **`zrInstallZrepl` (2.4.1)** — проверка на GSW.
6. **SMART `/dev/da2`**.

## ✅ ГОТОВО (2026-10-23)

- ☑ **zrepl-миграция завершена**: `wsw/wsw` → `wsw/zroot` (252G),
  `ws2_local`/`wsw/wsw` удалены, holds сняты, `zrepl.yml` WS2
  исправлен (`root_fs`, `client_identity`), `configcheck` + restart OK.
- ☑ **GSW**: `/opt/nextcloud-gsw/` (compose + nginx.conf),
  контейнеры пересозданы, данные сохранены, снаружи работает.
- ☑ **ESXi**: `sshClient: true` на 12/13, ключи RSA 4096 между
  хостами и с WSW, `esxiCopyScripts` (8.1.12) — копирование на ESXi
  через `sftp`, `esxiDiskAttachPhysicalRDM` (8.1.3) — RDM через SSH.
- ☑ **Конфиги**: `loader.conf`, `sysctl.conf`, `periodic.conf`,
  `rc.conf`, `crontab`, `syslog.conf`, `fstab`, `motd.template`,
  `ntp.conf` — с комментариями и правками.
- ☑ **T-030**: `sync.freebsd.list` (46 путей), push профилей root,
  аудит WS2, аргументы pull/push в любом порядке, вывод аудита
  выровнен (`printf`).
- ☑ **AI_FUNCTIONS.tsv** — индекс функций (15 модулей).
- ☑ **`zpoolListFreeDisks` (5.2.12)** — все диски с состоянием,
  проверено на WSW и GSW.
- ☑ **`zrInstallZrepl` (2.4.1)** — расширена под RedOS
  (RPM-репозиторий, systemd), FreeBSD-ветка без изменений.

## ✅ ГОТОВО (2026-10-19)

- ☑ Проверка разбивки дампа (5 частей) — рабочая.
- ☑ `merge_project.ps1` — 2 бага: футер последней части, TOC ROOT.
- ☑ `61_funcLogs.sh` — сломанный heredoc 6.1.3/6.1.4, `timeout`, `createDir`.
- ☑ `funcCheck.sh` — `warn` → `logsMsg "WARN"`.
- ☑ `114_funcPostMortem.sh` — `logsMsg "ERR"` → `"ERROR"`, `MenuRegister "11"`.
- ☑ T-030 архитектура (5 решений) + `sync.*.list` + модуль `12_Deploy`.

## ✅ ГОТОВО (2026-10-18)

- ☑ **T-001** — первичный разбор кода (100%).
- ☑ **T-018** — ревизия `Func/Watch/` (поглощён модулем 11).
- ☑ **T-003** — `ConfManual.sh` (убраны дубли, устаревшее).
- ☑ **T-021** — миграция логгера (~98 вызовов).
- ☑ **Сканеры** — блокировка IP.
- ☑ **dma** — SMARTHOST, periodic-отчёты.
- ☑ **Картинки WordPress** — `sites/10/ASC_10` vs `uploads/ASC_10`.
- ☑ **WS2 SSH** — `kex_exchange_identification`.
- ☑ **T-015 (RedOS)** — systemd-юнит.
- ☑ **T-017** — универсальный механизм монтирования.
- ☑ **T-005** — мёртвые переменные `ConfPaths.sh`.
- ☑ **T-020** — тестирование `53_funcGpart.sh`.
- ☑ **monPhpFpm** — пул (`pm.status_path`).
- ☑ **monReverseProxyHeaders/Fix** — проверка на сервере.
- ☑ **`merge_project.ps1`** — нарезка на части ~250 КБ в `Win\MergeProjectOut\`.

## 📊 СТАТИСТИКА

| Метрика | Значение |

| В работе | ~8 |
| Готово | 190+ |
| Прогресс T-001 | **100%** |
| Прогресс T-030 | ~50% (архитектура + код + push профилей, без полного теста pull/push) |

## 🎯 ТЕКУЩИЙ ФОКУС

- **zrepl `push_ws2_zroot`** — `no common snapshot`, полный send.
- **GSW-диск** — перенос Nextcloud на `/mnt/doc`.
- **ESXi / RDM** — блок имени из `t10.ATA...`.
- **T-030.4** — профили root → `ready`.
- **`zrInstallZrepl` (2.4.1)** — проверка на GSW.
- **SMART `/dev/da2`**.