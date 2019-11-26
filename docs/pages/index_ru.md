---
title: Главная
permalink: /ru/
lang: ru
ref: main
layout: default
---

<div class="welcome">
    <div class="page__container">
        <div class="welcome__content">
            <h1 class="welcome__title">
                GitOps утилита
            </h1>
            <div class="welcome__subtitle">
                 Быстро и легко обеспечивает доставку приложения.<br/>Open Source. Написана на Golang.
            </div>
            <form action="https://www.google.com/search" class="welcome__search" method="get" name="searchform" target="_blank">
                <input name="sitesearch" type="hidden" value="werf.io">
                <input autocomplete="on" class="page__input welcome__search-input" name="q" placeholder="Search the documentation" required="required"  type="text">
                <button type="submit" class="page__icon page__icon_search welcome__search-btn"></button>
            </form>
        </div>
    </div>
</div>

<div class="page__container">
    <div class="intro">
        <div class="intro__image"></div>
        <div class="intro__content">
            <div class="intro__title">
                CLI утилита построения пайплайнов CI/CD
            </div>
            <div class="intro__text">
                <ul class="intro__list">
                    <li>
                        Werf — единственный инструмент, интегрирующий в себе такие известные инструменты как:<br/> <code>git</code>, <code>helm</code> и <code>Docker</code>.
                    </li>
                    <li>
                        Может быть встроен в любую существующую CI/CD-систему (наример Gitlab CI) <br>для построения пайплайнов CI/CD используя набор готовых инструментов:
                        <ul class="intro__list_c2">
                            <li><code>werf build-and-publish</code>;</li>
                            <li><code>werf deploy</code>;</li>
                            <li><code>werf dismiss</code>;</li>
                            <li><code>werf cleanup</code>.</li>
                        </ul>
                    </li>
                    <li>
                        Open Source, написана на Golang.
                    </li>
                    <li>
                        Werf — это не SAAS, а (по нашему мнению) представитель высокоуровневых CI/CD инструментов нового поколения.
                    </li>
                </ul>
            </div>
        </div>
    </div>
</div>

<div class="page__container">
    <ul class="intro-extra">
        <li class="intro-extra__item">
            <div class="intro-extra__item-title">
                Удобный деплой
            </div>
            <div class="intro-extra__item-text">
                <ul class="intro__list">
                    <li>Полная совместимость с Helm.</li>
                    <li>Простое использование RBAC.</li>
                    <li>Обычный подход к развертыванию приложений в Kubernetes не гарантирует развертывания функционирующего приложения. Werf — дает вам эту гарантию.</li>
                    <li>Werf может остановить весь процесс развертывания задания CI-системы в случае найденной проблемы, не дожидаясь таймаутов и не заставляя вас запускать kubectl. Вы быстрее отладите ваше приложение.</li>
                    <li>Настраиваемый детектор ошибок и готовности ресурсов Kubernetes с использованием их аннотаций.</li>
                    <li>Богатое журналирование и информативный отчет об ошибках.</li>
                </ul>
            </div>
        </li>
        <li class="intro-extra__item">
            <div class="intro-extra__item-title">
                Управление всем жизненным циклом образа
            </div>
            <div class="intro-extra__item-text">
                <ul class="intro__list">
                    <li>Собирайте образы из Dockerfile'ов либо используйте наш расширенный сборщик с Ansible и инкрементальной сборкой, учитывающей историю в git.</li>
                    <li>Пуликуйте образы в Docker-registry с использованием расширенной схемы именования образов.</li>
                    <li>Развертывайте образы приложения в кластере Kubernetes.</li>
                    <li>Очищайте Docker-registry от мусора используя политики очистки.</li>
                </ul>
            </div>
        </li>
    </ul>
</div>

<div class="stats">
    <div class="page__container">
        <div class="stats__content">
            <div class="stats__title">Активная разработка</div>
            <ul class="stats__list">
                <li class="stats__list-item">
                    <div class="stats__list-item-num">4</div>
                    <div class="stats__list-item-title">релиза в неделю</div>
                    <div class="stats__list-item-subtitle">в среднем за прошлый год</div>
                </li>
                <li class="stats__list-item">
                    <div class="stats__list-item-num">1200</div>
                    <div class="stats__list-item-title">инсталляций</div>
                    <div class="stats__list-item-subtitle">в больших и маленьких проектах</div>
                </li>
                <li class="stats__list-item">
                    <div class="stats__list-item-num gh_counter">1010</div>
                    <div class="stats__list-item-title">звезд на GitHub</div>
                    <div class="stats__list-item-subtitle">подкиньте еще ;)</div>
                </li>
            </ul>
        </div>
    </div>
