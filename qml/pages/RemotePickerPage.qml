import QtQuick 2.0
import Sailfish.Silica 1.0

Page {
  id: picker_page

  property var remote_page_ref: null

  SilicaListView {
    anchors.fill: parent
    header: PageHeader { title: "Switch View" }
    model: ListModel { id: list_model }

    PullDownMenu {
      MenuItem {
        text: "Add Remote"
        onClicked: add_remote()
      }
    }

    delegate: ListItem {
      id: delegate_item
      contentHeight: Theme.itemSizeMedium
      menu: model.item_type === "remote" ? context_menu : null

      property int item_idx: model.item_index
      property string item_nm: model.item_name

      Component {
        id: context_menu
        ContextMenu {
          MenuItem {
            text: "Rename"
            onClicked: rename_remote(delegate_item.item_idx, delegate_item.item_nm)
          }
          MenuItem {
            text: "Delete"
            onClicked: {
              var idx = delegate_item.item_idx
              var fn = delete_remote
              var label = app.remotes.length <= 1 ? "Reset" : "Deleted"
              delegate_item.remorseAction(label, function() { fn(idx) })
            }
          }
        }
      }

      Label {
        text: model.item_name
        color: model.is_current ? Theme.highlightColor : Theme.primaryColor
        anchors {
          left: parent.left
          leftMargin: Theme.horizontalPageMargin
          verticalCenter: parent.verticalCenter
        }
      }

      Separator {
        anchors.top: parent.top
        width: parent.width
        color: Theme.primaryColor
        opacity: 0.8
        visible: index === 0
      }

      Separator {
        anchors.bottom: parent.bottom
        width: parent.width
        color: Theme.primaryColor
        opacity: 0.8
      }

      onClicked: {
        if (model.item_type === "remote") {
          save_nav("remote", model.item_index)
        } else if (model.item_type === "states") {
          save_nav("states", -1)
        } else if (model.item_type === "logs") {
          save_nav("logs", -1)
        }
      }
    }

    VerticalScrollDecorator {}
  }

  Component.onCompleted: build_model()

  function save_nav(dyn_page, remote_idx) {
    var s = app.settings || {}
    s.dynamic_page = dyn_page
    if (remote_idx >= 0) {
      s.remote_index = remote_idx
      if (remote_page_ref) {
        remote_page_ref.remote_index = remote_idx
        remote_page_ref.load_items()
      }
    }
    app.settings = s
    python.save_settings()
    app.dynamic_page = dyn_page
    pageStack.pop()
  }

  function build_model() {
    list_model.clear()
    list_model.append({
      "item_name": "States",
      "item_type": "states",
      "item_index": -1,
      "is_current": app.dynamic_page === "states"
    })
    list_model.append({
      "item_name": "Log",
      "item_type": "logs",
      "item_index": -1,
      "is_current": app.dynamic_page === "logs"
    })
    var remotes = app.remotes || []
    for (var i = 0; i < remotes.length; i++) {
      list_model.append({
        "item_name": remotes[i].name || ("Remote " + (i + 1)),
        "item_type": "remote",
        "item_index": i,
        "is_current": app.dynamic_page === "remote" && remote_page_ref && remote_page_ref.remote_index === i
      })
    }
  }

  function add_remote() {
    var dialog = pageStack.push(Qt.resolvedUrl("RemoteNameDialog.qml"), {
      "remote_name": "",
      "dialog_title": "Add Remote"
    })
    if (dialog) dialog.accepted.connect(function() {
      var new_remote = {
        "id": "remote_" + Math.random().toString(36).substr(2, 9),
        "name": dialog.remote_name,
        "buttons": []
      }
      var remotes = app.remotes.slice()
      remotes.push(new_remote)
      app.remotes = remotes
      python.save_remotes()
      app.signal_update_remotes(app.remotes)
      build_model()
    })
  }

  function rename_remote(idx, current_name) {
    var dialog = pageStack.push(Qt.resolvedUrl("RemoteNameDialog.qml"), {
      "remote_name": current_name,
      "dialog_title": "Rename Remote"
    })
    if (dialog) dialog.accepted.connect(function() {
      var remotes = app.remotes.slice()
      remotes[idx] = { "id": remotes[idx].id, "name": dialog.remote_name, "buttons": remotes[idx].buttons }
      app.remotes = remotes
      python.save_remotes()
      app.signal_update_remotes(app.remotes)
      build_model()
    })
  }

  function delete_remote(idx) {
    var remotes = app.remotes.slice()
    if (remotes.length <= 1) {
      remotes[0] = { "id": remotes[0].id, "name": "Remote", "buttons": [] }
    } else {
      remotes.splice(idx, 1)
      if (remote_page_ref && remote_page_ref.remote_index >= remotes.length) {
        remote_page_ref.remote_index = remotes.length - 1
      }
    }
    app.remotes = remotes
    python.save_remotes()
    app.signal_update_remotes(app.remotes)
    if (remote_page_ref) remote_page_ref.load_items()
    build_model()
  }
}
