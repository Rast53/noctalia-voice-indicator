import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""
    property int sectionWidgetIndex: -1
    property int sectionWidgetsCount: 0

    property string voiceState: "idle"
    property string tooltip: localizedState("idle")
    readonly property string localeName: (Qt.locale().name || Quickshell.env("LANG") || "en").toLowerCase()
    readonly property bool isRu: localeName.indexOf("ru") === 0

    function tr(en, ru) { return root.isRu ? ru : en }

    function localizedState(state) {
        if (state === "recording") return tr("Voice input: recording", "Голосовой ввод: запись")
        if (state === "processing") return tr("Voice input: processing", "Голосовой ввод: обработка")
        if (state === "success") return tr("Voice input: success", "Голосовой ввод: готово")
        if (state === "error") return tr("Voice input: error", "Голосовой ввод: ошибка")
        return tr("Voice input: idle", "Голосовой ввод: ожидание")
    }

    readonly property var cfg: pluginApi?.pluginSettings ?? ({})
    readonly property var defaults: pluginApi?.manifest?.metadata?.defaultSettings ?? ({})

    readonly property real dotScale: Number(cfg.dotScale ?? defaults.dotScale ?? 0.38)
    readonly property real activeWidthScale: Number(cfg.activeWidthScale ?? defaults.activeWidthScale ?? 0.92)
    readonly property real idleOpacity: Number(cfg.idleOpacity ?? defaults.idleOpacity ?? 0.55)
    readonly property bool showIdle: cfg.showIdle ?? defaults.showIdle ?? true
    readonly property bool pulse: cfg.pulse ?? defaults.pulse ?? true
    readonly property string visualStyle: cfg.visualStyle || defaults.visualStyle || "orb"

    readonly property string recordingColor: cfg.recordingColor || defaults.recordingColor || "#b86cff"
    readonly property string processingColor: cfg.processingColor || defaults.processingColor || "#5da9ff"
    readonly property string successColor: cfg.successColor || defaults.successColor || "#6be675"
    readonly property string errorColor: cfg.errorColor || defaults.errorColor || "#ff6b6b"
    readonly property string idleColor: cfg.idleColor || defaults.idleColor || "#6f7480"

    readonly property string screenName: screen ? screen.name : ""
    readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
    readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
    readonly property real dotSize: Math.max(8, capsuleHeight * dotScale)
    readonly property bool active: voiceState !== "idle"

    implicitWidth: (!showIdle && !active) ? 0 : Math.max(capsuleHeight * 0.72, active ? capsuleHeight * activeWidthScale : dotSize + Style.marginS)
    implicitHeight: capsuleHeight
    visible: showIdle || active

    function parseState(text) {
        try {
            const data = JSON.parse(text || "{}");
            let s = data.state || "idle";
            if (s === "hidden" || s === "ready") s = "idle";
            root.voiceState = s;
            root.tooltip = root.localizedState(s);
        } catch (e) {
            root.voiceState = "error";
            root.tooltip = root.tr("Voice input: state read error", "Голосовой ввод: ошибка чтения состояния");
        }
    }

    function stateColor() {
        if (voiceState === "recording") return recordingColor;
        if (voiceState === "processing") return processingColor;
        if (voiceState === "success") return successColor;
        if (voiceState === "error") return errorColor;
        return idleColor;
    }

    FileView {
        id: stateFile
        path: "/tmp/voice-type-state.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.parseState(text())
        onLoadFailed: function(error) {
            root.voiceState = "idle";
            root.tooltip = root.localizedState("idle");
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: stateFile.reload()
    }

    Item {
        id: visualWrap
        anchors.centerIn: parent
        width: root.active ? root.capsuleHeight * root.activeWidthScale : root.dotSize
        height: root.dotSize
        opacity: root.active ? 1.0 : root.idleOpacity

        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 140 } }

        // Style 1: tiny Siri-like orb with moving blobs.
        Item {
            id: orbWrap
            anchors.fill: parent
            visible: root.visualStyle === "orb"
            scale: 1.0

            SequentialAnimation on scale {
                running: root.visualStyle === "orb" && root.pulse && root.voiceState === "recording"
                loops: Animation.Infinite
                NumberAnimation { to: 1.13; duration: 620; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.98; duration: 620; easing.type: Easing.InOutSine }
            }

            Rectangle {
                id: orb
                anchors.fill: parent
                radius: height / 2
                clip: true
                color: root.voiceState === "idle" ? root.idleColor : "#18131f"
                border.color: root.active ? Qt.rgba(1, 1, 1, 0.18) : Style.capsuleBorderColor
                border.width: root.active ? 1 : Style.capsuleBorderWidth
                Behavior on color { ColorAnimation { duration: 160 } }

                Rectangle {
                    id: blobA
                    width: orb.width * 0.82; height: orb.height * 1.45
                    radius: Math.min(width, height) / 2
                    x: orb.width * (root.voiceState === "recording" ? -0.24 : -0.12)
                    y: orb.height * -0.22
                    color: root.recordingColor
                    opacity: root.voiceState === "idle" ? 0.30 : 0.88
                    SequentialAnimation on x {
                        running: root.visualStyle === "orb" && root.voiceState === "recording"
                        loops: Animation.Infinite
                        NumberAnimation { to: orb.width * 0.18; duration: 900; easing.type: Easing.InOutSine }
                        NumberAnimation { to: orb.width * -0.24; duration: 900; easing.type: Easing.InOutSine }
                    }
                }

                Rectangle {
                    id: blobB
                    width: orb.width * 0.72; height: orb.height * 1.32
                    radius: Math.min(width, height) / 2
                    x: orb.width * 0.34
                    y: orb.height * -0.14
                    color: root.processingColor
                    opacity: root.voiceState === "idle" ? 0.22 : 0.76
                    SequentialAnimation on y {
                        running: root.visualStyle === "orb" && root.voiceState === "recording"
                        loops: Animation.Infinite
                        NumberAnimation { to: orb.height * 0.03; duration: 760; easing.type: Easing.InOutSine }
                        NumberAnimation { to: orb.height * -0.18; duration: 760; easing.type: Easing.InOutSine }
                    }
                }

                Rectangle {
                    id: blobC
                    width: orb.width * 0.58; height: orb.height * 1.08
                    radius: Math.min(width, height) / 2
                    x: orb.width * 0.12
                    y: orb.height * 0.05
                    color: root.successColor
                    opacity: root.voiceState === "success" ? 0.90 : (root.voiceState === "idle" ? 0.10 : 0.44)
                    SequentialAnimation on x {
                        running: root.visualStyle === "orb" && root.voiceState === "recording"
                        loops: Animation.Infinite
                        NumberAnimation { to: orb.width * -0.02; duration: 1080; easing.type: Easing.InOutSine }
                        NumberAnimation { to: orb.width * 0.24; duration: 1080; easing.type: Easing.InOutSine }
                    }
                }

                Rectangle { visible: root.voiceState === "error"; anchors.fill: parent; radius: height / 2; color: root.errorColor; opacity: 0.82 }
                Rectangle { width: orb.width * 0.38; height: orb.height * 0.30; radius: height / 2; x: orb.width * 0.18; y: orb.height * 0.16; color: "#ffffff"; opacity: root.active ? 0.24 : 0.10 }
            }
        }

        // Style 2: compact color wave with gaussian-like bar heights.
        Row {
            id: waveWrap
            anchors.centerIn: parent
            visible: root.visualStyle === "wave"
            spacing: Math.max(1, visualWrap.width * 0.045)

            Repeater {
                model: [0.20, 0.42, 0.72, 1.00, 0.72, 0.42, 0.20]
                Rectangle {
                    required property real modelData
                    width: Math.max(2, visualWrap.width * 0.085)
                    height: Math.max(3, visualWrap.height * modelData * (root.voiceState === "idle" ? 0.72 : 1.0))
                    anchors.verticalCenter: parent.verticalCenter
                    radius: width / 2
                    color: {
                        if (root.voiceState === "processing") return root.processingColor;
                        if (root.voiceState === "success") return root.successColor;
                        if (root.voiceState === "error") return root.errorColor;
                        if (root.voiceState === "idle") return root.idleColor;
                        const colors = [root.processingColor, root.recordingColor, root.successColor, root.recordingColor, root.processingColor];
                        return colors[index % colors.length];
                    }
                    opacity: root.voiceState === "idle" ? 0.45 : 0.96

                    SequentialAnimation on height {
                        running: root.visualStyle === "wave" && root.voiceState === "recording" && root.pulse
                        loops: Animation.Infinite
                        PauseAnimation { duration: index * 70 }
                        NumberAnimation { to: Math.max(3, visualWrap.height * (0.25 + modelData * 0.88)); duration: 360; easing.type: Easing.InOutSine }
                        NumberAnimation { to: Math.max(3, visualWrap.height * modelData * 0.58); duration: 430; easing.type: Easing.InOutSine }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: TooltipService.show(root, root.tooltip, BarService.getTooltipDirection(root.screenName))
        onExited: TooltipService.hide()
    }
}
