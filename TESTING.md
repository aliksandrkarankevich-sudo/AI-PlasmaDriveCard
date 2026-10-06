# Тестирование v0.96.0-beta3

> Руководство для проверки тестовой версии (pre-release).  
> Ошибки оставляйте через **[Issues → Bug report](../../issues/new?template=bug.yml)**, идеи — через **[Feature request](../../issues/new?template=feature.yml)**.

## Быстрая установка

### Вариант А — из GitHub Releases (рекомендуется)

```bash
curl -fsSL https://raw.githubusercontent.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard/main/scripts/install-from-github.sh -o install-from-github.sh
bash install-from-github.sh
```

Если стабильных релизов нет, скрипт сам возьмёт последний pre-release. Для явного выбора добавьте `--prerelease`.

### Вариант Б — из исходников (собрать вручную)

```bash
git clone https://github.com/aliksandrkarankevich-sudo/AI-PlasmaDriveCard.git
cd AI-PlasmaDriveCard
bash scripts/build.sh
kpackagetool6 --type Plasma/Applet --install dist/cachyos-drive-card-0.96.0-beta3.plasmoid
```

При обновлении с предыдущей версии замените `--install` на `--upgrade`.

### Перезапуск Plasma

```bash
systemctl --user restart plasma-plasmashell.service
```

Если служба недоступна: `kquitapp6 plasmashell && kstart plasmashell` (в fish: `kquitapp6 plasmashell; and kstart plasmashell`).

### Добавление виджета

Правая кнопка на рабочем столе → **Добавить виджеты** → найдите «Карточка дисков».

## Что проверять

### Визуальное

- [ ] Фон виджета переходит в прозрачность со **всех четырёх сторон** (не только по горизонтали)
- [ ] Центр фона имеет ожидаемую непрозрачность (без двойного наложения)
- [ ] Скругления и отступы выглядят корректно
- [ ] Значки дисков и папок отображаются
- [ ] Индикатор заполнения отображается с нужной толщиной
- [ ] Индикация чтения/записи мигает при активности

### Поведение

- [ ] Нажатие на **всю строку** диска открывает файловый менеджер
- [ ] Подсветка строки при наведении работает
- [ ] Настройки: изменение прозрачности, ширины перехода, кривой — применяются без перезапуска
- [ ] После подключения внешнего диска он появляется автоматически
- [ ] После отключения строка исчезает

### Масштаб и DPI

- [ ] Виджет нормально выглядит на 100% масштабе
- [ ] Виджет нормально выглядит на 125% / 150% масштабе (если доступно)

## Сбор журнала при ошибке

```bash
journalctl --user -b | grep -Ei 'plasmashell|drivecard|qml' | tail -50
```

Перед публикацией удалите из вывода домашние пути, имена пользователя и UUID. В журнале могут быть строки от других приложений и обоев — нужны только строки с `drivecard`.

## Удаление после тестирования

```bash
bash scripts/uninstall.sh
```

Или вручную:

```bash
kpackagetool6 --type Plasma/Applet --remove io.github.cachyos.drivecard
```

## Авторы

Разработчик: aliksandrkarankevich-sudo. Соавтор: Perplexity AI.
