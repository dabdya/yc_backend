Обновление версии статического фронта запускается с помощью скрипта ```update_version.sh version [bucket-name]```

Для работы необходима утилита ```s3cmd```, ее можно установить по команде ```sudo apt install s3cmd``` и сконфигурировать командой ```s3cmd --configure```, а именно: 

> В интерактивном режиме ввести ```Access Key``` и ```Secret Key``` (остальные параметры можно оставить по умолчанию). Ключи доступа можно сгенерировать на [странице](https://console.cloud.yandex.ru/folders/b1g33gjkc3vp2r4jcp4k/service-account/ajedfl2hvk4b3o1mfk4o), нажав на кнопку создать новый ключ. 