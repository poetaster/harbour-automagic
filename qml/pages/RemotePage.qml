import QtQuick 2.2
import Sailfish.Silica 1.0

Item {
  id: remote_page

  property int remote_index: 0

  SilicaGridView {
    id: grid_view
    anchors.fill: parent

    cellWidth: width / 3
    cellHeight: width / 3

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
        text: "Add Button"
        onClicked: {
          var dialog = pageStack.push(Qt.resolvedUrl("RemoteButtonEditDialog.qml"), {
            "button_data": { "id": "", "name": "", "flow_id": "", "color": 0 }
          })
          if (dialog) dialog.accepted.connect(function() {
            var btn = dialog.button_data
            btn.id = "btn_" + Math.random().toString(36).substr(2, 9)
            var remotes = app.remotes.slice()
            var idx = remote_index
            var buttons = (remotes[idx].buttons || []).slice()
            buttons.push(btn)
            remotes[idx] = { "id": remotes[idx].id, "name": remotes[idx].name, "buttons": buttons }
            app.remotes = remotes
            python.save_remotes()
            load_items()
          })
        }
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
        height: header_btn.height

        SecondaryButton {
          id: header_btn
          preferredWidth: parent.width
          text: (app.remotes && app.remotes[remote_index]) ? app.remotes[remote_index].name : "Remote"
          layoutDirection: Qt.RightToLeft
          anchors {
            verticalCenter: parent.verticalCenter
            horizontalCenter: parent.horizontalCenter
          }
          onClicked: {
            pageStack.push(Qt.resolvedUrl("RemotePickerPage.qml"), {
              "remote_page_ref": remote_page
            })
          }
        }

        Icon {
          source: "../../icons/arrow_forward.svg"
          height: 60
          width: height
          anchors {
            verticalCenter: header_btn.verticalCenter
            right: header_btn.right
            rightMargin: Theme.paddingLarge
          }
        }
      }
    }

    model: ListModel { id: list_model }

    delegate: RemoteButtonItem {}

    ViewPlaceholder {
      enabled: grid_view.count < 1
      text: "No buttons"
      hintText: "Pull down to add a button"
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

  function load_items() {
    list_model.clear()
    if (!app || !app.remotes || app.remotes.length === 0) return
    var idx = Math.min(remote_index, app.remotes.length - 1)
    var buttons = app.remotes[idx].buttons || []
    for (var i = 0; i < buttons.length; i++) {
      list_model.append({ "btn": buttons[i] })
    }
  }

  Component.onCompleted: {
    app.signal_update_remotes.connect(load_items)
    if (app.settings && app.settings.remote_index !== undefined)
      remote_index = Math.min(parseInt(app.settings.remote_index) || 0, Math.max(0, (app.remotes || []).length - 1))
    load_items()
  }

  Component.onDestruction: {
    app.signal_update_remotes.disconnect(load_items)
  }
}
