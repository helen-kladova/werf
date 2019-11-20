---
title: Базовый образ
sidebar: documentation
permalink: ru/documentation/configuration/stapel_image/base_image.html
ref: documentation_configuration_stapel_image_base_image
lang: ru
author: Alexey Igrychev <alexey.igrychev@flant.com>
summary: |
  <a class="google-drawings" href="https://docs.google.com/drawings/d/e/2PACX-1vReDSY8s7mMtxuxwDTwtPLFYjEXePaoIB-XbEZcunJGNEHrLbrb9aFxyOoj_WeQe0XKQVhq7RWnG3Eq/pub?w=2031&amp;h=144" data-featherlight="image">
      <img src="https://docs.google.com/drawings/d/e/2PACX-1vReDSY8s7mMtxuxwDTwtPLFYjEXePaoIB-XbEZcunJGNEHrLbrb9aFxyOoj_WeQe0XKQVhq7RWnG3Eq/pub?w=1016&amp;h=72">
  </a>

  <div class="language-yaml highlighter-rouge"><pre class="highlight"><code><span class="s">from</span><span class="pi">:</span> <span class="s">&lt;image[:&lt;tag&gt;]&gt;</span>
  <span class="s">fromLatest</span><span class="pi">:</span> <span class="s">&lt;bool&gt;</span>
  <span class="s">fromCacheVersion</span><span class="pi">:</span> <span class="s">&lt;arbitrary string&gt;</span>
  <span class="s">fromImage</span><span class="pi">:</span> <span class="s">&lt;image name&gt;</span>
  <span class="s">fromImageArtifact</span><span class="pi">:</span> <span class="s">&lt;artifact name&gt;</span></code></pre>
  </div>
---

Пример минимального `werf.yaml`:
```yaml
project: my-project
configVersion: 1
---
image: example
from: alpine
```

Приведенная конфигурация описывает _образ_ `example`, _базовым образом_ для которого является образ с именем `alpine`.

_Базовый образ_ может быть указан с помощью директив `from`, `fromImage` или `fromImageArtifact`.

## from, fromLatest

Директива `from` определяет имя и тэг _базового образа_. Если тэг не указан, то по умолчанию это — `latest`.

```yaml
from: <image>[:<tag>]
```

По умолчанию, процесс борки не зависит от digest'а _базового образа_, а зависит только от значения директивы `from`.  Поэтому, изменение _базового образа_ в локальном хранилище или в Docker registry не будет влиять не сборку, пока стадия _from_ с указанным значением образа находится в _кэше стадий_.

Если же вам нужна проверка digest образа, чтобы всегда использовать актуальный _базовый образ_, вы можете использовать директиву `fromLatest`. Это приведет к тому, чтобы при сборке всегда будет осуществляться соединение с хранилищем или Docker registry для получения актуального digest _базового образа_.

Пример использования директивы `fromLatest`:
```yaml
fromLatest: true
```

> Обратите внимание, что если вы включаете _fromLatest_, то Werf использует digest актуального _базового образа_ при подсчете сигнатуры стадии _from_. Это может приводить к неожиданным сменам сигнатур стадий, что как следствие приводит к тому, что после смены _базового образа_ все собранные ранее зависимые образы становятся недоступны при сборке. Примеры проблем, которые это поведение может вызвать при CI процессах (например — pipeline GitLab):
- сборка прошла успешно, но затем обновляется _базовый образ_ и следующие задания pipeline (например деплой) уже не работают (собранного конечного образа, с учетом обновленного _базового образа_ не существует)
- собранное приложение успешно задеплоено, но затем обновляется _базовый образ_ и повторный запуск задания деплоя уже не работает (собранного конечного образа, с учетом обновленного _базового образа_ не существует)

## fromImage and fromImageArtifact

В качестве _базового образа_ можно указывать не только образ из локального хранилища или Docker registry, но и имя другого _образа_ или [_артефакта_]({{ site.baseurl }}/documentation/configuration/stapel_artifact.html), описанного в том-же файле `werf.yaml`. В этом случае необходимо использовать директивы `fromImage` и `fromImageArtifact` соответственно.

```yaml
fromImage: <image name>
fromImageArtifact: <artifact name>
```

Если _базовый образ_ уникален для конкретного приложения, то рекомендуемый способ — хранить его описание в конфигурации приложения (в файле `werf.yaml`) как отдельный _образ_ или _артефакт_, вместо того, чтобы ссылаться на Docker-образ.

Также, эта рекомендация будет полезной, если вам по каким-либо причинам не хватает существующих стадий _конвейера стадий_. Используя в качестве _базового образа_ образ, описанный в том-же `werf.yaml` вы по сути можете построить свой конвейер стадий.

<a class="google-drawings" href="https://docs.google.com/drawings/d/e/2PACX-1vTmQBPjB6p_LUpwiae09d_Jp0JoS6koTTbCwKXfBBAYne9KCOx2CvcM6DuD9pnopdeHF--LPpxJJFhB/pub?w=1629&amp;h=1435" data-featherlight="image">
<img src="https://docs.google.com/drawings/d/e/2PACX-1vTmQBPjB6p_LUpwiae09d_Jp0JoS6koTTbCwKXfBBAYne9KCOx2CvcM6DuD9pnopdeHF--LPpxJJFhB/pub?w=850&amp;h=673">
</a>

## fromCacheVersion

Как описано выше, в обычном случае процесс сборки активно использует кэширование. При сборке выполняется проверка — изменился ли _базовый образ_ (в зависимости от используемых директив это проверка на изменение digest или имени и тэга образа). Если образ не изменился, то сигнатура стадии `from` остается прежней, и если в кэше стадий есть образ с такой сигнатурой, то он и будет использован при сборке.

С помощью директивы `fromCacheVersion` вы можете влиять на сигнатуру стадии `from` (т.к. значение `fromCacheVersion` — это часть сигнатуры стадии), и таким образом управлять принудительной сборкой всего образа. Если вы измените значение, указанное в директиве `fromCacheVersion`, то независимо от того, менялся ли _базовый образ_ (или его digest) или он остался прежним, при сборке изменится сигнатура стадии `from` и соответственно всех следующих стадий. Это приведет к тому, что сборка всех стадий будет выполнена повторно.

```yaml
fromCacheVersion: <arbitrary string>
```
