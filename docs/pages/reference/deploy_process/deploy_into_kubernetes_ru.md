---
title: Deploy в Kubernetes
sidebar: documentation
permalink: ru/documentation/reference/deploy_process/deploy_into_kubernetes.html
ref: documentation_reference_deploy_process_deploy_into_kubernetes
lang: ru
author: Timofey Kirillov <timofey.kirillov@flant.com>
---

Werf дает совместимую альтернативу [Helm 2](https://helm.sh), но предлагает улучшенный процесс деплоя.

Для работы Kubernetes у Werf есть 2 основные команды: [deploy]({{ site.baseurl }}/documentation/cli/main/deploy.html) — для установки или обновления приложения в кластере, и [dismiss]({{ site.baseurl }}/documentation/cli/main/dismiss.html) — для удаления приложения из кластера.

В Werf есть нескольких настраиваемых режимов отслеживания развернутых ресурсов, с отслеживанием в том числе журналов и событий. Образы, собранные Werf легко интегрируются в [шаблоны](#шаблоны) helm-чартов. Werf может устанавливать аннотации и метки с произвольной информацией всем разворачиваемым в Kubernetes ресурсам проекта.

Конфигурация описывается в формате аналогичном фомату [Helm-чарта](#чарт).

## Чарт

Чарт — набор конфигурационных файлов описывающих приложение. Файлы чарта находятся в папке `.helm`, в корневой папке проекта:

```
.helm/
  templates/
    <name>.yaml
    <name>.tpl
  charts/
  secret/
  values.yaml
  secret-values.yaml
```

### Шаблоны

Шаблоны находятся в папке `.helm/templates`.

В этой папке находятся YAML-файлы `*.yaml`, каждый из который описывает один или несколько ресурсов Kubernetes, разделенных тремя дефисами `---`, например:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mydeploy
  labels:
    service: mydeploy
spec:
  selector:
    matchLabels:
      service: mydeploy
  template:
    metadata:
      labels:
        service: mydeploy
    spec:
      containers:
      - name: main
        image: ubuntu:18.04
        command: [ "/bin/bash", "-c", "while true; do date ; sleep 1 ; done" ]
---
apiVersion: v1
kind: ConfigMap
  metadata:
    name: mycm
  data:
    node.conf: |
      port 6379
      loglevel notice
```

Каждый YAML-файл предварительно обрабатывается как [Go-шаблон](https://golang.org/pkg/text/template/#hdr-Actions).

Использование Go-шаблонов дает следующие возможности:
 * генерирование разных спецификаций объекта Kubernetes в зависимости от какого-либо условия;
 * передача [данных](#данные) в шаблон зависящих от окружения;
 * выделение общих частей шаблона в блоки и их переиспользование в нескольких местах;
 * и т.д..

[Функции Sprig](https://masterminds.github.io/sprig/) и [дополнительные функции](https://docs.helm.sh/developing_charts/#chart-development-tips-and-tricks), такие как `include` и `required`, также могут быть использованы в шаблонах.

Пользователь также может размещать `*.tpl` файлы, которые не будут рендериться в обзект Kubernetes. Эти файлы могут быть использованы для хранения произвольных Go-шаблонов и выражений. Все шаблоны и выражения из `*.tpl` файлов доступны для использования в `*.yaml` файлах.

#### Интеграция с собранными образами

Чтобы использовать Docker-образы в шаблонах чарта, необходимо указать полное имя Docker-образа, включая Docker-репозиторий и Docker-тэг. Но как указать данные образа из файла конфигурации `werf.yaml` учитывая то, что полное имя Docker-образа зависит от выбранной стратегии тэгирования и указанного Docker-репозитория?

Второй вопрос, — как использовать параметр [`imagePullPolicy`](https://kubernetes.io/docs/concepts/containers/images/#updating-images) вместе с образом из  `werf.yaml`: указывать `imagePullPolicy: Always`? А как добиться скачивания образа только когда это действительно необходимо?

Для ответа на эти вопросы в Werf есть две функции: [`werf_container_image`](#werf_container_image) и [`werf_container_env`](#werf_container_env). Пользователь может использовать эти функции в шаблонах чарта для корректного и безопасносго указания образов описанных в файле конфигурации `werf.yaml`.

##### werf_container_image

Данная функция генерирует ключи `image` и `imagePullPolicy` со значениями, необходимыми для соответствующего контейнера пода.

Особенность функции в том, что значение `imagePullPolicy` формируется исходя из значения `.Values.global.werf.is_branch`. Если не используется тэг, то функция возвращает `imagePullPolicy: Always`, иначе (если используется тэг) — ключ `imagePullPolicy` не возвращается. В результате, образ будет всегда скачиваться если он был собран для git-ветки, т.к. у Docker-образа с тем-же именем мог измениться ID.

Функция может возвращать несколько строк, поэтому она должна использоваться совместно с конструкцией `indent`.

Логика генерации ключа `imagePullPolicy`:
* Значение `.Values.global.werf.is_branch=true` подразумевает, что развертывается образ для git-ветки, с расчетом на использование самого свежего образа.
  * В этом случае, образ с соответствующим тэгом должен быть принудительно скачан, даже если он уже есть в локальном хранилище Docker-образов. Это необходимо, чтобы получить самый "свежий" образ, соответствующий образу с таким Docker-тэгом.
  * В этом случае – `imagePullPolicy=Always`.
* Значение `.Values.global.werf.is_branch=false` подразумеваеи, что развертывается образ для git-тэга или конкретного git-коммита.
  * В этом случае, образ для соответствующего Docker-тэга можно не обновлять, если он уже находится в локальном хранилище Docker-образов.
  * В этом случае, `imagePullPolicy` не устанавливается, т.е. итоговое значение у объекта в кластере будет соответствовать значению по умолчанию — `imagePullPolicy=IfNotPresent`.

> Образы, протэгированные с использованием пользовательской стратегии тэгирования (`--tag-custom`) обрабатываются аналогично образам протэгированным стратегией тэгирования *git-branch* (`--tag-git-branch`).

Пример использования функции в случае нескольких описанных в файле конфигурации `werf.yaml` образов:
* `tuple <image-name> . | werf_container_image | indent <N-spaces>`

Пример использования функции в случае описанного в файле конфигурации `werf.yaml` безымянного образа:
* `tuple . | werf_container_image | indent <N-spaces>`
* `werf_container_image . | indent <N-spaces>` (дополнительный упрощенный формат использования)

##### werf_container_env

Позволяет упростить процесс релиза, в случае если образ остается неизменным. Возвращает блок с переменной окружения `DOCKER_IMAGE_ID` контейнера пода. Значение переменной будет установлено только если `.Values.global.werf.is_branch=true`, т.к. в этом случае Docker-образ для соответствующего имени и тэга может быть обновлен, а имя и тэг останутся неизменными. Значение переменной `DOCKER_IMAGE_ID` содержит новый ID Docker-образа, что вынуждает Kubernetes обновить объект.

Функция может возвращать несколько строк, поэтому она должна использоваться совместно с конструкцией `indent`.

> Образы, протэгированные с использованием пользовательской стратегии тэгирования (`--tag-custom`) обрабатываются аналогично образам протэгированным стратегией тэгирования *git-branch* (`--tag-git-branch`).

Пример использования функции в случае нескольких описанных в файле конфигурации `werf.yaml` образов:
* `tuple <image-name> . | werf_container_env | indent <N-spaces>`

Пример использования функции в случае описанного в файле конфигурации `werf.yaml` безымянного образа:
* `tuple . | werf_container_env | indent <N-spaces>`
* `werf_container_env . | indent <N-spaces>` (дополнительный упрощенный формат использования)

##### Примеры

Пример использования образа `backend`, описанного в `werf.yaml`:

{% raw %}
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  labels:
    service: backend
spec:
  selector:
    matchLabels:
      service: backend
  template:
    metadata:
      labels:
        service: backend
    spec:
      containers:
      - name: main
        command: [ ... ]
{{ tuple "backend" . | werf_container_image | indent 8 }}
        env:
{{ tuple "backend" . | werf_container_env | indent 8 }}
```
{% endraw %}

Пример использования безымянного образа, описанного в `werf.yaml`:

{% raw %}
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  labels:
    service: backend
spec:
  selector:
    matchLabels:
      service: backend
  template:
    metadata:
      labels:
        service: backend
    spec:
      containers:
      - name: main
        command: [ ... ]
{{ werf_container_image . | indent 8 }}
        env:
{{ werf_container_env . | indent 8 }}
```
{% endraw %}

#### Файлы секретов

Файлы секретов удобны для хранения непосредственно в репозитории проекта конфиденциальных данных, таких как сертификаты и закрытые ключи.

Файлы секретов размещаются в папке `.helm/secret`, где пользователь может создать произвольную структуру файлов. Читайте подробнее о том как шифровать файлы в соответствующей [статье]({{ site.baseurl }}/ru/documentation/reference/deploy_process/working_with_secrets.html#шифрование-файлов-секретов)

##### werf_secret_file

`werf_secret_file` — это функция, используемая в шаблонах чартов, предназначена для удобной работы с секретами, — она возвращает содержимое файла секрета.
Обычно она используется при формировании манифестов секретов в Kubernetes (`Kind: Secret`).
Функции в качестве аргумента необходимо передать путь к файлу относительно папки `.helm/secret`.

Пример использования расшифрованного содержимого файлов `.helm/secret/backend-saml/stage/tls.key` и `.helm/secret/backend-saml/stage/tls.crt` в шаблоне:

{% raw %}
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: myproject-backend-saml
type: kubernetes.io/tls
data:
  tls.crt: {{ werf_secret_file "backend-saml/stage/tls.crt" | b64enc }}
  tls.key: {{ werf_secret_file "backend-saml/stage/tls.key" | b64enc }}
```
{% endraw %}

Обратите внимание, что `backend-saml/stage/` — произвольная структура файлов, и пользователь может размещать все файлы в одной папке `.helm/secret` либо создавать структуру со своему усмотрению.

#### Встроенные шаблоны и параметры

{% raw %}
 * `{{ .Chart.Name }}` — возвращает имя проекта, указанное в `werf.yaml` (ключ `project`).
 * `{{ .Release.Name }}` — возвращает [имя релиза](#релиз).
 * `{{ .Files.Get }}` — функция для получения содержимого файла в шаблон, требует указания пути к файлу в качестве аргумента. Путь указыватеся относительно папки `.helm` (файлы вне папки `.helm` недоступны).
{% endraw %}

### Данные

Под данными понимается произвольная YAML-карта, заполненная парами ключ-значение или массивами, которые можно использовать в [шаблонах](#шаблоны).

Werf позволяет использовать следующие типы данных:

 * Обычные пользовательские данные
 * Пользовательские секреты
 * Сервисные данные

#### Обычные пользовательские данные

Для хранения обычных данных используйте файл чарта `.helm/values.yaml` (необязательно). Пример структуры:

```yaml
global:
  names:
  - alpha
  - beta
  - gamma
  mysql:
    staging:
      user: mysql-staging
    production:
      user: mysql-production
    _default:
      user: mysql-dev
      password: mysql-dev
```

Данные, размещенные внутри ключа `global`, будут доступны как в текущем чарте, так и всех [вложенных чартах]({{ site.baseurl }}/ru/documentation/reference/deploy_process/working_with_chart_dependencies.html) (сабчарты, subcharts).

Данные, размещенные внутри произвольного ключа `SOMEKEY` будут доступны в текущем чарте и [вложенном чарте]({{ site.baseurl }}/ru/documentation/reference/deploy_process/working_with_chart_dependencies.html) с именем `SOMEKEY`.

Файл `.helm/values.yaml` — файл по умолчанию для хранения данных. Данные также могут передаваться следующими способами:

 * С помощью параметра `--values=PATH_TO_FILE` может быть указан отдельный файл с данными (может быть указано несколько параметров, по одному для каждого файла данных).
 * С помощью параметров `--set key1.key2.key3.array[0]=one`, `--set key1.key2.key3.array[1]=two` могут быть указаны непосредственно пары ключ-значение (может быть указано несколько параметров, смотри также `--set-string key=forced_string_value`).

#### Пользовательские секреты

Секреты, предназначенные для хранения конфиденциальных данных, удобны для хранения прямо в репозитории проекта паролей, сертификатов и других чувствительных к утечке данных.

Для хранения данных секретов, используйте файл чарта `.helm/secret-values.yaml` (необязательно). Пример структуры:

```yaml
global:
  mysql:
    production:
      password: 100024fe29e45bf00665d3399f7545f4af63f09cc39790c239e16b1d597842161123
    staging:
      password: 100024fe29e45bf00665d3399f7545f4af63f09cc39790c239e16b1d597842161123
```

Каждое значение в файле секретов похожее на это — `100024fe29e45bf00665d3399f7545f4af63f09cc39790c239e16b1d597842161123`, представляет собой какие-то зашифрованные с помощью Werf данные. Структура хранения секретов, такая-же как и при хранении обычных данных, например, в `values.yaml`. Читайте подробнее о [генерации секретов и работе с ними]({{ site.baseurl }}/ru/documentation/reference/deploy_process/working_with_secrets.html#шифрование-секретов) в соответствующей статье.

Файл `.helm/secret-values.yaml` — файл по умолчанию для хранения данных секретов. Данные также могут передаваться с помощью параметра `--secret-values=PATH_TO_FILE`, с помощью которого может быть указан отдельный файл с данными секретов (может быть указано несколько параметров, по одному для каждого файла данных секретов).

#### Сервисные данные

Сервисные данные генерируются Werf автоматически для передачи дополнительной информации при рендеринге шаблонов чарта.

Пример структуры и значений сервисных данных Werf:

```yaml
global:
  env: stage
  namespace: myapp-stage
  werf:
    ci:
      branch: mybranch
      is_branch: true
      is_tag: false
      ref: mybranch
      tag: '"-"'
    docker_tag: mybranch
    image:
      assets:
        docker_image: registry.domain.com/apps/myapp/assets:mybranch
        docker_image_id: sha256:ddaec322ee2c622aa0591177062a81009d9e52785be6915c5a37e822c2019755
      rails:
        docker_image: registry.domain.com/apps/myapp/rails:mybranch
        docker_image_id: sha256:646c56c828beaf26e67e84a46bcdb6ab555c6bce8ebeb066b79a9075d0e87f50
    is_nameless_image: false
    name: myapp
    repo: registry.domain.com/apps/myapp
```

Существуют следующие сервисные данные:
 * Название окружения CI/CD системы, используемое во время деплоя: `.Values.global.env`.
 * Namespace Kubernetes используемый во время деплоя: `.Values.global.namespace`.
 * Имя используемой git-ветки или git-тэга: `.Values.global.werf.ci.is_branch`, `.Values.global.werf.ci.branch`, `.Values.global.werf.ci.is_tag`, `.Values.global.werf.ci.tag`.
 * `.Values.global.ci.ref` — содержит либо название git-ветки либо название git-тэга.
 * Полное имя Docker-образа и его ID, для каждого описанного в файле конфигурации `werf.yaml` образа: `.Values.global.werf.image.IMAGE_NAME.docker_image` и `.Values.global.werf.image.IMAGE_NAME.docker_image_id`.
 * `.Values.global.werf.is_nameless_image` — устанавливается если в файле конфигурации `werf.yaml` описан безымянный образ.
 * Имя проекта из файла конфигурации `werf.yaml`: `.Values.global.werf.name`.
 * Docker-тэг, используемый при деплое образа, описанного в файле конфигурации `werf.yaml` (соответственно выбранной стратегии тэгирования): `.Values.global.werf.docker_tag`.
 * Docker-репозиторий образа используемый при деплое: `.Values.global.werf.repo`.

#### Итоговое объединение данных

Во время процесса деплоя Werf объединяет все данные, включая секреты и сервисные данные, в единую структуру, которая передается на вход этапа рендеринга шаблонов (смотри подробнее [как использовать данные в шаблонах](#использование-данных-в-шаблонах)). Данные объединяются в следующем порядке приоритета (последующее значение переопределяет предыдущее):

 1. Данные из файла `.helm/values.yaml`.
 2. Данные из параметров запуска `--values=PATH_TO_FILE`, в порядке указания параметров.
 3. Данные секретов из файла `.helm/secret-values.yaml`.
 4. Данные секретов из параметров запуска `--secret-values=PATH_TO_FILE`, в порядке указания параметров.
 5. Сервисные данные.

### Использование данных в шаблонах

Для доступа к данным в шаблонах чарта используется следующий синтаксис:

{% raw %}
```yaml
{{ .Values.key.key.arraykey[INDEX].key }}
```
{% endraw %}

Объект `.Values` содержит [итоговый набор объединенных значений](#итоговое-объединение-данных).

## Релиз

В то время как чарт — набор конфигурационных файлов вашего приложения, релиз (release) — это объект времени выполнения, экземпляр вашего приложения, развернутого с помощью Werf.

У каждого релиза есть одно имя и несколько версий. При каждом деплое с помощтю Werf создается новая версия релиза.

### Хранение релизов

Информация о каждой версии релиза хранится в самом кластере Kubernetes. Werf может хранить ее в объеках ConfigMap или Secret, в любых namespace.

По умолчанию, Werf хранит информацию о релизах в объектах ConfigMap в namespace `kube-system`, что полностью совместимо с конфигурацией [Helm 2](https://helm.sh) по умолчанию. Место хранения информации о релизах может быть указано при деплое с помощью параметров: `--helm-release-storage-namespace=NS` иd `--helm-release-storage-type=configmap|secret` Werf.

Для получения информации обо всех созданных релизах, нужно использовать команду: `kubectl -n kube-system get cm`. Имена объектов ConfigMap, содержащих информацию о релизах, имеют следующих шаблон имени — `RELEASE_NAME.RELEASE_VERSION`. Наибольший номер `RELEASE_VERSION` соответствует последней развернутой версии. В ConfigMap, содержащих информацию о релизах, также есть метки (labels) по которым можно получить информацию о статусе релиза:

```yaml
kind: ConfigMap
metadata:
  ...
  labels:
    MODIFIED_AT: "1562938540"
    NAME: werfio-test
    OWNER: TILLER
    STATUS: DEPLOYED
    VERSION: "165"
```

ЗАМЕЧАНИЕ: Изменение статуса релиза в метках ConfigMap не повлияет на реальный статус релиза, так как метки содержат информацию только для справочных целей и поиска/фильтрации объектов. Реальное состояние релиза хранится в ключ `data` ConfigMap.

#### Замечание о совместимости с Helm

Werf полностью совместим с уже установленным Helm 2, т.к. хранение информации о релизах осуществляется одинаковым образом как и в Helm, и в одном и том-же месте. Если вы используете в Helm специфичное место хранения информации о релизах а не значение по умолчанию, то вам нужно указывать место хранения с помощью опций Werf `--helm-release-storage-namespace` и `--helm-release-storage-type`.

Информация о релизах, созданных с помощью Werf, может быть получена с помощью helm, например командами `helm list` и `helm get`. С помощью Werf также можно обновлять релизы, развернутые ранее с помощью Helm.

Более того, вы можете работать в одном кластере Kubernetes одновременно и с Werf и с Helm 2.

### Окружение

По умолчанию, Werf предполагает что каждый релиз должен относиться к какому-либо окружению, например `staging`, `test` или `production`.

На основании окружения Werf определяет:

 1. Имя релиза.
 2. Namespace в Kubernetes.

Передача имени окружения является обязательной для операции деплоя, и должна быть выполнена либо с помощью параметра `--env` Werf либо автоматически определяться на основании данных используемой CI/CD системы (читай подробнее про [интеграцию c CI/CD системами]({{ site.baseurl }}/ru/documentation/reference/plugging_into_cicd/overview.html#интеграция-с-настройками-ci-cd)).

### Имя релиза

По умолчанию название релиза формируется по шаблону `[[project]]-[[env]]`. Где `[[ project ]]` — имя [проекта]({{ site.baseurl }}/ru/documentation/configuration/introduction.html#имя-проекта), а `[[ env ]]` имя [окружения](#окружения).

Например, для проекта с именем `symfony-demo` будет сформировано следующее имя релиза в зависимости от имени окружения:
* `symfony-demo-stage` для окружения `stage`;
* `symfony-demo-test` для окружения `test`;
* `symfony-demo-prod` для окружения `prod`.

Имя релиза может быть переопределено с помощью параметра `--release NAME` при деплое. В этом случае Werf будет использовать указанное имя как есть, без каких либо преобразований и использования шаблонов.

Имя релиза также можно явно определить в файле конфигурации `werf.yaml`, установив параметр [`deploy.helmRelease`]({{ site.baseurl }}/ru/documentation/configuration/deploy_into_kubernetes.html#имя-релиза).

#### Слагификация имени релиза

Сформированное по шаблону имя Helm-релиза [слагифицируется]({{ site.baseurl }}/documentation/reference/toolbox/slug.html#базовый-алгоритм), в результате чего получается уникальное имя Helm-релиза.

Слагификация имени Helm-релиза включена по умолчанию, но может быть отключена указанием параметра [`deploy.helmReleaseSlug=false`]({{ site.baseurl }}/ru/documentation/configuration/deploy_into_kubernetes.html#имя-релиза) в файле конфигурации `werf.yaml`.

### Kubernetes namespace

По умолчанию namespace, используемый в Kubernetes, формируется по шаблону `[[ project ]]-[[ env ]]`, где `[[ project ]]` — [имя проекта]({{ site.baseurl }}/ru/documentation/configuration/introduction.html#meta-configuration-doc), а `[[ env ]]` — имя [окружения](#окружения).

Например, для проекта с именем `symfony-demo` будет сформировано следующее имя namespace в Kubernetes, в зависимости от имени окружения:
* `symfony-demo-stage` для окружения `stage`;
* `symfony-demo-test` для окружения `test`;
* `symfony-demo-prod` для окружения `prod`.

Имя namespace в Kubernetes может быть переопределено с помощью параметра `--namespace NAMESPACE` при деплое. В этом случае Werf будет использовать указанное имя как есть, без каких либо преобразований и использования шаблонов.

Имя namespace также можно явно определить в файле конфигурации `werf.yaml`, установив параметр [`deploy.namespace`]({{ site.baseurl }}/ru/documentation/configuration/deploy_into_kubernetes.html#kubernetes-namespace).

#### Слагификация Kubernetes namespace slug

Сформированное по шаблону имя namespace [слагифицируется]({{ site.baseurl }}/documentation/reference/toolbox/slug.html#базовый-алгоритм) чтобы удовлетворять требованиям к [DNS именам](https://www.ietf.org/rfc/rfc1035.txt), результате чего получается уникальное имя namespace в Kubernetes.

Слагификация имени namespace включена по умолчанию, но может быть отключена указанием параметра [`deploy.namespaceSlug=false`]({{ site.baseurl }}/ru/documentation/configuration/deploy_into_kubernetes.html#kubernetes-namespace) в файле конфигурации `werf.yaml`.

## Процесс деплоя

Во время запуска команды `werf deploy` Werf запускает процесс деплоя, включающий следующие этапы:

 1. Рендеринг шаблонов чартов в единый список манифестов объектов Kubernetes и их проверка.
 2. Запуск [хуков](#helm-hooks) `pre-install` или `pre-upgrade`, отслеживание их работы вплоть до успешного или неуспешного завершения, вывод логов и другой информации.
 3. Применение изменений к ресурсам Kubernetes: создание новых, удаление старых, обновление существующих.
 4. Создание новых версий релизов и сохранение состояния манифестов ресурсов в данные этого релиза.
 5. Отслеживание всех ресурсов релиза (для тех, у кого есть пробы, — до готовности readiness-проб), вывод их логов и другой информации.
 6. Запуск [хуков](#helm-hooks) `post-install` или `post-upgrade`, отслеживание их работы вплоть до успешного или неуспешного завершения, вывод логов и другой информации.

ЗАМЕЧАНИЕ: Werf удалит все созданные им при деплое ресурсы сразу же, во время процесса деплоя если он завершится неудачей на любом указанном выше этапе!

Во время выполнения Helm-хуков на шагах 2 и 6 Werf будет отслеживать ресурсы хуков до их успешного завершения. Отслеживание может быть [настроено](#настройка-отслеживания-ресурсов) для каждого хука ресурса.

On the step 5 werf tracks all release resources until each resource reaches "ready" state. All resources are tracked at the same time. During tracking werf unifies info from all release resources in realtime into single text output and periodically prints so called status progress table. Tracking [can be configured](#resource-tracking-configuration) for each resource.

Werf shows logs of resources Pods only until pod reaches "ready" state, except for Jobs. For Pods of a Job logs will be shown till Pods are terminated.

Internally [kubedog library](https://github.com/flant/kubedog) is used to track resources. Deployments, StatefulSets, DaemonSets and Jobs are supported for tracking now. Service, Ingress, PVC and other are [soon to come](https://github.com/flant/werf/issues/1637).

### Method of applying changes

Currently changes to manifest are applied only based on the previous state of manifests. The real state of resources is not taken into account. Resource state stored in the release and real resource state can get out of sync (for example by manual editing of resource manifest using `kubectl edit` command). This will lead to errors in subsequent werf deploy invocations. So it is up to user now to remember, that resources should be changed only by editing chart templates and running `werf deploy`. The new 3-way-merge method of applying changes to the resources which solves this problem is coming soon, subscribe to the issue: https://github.com/flant/werf/issues/1616.

### If deploy failed

In the case of failure during release process werf will create a new release in the FAILED state. This state can then be inspected by the user to find the problem and solve it in the next deploy invocation.

Then on the next deploy invocation werf will rollback release to the last successful version. During rollback all release resources will be restored to the last successful version state before applying any new changes to the resources manifests.

This rollback step is needed now and will be passed away when [3-way-merge method of applying changes](#method-of-applying-changes) will be implemented.

### Helm hooks

The helm hook is arbitrary kubernetes resource marked with special annotation `helm.sh/hook`. For example:

```yaml
kind: Job
metadata:
  name: somejob
  annotations:
    "helm.sh/hook": pre-upgrade,pre-install
    "helm.sh/hook-weight": "1"
```

There are a lot of different helm hooks which come into play during deploy process. We have already seen `pre|post-install|upgade` hooks in the [deploy process](#deploy-process), which are the most usually needed hooks to run such tasks as migrations (in `pre-uprade` hooks) or some post deploy actions. The full list of available hooks can be found in the [helm docs](https://github.com/helm/helm/blob/master/docs/charts_hooks.md#the-available-hooks).

Hooks are sorted in the ascending order specified by `helm.sh/hook-weight` annotation (hooks with the same weight are sorted by the names), then created and executed sequentially. Werf recreates kuberntes resource for each of the hook in the case when resource already exists in the cluster. Hooks kubernetes resources are not deleted after execution.

### Resource tracking configuration

Tracking can be configured for each resource using resource annotations:

 * [`werf.io/track-termination-mode`](#track-termination-mode);
 * [`werf.io/fail-mode`](#fail-mode);
 * [`werf.io/failures-allowed-per-replica`](#failures-allowed-per-replica);
 * [`werf.io/log-regex`](#log-regex);
 * [`werf.io/log-regex-for-CONTAINER_NAME`](#log-regex-for-container);
 * [`werf.io/skip-logs`](#skip-logs);
 * [`werf.io/skip-logs-for-containers`](#skip-logs-for-containers);
 * [`werf.io/show-logs-only-for-containers`](#show-logs-only-for-containers);
 * [`werf.io/show-service-messages`](#show-service-messages).

All of these annotations can be combined and used together for resource.

**TIP** Use `"werf.io/track-termination-mode": NonBlocking` and `"werf.io/fail-mode": IgnoreAndContinueDeployProcess` when you need to define a Job in the release, that runs in background and does not affect deploy process.

**TIP** Use `"werf.io/track-termination-mode": NonBlocking` when you need a StatefulSet with `OnDelete` manual update strategy, but you don't need to block deploy process till StatefulSet is updated immediately.

**TIP** Show service messages example:

![Demo](https://raw.githubusercontent.com/flant/werf-demos/master/deploy/werf-new-track-modes-1.gif)

**TIP** Skip logs example:

![Demo](https://raw.githubusercontent.com/flant/werf-demos/master/deploy/werf-new-track-modes-2.gif)

**TIP** NonBlocking track termination mode example:

![Demo](https://raw.githubusercontent.com/flant/werf-demos/master/deploy/werf-new-track-modes-3.gif)

#### Track termination mode

`"werf.io/track-termination-mode": WaitUntilResourceReady|NonBlocking`

 * `WaitUntilResourceReady` (default) — specifies to block whole deploy process till each resource with this track termination mode is ready.
 * `NonBlocking` — specifies to track this resource only until there are other resources not ready yet.

#### Fail mode

`"werf.io/fail-mode": FailWholeDeployProcessImmediately|HopeUntilEndOfDeployProcess|IgnoreAndContinueDeployProcess`

 * `FailWholeDeployProcessImmediately` (default) — fail whole deploy process when error occurred for resource.
 * `HopeUntilEndOfDeployProcess` — when error occurred for resource set this resource into "hope" mode and continue tracking other resources. When all of remained resources has become ready or all of remained resources are in the "hope" mode, transit resource back to "normal" mode and fail whole deploy process when error occurred for this resource once again.
 * `IgnoreAndContinueDeployProcess` — resource errors does not affect deploy process.

#### Failures allowed per replica

`"werf.io/failures-allowed-per-replica": DIGIT`

By default 1 failure per replica is allowed before considering whole deploy process as failed. This setting is related to [fail mode](#fail-mode): it defines a threshold before fail mode comes into play.

#### Log regex

`"werf.io/log-regex": RE2_REGEX`

Defines a [Re2 regex](https://github.com/google/re2/wiki/Syntax) that applies to all logs of all containers of all Pods owned by resource with this annotation. Werf will show only those log lines that fit specified regex. By default werf will show all log lines.

#### Log regex for container

`"werf.io/log-regex-for-CONTAINER_NAME": RE2_REGEX`

Defines a [Re2 regex](https://github.com/google/re2/wiki/Syntax) that applies to logs of specified container by name `CONTAINER_NAME` of all Pods owned by resource with this annotation. Werf will show only those log lines that fit specified regex. By default werf will show all log lines.

#### Skip logs

`"werf.io/skip-logs": true|false`

Set to `true` to suppress all logs of all containers of all Pods owned by resource with this annotation. Annotation is disabled by default.

#### Skip logs for containers

`"werf.io/skip-logs-for-containers": CONTAINER_NAME1,CONTAINER_NAME2,CONTAINER_NAME3...`

Comma-separated list of containers names of all Pods owned by resource with this annotation for which werf should fully suppress log output.

#### Show logs only for containers

`"werf.io/show-logs-only-for-containers": CONTAINER_NAME1,CONTAINER_NAME2,CONTAINER_NAME3...`

Comman-separated list on containers names of all Pods owned by resource with this annotation for which werf should show logs. Logs of containers not specified in this list will be suppressed. By default werf shows logs of all containers of all Pods of resource.

#### Show service messages

`"werf.io/show-service-messages": true|false`

Set to `true` to enable additional debug info for resource including kubernetes events in realtime text stream during tracking. By default werf will show these service messages only when this resource has failed whole deploy process.

### Annotate and label chart resources

#### Auto annotations

Werf automatically sets following builtin annotations to all chart resources deployed:

 * `"werf.io/version": FULL_WERF_VERSION` — werf version that being used when running `werf deploy` command;
 * `"project.werf.io/name": PROJECT_NAME` — project name specified in the `werf.yaml`;
 * `"project.werf.io/env": ENV` — environment name specified with `--env` param or `WERF_ENV` variable; optional, will not be set if env is not used.

Werf also sets auto annotations with info from the used CI/CD system (Gitlab CI for example)  when using `werf ci-env` command prior to run `werf deploy` command. For example [`project.werf.io/git`]({{ site.baseurl }}/documentation/reference/plugging_into_cicd/gitlab_ci.html#werf_add_annotation_project_git), [`ci.werf.io/commit`]({{ site.baseurl }}/documentation/reference/plugging_into_cicd/gitlab_ci.html#werf_add_annotation_ci_commit), [`gitlab.ci.werf.io/pipeline-url`]({{ site.baseurl }}/documentation/reference/plugging_into_cicd/gitlab_ci.html#werf_add_annotation_gitlab_ci_pipeline_url) and [`gitlab.ci.werf.io/job-url`]({{ site.baseurl }}/documentation/reference/plugging_into_cicd/gitlab_ci.html#werf_add_annotation_gitlab_ci_job_url).

For more info about CI/CD integration check out following pages:

 * [plugging into CI/CD overview]({{ site.baseurl }}/documentation/reference/plugging_into_cicd/overview.html);
 * [plugging into Gitlab CI]({{ site.baseurl }}/documentation/reference/plugging_into_cicd/gitlab_ci.html).

#### Custom annotations and labels

User can pass arbitrary additional annotations and labels using cli options `--add-annotation annoName=annoValue` (can be specified multiple times) and `--add-label labelName=labelValue` (can be specified multiple times) for werf deploy invocation.

For example, to set annotations and labels `commit-sha=9aeee03d607c1eed133166159fbea3bad5365c57`, `gitlab-user-email=vasya@myproject.com` to all kubernetes resources from chart use following werf deploy invocation:

```bash
werf deploy \
  --add-annotation "commit-sha=9aeee03d607c1eed133166159fbea3bad5365c57" \
  --add-label "commit-sha=9aeee03d607c1eed133166159fbea3bad5365c57" \
  --add-annotation "gitlab-user-email=vasya@myproject.com" \
  --add-label "gitlab-user-email=vasya@myproject.com" \
  --env dev \
  --images-repo :minikube \
  --stages-storage :local
```

### Resources manifests validation

If resource manifest in the chart contains logical or syntax errors then werf will write validation warning to the output during deploy process. Also all validation errors will be written to the `debug.werf.io/validation-messages`. These errors typically does not affect deploy process exit status, because kubernetes apiserver can accept wrong manifests with certain typos or errors without reporting errors.

For example, having following typos in the chart templates (`envs` instead of `env` and `redinessProbe` instead of `readinessProbe`):

```
      containers:
      - name: main
        command: [ "/bin/bash", "-c", "while true; do date ; sleep 1 ; done" ]
        image: ubuntu:18.04
        redinessProbe:
          tcpSocket:
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
      envs:
      - name: MYVAR
        value: myvalue
```

Validation output will be like:

```
│   WARNING ### Following problems detected during deploy process ###
│   WARNING Validation of target data failed: deployment/mydeploy1: [ValidationError(Deployment.spec.template.spec.containers[0]): unknown field               ↵
│ "redinessProbe" in io.k8s.api.core.v1.Container, ValidationError(Deployment.spec.template.spec): unknown field "envs" in io.k8s.api.core.v1.PodSpec]
```

And resource will contain `debug.werf.io/validation-messages` annotation:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  annotations:
    debug.werf.io/validation-messages: 'Validation of target data failed: deployment/mydeploy1:
      [ValidationError(Deployment.spec.template.spec.containers[0]): unknown field
      "redinessProbe" in io.k8s.api.core.v1.Container, ValidationError(Deployment.spec.template.spec):
      unknown field "envs" in io.k8s.api.core.v1.PodSpec]'
...
```

## Multiple Kubernetes clusters

There are cases when separate Kubernetes clusters are needed for a different environments. You can [configure access to multiple clusters](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters) using kube contexts in a single kube config.

In that case deploy option `--kube-context=CONTEXT` should be specified manually along with the environment.
