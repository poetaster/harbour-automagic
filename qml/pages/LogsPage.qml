import QtQuick 2.2
import Sailfish.Silica 1.0

Item {
  id: logs_page

  ListModel { id: full_log_model }

  SilicaListView {
    id: list_view
    anchors.fill: parent

    PullDownMenu {
      MenuItem {
        text: "Settings"
        onClicked: pageStack.push(Qt.resolvedUrl("SettingsDialog.qml"))
      }
      MenuItem {
        text: "Export to Folder"
        onClicked: pageStack.push(Qt.resolvedUrl("ExportDialog.qml"), { mode: "export" })
      }
      MenuItem {
        text: "Upload to Library"
        visible: !!(app.settings && app.settings.library_token && app.settings.display_name)
        onClicked: pageStack.push(Qt.resolvedUrl("ExportDialog.qml"), { mode: "upload" })
      }
      MenuItem {
        text: "Import"
        onClicked: pageStack.push(Qt.resolvedUrl("ImportPage.qml"))
      }
      MenuItem {
        text: "Reload Daemon"
        onClicked: python.daemon_reload()
      }
    }

    header: Item {
      width: parent.width
      height: Theme.itemSizeLarge + Theme.paddingLarge

      Item {
        anchors {
          bottom: parent.bottom
          bottomMargin: Theme.paddingMedium
          left: parent.left
          right: parent.right
        }
        height: logs_header_btn.height

        SecondaryButton {
          id: logs_header_btn
          preferredWidth: parent.width
          text: "Log"
          layoutDirection: Qt.RightToLeft
          anchors {
            verticalCenter: parent.verticalCenter
            horizontalCenter: parent.horizontalCenter
          }
          onClicked: pageStack.push(Qt.resolvedUrl("RemotePickerPage.qml"))
        }

        Icon {
          source: "../../icons/arrow_forward.svg"
          height: 60
          width: height
          anchors {
            verticalCenter: logs_header_btn.verticalCenter
            right: logs_header_btn.right
            rightMargin: Theme.paddingLarge
          }
        }
      }
    }

    model: full_log_model

    delegate: ListItem {
      contentHeight: logCol.height + Theme.paddingLarge
      
      Column {
        id: logCol
        width: parent.width - (Theme.horizontalPageMargin * 2)
        x: Theme.horizontalPageMargin
        anchors.verticalCenter: parent.verticalCenter
        
        Label {
          text: log_time + " | " + log_flow
          font.pixelSize: Theme.fontSizeExtraSmall
          color: Theme.secondaryHighlightColor
          truncationMode: TruncationMode.Fade
          width: parent.width
        }
        Label {
          text: log_msg
          font.pixelSize: Theme.fontSizeExtraSmall
          color: Theme.primaryColor
          wrapMode: Text.Wrap
          width: parent.width
        }
      }
      
      Separator {
        width: parent.width
        color: Theme.primaryColor
        opacity: 0.1
        anchors.bottom: parent.bottom
      }
    }

    ViewPlaceholder {
      enabled: list_view.count < 1
      text: "No logs received yet"
    }

    VerticalScrollDecorator {}
  }

  Rectangle {
    anchors {
      left: parent.left
      right: parent.right
      bottom: parent.bottom
    }
    height: disconnected_label.height + Theme.paddingMedium * 2
    color: Theme.rgba(Theme.highlightBackgroundColor, 0.8)
    opacity: app.connected ? 0.0 : 1.0
    visible: opacity > 0

    Behavior on opacity { FadeAnimation {} }

    Label {
      id: disconnected_label
      anchors.centerIn: parent
      text: "Daemon disconnected"
      color: Theme.highlightColor
      font.pixelSize: Theme.fontSizeSmall
    }
  }

  Component.onCompleted: {
    app.signal_log_received.connect(handle_log_received)
  }

  Component.onDestruction: {
    app.signal_log_received.disconnect(handle_log_received)
  }

  function handle_log_received(flow_id, step_id, run_id, message) {
    var d = new Date()
    var h = ("0" + d.getHours()).slice(-2)
    var m = ("0" + d.getMinutes()).slice(-2)
    var s = ("0" + d.getSeconds()).slice(-2)
    var timeStr = h + ":" + m + ":" + s

    var flowName = String(flow_id || "unknown")
    if (app.flows) {
      for (var i = 0; i < app.flows.length; i++) {
        if (app.flows[i].id === flow_id) {
          flowName = app.flows[i].name || flow_id
          break
        }
      }
    }

    full_log_model.append({
      "log_time": timeStr,
      "log_flow": flowName,
      "log_msg": String(message || "")
    })

    var limit = (app.settings && app.settings.log_limit) ? app.settings.log_limit : 100
    while (full_log_model.count > limit) {
      full_log_model.remove(0)
    }
  }
}