</div>

<div class="features">
    <div class="page__container">
        <ul class="features__list">
            <li class="features__list-item">
                <div class="features__list-item-icon features__list-item-icon_easy"></div>
                <div class="features__list-item-title">Легко начать</div>
                <div class="features__list-item-text">Можно использвать текущий процесс сборки с Dockerfile. Легко добавить Werf в ваш проект прямо сейчас.</div>
            </li>
            <li class="features__list-item">
                <div class="features__list-item-icon features__list-item-icon_config"></div>
                <div class="features__list-item-title">Компактный файл конфигурации</div>
                <div class="features__list-item-text">Собирайте несколько образов используя один файл конфигурации, переиспользуйте общие части с помощью Go-шаблонов.</div>
            </li>
            <li class="features__list-item">
                <div class="features__list-item-icon features__list-item-icon_lifecycle"></div>
                <div class="features__list-item-title">Полный цикл управления жизненным циклом приложения</div>
                <div class="features__list-item-text">Легко управляйте процессом сборки и удаления образов, деплоем приложений в Kubernetes.</div>
            </li>
            <li class="features__list-item">
                <div class="features__list-item-icon features__list-item-icon_size"></div>
                <div class="features__list-item-title">Уменьшение размеров образа</div>
                <div class="features__list-item-text">Исключите исходный код и инструменты сборки с помощью артефактов, монтирования и возможностей Stapel.</div>
            </li>
            <li class="features__list-item">
                <div class="features__list-item-icon features__list-item-icon_ansible"></div>
                <div class="features__list-item-title">Собирайте образы с <span>Ansible</span></div>
                <div class="features__list-item-text">Используйте популярный и мощный IaaS-инструмент.</div>
            </li>
            <li class="features__list-item">
                <div class="features__list-item-icon features__list-item-icon_debug"></div>
                <div class="features__list-item-title">Продвинутые инструменты отладки сборочного процесса</div>
                <div class="features__list-item-text">Получайте доступ к любой стадии во время сборки, с помощью опций интроспекции.</div>
            </li>
            <li class="features__list-item"></li>
            <li class="features__list-item">
                <div class="features__list-item-icon features__list-item-icon_kubernetes"></div>
                <div class="features__list-item-title">Удобный деплой в <span>Kubernetes</span></div>
                <div class="features__list-item-text">Деплойте в Kubernetes используя стандартный менеджер пакетов с интерактивным отслеживанием процесса и получением журналов в режиме реального времени, прямо в CI-задании.</div>
            </li>
            <li class="features__list-item"></li>
        </ul>
        <a href="https://github.com/flant/werf/README_ru.md#полный-список-возможностей" target="_blank" class="page__btn page__btn_o features__btn">
            Узнайте полный список возможностей
        </a>
    </div>
</div>

<div class="community">
    <div class="page__container">
        <div class="community__content">
            <div class="community__title">Растущее дружелюбное сообщество</div>
            <div class="community__subtitle">Разработчики Werf всегда на связи с сообществом<br/> в Slack и Telegram.</div>
            <div class="community__btns">
                <a href="https://t.me/werf_ru" target="_blank" class="page__btn page__btn_w community__btn">
                    <span class="page__icon page__icon_telegram"></span>
                    Подключайся в Telegram
                </a>
                <a href="https://cloud-native.slack.com/messages/CHY2THYUU" target="_blank" class="page__btn page__btn_w community__btn">
                    <span class="page__icon page__icon_slack"></span>
                    Join via Slack
                </a>
            </div>
        </div>
    </div>
</div>

