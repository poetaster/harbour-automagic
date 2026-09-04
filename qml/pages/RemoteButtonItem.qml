import QtQuick 2.0
import Sailfish.Silica 1.0

GridItem {
  id: device_item

  property bool btn_active: false
  property bool btn_busy: false
  property string resolved_name: ""
  property string resolved_subtitle: ""

  RemorseItem { id: remorse_item }  

  menu: Component {
    ContextMenu {
      MenuItem {
        text: "Edit"
        onClicked: {
          var dialog = pageStack.push(Qt.resolvedUrl("RemoteButtonEditDialog.qml"), {
            "button_data": model.btn
          })
          var save_buttons_f = device_item.save_buttons;
          if (dialog) dialog.accepted.connect(function() {
            save_buttons_f(dialog.button_data);
          })
        }
      }
      MenuItem {
        text: "Delete"
        onClicked: {
          var bid = model.btn.id
          var delete_button_f = device_item.delete_button
          remorse_item.execute(device_item, "Deleted", function() { delete_button_f(bid) } )
        }
      }
    }
  }

  Rectangle {
    width: parent.width-4
    height: parent.height-4
    anchors.centerIn: parent
    opacity: btn_active ? 0.4 : 0.2
    color: Theme.highlightBackgroundColor
  }

  Rectangle {
    id: color_rectangle
    width: parent.width-14
    height: parent.height-14
    anchors.centerIn: parent
    border.color: model.btn.color ? model.btn.color : Theme.primaryColor
    border.width: 2
    visible: !!model.btn.color
    color: "transparent"
  }

  Label {
    id: btn_name_label
    y: Theme.paddingSmall
    width: parent.width - Theme.paddingSmall * 2
    anchors.horizontalCenter: parent.horizontalCenter

    maximumLineCount: 2
    wrapMode: Text.Wrap
    horizontalAlignment: Text.AlignHCenter
    fontSizeMode: Text.Fit
    font.pixelSize: Theme.fontSizeSmall
    minimumPixelSize: Theme.fontSizeTiny
    lineHeight: 0.9
    lineHeightMode: Text.ProportionalHeight

    text: resolved_name
  }

  Icon {
    id: status_icon

    anchors {
      verticalCenter: parent.verticalCenter
      horizontalCenter: parent.horizontalCenter
    }

    height: 80
    width: 80
    sourceSize: Qt.size(width*4, height*4)
    source: "image://theme/" + (model.btn.icon || "icon-m-game-controller")
  }

  Label {
    id: btn_subtitle_label
    width: parent.width - Theme.paddingSmall * 2
    anchors {
      horizontalCenter: parent.horizontalCenter
      bottom: parent.bottom
      bottomMargin: Theme.paddingMedium
    }

    maximumLineCount: 3
    wrapMode: Text.Wrap
    horizontalAlignment: Text.AlignHCenter
    fontSizeMode: Text.Fit
    font.pixelSize: Theme.fontSizeExtraSmall
    minimumPixelSize: Theme.fontSizeTiny
    lineHeight: 0.85
    lineHeightMode: Text.ProportionalHeight

    text: resolved_subtitle
  }

  SequentialAnimation {
    id: busy_animation
    loops: Animation.Infinite
    running: Boolean(btn_busy)
    PropertyAnimation {target: color_rectangle; property: "opacity"; from: 1.0; to: 0.0; duration: 500 }
    PropertyAnimation {target: color_rectangle; property: "opacity"; from: 0.0; to: 1.0; duration: 500 }

    onStopped: {
      color_rectangle.opacity = 1.0
      if (!model.btn.color || model.btn.color == "") {
        color_rectangle.border.color = Theme.primaryColor
        color_rectangle.visible = false
      }
    }
    onStarted: {
      if (!model.btn.color || model.btn.color == "") {
        color_rectangle.border.color = Theme.highlightColor
        color_rectangle.visible = true
      }
    }
  }

  onClicked: {
    busy_animation.start()
    python.exec_flow(model.btn.flow_id, model.btn.variables)
    busy_animation.stop()
  }

  Component.onCompleted: {
    app.signal_state_changed.connect(handle_state_changed)
    resolved_name = resolve_template(model.btn.name || "")
    resolved_subtitle = resolve_template(model.btn.subtitle || "")
    check_state()
  }

  Component.onDestruction: {
    app.signal_state_changed.disconnect(handle_state_changed)
  }

  function save_buttons(button_data) {
    var remotes = app.remotes.slice()
    var idx = remote_page.remote_index
    var buttons = (remotes[idx].buttons || []).slice()
    for (var i = 0; i < buttons.length; i++) {
      if (buttons[i].id === button_data.id) { buttons[i] = button_data; break }
    }
    remotes[idx] = { "id": remotes[idx].id, "name": remotes[idx].name, "buttons": buttons }
    app.remotes = remotes
    python.save_remotes()
    load_items()
  }

  function delete_button(button_id) {
    var remotes = app.remotes.slice()
    var idx = remote_page.remote_index
    var buttons = (remotes[idx].buttons || []).slice()
    for (var i = 0; i < buttons.length; i++) {
      if (buttons[i].id === button_id) { buttons.splice(i, 1); break }
    }
    remotes[idx] = { "id": remotes[idx].id, "name": remotes[idx].name, "buttons": buttons }
    app.remotes = remotes
    python.save_remotes()
    load_items()
  }

  function check_state() {
    if (!app.states) return
    if (typeof app.states[model.btn.state_active] !== "undefined")
      btn_active = Boolean(app.states[model.btn.state_active])
    if (typeof app.states[model.btn.state_busy] !== "undefined")
      btn_busy = Boolean(app.states[model.btn.state_busy])
  }

  function handle_state_changed(name, data) {
    if (name === model.btn.state_active) {
      btn_active = Boolean(data)
    } else if (name === model.btn.state_busy) {
      btn_busy = Boolean(data)
    }
    resolved_name = resolve_template(model.btn.name || "")
    resolved_subtitle = resolve_template(model.btn.subtitle || "")
  }

  function resolve_template(text) {
    if (!text || text.indexOf("{{") === -1) return text
    var result = text
    var start = result.indexOf("{{")
    while (start !== -1) {
      var end = result.indexOf("}}", start)
      if (end === -1) break
      var key = result.substring(start + 2, end)
      var val = (app.states && app.states[key] !== undefined) ? String(app.states[key]) : "null"
      result = result.substring(0, start) + val + result.substring(end + 2)
      start = result.indexOf("{{", start + val.length)
    }
    return result
  }
}
