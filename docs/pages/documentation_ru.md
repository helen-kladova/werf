---
title: Обзор
permalink: ru/documentation/index.html
sidebar: documentation
ref: documentation
lang: ru
---

Документация содержит более 100 различных статей, включая наиболее типичные примеры использования Werf, подробное описание функций, архитектуры и параметров вызова.

Мы рекомендуем начинать знакомство с раздела "Руководства":

- [Установка]({{ site.baseurl }}/ru/documentation/guides/installation.html) описывает зависимости Werf и возможные варианты установки.
- [Первые шаги]({{ site.baseurl }}/ru/documentation/guides/getting_started.html) помогают начать использовать Werf с обычным Dockerfile. Вы можете легко запустить Werf в вашем проекте прямо сейчас.
- [Деплой в Kubernetes]({{ site.baseurl }}/ru/documentation/guides/deploy_into_kubernetes.html) — краткий пример развертывания приложения в кластере Kubernetes.
- [Интеграция с GitLab CI/CD]({{ site.baseurl }}/ru/documentation/guides/gitlab_ci_cd_integration.html) расскажет всё об интеграции с GitLab: про сборку, про публикацию, про деплой и очистку Docker-регистри.
- [Интеграция с неподдерживаемыми системами CI/CD]({{ site.baseurl }}/ru/documentation/guides/unsupported_ci_cd_integration.html) расскажет о том, как интегрировать Werf в любую CI/CD-систему, которая пока еще [официально не поддерживается]({{ site.baseurl }}/ru/documentation/reference/plugging_into_cicd/overview.html).
- В разделе расширенной сборки рассказывается о нашем синтаксисе описания сборки образов, которая дает преимущества инкрементальной сборки с учетом истории в git и других интересных инструментах. Рекомендуем начать знакомство с создания [первого приложения]({{ site.baseurl }}/ru/documentation/guides/advanced_build/first_application.html).

Следующий раздел — **Конфигурация**.

Для использования Werf в вашем проекте, необходимо создать файл конфигурации `werf.yaml`, что включает в себя:

1. Описание метаинформации проекта, которая впоследствии будет использоваться в командах сборки, деплоя  и других. Пример такой метаинформации — имя проекта.
2. Описание образов для сборки.

В статье ["Общие сведения"]({{ site.baseurl }}/ru/documentation/configuration/introduction.html) вы найдете информацию о:

* Структуре секций и их конфигурации
* Подходах к описанию конфигурации
* Процессах обработки конфигурации
* Поддерживаемых функциях Go-шаблонов

В других статьях раздела "Конфигурация" дается детальная информация о директивах описания [Dockerfile-образа]({{ site.baseurl }}/ru/documentation/configuration/dockerfile_image.html), [Stapel-образа]({{ site.baseurl }}/ru/documentation/configuration/stapel_image/naming.html), [Stapel-артефакта]({{ site.baseurl }}/ru/documentation/configuration/stapel_artifact.html) и особенностях их использования.

Раздел **Справочника** посвящен описанию основных процессов Werf:

* [Сборка]({{ site.baseurl }}/ru/documentation/reference/build_process.html)
* [Публикация]({{ site.baseurl }}/ru/documentation/reference/publish_process.html)
* [Деплой]({{ site.baseurl }}/ru/documentation/reference/deploy_process/deploy_into_kubernetes.html)
* [Очистка]({{ site.baseurl }}/ru/documentation/reference/cleaning_process.html)

Каждая статья описывает определенный процесс: его состав, доступные опции и особенности.

Также в этот раздел включены статьи с описанием базовых примитивов и общих инструментов:

* [Стадии и образы]({{ site.baseurl }}/ru/documentation/reference/stages_and_images.html)
* [Авторизация в Docker-регистри]({{ site.baseurl }}/ru/documentation/reference/registry_authorization.html)
* [Разработка и отладка]({{ site.baseurl }}/ru/documentation/reference/development_and_debug/setup_minikube.html)
* [Toolbox]({{ site.baseurl }}/ru/documentation/reference/toolbox/slug.html)

Werf — это CLI-утилита, поэтому, если вы хотите найти описание как базовых команд, необходимых для управления процессом CI/CD, так и служебных команд, обеспечивающих расширенные функциональные возможности — используйте раздел [**CLI Commands**]({{ site.baseurl }}/documentation/cli/main/build.html).

Раздел [**Разработка**]({{ site.baseurl }}/ru/documentation/development/stapel.html)
содержит информацию, предназначенную для более глубокого понимания работы компонентов Werf, участии в развитии Werf со стороны разработчика и т.д.