<div class="roadmap">
    <div class="page__container">
        <div class="roadmap__title">
            Дорожная карта
        </div>
        <div class="roadmap__content">
            <div class="roadmap__goals">
                <div class="roadmap__goals-content">
                    <div class="roadmap__goals-title">Цели</div>
                    <ul class="roadmap__goals-list">
                        <li class="roadmap__goals-list-item">
                            Полнофункциональная версия Werf, которая хорошо работает на одном выделенным постоянно хосте для выполнения всех операций Werf (сборка, деплой и очистка).
                        </li>
                        <li class="roadmap__goals-list-item">
                            Проверенные подходы и рецепты работы<br/>
                            с большинством CI-систем.
                        </li>
                        <li class="roadmap__goals-list-item">
                            Building images completely in userspace, <br/>
                            a container or Kubernetes cluster.
                        </li>
                    </ul>
                </div>
            </div>
            <div class="roadmap__steps">
                <div class="roadmap__steps-content">
                    <div class="roadmap__steps-title">Этапы</div>
                    <ul class="roadmap__steps-list">
                        <li class="roadmap__steps-list-item" data-roadmap-step="1616">
                            <a href="https://github.com/flant/werf/issues/1616" class="roadmap__steps-list-item-issue" target="_blank">#1616</a>
                            <span class="roadmap__steps-list-item-text">
                                Использование <a href="https://kubernetes.io/docs/tasks/manage-kubernetes-objects/declarative-config/#merge-patch-calculation" target="_blank">3-х этапного слияния</a> при обновлении helm-релизов.
                            </span>
                        </li>
                        <li class="roadmap__steps-list-item" data-roadmap-step="1184">
                            <a href="https://github.com/flant/werf/issues/1184" class="roadmap__steps-list-item-issue" target="_blank">#1184</a>
                            <span class="roadmap__steps-list-item-text">
                                Контентно-адресуемое тэгирование.
                            </span>
                        </li>
                        <li class="roadmap__steps-list-item" data-roadmap-step="1617">
                            <a href="https://github.com/flant/werf/issues/1617" class="roadmap__steps-list-item-issue" target="_blank">#1617</a>
                            <span class="roadmap__steps-list-item-text">
                            Проверенные подходы и рецепты работы<br/>
                            с большинством CI-систем.
                            </span>
                        </li>
                        <li class="roadmap__steps-list-item" data-roadmap-step="1614">
                            <a href="https://github.com/flant/werf/issues/1614" class="roadmap__steps-list-item-issue" target="_blank">#1614</a>
                            <span class="roadmap__steps-list-item-text">
                                Распределенная сборка.
                            </span>
                        </li>
                        <li class="roadmap__steps-list-item" data-roadmap-step="1606">
                            <a href="https://github.com/flant/werf/issues/1606" class="roadmap__steps-list-item-issue" target="_blank">#1606</a>
                            <span class="roadmap__steps-list-item-text">
                                Поддержка Helm 3.
                            </span>
                        </li>
                        <li class="roadmap__steps-list-item" data-roadmap-step="1618">
                            <a href="https://github.com/flant/werf/issues/1618" class="roadmap__steps-list-item-issue" target="_blank">#1618</a>
                            <span class="roadmap__steps-list-item-text">
                                Сборка в userspace без Docker-демона<br/>
                                (как в <a href="https://github.com/GoogleContainerTools/kaniko" target="_blank">kaniko</a>).
                            </span>
                        </li>
                    </ul>
                </div>
            </div>
        </div>
    </div>
</div>

<div class="page__container">
    <div class="documentation">
        <div class="documentation__image">
        </div>
        <div class="documentation__info">
            <div class="documentation__info-title">
                Исчерпывающая документация
            </div>
            <div class="documentation__info-text">
                Документация содержит более 100 статей, включающих описание частых случаев (первые шаги, деплой в Kubernetes, интеграция с CI/CD системами и другое), полное описание функций, архитектуры и CLI-команд.
            </div>
        </div>
        <div class="documentation__btns">
            <a href="https://github.com/flant/werf" target="_blank" class="page__btn page__btn_b documentation__btn">
                Начать использовать
            </a>
            <a href="{{ site.baseurl }}/ru/documentation/guides/getting_started.html" class="page__btn page__btn_o documentation__btn">
                Руководства для старта
            </a>
            <a href="{{ site.baseurl }}/ru/documentation/cli/main/build.html" class="page__btn page__btn_o documentation__btn">
                CLI команды
            </a>
        </div>
    </div>
</div>
