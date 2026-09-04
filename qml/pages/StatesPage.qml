import QtQuick 2.2
import Sailfish.Silica 1.0

Item {
  id: states_page

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
      MenuItem {
        text: "Update States"
        onClicked: python.get_states()
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
        height: states_header_btn.height

        SecondaryButton {
          id: states_header_btn
          preferredWidth: parent.width
          text: "States"
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
            verticalCenter: states_header_btn.verticalCenter
            right: states_header_btn.right
            rightMargin: Theme.paddingLarge
          }
        }
      }
    }

    model: ListModel { id: list_model }

    delegate: ListItem {
      contentHeight: Theme.itemSizeSmall
      
      Row {
        anchors.fill: parent
        anchors.leftMargin: Theme.horizontalPageMargin
        anchors.rightMargin: Theme.horizontalPageMargin

        Label {
          width: parent.width * 0.6
          text: state_id
          color: Theme.secondaryColor
          font.pixelSize: Theme.fontSizeExtraSmall
          anchors.verticalCenter: parent.verticalCenter
          truncationMode: TruncationMode.Fade
        }
        Label {
          width: parent.width * 0.4
          text: state_value
          color: Theme.highlightColor
          font.pixelSize: Theme.fontSizeSmall
          horizontalAlignment: Text.AlignRight
          anchors.verticalCenter: parent.verticalCenter
          truncationMode: TruncationMode.Fade
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
      text: "No states active"
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
    app.signal_update_states.connect(load_items)
    app.signal_state_changed.connect(handle_state_changed)
    python.get_states()
  }

  Component.onDestruction: {
    app.signal_update_states.disconnect(load_items)
    app.signal_state_changed.disconnect(handle_state_changed)
  }

  function handle_state_changed(name, data) {
    if (!app.states) {
      app.states = {}
    }
    app.states[name] = data

    for (var i = 0; i < list_model.count; i++) {
      if (list_model.get(i).state_id === name) {
        list_model.setProperty(i, "state_value", String(data))
        return
      }
    }
    
    load_items()
  }

  function load_items() {
    list_model.clear()
    var keys = Object.keys(app.states).sort()
    for (var i = 0; i < keys.length; i++) {
      var key = keys[i]
      list_model.append({
        "state_id": key,
        "state_value": String(app.states[key])
      })
    }
  }
}
