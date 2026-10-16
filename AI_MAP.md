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
|------|-----------|
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

### Func/01_Config/ — конфигурация (9 файлов)

| Файл | Статус |
|------|--------|
| 11_funcNet.sh | не начато |
| 12_funcUsers.sh | не начато |
| 13_funcSsh.sh | не начато |
| 14_funcRsync.sh | не начато |
| 15_funcSslRsa.sh | ГОТОВО |
| 16_funcCertbot.sh | ГОТОВО |
| 17_funcDocker.sh | ГОТОВО |
| 18_funcPhp.sh | не начато |
| 19_funcCyrillic.sh | не начато |

### Func/02_Backup/ — бэкапы (8 файлов)

| Файл | Статус |
|------|--------|
| 21_funcBackupPc.sh | не начато |
| 22_funcRestic.sh | ГОТОВО |
| 23_funcBackrest.sh | ГОТОВО |
| 24_funcZrepl.sh | ГОТОВО |
| 25_funcSyncMigrate.sh | не начато |
| 26_funcSyncArc.sh | не начато |
| 27_funcSyncRsync.sh | не начато |
| 28_funcSyncZFS.sh | не начато |

### Func/05_Disks/ — диски (6 файлов)

| Файл | Статус |
|------|-------|
| 51_funcZFS.sh | ГОТОВО |
| 52_funcZpool.sh | ГОТОВО |
| 53_funcGpart.sh | ГОТОВО |
| 54_funcFiles.sh | ГОТОВО |
| 57_funcDiskMount.sh | ГОТОВО |
| 58_funcDiskClone.sh | ГОТОВО |

### Func/06_Logs/ — логи (3 файла)

| Файл | Статус |
|------|-------|
| 61_funcLogs.sh | ГОТОВО |
| 62_* | не начато |
| 63_* | не начато |

### Func/09_System/ — система (4 файла)

| Файл | Статус |
|------|--------|
| 91_funcPreInstall.sh | не начато |
| 92_funcSystem.sh | ГОТОВО (9.2.1–9.2.8) |
| 93_funcInstall.sh | не начато |
| 99_funcUpdate.sh | не начато |

### Func/11_Check/ — мониторинг

| Файл | Функции | Статус |
|------|---------|--------|
| 11_funcMonZfs.sh | 11.1.1–11.1.8 | ГОТОВО |
| 11_funcMonMemory.sh | 11.2.1–11.2.5 | ГОТОВО |
| 11_funcMonWebStack.sh | 11.3.1–11.3.8 | ГОТОВО |
| 113_funcCheckBSD.sh | 11.4.1 | ГОТОВО |
| 114_funcPostMortem.sh | 11.4.1, 11.4.2 | ГОТОВО (15.10) |

### Func/Scripts/ — утилиты (2 файла)

funcCheck.sh, funcUtil.sh (`createDir`, `source_required`,
`installDrbashWrapper`, fallback `logsMsg`).

### Func/Watch/ — наблюдение (T-018, статус неизвестен)

Требуется ревизия: что внутри, что уже перенесено в 11_Check
(например, `watchMysql.sh` → `monMysql`).

## 🔗 Связи

- Все модули регистрируются через MenuRegister.
- Диспетчер: MenuStart.
- Двухплатформенность: ${OSType}.
- Единая точка входа: `startMain.sh <ID>`.
- Единый логгер — `logsMsg`.
- **HTTP-проверка:** `_webstack_http_check`.
- **zrepl sink:** путь = `root_fs/${client_identity}/${source_path}`.

## 📊 Статус разбора T-001

| Модуль | Разобрано | Статус |
|--------|-----------|--------|
| startMain.sh | 1/1 | готово |
| Conf/ | 7/7 | готово |
| Func/Scripts | 2/2 | готово |
| Func/Menu | 1/1 | готово |
| Func/05_Disks | 6/6 | ГОТОВО |
| Func/06_Logs | 1/3 | 61 готов |
| Func/09_System | 1/4 | 92 готов |
| Func/11_Check | 11.1.x–11.4.2 | ГОТОВО |
| Func/01_Config | 3/9 | частично |
| Func/02_Backup | 3/8 | 22, 23, 24 |
| Func/Watch | ? | требует ревизии |
| Остальные Func/ | 0 | не начато |

Итого: ~30 файлов разобрано.