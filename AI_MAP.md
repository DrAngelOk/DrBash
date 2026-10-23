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

### Def/ — списки (8 файлов)

dns.list, esxi.list, scriptpaths.list, server.list, users.cfg,
restic_clients.list, **sync.freebsd.list** (T-030), **sync.redos.list** (T-030).

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

### Func/04_FW/ — брандмауэр и SELinux (3 файла) — ГОТОВО

| Файл | Статус |

| 41_funcFirewall.sh | ГОТОВО |
| 42_funcFirewall2.sh | ГОТОВО |
| 44_funcSeLinux.sh | ГОТОВО |

> **[FIX] T-030:** в AI_MAP ранее значилось `Func/04_Security/`. Фактическая папка — `Func/04_FW/`. Исправлено.

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

| 61_funcLogs.sh | ГОТОВО (2026-10-19: починен сломанный heredoc 6.1.3/6.1.4) |
| 62_funcTelegram.sh | ГОТОВО |
| 66_funcJournalctl.sh | ГОТОВО |

### Func/07_Mon/ — мониторинг (9 файлов) — ГОТОВО (9/9)

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

> **[FIX] T-030:** в AI_MAP ранее значилось `Func/07_Monitoring/`. Фактическая папка — `Func/07_Mon/`. Исправлено.

### Func/08_VM/ — гипервизоры (2 файла) — ГОТОВО (2/2)

| Файл | Статус |

| 81_funcEsxi.sh | ГОТОВО (2026-10-23: `esxiCopyScripts` 8.1.12, `esxiDiskAttachPhysicalRDM` 8.1.3 через SSH) |
| 82_funcVmTools.sh | ГОТОВО |

> **[FIX] T-030:** в AI_MAP ранее значилось `Func/08_ESXi/`. Фактическая папка — `Func/08_VM/`. Исправлено.

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

### Func/11_Check/ — мониторинг и проверки — ГОТОВО

| Файл | Функции | Статус |

| 111_funcCheckDisk.sh | 11.1.1–11.1.8 | ГОТОВО |
| 112_funcCheckRAM.sh | 11.2.1–11.2.6 | ГОТОВО |
| 113_funcCheckBSD.sh | 11.3.1–11.3.8 | ГОТОВО |
| 114_funcPostMortem.sh | 11.4.1, 11.4.2 | ГОТОВО (2026-10-19: `logsMsg "ERR"` → `"ERROR"`, `MenuRegister "11"`) |

> **[FIX] T-030:** имена файлов в карте не совпадали с фактическими. Ранее значилось `11_funcMonZfs.sh`, `11_funcMonMemory.sh`, `11_funcMonWebStack.sh`. Фактические — `111_funcCheckDisk.sh`, `112_funcCheckRAM.sh`, `113_funcCheckBSD.sh`. Исправлено.

### Func/12_Deploy/ — развёртывание и синхронизация (НОВЫЙ, T-030)

| Файл | ID | Статус |

| 120_funcSyncCommon.sh | — (служебный) | ГОТОВО |
| 121_funcSyncAudit.sh | 12.1.1 | ГОТОВО (аудит WSW: 39 путей, 28 есть; WS2 `diff=same`) |
| 122_funcSyncPull.sh | 12.1.2 | НЕ ПРОВЕРЕНО (аргументы в любом порядке) |
| 123_funcSyncPush.sh | 12.1.3 | ГОТОВО (push профилей root) |

### Func/Scripts/ — утилиты (2 файла)

| Файл | Статус |

| funcCheck.sh | ГОТОВО (2026-10-19: `warn` → `logsMsg "WARN"`) |
| funcUtil.sh | ГОТОВО |

`funcUtil.sh` содержит `createDir`, `source_required`, `installDrbashWrapper`, fallback `logsMsg`.

### Func/Watch/ — наблюдение — ЗАКРЫТ (T-018)

5 «сырых» файлов поглощены модулем 11.

## 🔗 Связи

- Все модули регистрируются через MenuRegister.
- Диспетчер: MenuStart.
- Двухплатформенность: ${OSType}.
- Единая точка входа: `startMain.sh <ID>`.
- Единый логгер — `logsMsg`.
- **HTTP-проверка:** `_webstack_http_check`.
- **zrepl sink:** путь = `root_fs/${client_identity}/${source_path}`.
- **T-030:** эталон конфигов — `DirScriptsSampleNet` (`/mnt/scripts/Sample`), манифест — `Def/sync.<ostype>.list`.
- **ESXi:** управление по SSH (`/root/.ssh/id_rsa_esxi`), `sshClient: true` для исходящих.

## 📊 Статус разбора T-001

**T-001 — 100% (ЗАКРЫТА).**

Итого: ~60 файлов разобрано. T-001 — 100%.

## 📌 Актуально

**T-030 (в работе, ~50%):**
- Архитектура: 5 решений (источник — GitHub, роли — переключатели, pull+push, эталон побеждает, `sync.list` + `Sample/`).
- Создан модуль `12_Deploy` (120 common, 121 audit, 122 pull, 123 push).
- `Def/sync.freebsd.list` (46 путей), `Def/sync.redos.list` (24 пути).
- Аудит WSW: 28 из 39 путей существуют. Push профилей root → `Sample/`. Аудит WS2: `diff=same`.
- Осталось: перевести профили root в `ready`, тесты pull/push, роли, развёртывание нового сервера.

**Закрыто в сессии 2026-10-23:**
- zrepl-миграция завершена (`wsw/zroot`, `ws2/*`, holds, `zrepl.yml`).
- GSW: `/opt/nextcloud-gsw/`, compose + nginx.conf, контейнеры пересозданы.
- ESXi: `sshClient` на 12/13, ключи RSA, `esxiCopyScripts`, `esxiDiskAttachPhysicalRDM` (RDM через SSH).
- Конфиги: `loader.conf`, `sysctl.conf`, `periodic.conf`, `rc.conf`, `crontab`, `syslog.conf`, `fstab`, `motd.template`, `ntp.conf`.
- T-030: `sync.freebsd.list` (46), push профилей root, аудит WS2, аргументы pull/push, вывод аудита.
- `AI_FUNCTIONS.tsv` — индекс функций (15 модулей).

**Закрыто в сессии 2026-10-19:**
- Проверка разбивки дампа (5 частей).
- `merge_project.ps1` — 2 бага.
- `61_funcLogs.sh`, `funcCheck.sh`, `114_funcPostMortem.sh`.
- T-030 архитектура + `sync.*.list` + модуль `12_Deploy` + `ConfPaths.sh`.

**Осталось (кроме T-030):**
- ESXi / RDM — блок имени из `t10.ATA...`.
- GSW-диск (второй vmdk).
- SMART `/dev/da2`.
- T-004 (`source_required`).
- `server.list` под роли, скрипт вкл/выкл ролей, `Def/disks.list`, `rsInitRepository`.
- T-033 (crontab), T-034 (dma SMARTHOST).