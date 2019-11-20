Образы описываются с помощью директивы _image_: `image: <image name>`, с которой начинается описание образа в конфигурации.
Параметр _image name_ — строка с именем образа, аналогичная соответствующей в Docker:

```yaml
image: frontend
```

Если в файле конфигурации описывается только один образ, то он может быть безымянным:

```yaml
image: ~
```

Если в файле конфигурации описывается более одного образа, то **каждый образ** должен иметь собственное имя:

```yaml
image: frontend
...
---
image: backend
...
```

Образ может иметь несколько имен, указываемых в виде YAML-списка (это эквивалентно описанию нескольких одинаковых образов с разными именами):

```yaml
image: [main-front,main-back]
```

Указав имя образа вы можете использовать его впоследствии в большинстве команд, например:
* [werf build \[IMAGE_NAME...\] \[options\]]({{ site.baseurl }}/documentation/cli/main/build.html)
* [werf publish \[IMAGE_NAME...\] \[options\]]({{ site.baseurl }}/documentation/cli/main/publish.html)
* [werf build-and-publish \[IMAGE_NAME...\] \[options\]]({{ site.baseurl }}/documentation/cli/main/build_and_publish.html)
* [werf run \[options\] \[IMAGE_NAME\] \[-- COMMAND ARG...\]]({{ site.baseurl }}/documentation/cli/main/run.html)

Также, имя образа используется при загрузке собранного образа в registry (читайте подробнее в соответствующей [статье]({{ site.baseurl }}/ru/documentation/reference/publish_process.html)).
