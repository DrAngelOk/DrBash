# AI MAP — DrAngelOk/DrBash

Карта проекта: структура, модули, связи, статус разбора.

## 🗺 Точка входа

startMain.sh — единственная точка входа, в корне проекта.

Цепочка запуска:

    startMain.sh
      → Conf/ConfAll.sh
        → Conf/ConfManual.sh
        → Conf/ConfSets.sh
        → Conf/ConfServers.sh
        → Conf/ConfPaths.sh
        → Conf/ConfResticClients.sh
        → Func/Scripts/funcCheck.sh
        → Conf/ConfSources.sh
          → Func/Menu/funcMenu.sh
          → Func/**/*.sh
          → Modules/**/*.sh
          → Test/**/*.sh

## 📁 Структура

### Conf/ — конфигурация (7 файлов)

| Файл | Назначение |

| ConfAll.sh | Главный диспетчер |
| ConfManual.sh | Ручные настройки |
| ConfPaths.sh | Карта путей |
| ConfServers.sh | INI-парсер server.list |
| ConfSets.sh | Системные настройки, детекция ОС |
| ConfSources.sh | Автоподключение модулей |
| ConfResticClients.sh | INI-парсер restic_clients.list |

### Def/ — списки (6 файлов)

dns.list, esxi.list, scriptpaths.list, server.list, users.cfg,
restic_clients.list.

### Func/01_Config/ — конфигурация (9 файлов) — ГОТОВО (9/9)

| Файл | Статус |

| 11_funcNet.sh | ГОТОВО |
| 12_funcUsers.sh | ГОТОВО |
| 13_funcSsh.sh | ГОТОВО |
| 14_funcRsync.sh | ГОТОВО |
| 15_funcSslRsa.sh | ГОТОВО |
| 16_funcCertbot.sh | ГОТОВО |
| 17_funcDocker.sh | ГОТОВО |
| 18_funcPhp.sh | ГОТОВО |
| 19_funcCyrillic.sh | ГОТОВО |

### Func/02_Backup/ — бэкапы (8 файлов) — ГОТОВО (8/8)

| Файл | Статус |

| 21_funcBackupPc.sh | ГОТОВО |
| 22_funcRestic.sh | ГОТОВО |
| 23_funcBackrest.sh | ГОТОВО |
| 24_funcZrepl.sh | ГОТОВО |
| 25_funcSyncMigrate.sh | ГОТОВО |
| 26_funcSyncArc.sh | ГОТОВО |
| 27_funcSyncRsync.sh | ГОТОВО |
| 28_funcSyncZFS.sh | ГОТОВО |

### Func/03_Servers/ — серверы (31–39) — ГОТОВО

| Файл | Статус |

| 31_funcWeb.sh | ГОТОВО |
| 32_funcSql.sh | ГОТОВО |
| 33_funcOpenVpn.sh | ГОТОВО |
| 35_funcMemcached.sh | ГОТОВО |
| 36_funcSamba.sh | ГОТОВО |
| 37_funcNfs.sh | ГОТОВО |
| 38_funcNextcloud.sh | ГОТОВО |
| 39_funcDns.sh | ГОТОВО |

### Func/04_Security/ — безопасность (41–44) — ГОТОВО

| Файл | Статус |

| 41_funcFirewall.sh | ГОТОВО |
| 42_funcFirewall2.sh | ГОТОВО |
| 44_funcSeLinux.sh | ГОТОВО |

### Func/05_Disks/ — диски (6 файлов) — ГОТОВО (6/6)

| Файл | Статус |

| 51_funcZFS.sh | ГОТОВО |
| 52_funcZpool.sh | ГОТОВО |
| 53_funcGpart.sh | ГОТОВО |
| 54_funcFiles.sh | ГОТОВО |
| 57_funcDiskMount.sh | ГОТОВО |
| 58_funcDiskClone.sh | ГОТОВО |

### Func/06_Logs/ — логи (3 файла) — ГОТОВО (3/3)

| Файл | Статус |

| 61_funcLogs.sh | ГОТОВО |
| 62_funcTelegram.sh | ГОТОВО |
| 66_funcJournalctl.sh | ГОТОВО |

### Func/07_Monitoring/ — мониторинг (9 файлов) — ГОТОВО (9/9)

| Файл | Статус |

| 71_funcMon.sh | ГОТОВО |
| 72_funcMonAtop.sh | ГОТОВО |
| 73_funcMonMytop.sh | ГОТОВО |
| 74_funcMonApache.sh | ГОТОВО |
| 75_funcMonApachetop.sh | ГОТОВО |
| 76_funcMonGoaccess.sh | ГОТОВО |
| 77_funcMonIotop.sh | ГОТОВО |
| 78_funcMonNet.sh | ГОТОВО |
| 79_funcMonIftop.sh | ГОТОВО |

