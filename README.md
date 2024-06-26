# Скрипт авто. рег. операции

Данный скрипт предназначен для выполнения рутинных задач по ежемесячному обслуживанию в автоматическом режиме

**[Обратная связь по скрипту](https://docs.google.com/spreadsheets/d/1nqhxDo37lmxKHH_qHu296oqsVHGzTcksOJpV6ko9B0w/edit?pli=1#gid=0)**

**Документация лежит на консе X:\Документы\Документация хостинг\RegOps**


## Описание скрипта 
1. Проверяет службу 1C:Enterprise 8.3 Server Agent (x86-64) и если она есть, то происходит очистка 
содержимая в папках snccntx* (Удаление сеансовых данных сервера)
2. Добавляет задание в планировщик на запуска update_windows_after_reboot.bat после перезагрузки
3. Очистка временных файлов у пользователей
4. Проверка IIS службы и если есть, то происходит чистка C:\inetpub\logs файлов более 7-ми дней
5. Проверка антивирусом Kaspersky - чтобы тонко настроить проверку, можно воспользоваться [инструкцией](https://support.kaspersky.ru/kvrt2020/howto/15679)
6. Проверка\установка обновлений windows
7. Автоматическая перезагрузка сервера
8. После автоматической перезагрузки если успешно прошел 2 пункт, то должна пройтись еще раз проверка и установка обновлений
9. Как выполнился скрипт, должно появиться 4 файла с логами: 
* "C:\scripts\RegOps\Log_data\RegOps.log" - описание о происходящих событиях
* "C:\scripts\RegOps\Log_data\WindowsUpdate_Temp.log" - установленные апдейты
* "C:\scripts\RegOps\Log_data\WindowsUpdate_Temp_AfterReboot.log" - установленные апдейты после перезагрузки
* "C:\scripts\RegOps\KVRT\сегодняшняя_дата\Reports" - результаты проверка антивируса
10. Отправка отчета на почту архив с логами - если правильно сделан файл C:\scripts\RegOps\creds.enc


## Запуск скрипта

1. Скачиваем из github архив с файлами
2. Распаковываем файлы в C:\Scripts (Это путь очень важен)
3. Выполняем файл "C:\Scripts\add_creds.ps1" с помощью Powershell - чтобы сгенерировать "C:\scripts\RegOps\creds.enc" для отправки на почту
4. Вводим данные которые запрашивает  
- Пароль от regops@service.efsol.ru - находится "X:\Документы\Документация хостинг\RegOps\Учетная запись от почты regops.txt"
- Почтовый ящик куда требуется отправлять отчет - инженера
5. Выполняем файл "C:\Scripts\reg_ops_win_v2.5.ps1" с помощью PowerShell

## Версии скрипта
**V2.5**
* Добавлен отчет после выполнения скрипта
* Изменение папки с логами

**V2.4**
* Добавлена проверка службы 1С Сервера и если есть, то находит где находится папка srvinfo и чистит сеансовые данные сервера 

**V2.3**
* Решение проблемы связанные с очисткой IIS логов - так же проверяется IIS служба
* Переделана перезагрузка сервера на автоматическую

**V2.2** 
* Решение проблемы с применением shutdown, теперь перезагрузка через Restart-Computer
* Решение проблемы связанная с чисткой временных файлов у пользователей

**V2.1**
* Проверка службы обновлений, если нет, то включает
* Проверка установленных компонентов ps windows update, если нету, то ставит, если есть то идем дальше
* Проверка обновлений и установка
* Перезагрузка после установленных обновлений
* Описание логов в отдельном файле (установленные обновления и этапы)
