# AI TASKS — Z:\DOC\СЕРВЕРА\Scripts

## 🎯 В РАБОТЕ

□ **T-030 — Развёртывание серверов и синхронизация файлов настроек.**
Архитектура зафиксирована (5 решений). Модуль `12_Deploy` создан.
- ☑ `Def/sync.freebsd.list` (39 путей, все `do-not-touch`)
- ☑ `Def/sync.redos.list` (24 пути, `do-not-touch` + 2 `manual`)
- ☑ `120_funcSyncCommon.sh` (парсер + хелперы)
- ☑ `121_funcSyncAudit.sh` (12.1.1, read-only, TXT+TSV)
- ☑ `122_funcSyncPull.sh` (12.1.2, dry/--yes/--force, бэкап)
- ☑ `123_funcSyncPush.sh` (12.1.3, dry/--yes, бэкап эталона)
- ☑ `ConfPaths.sh`: `DirScriptsSampleNet`, `DirScriptsDeploy`, `DirSyncListPrefix`
- ☑ Аудит WSW: 39 путей, 28 есть, 11 нет, `Sample/` = 0
- □ **T-030.2** — перевести `.profile`, `.bashrc`, `.bashrc.d` в `manual`, push → `Sample/`, согласовать → `ready`
- □ **T-030.4** — наполнить `Sample/` эталонами (WSW + WS2, сравнение)
- □ **T-030.5** — проверить pull на реальных эталонах
- □ **T-030.6** — проверить push на реальных эталонах
- □ **T-030.8** — скрипт вкл/выкл ролей (`server.list` → службы)
- □ **T-030.9** — развёртывание нового сервера (оркестратор)
- □ `39_funcDns.sh` (`dnsSetup`) → `DirScriptsSampleNet` (отложено)

□ **SMART** — `/dev/da2` self-test failed (WDC16). Нужно `smartctl -a /dev/da2`.

□ **T-004 — source_required** (отложено).

□ **НОВАЯ** — `server.list` под роли.

□ **НОВАЯ** — `Def/disks.list`.

□ **НОВАЯ** — `rsInitRepository` от `angelrs`.

## ⏳ СЛЕДУЮЩЕЕ

1. **T-030.2** — первый цикл push: `.profile`/`.bashrc`/`.bashrc.d` → `manual` → push → `Sample/`.
2. **T-030.4** — аудит WS2 (`12.1.1`), сравнение с WSW, согласование эталонов.
3. **SMART `/dev/da2`** — проверить.
4. **zrepl-миграция** — завершить (`wsw` + конфиг WS2).
5. **T-004** — `source_required`.

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

| В работе | ~5 |
| Готово | 171+ |
| Прогресс T-001 | **100%** |
| Прогресс T-030 | ~40% (архитектура + код, без тестов) |

## 🎯 ТЕКУЩИЙ ФОКУС

- **T-030.2** — первый push профилей root.
- **T-030.4** — аудит WS2 + сравнение.
- **SMART `/dev/da2`**.
- **zrepl-миграция** — завершить.
- **T-004** — `source_required`.