### Func/08_ESXi/ — гипервизоры (2 файла) — ГОТОВО (2/2)

| Файл | Статус |

| 81_funcEsxi.sh | ГОТОВО |
| 82_funcVmTools.sh | ГОТОВО |

### Func/09_System/ — система (4 файла) — ГОТОВО (4/4)

| Файл | Статус |

| 91_funcPreInstall.sh | ГОТОВО |
| 92_funcSystem.sh | ГОТОВО |
| 93_funcInstall.sh | ГОТОВО |
| 99_funcUpdate.sh | ГОТОВО |

### Func/10_Sites/ — сайты (2 файла) — ГОТОВО (2/2)

| Файл | Статус |

| 101_funcWordPress.sh | ГОТОВО |
| 102_funcSiteMonit.sh | ГОТОВО |

### Func/11_Check/ — мониторинг — ГОТОВО

| Файл | Функции | Статус |

| 11_funcMonZfs.sh | 11.1.1–11.1.8 | ГОТОВО |
| 11_funcMonMemory.sh | 11.2.1–11.2.6 | ГОТОВО |
| 11_funcMonWebStack.sh | 11.3.1–11.3.8 | ГОТОВО |
| 113_funcCheckBSD.sh | 11.4.1 | ГОТОВО |
| 114_funcPostMortem.sh | 11.4.1, 11.4.2 | ГОТОВО |

### Func/Scripts/ — утилиты (2 файла)

funcCheck.sh, funcUtil.sh (`createDir`, `source_required`,
`installDrbashWrapper`, fallback `logsMsg`).

### Func/Watch/ — наблюдение — ЗАКРЫТ (T-018)

5 «сырых» файлов поглощены модулем 11:
- `watchApache.sh` → `monApache` (11.3.2).
- `watchMysql.sh` → `monMysql` (11.3.3).
- `watchOpenvpn.sh` → `monOpenvpn` (11.3.4).
- `watchWSW.sh` → `monMemory` + `monWebStackSummary` (11.2.x, 11.3.5).
- `wsw-postmortem.sh` → `monPostmortem` (11.4.1) + `pmAnalyze` (11.4.2).
Добавлена `monSystemLoad` (11.2.6).

## 🔗 Связи

- Все модули регистрируются через MenuRegister.
- Диспетчер: MenuStart.
- Двухплатформенность: ${OSType}.
- Единая точка входа: `startMain.sh <ID>`.
- Единый логгер — `logsMsg`.
- **HTTP-проверка:** `_webstack_http_check`.
- **zrepl sink:** путь = `root_fs/${client_identity}/${source_path}`.

## 📊 Статус разбора T-001

**T-001 — 100% (ЗАКРЫТА).**

| Модуль | Разобрано | Статус |

| startMain.sh | 1/1 | ГОТОВО |
| Conf/ | 7/7 | ГОТОВО |
| Func/Scripts | 2/2 | ГОТОВО |
| Func/Menu | 1/1 | ГОТОВО |
| Func/01_Config | 9/9 | ГОТОВО |
| Func/02_Backup | 8/8 | ГОТОВО |
| Func/03_Servers | 8/8 | ГОТОВО |
| Func/04_Security | 3/3 | ГОТОВО |
| Func/05_Disks | 6/6 | ГОТОВО |
| Func/06_Logs | 3/3 | ГОТОВО |
| Func/07_Monitoring | 9/9 | ГОТОВО |
| Func/08_ESXi | 2/2 | ГОТОВО |
| Func/09_System | 4/4 | ГОТОВО |
| Func/10_Sites | 2/2 | ГОТОВО |
| Func/11_Check | 11.1.x–11.4.2 | ГОТОВО |
| Func/Watch | 5/5 | ЗАКРЫТ (T-018) |

Итого: ~60 файлов разобрано. T-001 — 100%.

## 📌 Актуально

**Закрыто в сессии 2026-10-18:**
- T-001 (100%), T-018, T-003, T-021.
- Сканеры, dma, картинки WordPress, WS2 SSH, T-015, T-017,
  T-005, T-020, monPhpFpm, monReverseProxyHeaders/Fix.
- `merge_project.ps1` — нарезка на части ~250 КБ в
  `Win\MergeProjectOut\`.

**Осталось:**
- zrepl-миграция (`wsw`, `@migrate`, destroy, конфиг WS2).
- SMART `/dev/da2`.
- T-004 (`source_required`).
- `server.list` под роли, скрипт вкл/выкл ролей, `Def/disks.list`,
  `rsInitRepository`.