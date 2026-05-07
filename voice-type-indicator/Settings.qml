import QtQuick
import QtQuick.Layouts
import Quickshell
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
    property string visualStyle: saved.visualStyle || defaults.visualStyle || "orb"
    property var transcriptionDefaults: defaults.transcription ?? ({})
    property var transcriptionSaved: saved.transcription ?? ({})
    property string transcriptionProvider: transcriptionSaved.provider || transcriptionDefaults.provider || "deepgram"
    property string transcriptionModel: transcriptionSaved.model || transcriptionDefaults.model || "nova-3"
    property string transcriptionLanguage: transcriptionSaved.language || transcriptionDefaults.language || "ru"
    property var transcriptionApiKeys: transcriptionSaved.apiKeys || transcriptionDefaults.apiKeys || ({})
    property string deepgramApiKey: transcriptionApiKeys["deepgram"] !== undefined ? transcriptionApiKeys["deepgram"] : ""
    readonly property string envDeepgramApiKey: Quickshell.env("DEEPGRAM_API_KEY") || Quickshell.env("NOCTALIA_VOICE_TYPE_DEEPGRAM_API_KEY") || ""
    readonly property bool deepgramApiKeyManagedByEnv: envDeepgramApiKey !== ""

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
        text: "Voice indicator"
        pointSize: Style.fontSizeXL
        font.bold: true
    }

    NLabel {
        description: "Настройки маленького индикатора голосового ввода в верхней панели. Цвета вводятся HEX, например #b86cff."
        Layout.fillWidth: true
    }

    NDivider { Layout.fillWidth: true }

    NText {
        text: "Transcription"
        pointSize: Style.fontSizeM
        font.bold: true
    }

    NComboBox {
        Layout.fillWidth: true
        label: "STT provider"
        description: "Пока реализован Deepgram. Позже сюда добавим OpenRouter/OpenAI-compatible STT."
        model: [
            { key: "deepgram", name: "Deepgram" }
        ]
        currentKey: root.transcriptionProvider
        onSelected: function(key) {
            root.transcriptionProvider = key
            if ((root.transcriptionModel || "") === "")
                root.transcriptionModel = root.sttProviders[key]?.defaultModel || "nova-3"
        }
    }

    NTextInput {
        Layout.fillWidth: true
        label: "STT model"
        description: "Deepgram model name. Leave empty to use provider default."
        text: root.transcriptionModel === (root.sttProviders[root.transcriptionProvider]?.defaultModel || "") ? "" : root.transcriptionModel
        placeholderText: root.sttProviders[root.transcriptionProvider]?.defaultModel || "nova-3"
        onTextChanged: {
            var value = (text || "").trim()
            root.transcriptionModel = value === "" ? (root.sttProviders[root.transcriptionProvider]?.defaultModel || "nova-3") : value
        }
    }

    NTextInput {
        Layout.fillWidth: true
        label: "Language"
        description: "BCP-47/language code for STT, e.g. ru, en, auto."
        text: root.transcriptionLanguage
        placeholderText: "ru"
        onTextChanged: root.transcriptionLanguage = (text || "").trim() || "ru"
    }

    NTextInput {
        Layout.fillWidth: true
        visible: root.sttProviders[root.transcriptionProvider]?.requiresKey ?? true
        label: "Deepgram API key"
        description: root.deepgramApiKeyManagedByEnv ? "Managed by environment variable" : "Stored in local Noctalia plugin settings. Get a key: https://console.deepgram.com/"
        placeholderText: root.deepgramApiKeyManagedByEnv ? "Set via DEEPGRAM_API_KEY / NOCTALIA_VOICE_TYPE_DEEPGRAM_API_KEY" : "Enter Deepgram API key..."
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

    NComboBox {
        Layout.fillWidth: true
        label: "Стиль индикатора"
        description: "Orb — переливающийся шар. Wave — цветовые столбики с нормальным распределением."
        model: [
            { key: "orb", name: "Siri orb" },
            { key: "wave", name: "Color wave" }
        ]
        currentKey: root.visualStyle
        onSelected: key => root.visualStyle = key
    }

    NLabel {
        label: "Размер точки"
        description: Math.round(root.dotScale * 100) + "% высоты панели"
    }

    NSlider {
        Layout.fillWidth: true
        from: 0.22
        to: 0.70
        stepSize: 0.01
        value: root.dotScale
        onValueChanged: root.dotScale = value
    }

    NLabel {
        label: "Ширина капсулы при записи"
        description: Math.round(root.activeWidthScale * 100) + "% высоты панели"
    }

    NSlider {
        Layout.fillWidth: true
        from: 0.55
        to: 1.80
        stepSize: 0.01
        value: root.activeWidthScale
        onValueChanged: root.activeWidthScale = value
    }

    NLabel {
        label: "Прозрачность idle-точки"
        description: Math.round(root.idleOpacity * 100) + "%"
    }

    NSlider {
        Layout.fillWidth: true
        from: 0.10
        to: 1.00
        stepSize: 0.01
        value: root.idleOpacity
        onValueChanged: root.idleOpacity = value
    }

    NToggle {
        Layout.fillWidth: true
        label: "Показывать точку в idle"
        description: "Если выключить, индикатор будет появляться только во время записи/обработки."
        checked: root.showIdle
        onToggled: checked => root.showIdle = checked
    }

    NToggle {
        Layout.fillWidth: true
        label: "Пульсация при записи"
        checked: root.pulse
        onToggled: checked => root.pulse = checked
    }

    NDivider { Layout.fillWidth: true }

    NLabel { label: "Цвета"; description: "Нажимай на готовые цветные плашки или впиши HEX вручную." }

    GridLayout {
        Layout.fillWidth: true
        columns: 5
        rowSpacing: Style.marginS
        columnSpacing: Style.marginM

        NLabel { label: "Recording" }
        Repeater { model: ["#b86cff", "#ff4f8b", "#7c5cff", "#2de2e6"] ; Rectangle { width: 26; height: 18; radius: 9; color: modelData; border.color: root.recordingColor === modelData ? Color.mOnSurface : "transparent"; border.width: 2; MouseArea { anchors.fill: parent; onClicked: root.recordingColor = modelData } } }
        NTextInput { Layout.fillWidth: true; text: root.recordingColor; onTextChanged: root.recordingColor = text }

        NLabel { label: "Processing" }
        Repeater { model: ["#5da9ff", "#2de2e6", "#7c5cff", "#31d0aa"] ; Rectangle { width: 26; height: 18; radius: 9; color: modelData; border.color: root.processingColor === modelData ? Color.mOnSurface : "transparent"; border.width: 2; MouseArea { anchors.fill: parent; onClicked: root.processingColor = modelData } } }
        NTextInput { Layout.fillWidth: true; text: root.processingColor; onTextChanged: root.processingColor = text }

        NLabel { label: "Success" }
        Repeater { model: ["#6be675", "#31d0aa", "#a7ff83", "#2fb85d"] ; Rectangle { width: 26; height: 18; radius: 9; color: modelData; border.color: root.successColor === modelData ? Color.mOnSurface : "transparent"; border.width: 2; MouseArea { anchors.fill: parent; onClicked: root.successColor = modelData } } }
        NTextInput { Layout.fillWidth: true; text: root.successColor; onTextChanged: root.successColor = text }

        NLabel { label: "Error" }
        Repeater { model: ["#ff6b6b", "#ff4f8b", "#c0392b", "#ffb86b"] ; Rectangle { width: 26; height: 18; radius: 9; color: modelData; border.color: root.errorColor === modelData ? Color.mOnSurface : "transparent"; border.width: 2; MouseArea { anchors.fill: parent; onClicked: root.errorColor = modelData } } }
        NTextInput { Layout.fillWidth: true; text: root.errorColor; onTextChanged: root.errorColor = text }

        NLabel { label: "Idle" }
        Repeater { model: ["#6f7480", "#4b5563", "#8b949e", "#3a3f4b"] ; Rectangle { width: 26; height: 18; radius: 9; color: modelData; border.color: root.idleColor === modelData ? Color.mOnSurface : "transparent"; border.width: 2; MouseArea { anchors.fill: parent; onClicked: root.idleColor = modelData } } }
        NTextInput { Layout.fillWidth: true; text: root.idleColor; onTextChanged: root.idleColor = text }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Style.marginM
        NLabel { label: "Preview" }
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
            "language": root.transcriptionLanguage || "ru",
            "apiKeys": root.transcriptionApiKeys
        }
        pluginApi.saveSettings()
        return pluginApi.pluginSettings
    }
}
