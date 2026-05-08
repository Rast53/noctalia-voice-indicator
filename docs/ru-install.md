# Установка Noctalia Voice Type

Цель: пользователь ставит плагин Noctalia, запускает одну команду установки CLI, добавляет ключ Deepgram и бинды niri — после этого F12/F11 работают без ручной магии.

## 1. Поставить плагин Noctalia

1. Откройте **Noctalia Settings → Plugins → Sources**.
2. Нажмите **Add plugin source**.
3. Укажите:
   - Repository Name: `Noctalia Voice Type`
   - Repository URL: `https://github.com/Rast53/noctalia-voice-indicator`
4. Обновите список плагинов.
5. Установите и включите **Voice Type Indicator**.
6. Если Noctalia не добавила виджет автоматически, добавьте в панель `plugin:voice-type-indicator`.

## 2. Установить локальный CLI

На CachyOS/Arch:

```bash
curl -fsSL https://raw.githubusercontent.com/Rast53/noctalia-voice-indicator/main/scripts/setup-cachyos.sh | bash
```

Скрипт можно запускать повторно. Он:

- ставит системные зависимости через `pacman`;
- клонирует/обновляет репозиторий в `~/.local/src/noctalia-voice-type`;
- ставит Python CLI в venv;
- создаёт `~/.config/noctalia-voice-type/env`, если файла ещё нет;
- создаёт state-file для индикатора;
- печатает диагностику и snippet для niri.

## 3. Добавить ключ Deepgram

Вариант А — через env-файл:

```bash
$EDITOR ~/.config/noctalia-voice-type/env
```

Заполните:

```env
DEEPGRAM_API_KEY=ваш-ключ
VOICE_TYPE_LANGUAGE=ru
```

Вариант Б — через настройки плагина Noctalia:

1. Введите ключ в поле **API-ключ Deepgram**.
2. Сохраните настройки.
3. Выполните:

```bash
noctalia-voice-type sync-noctalia-settings
```

Команда перенесёт provider/model/language/key в приватный CLI env-файл и не напечатает ключ.

## 4. Добавить бинды niri

```bash
noctalia-voice-type niri-snippet
```

Вставьте вывод в `~/.config/niri/config.kdl`, затем:

```bash
niri msg action load-config
```

По умолчанию:

- `F12` — короткая запись: нажал → говоришь → нажал ещё раз → текст вставился.
- `F11` — длинная диктовка: нажали один раз для старта; запись сама остановится после 10 секунд тишины, либо можно нажать F11 ещё раз вручную.

## 5. Проверить готовность

```bash
noctalia-voice-type doctor --human
```

Все обязательные пункты должны быть `OK`. Секреты команда не выводит.

## Локализация

Интерфейс плагина выбирает язык автоматически:

- системная локаль `ru*` → русский;
- любая другая локаль → английский.

Распознаваемый язык STT по умолчанию тоже берётся из локали при первом создании env-файла: `ru` для русской системы, `en` для остальных.
