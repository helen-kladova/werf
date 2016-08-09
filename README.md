# dapp [![Gem Version](https://badge.fury.io/rb/dapp.svg)](https://badge.fury.io/rb/dapp) [![Build Status](https://travis-ci.org/flant/dapp.svg)](https://travis-ci.org/flant/dapp) [![Code Climate](https://codeclimate.com/github/flant/dapp/badges/gpa.svg)](https://codeclimate.com/github/flant/dapp) [![Test Coverage](https://codeclimate.com/github/flant/dapp/badges/coverage.svg)](https://codeclimate.com/github/flant/dapp/coverage)

## Reference

### Dappfile

#### Основное
*TODO*

#### Артифакты
*TODO*

#### Docker
*TODO*

#### Shell
*TODO*

#### Chef

##### chef.module \<mod\>[, \<mod\>, \<mod\> ...]
Включить переданные модули для chef builder в данном контексте.

* Для каждого переданного модуля может существовать по одному рецепту на каждый из stage.
* Файл рецепта для \<stage\>: recipes/\<stage\>.rb
* Рецепт модуля будет добавлен в runlist для данного stage если существует файл рецепта.
* Порядок вызова рецептов модулей в runlist совпадает порядком их описания в конфиге.
* При сборке stage, для каждого из включенных модулей, при наличии файла рецепта, будут скопированы:
  * files/\<stage\>/ -> files/default/
  * templates/\<stage\>/ -> templates/default/
  * metadata.json

##### chef.skip_module \<mod\>[, \<mod\>, \<mod\> ...]
Выключить переданные модули для chef builder в данном контексте.

##### chef.reset_modules
Выключить все модули для chef builder в данном контексте.

##### chef.recipe \<recipe\>[, \<recipe\>, \<recipe\> ...]
Включить переданные рецепты из проекта для chef builder в данном контексте.

* Для каждого преданного рецепта может существовать файл рецепта в проекте на каждый из stage.
* Файл рецепта для \<stage\>: recipes/\<stage\>/\<recipe\>.rb
* Рецепт будет добавлен в runlist для данного stage если существует файл рецепта.
* Порядок вызова рецептов в runlist совпадает порядком их описания в конфиге.
* При сборке stage, при наличии хотя бы одного файла рецепта из включенных, будут скопированы:
  * files/\<stage\> -> files/default/
  * templates/\<stage\>/ -> templates/default/
  * metadata.json

##### chef.remove_recipe \<recipe\>[, \<recipe\>, \<recipe\> ...]
Выключить переданные рецепты из проекта для chef builder в данном контексте.

##### chef.reset_recipes
Выключить все рецепты из проекта для chef builder в данном контексте.

##### chef.reset_all
Выключить все рецепты из проекта и все модули для chef builder в данном контексте.

##### Примеры
* [Dappfile](doc/example/Dappfile.chef.1)

### Команды

#### dapp build
Собрать приложения, удовлетворяющие хотя бы одному из **PATTERN**-ов (по умолчанию *).

Синопсис:
`dapp build [options] [PATTERN ...]`

##### Опции среды сборки

###### --dir PATH
Определяет директорию, которая используется при поиске одного или нескольких **Dappfile**.
По умолчанию поиск ведётся в текущей папке пользователя.
###### --metadata-dir PATH
Переопределяет директорию хранения временных файлов, которые могут использоваться между сборками.
###### --tmp-dir-prefix PREFIX
Переопределяет префикс временной директории, файлы которой используются только во время сборки.

##### Опции логирования

###### --dry-run
Позволяет запустить сборщик в холостую и посмотреть процесс сборки.
###### --verbose
Подробный вывод.
###### --color MODE
Отвечает за регулирование цвета при выводе в терминал.
Существует несколько режимов (**MODE**): **on**, **of**, **auto**.
По умолчанию используется **auto**, который окрашивает вывод, если вывод производится непосредственно в терминал.
###### --time
Добавляет время каждому событию лога.

##### Опции интроспекции
Позволяют поработать с образом на определённом этапе сборки.

###### --introspect-stage STAGE
После успешного прохождения стадии **STAGE**.
###### --introspect-before-error
Перед выполением команд несобравшейся стадии.
###### --introspect-error
После завершения команд стадии с ошибкой.

#### dapp push
Выкатить собранное приложение с именем **REPO**.

Синопсис:
`dapp push [options] [PATTERN...] REPO`

##### --force
Позволяет перезаписывать существующие образы.

##### Опции тегирования
Отвечают за тег(и), с которыми выкатывается приложение.
Могут быть использованы совместно и по несколько раз.
В случае отсутствия, используется тег **latest**.

###### --tag TAG
Добавляет произвольный тег **TAG**.
###### --tag-branch
Добавляет тег с именем ветки сборки. 
###### --tag-commit
Добавляет тег с комитом сборки. 
###### --tag-build-id
Добавляет тег с идентификатором сборки (CI).
###### --tag-ci
Добавляет теги, взятые из переменных окружения CI систем.

#### dapp smartpush
Выкатить каждое собранное приложение с именем **REPOPREFIX**/имя приложения.

Синопсис:
`dapp smartpush [options] [PATTERN ...] REPOPREFIX`

Опции такие же как у **dapp push**.

#### dapp list
Вывести список приложений.

Синопсис:
`dapp list [options] [PATTERN ...]`

#### dapp run
Запустить собранное приложение с докерными аргументами **DOCKER ARGS**.

Синопсис:
`dapp run [options] [PATTERN...] [DOCKER ARGS]`

##### [DOCKER ARGS]
Может содержать докерные опции и/или команду.
Перед командой необходимо использовать группу символов ' -- '.

###### Примеры использования
```
dapp run -ti --rm
dapp run -ti --rm -- bash -ec true
dapp run -- bash -ec true
```

#### dapp stages
Группа команд для удаления образов из docker-a.

##### dapp stages flush
Удаляет все тегированные образы приложений.

Синопсис:
`dapp stages flush [options] [PATTERN...]`

##### dapp stages cleanup
Удаляет все нетегированные образы приложений.

Синопсис:
`dapp stages cleanup [options] [PATTERN...]`

#### dapp metadata flush
Удаляет временные папки приложений.

Синопсис:
`dapp metadata flush [options] [PATTERN...]`

## Architecture

### Стадии
*TODO*

### Хранение данных

#### Кэш стадий
*TODO*

#### Временное
*TODO*

#### Метаданные
*TODO*

#### Кэш сборки
*TODO*
