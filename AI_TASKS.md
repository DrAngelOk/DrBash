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

□ **T-018 (расширено)** — ревизия `Func/Watch/`.
- □ Что в `Func/Watch/` сейчас
- □ Что уже перенесено (`watchMysql.sh`, `mon*`)
- □ Что осталось
- □ Решение по каждому: перенести / удалить / оставить

□ **WS2 SSH** — `kex_exchange_identification: timeout`.
TCP-сессия идёт, SSH-баннер не приходит. `UseDNS no`, MTU —
не помогло. Отложено.

□ **Картинки WordPress** — `sites/10/ASC_10/...` vs
`uploads/ASC_10/...`. Петля `AH00124`. Отложено.

□ **T-001 — Первичный разбор кода проекта**
- `startMain.sh` — ГОТОВО
- `Conf/` (7 файлов) — ГОТОВО
- `Func/Scripts/` (2 файла) — ГОТОВО
- `Func/Menu/funcMenu.sh` — ГОТОВО
- `Func/05_Disks/` (6 файлов) — ГОТОВО
- `Func/06_Logs/61_funcLogs.sh` — ГОТОВО (ротация)
- `Func/01_Config/` (9 файлов) — ЧАСТИЧНО (15, 16, 17)
- `Func/02_Backup/` — ЧАСТИЧНО (22, 23, 24)
- `Func/03_Servers/ … Func/10_Sites/` — НЕ НАЧАТО
- `Func/11_Check/` — ГОТОВО (11.1.x, 11.2.x, 11.3.x, 11.4.1, 11.4.2)

□ **T-021 — Миграция логгера** — ~98 вызовов `info`/`warn`/`err`.

□ **T-003 — ConfManual.sh** — устаревшие данные.

□ **T-015 (RedOS)** — systemd-юнит.

□ **T-017 — Универсальный механизм монтирования.**

□ **T-004 — source_required** (отложено).

□ **T-005 — Мёртвые переменные ConfPaths.sh** (отложено).

□ **T-020 — Тестирование 53_funcGpart.sh** (отложено).

□ **Сканеры** — блокировка IP (`20.58.188.171`, `13.140.57.64`).

□ **SMART** — `/dev/da2` self-test failed (WDC16).
Нужно `smartctl -a /dev/da2`.

□ **dma** — настроить SMARTHOST, вернуть periodic-отчёты.

□ **`monPhpFpm`** — пул не настроен (`pm.status_path`).

□ **`monReverseProxyHeaders` / `monReverseProxyFix`** —
проверить на сервере (11.3.7, 11.3.8).

□ **НОВАЯ** — `server.list` под роли.

□ **НОВАЯ** — скрипт вкл/выкл ролей.

□ **НОВАЯ** — `Def/disks.list`.

□ **НОВАЯ** — `rsInitRepository` от `angelrs`.

## ⏳ СЛЕДУЮЩЕЕ

1. **zrepl-миграция** — завершить (`wsw`, `@migrate`, destroy, конфиг).
2. **T-018 (расширено)** — ревизия `Func/Watch/`.
3. **T-001** — `Func/01_Config` (11–14, 18, 19).
4. **Сканеры** — блокировка.
5. **SMART `/dev/da2`** — проверить.

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
|---------|----------|
| В работе | ~14 |
| Готово | 150+ |
| Прогресс T-001 | ~35% |

## 🎯 ТЕКУЩИЙ ФОКУС

- **zrepl-миграция** — завершить (`wsw` + конфиг).
- **T-018** — ревизия `Func/Watch/`.
- **T-001** — `Func/01_Config`.
- **Сканеры** — блокировка.
- **SMART `/dev/da2`** — проверить.