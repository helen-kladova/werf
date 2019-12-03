---
title: Рендеринг и линтер конфигурации
sidebar: documentation
permalink: documentation/reference/development_and_debug/lint_and_render_chart.html
author: Timofey Kirillov <timofey.kirillov@flant.com>
---

Во время разработки [шаблонов helm-чартов]({{ site.baseurl }}/ru/documentation/reference/deploy_process/deploy_into_kubernetes.html#шаблоны) зачастую полезно выполнять проверку корректности синтаксиса перед выполнением процесса деплоя.

Werf содержит два инструмента для выполнения этой задачи:

 1. [Рендеринг шаблонов](#рендеринг)
 2. [Линтер шаблонов](#линтер)

## Рендеринг

Во время рендеринга шаблонов Werf возвращает содержимое всех manifest-файлов шаблона выполняя в том числе и все Go-шаблоны.

Для получения отрендеренного manifest-файла шаблона необходимо использовать команду [werf helm render]({{ site.baseurl }}/documentation/cli/management/helm/render.html). Этой команде можно передавать все те-же параметры что и команде [`werf deploy`]({{ site.baseurl }}/documentation/cli/main/deploy.html), в том числе  передавать дополнителные [переменные]({{ site.baseurl }}/ru/documentation/reference/deploy_process/deploy_into_kubernetes.html#values), адрес репозитория Docker-образов и другие параметры.

Рендеринг помогает при отладке проблем деплоя связанных с ошибками в шаблонах, YAML-формате, описании объектов Kubernetes и т.д..

## Линтер

Линтер выполняет проверку [чарта]({{ site.baseurl }}/ru/documentation/reference/deploy_process/deploy_into_kubernetes.html#chart) на различные проблемы, например:
 * Ошибки в Go-шаблонах;
 * Ошибки в YAML-синтаксисе;
 * Ошибки в синтаксисе объектов Kubernetes: не корректный тип объекста, отсутствующие параметры, поля, и т.д.;
 * Логические ошибки в описании объектов Kubernetes ([скоро](https://github.com/flant/werf/issues/1187)): отсутствующие label у ресурсов, ошибочные имена у связанных ресурсов, проверка apiVersion объекта на корректность, и т.д.;
 * Возможные проблемы безопасности ([скоро](https://github.com/flant/werf/issues/1317)).

Для запуска линтера необходимо выполнить команду [`werf helm lint`]({{ site.baseurl }}/documentation/cli/management/helm/lint.html). Ее можно выполнять как локально, так и в рамках pipeline CI/CD систем в качестве автоматического теста чарта на ошибки.
Этой команде можно передавать все те-же параметры что и команде [`werf deploy`]({{ site.baseurl }}/documentation/cli/main/deploy.html), в том числе  передавать дополнительные [переменные]({{ site.baseurl }}/ru/documentation/reference/deploy_process/deploy_into_kubernetes.html#values), адрес репозитория Docker-образов и другие параметры.
