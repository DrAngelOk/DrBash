
AI MAP — DrAngelOk/DrBash
Карта проекта: структура, модули, связи, статус разбора.
Читается перед разбором кода (T-001).

🗺 Точка входа
startMain.sh — в корне проекта, НЕ в дампе (в scriptpaths.list нет корня).

Цепочка запуска:

text
startMain.sh
  → Conf/ConfAll.sh
    → Conf/ConfManual.sh   (ручные настройки: имена, пароли, флаги)
    → Conf/ConfSets.sh     (детекция ОС, дата)
    → Conf/ConfServers.sh  (парсер server.list)
    → Conf/ConfPaths.sh    (карта путей)
    → Func/Scripts/funcCheck.sh  (создание папок)
    → Conf/ConfSources.sh  (автоподключение модулей)
      → Func/Menu/funcMenu.sh  (ядро меню)
      → Func/**/*.sh           (все модули)
📁 Структура
Conf/ — конфигурация (6 файлов)
Файл	Назначение
ConfAll.sh	Главный управляющий диспетчер
ConfManual.sh	Ручные настройки: имена, пароли, флаги
ConfPaths.sh	Карта путей и точек монтирования
ConfServers.sh	INI-парсер server.list
ConfSets.sh	Системные настройки, детекция ОС
ConfSources.sh	Автоподключение модулей
Def/ — списки (5 файлов)
Файл	Назначение
dns.list	Домены
esxi.list	Хосты ESXi, датасторы
scriptpaths.list	Манифест подпапок для дампа
server.list	Параметры серверов (INI)
users.cfg	Пользователи (CSV)
Func/01_Config/ — конфигурация (9 файлов)
Файл	Назначение
11_funcNet.sh	Сеть: hostname, IP, шлюз
12_funcUsers.sh	Пользователи, sudo, безопасность
13_funcSsh.sh	SSH
14_funcRsync.sh	Rsync
15_funcSslRsa.sh	SSL/RSA
16_funcCertbot.sh	Certbot
17_funcDocker.sh	Docker
18_funcPhp.sh	PHP
19_funcCyrillic.sh	Кириллица
Func/02_Backup/ — бэкапы (8 файлов)
21_funcBackupPc.sh, 22_funcRestic.sh, 23_funcBackrest.sh, 24_funcZrepl.sh, 25_funcSyncMigrate.sh, 26_funcSyncArc.sh, 27_funcSyncRsync.sh, 28_funcSyncZFS.sh.

Func/03_Servers/ — серверы (9 файлов)
31_funcWeb.sh, 32_funcSql.sh, 33_funcOpenVpn.sh, 35_funcMemcached.sh, 36_funcSamba.sh, 37_funcNfs.sh, 38_funcNextcloud.sh, 39_funcDns.sh.

Func/04_FW/ — файрвол (3 файла)
41_funcFirewall.sh, 42_funcFirewall2.sh, 44_funcSeLinux.sh.

Func/05_Disks/ — диски (5 файлов)
51_funcZFS.sh, 52_funcZpool.sh, 53_funcGpart.sh, 54_funcFiles.sh, 58_funcDiskClone.sh.

Func/06_Logs/ — логи (3 файла)
61_funcLogs.sh, 62_funcTelegram.sh, 66_funcJournalctl.sh.

Func/07_Mon/ — мониторинг (9 файлов)
71_funcMon.sh, 72_funcMonAtop.sh, 73_funcMonMytop.sh, 74_funcMonApache.sh, 75_funcMonApachetop.sh, 76_funcMonGoaccess.sh, 77_funcMonIotop.sh, 78_funcMonNet.sh, 79_funcMonIftop.sh.

Func/08_VM/ — виртуализация (2 файла)
81_funcEsxi.sh, 82_funcVmTools.sh.

Func/09_System/ — система (4 файла)
91_funcPreInstall.sh, 92_funcSystem.sh, 93_funcInstall.sh, 99_funcUpdate.sh.

Func/10_Sites/ — сайты (2 файла)
101_funcWordPress.sh, 102_funcSiteMonit.sh.

Func/Menu/ — меню (1 файл)
funcMenu.sh — ядро интерфейса, MenuRegister, menuExecuteCLI.

Func/Scripts/ — утилиты (2 файла)
funcCheck.sh — создание папок, funcUtil.sh — source_required.

🔗 Связи
Все модули регистрируются через MenuRegister.

Диспетчер запуска: menuExecuteCLI в Func/Menu/funcMenu.sh.

Двухплатформенность: ${OSType} (RedOS / FreeBSD).

Модули пронумерованы: 01_Config … 10_Sites.

Файлы внутри модулей: NN_funcName.sh.

⚠️ Найденные проблемы (предварительно)
ConfSources.sh: local вне функции — строка local file_name=$(basename ...) внутри while на верхнем уровне. В Bash local работает только внутри функции. Баг.

7 файлов в CP1251 (битые кодировки):

Conf/ConfManual.sh

Def/esxi.list

Def/server.list

Def/users.cfg

Func/05_Disks/51_funcZFS.sh

Func/07_Mon/71_funcMon.sh

Func/Scripts/funcCheck.sh

startMain.sh не собирается дампом — в scriptpaths.list нет корня. Точку входа смотреть отдельно.

📊 Статус разбора T-001
Модуль	Файлов	Разобрано	Статус
startMain.sh	1	0	не начато
Conf/	6	0	не начато
Def/	5	0	не начато
Func/01_Config	9	0	не начато
Func/02_Backup	8	0	не начато
Func/03_Servers	9	0	не начато
Func/04_FW	3	0	не начато
Func/05_Disks	5	0	не начато
Func/06_Logs	3	0	не начато
Func/07_Mon	9	0	не начато
Func/08_VM	2	0	не начато
Func/09_System	4	0	не начато
Func/10_Sites	2	0	не начато
Func/Menu	1	0	не начато
Func/Scripts	2	0	не начато
Итого: 67 файлов, разобрано 0.