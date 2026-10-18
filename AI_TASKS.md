# AI TASKS — Z:\DOC\СЕРВЕРА\Scripts

## 🎯 В РАБОТЕ

□ **zrepl-миграция структуры приёмника (WS2)** — ЗАВЕРШИТЬ.
- ☑ `ws2_local/zroot` → `ws2/zroot` (СДЕЛАНО)
- ☑ `ws2_local/www2` → `ws2/www2` (СДЕЛАНО)
- ☑ `ws2_local/BS07_MY/ws2_local/BS07_MY` → `ws2/BS07_MY` (2.03T) (СДЕЛАНО)
- □ `wsw/wsw/zroot` → `wsw/zroot` (252G) — НЕ ЗАПУЩЕНО
  - `@migrate` на `wsw/wsw/zroot` — есть
  - команда: `zfs send -R -s BS07_MY/ZREPL/wsw/wsw/zroot@migrate | zfs recv -F -s BS07_MY/ZREPL/wsw/zroot`
- □ Снять `@migrate` со всех новых датасетов
- □ Destroy `BS07_MY/ZREPL/ws2_local` (recursive)
- □ Destroy `BS07_MY/ZREPL/wsw/wsw` (recursive, родитель `wsw` оставить)
- □ Правка `zrepl.yml` на WS2:
  - `push_ws2_*`: `client_identity: ws2_local` → `ws2`
  - `local_sink_*`: `root_fs: BS07_MY/ZREPL` (без хвоста)
  - `sink_wsw`: `root_fs: BS07_MY/ZREPL` (без `/wsw`)
- □ `zrepl configcheck`
- □ `service zrepl restart` (сначала WS2, потом WSW)
- □ `zrepl status` — проверить

□ **SMART** — `/dev/da2` self-test failed (WDC16).
Нужно `smartctl -a /dev/da2`.

□ **T-004 — source_required** (отложено).

□ **НОВАЯ** — `server.list` под роли.

□ **НОВАЯ** — скрипт вкл/выкл ролей.

□ **НОВАЯ** — `Def/disks.list`.

□ **НОВАЯ** — `rsInitRepository` от `angelrs`.

## ⏳ СЛЕДУЮЩЕЕ

1. **zrepl-миграция** — завершить (`wsw`, `@migrate`, destroy, конфиг).
2. **SMART `/dev/da2`** — проверить.
3. **T-004** — `source_required`.
4. **НОВЫЕ** — `server.list` под роли, скрипт вкл/выкл ролей,
   `Def/disks.list`, `rsInitRepository`.

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
- ☑ **`merge_project.ps1`** — нарезка на части ~250 КБ в
  `Win\MergeProjectOut\`.

## ✅ ГОТОВО (2026-10-16)

- ☑ `ws2_local/BS07_MY/ws2_local/BS07_MY` → `ws2/BS07_MY` (2.03T).
- ☑ Диагноз `REFER 297G` на корне `ws2_local/BS07_MY` —
  артефакт прерванного `zfs receive`.
- ☑ Обнаружено: `@migrate` на корне не создавался,
  `zfs snapshot -rn` не поддерживается.

## ✅ ГОТОВО (2026-10-15)

- ☑ `monPostmortem` (11.4.1) — защита от зависаний.
- ☑ `pmAnalyze` (11.4.2) — автопарсер дампа.
- ☑ `ws2_local/zroot` → `ws2/zroot`.
- ☑ `ws2_local/www2` → `ws2/www2`.
- ☑ Формула zrepl sink задокументирована.

## ✅ ГОТОВО (2026-10-14)

- ☑ `installDrbashWrapper` + `systemInstallDrbash` (9.2.8).
- ☑ `zfsShowArcStats` (5.1.14) … `zfsTuneVirtualization` (5.1.18).
- ☑ `syncNextcloud` (5.7.5) — вывод хода.
- ☑ `monZfsToolsInstall` (11.1.1) … `monSmartStatus` (11.1.8).
- ☑ `monMemory` (11.2.1) … `monMemoryErrorsDeep` (11.2.5).
- ☑ `monMysqlCreateMonitor` (11.3.1) … `monReverseProxyFix` (11.3.8).
- ☑ `monPostmortem` (11.4.1) — базовая версия.
- ☑ `_webstack_http_check`.
- ☑ `wp-config.php` — `HTTP_X_FORWARDED_PROTO`.
- ☑ `arc.max`/`arc.min` — применено.
- ☑ `unmapped_buf_allowed="0"`, `min_auto_ashift="12"`.
- ☑ `smartd.conf` — создан.
- ☑ `periodic.conf` — отчёты отключены.
- ☑ MySQL-монитор `monitor` — создан.

## 📊 СТАТИСТИКА

| Метрика | Значение |

| В работе | ~7 |
| Готово | 165+ |
| Прогресс T-001 | **100%** |

## 🎯 ТЕКУЩИЙ ФОКУС

- **zrepl-миграция** — завершить (`wsw` + конфиг).
- **SMART `/dev/da2`** — проверить.
- **T-004** — `source_required`.
- **НОВЫЕ** — `server.list` под роли, скрипт вкл/выкл ролей,
  `Def/disks.list`, `rsInitRepository`.