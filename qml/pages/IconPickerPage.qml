import QtQuick 2.2
import Sailfish.Silica 1.0

Page {
  id: iconPickerPage

  signal iconPicked(string name)

  property string selectedIcon: ""
  property var allIcons: [
    "icon-m-about", "icon-m-add", "icon-m-alarm", "icon-m-answer", "icon-m-attach",
    "icon-m-back", "icon-m-backspace", "icon-m-backup", "icon-m-bluetooth",
    "icon-m-call", "icon-m-camera", "icon-m-car", "icon-m-charging",
    "icon-m-clear", "icon-m-clipboard", "icon-m-clock", "icon-m-close",
    "icon-m-cloud-download", "icon-m-cloud-upload", "icon-m-contact",
    "icon-m-date", "icon-m-delete", "icon-m-developer-mode", "icon-m-device-lock",
    "icon-m-dialpad", "icon-m-dismiss", "icon-m-display", "icon-m-document",
    "icon-m-edit", "icon-m-enter", "icon-m-enter-accept",
    "icon-m-enter-close", "icon-m-enter-next", "icon-m-events",
    "icon-m-favorite-selected",
    "icon-m-file-apk", "icon-m-file-audio", "icon-m-file-document",
    "icon-m-file-image", "icon-m-file-other", "icon-m-file-pdf",
    "icon-m-file-rpm", "icon-m-file-video",
    "icon-m-folder", "icon-m-forward", "icon-m-game-controller", "icon-m-gesture",
    "icon-m-gps", "icon-m-headset", "icon-m-health", "icon-m-home",
    "icon-m-image", "icon-m-keyboard", "icon-m-left", "icon-m-link", "icon-m-location",
    "icon-m-media", "icon-m-menu", "icon-m-message", "icon-m-mic", "icon-m-mic-mute",
    "icon-m-music", "icon-m-next", "icon-m-nfc", "icon-m-note", "icon-m-notifications",
    "icon-m-other", "icon-m-pause", "icon-m-phone", "icon-m-play", "icon-m-previous",
    "icon-m-question", "icon-m-refresh", "icon-m-reload", "icon-m-remove",
    "icon-m-right", "icon-m-rotate",
    "icon-m-search", "icon-m-select-all", "icon-m-send", "icon-m-setting", "icon-m-share",
    "icon-m-sms", "icon-m-speaker", "icon-m-speaker-on", "icon-m-stop",
    "icon-m-tablet", "icon-m-timer", "icon-m-toy", "icon-m-traffic", "icon-m-transfer",
    "icon-m-up", "icon-m-usb", "icon-m-vibration", "icon-m-video", "icon-m-voicemail",
    "icon-m-warning", "icon-m-wlan"
  ]

  property var failedIcons: ({})

  ListModel { id: filteredModel }

  Timer {
    id: rebuildTimer
    interval: 0
    repeat: false
    onTriggered: rebuildModel()
  }

  function rebuildModel() {
    filteredModel.clear()
    for (var i = 0; i < allIcons.length; i++) {
      if (!iconPickerPage.failedIcons[allIcons[i]]) {
        filteredModel.append({ "iconName": allIcons[i] })
      }
    }
  }

  SilicaGridView {
    id: gridView
    anchors.fill: parent

    cellWidth: Math.floor(width / 6)
    cellHeight: cellWidth

    model: filteredModel

    header: PageHeader { title: "Pick Icon" }

    delegate: BackgroundItem {
      id: cell
      width: gridView.cellWidth
      height: gridView.cellHeight

      property bool isCurrent: model.iconName === iconPickerPage.selectedIcon

      Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        color: Theme.highlightBackgroundColor
        opacity: isCurrent ? 0.3 : 0.0
        radius: Theme.paddingSmall
      }

      Icon {
        anchors.centerIn: parent
        source: "image://theme/" + model.iconName
        //width: gridView.cellWidth - Theme.paddingSmall
        //height: gridView.cellWidth - Theme.paddingSmall
        color: cell.highlighted || isCurrent ? Theme.highlightColor : Theme.primaryColor

        onStatusChanged: {
          if (status === Image.Error) {
            iconPickerPage.failedIcons[model.iconName] = true
            rebuildTimer.restart()
          }
        }
      }

      onClicked: {
        iconPickerPage.iconPicked(model.iconName)
        pageStack.pop()
      }
    }

    VerticalScrollDecorator {}
  }

  Component.onCompleted: rebuildModel()
}
