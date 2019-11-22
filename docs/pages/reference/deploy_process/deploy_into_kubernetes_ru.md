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

 * С помощью параметра `--values=PATH_TO_FILE` может быть указан отдельный файлы с данными (может быть указано несколько параметров, по одному для каждого файла данных).
 * С помощью параметров `--set key1.key2.key3.array[0]=one`, `--set key1.key2.key3.array[1]=two` могут быть указаны непосредственно пары ключ-значение (может быть указано несколько параметров, смотри также `--set-string key=forced_string_value`).

#### Пользовательские секреты

Secret values are useful to store passwords and other sensitive data directly in the project repo.

Place user defined secret values into the chart file `.helm/secret-values.yaml` (which is optional). For example:

```yaml
global:
  mysql:
    production:
      password: 100024fe29e45bf00665d3399f7545f4af63f09cc39790c239e16b1d597842161123
    staging:
      password: 100024fe29e45bf00665d3399f7545f4af63f09cc39790c239e16b1d597842161123
```

Each value like `100024fe29e45bf00665d3399f7545f4af63f09cc39790c239e16b1d597842161123` in the secret values map is a werf secret encoded value. Otherwise secret values map is the same as a regular values map. See more info [about secret values generation and working with secrets]({{ site.baseurl }}/documentation/reference/deploy_process/working_with_secrets.html#secret-values-encryption).

File `.helm/secret-values.yaml` is the default secret values file. Additional user defined secret values can alternatively be passed via separate secret values files by sepcifying werf options `--secret-values=PATH_TO_FILE` (can be used multiple times to pass multiple files).

#### Сервисные данные

Service values are generated by werf automatically to pass additional werf service info when rendering chart templates.

Complete example of service values:

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

There are following service values:
 * Environment being used during deploy: `.Values.global.env`.
 * Kubernetes namespace being used during deploy: `.Values.global.namespace`.
 * Git branch name or git tag name used: `.Values.global.werf.ci.is_branch`, `.Values.global.werf.ci.branch`, `.Values.global.werf.ci.is_tag`, `.Values.global.werf.ci.tag`.
 * `.Values.global.ci.ref` is set to either git branch name or git tag name.
 * Full docker images names and ids for each image from `werf.yaml` config: `.Values.global.werf.image.IMAGE_NAME.docker_image` and `.Values.global.werf.image.IMAGE_NAME.docker_image_id`.
 * `.Values.global.werf.is_nameless_image` indicates whether there is a single image defined in the `werf.yaml` config.
 * Project name from `werf.yaml`: `.Values.global.werf.name`.
 * Docker tag being used during deploy for images from `werf.yaml` (accordingly to the selected tagging strategy): `.Values.global.werf.docker_tag`.
 * Images repo being used during deploy: `.Values.global.werf.repo`.

#### Merge result values

During deploy process werf merges all of user defined regular, user defined secret and service values into the single values map, which is passed to templates rendering engine to be used in the templates (see [how to use values in the templates](#using-values-in-the-templates)). Values are merged in the following order of priority (next values overwrite previous):

 1. User defined regular values from `.helm/values.yaml`.
 2. User defined regular values from all cli options `--values=PATH_TO_FILE` in the order of specification.
 3. User defined secret values from `.helm/secret-values.yaml`.
 4. User defined secret values from all cli options `--secret-values=PATH_TO_FILE` in the order of specification.
 5. Service values.

### Using values in the templates

To access values from chart templates following syntax is used:

{% raw %}
```yaml
{{ .Values.key.key.arraykey[INDEX].key }}
```
{% endraw %}

`.Values` object contains [merged result values](#merge-result-values) map.

## Release

While chart is a collection of configuration files of your application, release is a runtime object representing running instance of your application deployed with werf.

Each release have a single name and multiple versions. On each werf deploy invocation a new release version is created.

### Releases storage

Each release version is stored in the kubernetes cluster itself. Werf can store releases in ConfigMaps or Secrets in arbitrary namespaces.

By default werf stores releases in the ConfigMaps in the `kube-system` namespace to be fully compatible with [Helm 2](https://helm.sh) default installations. Releases storage can be configured by werf deploy cli options: `--helm-release-storage-namespace=NS` and `--helm-release-storage-type=configmap|secret`.

To inspect all created releases user can run: `kubectl -n kube-system get cm`. ConfigMaps names are constructed as `RELEASE_NAME.RELEASE_VERSION`. The biggest `RELEASE_VERSION` number is the last deployed version. ConfigMaps also have labels by which release status can be inspected:

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

NOTE: Changing release status in ConfigMap labels will not affect real release status, because ConfigMap labels serve only for informational and filtration purposes, the real release status is stored in the ConfigMap data.

#### Helm compatibility notice

Werf is fully compatible with already existing Helm 2 installations as long as releases storage is configured the same way as in helm. User might need to configure release storage with options `--helm-release-storage-namespace` and `--helm-release-storage-type` if existing helm installation uses non default releases storage.

Releases created by werf can be inspected and viewed with helm commands, such as `helm list` and `helm get`. Werf can also upgrade already existing releases originally created by helm.

Furthermore werf and Helm 2 installation could work in the same cluster at the same time.

### Environment

By default werf assumes that each release should be tainted with some environment, such as `staging`, `test` or `production`.

Based on the environment werf will determine:

 1. Release name.
 2. Kubernetes namespace.

Environment is a required parameter for deploy and should be specified either with option `--env` or automatically determined for the used CI/CD system, see [CI/CD configuration integration]({{ site.baseurl }}/documentation/reference/plugging_into_cicd/overview.html#ci-cd-configuration-integration) for more info.

### Release name

By default release name will be constructed by template `[[ project ]]-[[ env ]]`. Where `[[ project ]]` refers to the [project name]({{ site.baseurl }}/documentation/configuration/introduction.html#project-name) and `[[ env ]]` refers to the specified or detected environment.

For example for project named `symfony-demo` there will be following Helm Release names depending on the specified environment:
* `symfony-demo-stage` for the `stage` environment;
* `symfony-demo-test` for the `test` environment;
* `symfony-demo-prod` for the `prod` environment.

Release name could be redefined by deploy option `--release NAME`. In that case Werf will use specified name as is.

Custom release name can also be defined in the werf.yaml configuration [by setting `deploy.helmRelease`]({{ site.baseurl }}/documentation/configuration/deploy_into_kubernetes.html#release-name).

#### Release name slug

Helm Release name constructed by template will be slugified to fit release name requirements by [*release slug procedure*]({{ site.baseurl }}/documentation/reference/toolbox/slug.html#basic-algorithm), which generates unique valid Helm Release name.

This is default behaviour, which can be disabled by [setting `deploy.helmReleaseSlug=false`]({{ site.baseurl }}/documentation/configuration/deploy_into_kubernetes.html#release-name).

### Kubernetes namespace

By default Kubernetes Namespace will be constructed by template `[[ project ]]-[[ env ]]`. Where `[[ project ]]` refers to the [project name]({{ site.baseurl }}/documentation/configuration/introduction.html#meta-configuration-doc) and `[[ env ]]` refers to the determined environment.

For example for project named `symfony-demo` there will be following Kubernetes Namespaces depending on the specified environment:
* `symfony-demo-stage` for the `stage` environment;
* `symfony-demo-test` for the `test` environment;
* `symfony-demo-prod` for the `prod` environment.

Kubernetes Namespace could be redefined by deploy option `--namespace NAMESPACE`. In that case Werf will use specified name as is.

Custom Kubernetes Namespace can also be defined in the werf.yaml configuration [by setting `deploy.namespace`]({{ site.baseurl }}/documentation/configuration/deploy_into_kubernetes.html#kubernetes-namespace).

#### Kubernetes namespace slug

Kubernetes Namespace constructed by template will be slugified to fit [DNS Label](https://www.ietf.org/rfc/rfc1035.txt) requirements by [*namespace slug procedure*]({{ site.baseurl }}/documentation/reference/toolbox/slug.html#basic-algorithm), which generates unique valid Kubernetes Namespace.

This is default behaviour, which can be disabled by [setting `deploy.namespaceSlug=false`]({{ site.baseurl }}/documentation/configuration/deploy_into_kubernetes.html#kubernetes-namespace).

## Deploy process

When running `werf deploy` command werf starts deploy process which includes following steps:

 1. Render chart templates into single list of kubernetes resources manifests and validate them.
 2. Run `pre-install` or `pre-upgrade` [hooks](#helm-hooks) and track each of the hooks till successful or failed termination printing logs and other info along the way.
 3. Apply changes to kubernetes resources: create new, delete old, update existing.
 4. Create new release version and save current resources manifests state into this release.
 5. Track all release resources till readiness state reached printing logs and other info along the way.
 6. Run `post-install` or `post-upgrade` [hooks](#helm-hooks) and track each of the hooks till successful or failed termination printing logs and other info along the way.

NOTE: Werf will delete all newly created resources immediately during current deploy process if this deploy process fails at any step specified above!

During execution of helm hooks on the steps 2 and 6 werf will track these hooks resources until successful termination. Tracking [can be configured](#resource-tracking-configuration) for each hook resource.

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
