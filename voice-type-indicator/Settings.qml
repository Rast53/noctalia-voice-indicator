import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

ColumnLayout {
    id: root
    property var pluginApi: null

    readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings ?? ({})
    readonly property var saved: pluginApi?.pluginSettings ?? ({})

    property real dotScale: Number(saved.dotScale ?? defaults.dotScale ?? 0.38)
    property real activeWidthScale: Number(saved.activeWidthScale ?? defaults.activeWidthScale ?? 0.92)
    property real idleOpacity: Number(saved.idleOpacity ?? defaults.idleOpacity ?? 0.55)
    property string recordingColor: saved.recordingColor || defaults.recordingColor || "#b86cff"
    property string processingColor: saved.processingColor || defaults.processingColor || "#5da9ff"
    property string successColor: saved.successColor || defaults.successColor || "#6be675"
    property string errorColor: saved.errorColor || defaults.errorColor || "#ff6b6b"
    property string idleColor: saved.idleColor || defaults.idleColor || "#6f7480"
    property bool showIdle: saved.showIdle ?? defaults.showIdle ?? true
    property bool pulse: saved.pulse ?? defaults.pulse ?? true
    property string visualStyle: saved.visualStyle || defaults.visualStyle || "wave"
    property var transcriptionDefaults: defaults.transcription ?? ({})
    property var transcriptionSaved: saved.transcription ?? ({})
    property string transcriptionProvider: transcriptionSaved.provider || transcriptionDefaults.provider || "deepgram"
    property string transcriptionModel: transcriptionSaved.model || transcriptionDefaults.model || "nova-3"
    property string transcriptionLanguage: transcriptionSaved.language || transcriptionDefaults.language || defaultSttLanguage()
    property var transcriptionApiKeys: transcriptionSaved.apiKeys || transcriptionDefaults.apiKeys || ({})
    property string deepgramApiKey: transcriptionApiKeys["deepgram"] !== undefined ? transcriptionApiKeys["deepgram"] : ""
    readonly property string envDeepgramApiKey: Quickshell.env("DEEPGRAM_API_KEY") || Quickshell.env("NOCTALIA_VOICE_TYPE_DEEPGRAM_API_KEY") || ""
    readonly property bool deepgramApiKeyManagedByEnv: envDeepgramApiKey !== ""

    readonly property string localeName: (Qt.locale().name || Quickshell.env("LANG") || "en").toLowerCase()
    readonly property bool isRu: localeName.indexOf("ru") === 0
    readonly property string repoUrl: "https://github.com/Rast53/noctalia-voice-indicator"
    readonly property string installCommand: "curl -fsSL https://raw.githubusercontent.com/Rast53/noctalia-voice-indicator/main/scripts/setup-cachyos.sh | bash"
    readonly property string syncCommand: "noctalia-voice-type sync-noctalia-settings"
    readonly property string niriCommand: "noctalia-voice-type niri-snippet"

    property string setupStatus: tr("Checking setup status...", "Проверяю настройку...")
    property bool setupCheckDone: false
    property bool cliInstalled: false

    function tr(en, ru) { return root.isRu ? ru : en }
    function defaultSttLanguage() { return root.isRu ? "ru" : "en" }
    function pct(value) { return Math.round(value * 100) + "%" }

    Process {
        id: setupCheckProcess
        command: ["bash", "-lc", "noctalia-voice-type doctor --human 2>&1 || true"]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        onExited: function(exitCode) {
            var out = stdout.text || ""
            root.cliInstalled = out.indexOf("CLI executable") >= 0 || out.indexOf("cli_executable=OK") >= 0
            root.setupCheckDone = true
            root.setupStatus = out.trim() || stderr.text.trim() || root.tr("No setup information available. Install the CLI first.", "Нет данных о настройке. Сначала установите CLI.")
        }
    }

    Process {
        id: copyProcess
        command: ["wl-copy"]
        stdinEnabled: true
        property string pendingText: ""
        onStarted: {
            write(pendingText)
            pendingText = ""
            stdinEnabled = false
        }
    }

    function copyToClipboard(text) {
        copyProcess.pendingText = text
        copyProcess.stdinEnabled = true
        copyProcess.running = true
    }

    Component.onCompleted: setupCheckProcess.running = true

    readonly property var sttProviders: ({
        "deepgram": {
            "name": "Deepgram",
            "defaultModel": "nova-3",
            "requiresKey": true,
            "keyUrl": "https://console.deepgram.com/"
        }
    })

    spacing: Style.marginM

    NText {
        text: root.tr("Voice Type", "Голосовой ввод")
        pointSize: Style.fontSizeXL
        font.bold: true
    }

    NLabel {
        description: root.tr(
            "Noctalia bar indicator and setup checklist for local voice dictation. The interface follows your system language: Russian locale uses Russian, everything else uses English.",
            "Индикатор в панели Noctalia и чеклист настройки локального голосового ввода. Интерфейс берёт язык из системы: русская локаль — русский, остальные — английский."
        )
        Layout.fillWidth: true
    }

    NDivider { Layout.fillWidth: true }

    NText { text: root.tr("Setup", "Настройка"); pointSize: Style.fontSizeM; font.bold: true }

    NLabel {
        label: root.cliInstalled ? root.tr("CLI detected", "CLI найден") : root.tr("CLI is not installed yet", "CLI ещё не установлен")
        description: root.tr(
            "The plugin is the visual shell. Real dictation also needs the local CLI, system tools, a Deepgram key, and niri keybinds.",
            "Плагин — это визуальная часть. Для настоящей диктовки нужны локальный CLI, системные утилиты, ключ Deepgram и бинды niri."
        )
        Layout.fillWidth: true
    }

    NTextInput {
        Layout.fillWidth: true
        label: root.tr("1. Install local CLI and system dependencies", "1. Установить локальный CLI и системные зависимости")
        description: root.tr(
            "Run once in a terminal. It is safe to re-run: it updates the repo, preserves your env file, creates the state file, and prints next steps.",
            "Запустите один раз в терминале. Команду можно повторять: она обновит репозиторий, сохранит env-файл, создаст state-file и покажет следующие шаги."
        )
        text: root.installCommand
        readOnly: true
        showClearButton: false
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM
        NButton { text: root.tr("Copy install command", "Скопировать установку"); icon: "copy"; onClicked: root.copyToClipboard(root.installCommand) }
        NButton { text: root.tr("Refresh setup status", "Обновить статус"); icon: "refresh"; outlined: true; onClicked: setupCheckProcess.running = true }
    }

    NTextInput {
        Layout.fillWidth: true
        label: root.tr("2. Sync plugin STT settings to CLI", "2. Синхронизировать STT-настройки плагина в CLI")
        description: root.tr(
            "If you enter the Deepgram key below, run this after saving settings so the CLI env file receives provider/model/language/key values.",
            "Если вы вводите ключ Deepgram ниже, после сохранения настроек выполните это — CLI env получит provider/model/language/key."
        )
        text: root.syncCommand
        readOnly: true
        showClearButton: false
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM
        NButton { text: root.tr("Copy sync command", "Скопировать синхронизацию"); icon: "copy"; onClicked: root.copyToClipboard(root.syncCommand) }
    }

    NTextInput {
        Layout.fillWidth: true
        label: root.tr("3. Add niri keybinds", "3. Добавить бинды niri")
        description: root.tr(
            "Run this and paste the snippet into ~/.config/niri/config.kdl. Defaults: F12 = short dictation, F11 = long dictation.",
            "Выполните команду и вставьте snippet в ~/.config/niri/config.kdl. По умолчанию: F12 = короткая диктовка, F11 = длинная."
        )
        text: root.niriCommand
        readOnly: true
        showClearButton: false
    }

    RowLayout { Layout.fillWidth: true; spacing: Style.marginM; NButton { text: root.tr("Copy niri command", "Скопировать niri-команду"); icon: "copy"; onClicked: root.copyToClipboard(root.niriCommand) } }

    NTextInput {
        Layout.fillWidth: true
        label: root.tr("Setup status / doctor", "Статус настройки / doctor")
        description: root.tr("Local diagnostics from this session. It never prints secrets.", "Локальная диагностика текущей сессии. Секреты не выводятся.")
        text: root.setupStatus
        readOnly: true
        showClearButton: false
    }

    NDivider { Layout.fillWidth: true }

    NText { text: root.tr("Transcription", "Распознавание"); pointSize: Style.fontSizeM; font.bold: true }

    NComboBox {
        Layout.fillWidth: true
        label: root.tr("STT provider", "Провайдер STT")
        description: root.tr("Deepgram is stable now. OpenRouter/OpenAI-compatible STT is planned.", "Сейчас стабильно реализован Deepgram. OpenRouter/OpenAI-compatible STT — в плане.")
        model: [{ key: "deepgram", name: "Deepgram" }]
        currentKey: root.transcriptionProvider
        onSelected: function(key) {
            root.transcriptionProvider = key
            if ((root.transcriptionModel || "") === "") root.transcriptionModel = root.sttProviders[key]?.defaultModel || "nova-3"
        }
    }

    NTextInput {
        Layout.fillWidth: true
        label: root.tr("STT model", "Модель STT")
        description: root.tr("Deepgram model name. Leave empty to use provider default.", "Название модели Deepgram. Оставьте пустым для значения по умолчанию.")
        text: root.transcriptionModel === (root.sttProviders[root.transcriptionProvider]?.defaultModel || "") ? "" : root.transcriptionModel
        placeholderText: root.sttProviders[root.transcriptionProvider]?.defaultModel || "nova-3"
        onTextChanged: {
            var value = (text || "").trim()
            root.transcriptionModel = value === "" ? (root.sttProviders[root.transcriptionProvider]?.defaultModel || "nova-3") : value
        }
    }

    NTextInput {
        Layout.fillWidth: true
        label: root.tr("Language", "Язык")
        description: root.tr("BCP-47/language code for STT, e.g. ru, en, auto.", "Код языка для STT: ru, en, auto и т.п.")
        text: root.transcriptionLanguage
        placeholderText: root.defaultSttLanguage()
        onTextChanged: root.transcriptionLanguage = (text || "").trim() || root.defaultSttLanguage()
    }

    NTextInput {
        Layout.fillWidth: true
        visible: root.sttProviders[root.transcriptionProvider]?.requiresKey ?? true
        label: root.tr("Deepgram API key", "API-ключ Deepgram")
        description: root.deepgramApiKeyManagedByEnv ? root.tr("Managed by environment variable", "Управляется переменной окружения") : root.tr("Stored only in local Noctalia plugin settings. Get a key: https://console.deepgram.com/", "Хранится только в локальных настройках плагина Noctalia. Ключ: https://console.deepgram.com/")
        placeholderText: root.deepgramApiKeyManagedByEnv ? "DEEPGRAM_API_KEY / NOCTALIA_VOICE_TYPE_DEEPGRAM_API_KEY" : root.tr("Enter Deepgram API key...", "Введите API-ключ Deepgram...")
        text: root.deepgramApiKeyManagedByEnv ? "" : root.deepgramApiKey
        enabled: !root.deepgramApiKeyManagedByEnv
        inputMethodHints: Qt.ImhHiddenText
        onTextChanged: {
            if (!root.deepgramApiKeyManagedByEnv) {
                root.deepgramApiKey = text
                root.transcriptionApiKeys = Object.assign({}, root.transcriptionApiKeys, { "deepgram": text })
            }
        }
    }

    NDivider { Layout.fillWidth: true }

    NText { text: root.tr("Indicator", "Индикатор"); pointSize: Style.fontSizeM; font.bold: true }

    NComboBox {
        Layout.fillWidth: true
        label: root.tr("Indicator style", "Стиль индикатора")
        description: root.tr("Orb is a glowing dot. Wave is animated color bars.", "Orb — светящаяся точка. Wave — анимированные цветные столбики.")
        model: [
            { key: "orb", name: root.tr("Siri orb", "Siri-шар") },
            { key: "wave", name: root.tr("Color wave", "Цветовая волна") }
        ]
        currentKey: root.visualStyle
        onSelected: key => root.visualStyle = key
    }

    NLabel { label: root.tr("Dot size", "Размер точки"); description: root.pct(root.dotScale) + root.tr(" of bar height", " высоты панели") }
    NSlider { Layout.fillWidth: true; from: 0.22; to: 0.70; stepSize: 0.01; value: root.dotScale; onValueChanged: root.dotScale = value }

    NLabel { label: root.tr("Recording capsule width", "Ширина капсулы при записи"); description: root.pct(root.activeWidthScale) + root.tr(" of bar height", " высоты панели") }
    NSlider { Layout.fillWidth: true; from: 0.55; to: 1.80; stepSize: 0.01; value: root.activeWidthScale; onValueChanged: root.activeWidthScale = value }

    NLabel { label: root.tr("Idle dot opacity", "Прозрачность idle-точки"); description: root.pct(root.idleOpacity) }
    NSlider { Layout.fillWidth: true; from: 0.10; to: 1.00; stepSize: 0.01; value: root.idleOpacity; onValueChanged: root.idleOpacity = value }

    NToggle {
        Layout.fillWidth: true
        label: root.tr("Show idle dot", "Показывать точку в idle")
        description: root.tr("When disabled, the indicator appears only while recording or processing.", "Если выключить, индикатор появляется только во время записи или обработки.")
        checked: root.showIdle
        onToggled: checked => root.showIdle = checked
    }

    NToggle { Layout.fillWidth: true; label: root.tr("Pulse while recording", "Пульсация при записи"); checked: root.pulse; onToggled: checked => root.pulse = checked }

    NDivider { Layout.fillWidth: true }

    NLabel { label: root.tr("Colors", "Цвета"); description: root.tr("Pick a preset or enter HEX manually.", "Нажмите готовую плашку или введите HEX вручную.") }

    GridLayout {
        Layout.fillWidth: true
        columns: 5
        rowSpacing: Style.marginS
        columnSpacing: Style.marginM

        NLabel { label: root.tr("Recording", "Запись") }
        Repeater { model: ["#b86cff", "#ff4f8b", "#7c5cff", "#2de2e6"] ; Rectangle { width: 26; height: 18; radius: 9; color: modelData; border.color: root.recordingColor === modelData ? Color.mOnSurface : "transparent"; border.width: 2; MouseArea { anchors.fill: parent; onClicked: root.recordingColor = modelData } } }
        NTextInput { Layout.fillWidth: true; text: root.recordingColor; onTextChanged: root.recordingColor = text }

        NLabel { label: root.tr("Processing", "Обработка") }
        Repeater { model: ["#5da9ff", "#2de2e6", "#7c5cff", "#31d0aa"] ; Rectangle { width: 26; height: 18; radius: 9; color: modelData; border.color: root.processingColor === modelData ? Color.mOnSurface : "transparent"; border.width: 2; MouseArea { anchors.fill: parent; onClicked: root.processingColor = modelData } } }
        NTextInput { Layout.fillWidth: true; text: root.processingColor; onTextChanged: root.processingColor = text }

        NLabel { label: root.tr("Success", "Успех") }
        Repeater { model: ["#6be675", "#31d0aa", "#a7ff83", "#2fb85d"] ; Rectangle { width: 26; height: 18; radius: 9; color: modelData; border.color: root.successColor === modelData ? Color.mOnSurface : "transparent"; border.width: 2; MouseArea { anchors.fill: parent; onClicked: root.successColor = modelData } } }
        NTextInput { Layout.fillWidth: true; text: root.successColor; onTextChanged: root.successColor = text }

        NLabel { label: root.tr("Error", "Ошибка") }
        Repeater { model: ["#ff6b6b", "#ff4f8b", "#c0392b", "#ffb86b"] ; Rectangle { width: 26; height: 18; radius: 9; color: modelData; border.color: root.errorColor === modelData ? Color.mOnSurface : "transparent"; border.width: 2; MouseArea { anchors.fill: parent; onClicked: root.errorColor = modelData } } }
        NTextInput { Layout.fillWidth: true; text: root.errorColor; onTextChanged: root.errorColor = text }

        NLabel { label: "Idle" }
        Repeater { model: ["#6f7480", "#4b5563", "#8b949e", "#3a3f4b"] ; Rectangle { width: 26; height: 18; radius: 9; color: modelData; border.color: root.idleColor === modelData ? Color.mOnSurface : "transparent"; border.width: 2; MouseArea { anchors.fill: parent; onClicked: root.idleColor = modelData } } }
        NTextInput { Layout.fillWidth: true; text: root.idleColor; onTextChanged: root.idleColor = text }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM
        NLabel { label: root.tr("Preview", "Предпросмотр") }
        Rectangle { width: 24; height: 14; radius: 7; color: root.recordingColor }
        Rectangle { width: 24; height: 14; radius: 7; color: root.processingColor }
        Rectangle { width: 24; height: 14; radius: 7; color: root.successColor }
        Rectangle { width: 24; height: 14; radius: 7; color: root.errorColor }
        Rectangle { width: 14; height: 14; radius: 7; color: root.idleColor; opacity: root.idleOpacity }
    }

    function saveSettings() {
        pluginApi.pluginSettings.visualStyle = root.visualStyle
        pluginApi.pluginSettings.dotScale = root.dotScale
        pluginApi.pluginSettings.activeWidthScale = root.activeWidthScale
        pluginApi.pluginSettings.idleOpacity = root.idleOpacity
        pluginApi.pluginSettings.recordingColor = root.recordingColor
        pluginApi.pluginSettings.processingColor = root.processingColor
        pluginApi.pluginSettings.successColor = root.successColor
        pluginApi.pluginSettings.errorColor = root.errorColor
        pluginApi.pluginSettings.idleColor = root.idleColor
        pluginApi.pluginSettings.showIdle = root.showIdle
        pluginApi.pluginSettings.pulse = root.pulse
        pluginApi.pluginSettings.transcription = {
            "provider": root.transcriptionProvider,
            "model": root.transcriptionModel || (root.sttProviders[root.transcriptionProvider]?.defaultModel || "nova-3"),
            "language": root.transcriptionLanguage || root.defaultSttLanguage(),
            "apiKeys": root.transcriptionApiKeys
        }
        pluginApi.saveSettings()
        return pluginApi.pluginSettings
    }
}
