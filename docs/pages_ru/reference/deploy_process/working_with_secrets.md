---
title: Работа с секретами
sidebar: documentation
permalink: ru/documentation/reference/deploy_process/working_with_secrets.html
ref: documentation_reference_deploy_process_working_with_secrets
author: Alexey Igrychev <alexey.igrychev@flant.com>
---

Для хранения в репозитории паролей, файлов сертификатов и т.п., рекомендуется использовать подсистему работы с секретами Werf.

Идея заключается в том, что конфиденциальные данные должны храниться в репозитории вместе с приложением, и должны оставаться независимыми от какого-либо конкретного сервера.

## Ключ шифрования

Для шифрования и дешифрования данных необходим ключ шифрования. Есть два места откуда Werf может прочитать этот ключ:
* из переменной окружения `WERF_SECRET_KEY`
* из специального файла `.werf_secret_key`, находящегося в корневой папке проекта
* из файла `~/.werf/global_secret_key` (глобальный ключ)

> Ключ шифрования должен иметь **шестнадцатеричный дамп** длиной 16, 24, или 32 байта для выбора соответственно алгоритмов AES-128, AES-192, или AES-256. Команда [werf helm secret generate-secret-key]({{ site.baseurl }}/documentation/cli/management/helm/secret/generate_secret_key.html) возвращает ключ шифрования, подходящий для использования алгоритма AES-128.

Вы можете быстро сгенерировать ключ, используя команду [werf helm secret generate-secret-key]({{ site.baseurl }}/documentation/cli/management/helm/secret/generate_secret_key.html).

### Работа с переменной окружения WERF_SECRET_KEY

Если при запуске Werf доступна переменная окружения WERF_SECRET_KEY, то Werf может использовать ключ шифрования из нее.

При работе локально, вы можете объявить ее с консоли. При работе с GitLab CI используйте [CI/CD Variables](https://docs.gitlab.com/ee/ci/variables/#variables) – они видны только участникам проекта с ролью master и не видны обычным разработчикам.

### Работа с файлом .werf_secret_key

Использование файла `.werf_secret_key` является более безопасным и удобным, т.к.:
* пользователям или инженерам, ответственным за запуск/релиз приложения не требуется добавлять ключ шифрования при каждом запуске;
* значения секрета из файла не будет отражено в истории команд консоли, например в файле `~/.bash_history`.

> **Внимание! Не сохраняйте файл `.werf_secret_key` в git-репозитории. Если вы это сделаете, то потеряете весь смысл шифрования, т.к. любой пользователь с доступом к git-репозиторию, сможет получить ключ шифрования. Поэтому, файл `.werf_secret_key` должен находиться  в исключениях, т.е. в файле `.gitignore`!**

## Шифрация секретных переменных

Файлы с секретными переменными предназначены для хранения секретных данных в виде — `ключ: секрет`. **По умолчанию** Werf использует для этого файл `.helm/secret-values.yaml`, но пользователь может указать любое число подобных файлов с помощью параметров запуска.

Файл с секретными переменными может выглядеть следующим образом:
```yaml
mysql:
  host: 10005968c24e593b9821eadd5ea1801eb6c9535bd2ba0f9bcfbcd647fddede9da0bf6e13de83eb80ebe3cad4
  user: 100016edd63bb1523366dc5fd971a23edae3e59885153ecb5ed89c3d31150349a4ff786760c886e5c0293990
  password: 10000ef541683fab215132687a63074796b3892d68000a33a4a3ddc673c3f4de81990ca654fca0130f17
  db: 1000db50be293432129acb741de54209a33bf479ae2e0f53462b5053c30da7584e31a589f5206cfa4a8e249d20
```

Для управления файлами с секретными переменными используйте следующие команды:
- [werf helm secret values edit]({{ site.baseurl }}/documentation/cli/management/helm/secret/values/edit.html)
- [werf helm secret values encrypt]({{ site.baseurl }}/documentation/cli/management/helm/secret/values/encrypt.html)
- [werf helm secret values decrypt]({{ site.baseurl }}/documentation/cli/management/helm/secret/values/decrypt.html)

### Использование в шаблонах чарта

Значения секретных переменных расшифровываются в процессе деплоя и используются в Helm в качестве [дополнительных значений](https://github.com/kubernetes/helm/blob/master/docs/chart_template_guide/values_files.md). Таким образом, использование секретов не отличается от использования данных в обычном случае:

{% raw %}
```yaml
...
env:
- name: MYSQL_USER
  value: {{ .Values.mysql.user }}
- name: MYSQL_PASSWORD
  value: {{ .Values.mysql.password }}
```
{% endraw %}

## Шифрование файлов-секретов

Помимо использования секретов в переменных, в шаблонах также используются файлы, которые нельзя хранить незашифрованными в репозитории. Для размещения таких файлов выделен каталог `.helm/secret`, в котором должны храниться файлы с зашифрованным содержимым.

Чтобы использовать файлы содержащие секретную информацию в шаблонах Helm, вы должны сохранить их в соответствующем виде в каталоге `.helm/secret`.

Для управления файлами, содержащими секретную информацию, используйте следующие команды:
- [werf helm secret file edit]({{ site.baseurl }}/documentation/cli/management/helm/secret/file/edit.html)
- [werf helm secret file encrypt]({{ site.baseurl }}/documentation/cli/management/helm/secret/file/encrypt.html)
- [werf helm secret file decrypt]({{ site.baseurl }}/documentation/cli/management/helm/secret/file/decrypt.html)

### Использование в шаблонах чарта

Функция `werf_secret_file` позволяет использовать расшифрованное содержимое секретного файла в шаблоне. Обязательный аргумент функции пусть к секретному файлу, относительно папки `.helm/secret`.

Пример использования секрета `.helm/backend-saml/tls.key` в шаблоне:

{% raw %}
```yaml
...
data:
  tls.key: {{ werf_secret_file "backend-saml/tls.key" | b64enc }}
```
{% endraw %}

## Смена ключа шифрования

Для перегенерации всех секретных переменных и файлов содержащих секреты с новым ключом шифрования используется команда [werf helm secret rotate-secret-key]({{ site.baseurl }}/documentation/cli/management/helm/secret/rotate_secret_key.html).
