import QtQuick 2.2
import Sailfish.Silica 1.0

Dialog {
  id: dialog

  property var button_data: { "id": "", "name": "", "flow_id": "", "color": 0 }
  property int selected_flow_index: 0
  property string selected_color: button_data.color || ""
  property string selected_icon: button_data.icon || ""

  property int color_r: 0
  property int color_g: 0
  property int color_b: 0
  property string color_hex: ""

  canAccept: name_field.text.trim().length > 0 && app.flows && app.flows.length > 0

  ListModel { id: paramsModel }

  SilicaFlickable {
    anchors.fill: parent
    contentHeight: column.height + Theme.paddingLarge

    VerticalScrollDecorator {}

    Column {
      id: column
      width: parent.width
      spacing: 0

      DialogHeader {
        acceptText: button_data.id ? "Save" : "Add"
      }

      TextArea {
        id: name_field
        width: parent.width
        label: "Button name"
        placeholderText: "Button name"
        text: button_data.name || ""
      }

      TextArea {
        id: subtitle_field
        width: parent.width
        label: "Button subtitle"
        placeholderText: "Button subtitle"
        text: button_data.subtitle || ""
      }

      ComboBox {
        id: flow_combo
        width: parent.width
        label: "Flow"
        description: (!app.flows || app.flows.length === 0) ? "No flows defined" : ""

        menu: ContextMenu {
          Repeater {
            model: app.flows || []
            MenuItem {
              text: modelData.name || modelData.id
            }
          }
        }

        Component.onCompleted: {
          if (button_data.flow_id && app.flows) {
            for (var i = 0; i < app.flows.length; i++) {
              if (app.flows[i].id === button_data.flow_id) {
                currentIndex = i
                break
              }
            }
          }
        }

        onCurrentIndexChanged: {
          selected_flow_index = currentIndex
        }
      }

      SectionHeader { text: "Icon" }

      SecondaryButton {
        anchors.horizontalCenter: parent.horizontalCenter
        icon.source: "image://theme/" + (selected_icon || "icon-m-game-controller")
        onClicked: {
          var pg = pageStack.push(Qt.resolvedUrl("IconPickerPage.qml"), { "selectedIcon": selected_icon || "icon-m-game-controller" })
          if (pg) pg.iconPicked.connect(function(name) { selected_icon = name })
        }
      }

      SectionHeader { 
        text: "States"
      }

      TextArea {
        id: state_active_field
        width: parent.width
        label: "Active State Name"
        text: button_data.state_active || ""
        inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhLatinOnly
      }

      TextArea {
        id: state_busy_field
        width: parent.width
        label: "Busy State Name"
        text: button_data.state_busy || ""
        inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhLatinOnly
        onTextChanged: if (focus) button_data.state_busy
      }

      SectionHeader { 
        text: "Variables"
      }

      Repeater {
        model: paramsModel
        delegate: Column {
          width: parent.width
          Row {
            width: parent.width
            TextField {
              width: parent.width - delParamBtn.width
              label: "Variable"
              text: model.pKey
              inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhLatinOnly
              onTextChanged: if (focus) paramsModel.setProperty(index, "pKey", text)
            }
            IconButton {
              id: delParamBtn
              icon.source: "image://theme/icon-m-clear"
              onClicked: paramsModel.remove(index)
              anchors.verticalCenter: parent.verticalCenter
            }
          }
          TextArea {
            width: parent.width
            label: "Value"
            text: model.pValue
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhLatinOnly
            onTextChanged: if (focus) paramsModel.setProperty(index, "pValue", text)
          }
          Separator { width: parent.width; color: Theme.primaryColor; opacity: 0.5 }
        }
      }

      Item { width: 1; height: Theme.paddingSmall }

      Button {
        text: "Add Variable"
        visible: true
        anchors.horizontalCenter: parent.horizontalCenter
        onClicked: paramsModel.append({ "pKey": "", "pValue": "" })
      }

      SectionHeader {
        text: "Color"
      }

      Rectangle {
        id: color_rectangle
        x: Theme.horizontalPageMargin
        width: parent.width - 2 * Theme.horizontalPageMargin
        height: Theme.itemSizeSmall
        color: Qt.rgba(color_r/255, color_g/255, color_b/255, 1)

        Label {
          text: color_hex
          color: get_contrast_color(color_r, color_g, color_b)
          anchors {
            centerIn: color_rectangle
          }
        }
      }

      Slider {
        id: color_r_slider

        width: parent.width
        minimumValue: 0
        maximumValue: 255
        stepSize: 1
        value: color_r
        label: 'Red'

        onValueChanged: {
          if (down) {
            color_r = value
            color_hex = rgb_to_hex(color_r, color_g, color_b)
          }
        }

        onDownChanged: {
          if (!down) {
            color_r = value
            color_hex = rgb_to_hex(color_r, color_g, color_b)
          }
        }
      }

      Slider {
        id: color_g_slider

        width: parent.width
        minimumValue: 0
        maximumValue: 255
        stepSize: 1
        value: color_g
        label: 'Green'

        onValueChanged: {
          if (down) {
            color_g = value
            color_hex = rgb_to_hex(color_r, color_g, color_b)
          }
        }

        onDownChanged: {
          if (!down) {
            color_g = value
            color_hex = rgb_to_hex(color_r, color_g, color_b)
          }
        }
      }

      Slider {
        id: color_b_slider

        width: parent.width
        minimumValue: 0
        maximumValue: 255
        stepSize: 1
        value: color_b
        label: 'Blue'

        onValueChanged: {
          if (down) {
            color_b = value
            color_hex = rgb_to_hex(color_r, color_g, color_b)
          }
        }

        onDownChanged: {
          if (!down) {
            color_b = value
            color_hex = rgb_to_hex(color_r, color_g, color_b)
          }
        }
      }

      SectionHeader {
        text: "Predefined Colors"
      }

      Row {
        width: parent.width
        Rectangle {
          width: parent.width/3
          height: width
          color: Theme.highlightBackgroundColor
          opacity: 0.2
          //border.color: Theme.secondaryColor
          //border.width: 1
          MouseArea {
            id: mouseArea1

            anchors.fill: parent
            onClicked: {
              color_r_slider.value = Theme.highlightBackgroundColor.r * 255
              color_g_slider.value = Theme.highlightBackgroundColor.g * 255
              color_b_slider.value = Theme.highlightBackgroundColor.b * 255
              color_r = Theme.highlightBackgroundColor.r * 255
              color_g = Theme.highlightBackgroundColor.g * 255
              color_b = Theme.highlightBackgroundColor.b * 255
              color_hex = ""
            }

            Rectangle {
              anchors.fill: parent
              color: Theme.rgba("white", Theme.opacityLow)
              opacity: (mouseArea1.pressed && mouseArea1.containsMouse) ? 1.0 : 0.0
            }
          }
        }
        Rectangle {
          color: "white"
          width: parent.width/3
          height: width
          MouseArea {
            id: mouseArea2

            anchors.fill: parent
            onClicked: {
              color_r_slider.value = 255
              color_g_slider.value = 255
              color_b_slider.value = 255
              color_r = 255
              color_g = 255
              color_b = 255
              color_hex = rgb_to_hex(255, 255, 255)
            }

            Rectangle {
              anchors.fill: parent
              color: Theme.rgba("black", Theme.opacityLow)
              opacity: (mouseArea2.pressed && mouseArea2.containsMouse) ? 1.0 : 0.0
            }
          }
        }
        Rectangle {
          color: "black"
          width: parent.width/3
          height: width
          MouseArea {
            id: mouseArea3

            anchors.fill: parent
            onClicked: {
              color_r_slider.value = 0
              color_g_slider.value = 0
              color_b_slider.value = 0
              color_r = 0
              color_g = 0
              color_b = 0
              color_hex = rgb_to_hex(0, 0, 0)
            }

            Rectangle {
              anchors.fill: parent
              color: Theme.rgba("white", Theme.opacityLow)
              opacity: (mouseArea3.pressed && mouseArea3.containsMouse) ? 1.0 : 0.0
            }
          }
        }
      }

      ColorPicker {
        width: parent.width

        onColorChanged: {
          console.debug('Color Picker Change:', color.r, color.g, color.b)


          color_r = (color.r * 255) | 0
          color_g = (color.g * 255) | 0
          color_b = (color.b * 255) | 0

          color_r_slider.value = color_r
          color_g_slider.value = color_g
          color_b_slider.value = color_b

          color_hex = rgb_to_hex(color_r, color_g, color_b)
        }
      }
    }
  }

  Component.onCompleted: {
    if (button_data.variables) {
      for (var pk in button_data.variables) {
        paramsModel.append({ "pKey": pk, "pValue": String(button_data.variables[pk]) })
      }
    }

    if (!button_data.color || button_data.color == "") {
      color_r = Theme.highlightBackgroundColor.r * 255
      color_g = Theme.highlightBackgroundColor.g * 255
      color_b = Theme.highlightBackgroundColor.b * 255
      color_hex = ""
    } else {
      color_hex = button_data.color
      var color_rgb = hex_to_rgb(button_data.color);
      color_r = color_rgb.r
      color_g = color_rgb.g
      color_b = color_rgb.b
    }
  }

  onAccepted: {
    var pMap = {}
    for (var pIdx = 0; pIdx < paramsModel.count; pIdx++) {
      var p = paramsModel.get(pIdx)
      if (p.pKey.trim() !== "") pMap[p.pKey] = p.pValue
    }

    button_data = {
      "id":         button_data.id,
      "name":       name_field.text.trim(),
      "subtitle":   subtitle_field.text.trim(),
      "flow_id":    (app.flows && app.flows.length > selected_flow_index) ? app.flows[selected_flow_index].id : "",
      "color":      color_hex,
      "icon":       selected_icon || "icon-m-game-controller",
      "variables":  pMap,
      "state_active": state_active_field.text.trim(),
      "state_busy": state_busy_field.text.trim()
    }
  }

  function rgb_to_hex(r, g, b) {
    var format = function(v) {
      var hex = Math.round(v).toString(16);
      return hex.length === 1 ? "0" + hex : hex;
    };

    return "#" + format(r) + format(g) + format(b);
  }

  function hex_to_rgb(hex) {
    hex = hex.replace(/^#/, "");

    if (hex.length === 3) {
      hex = hex.split("").map(function(chx) {
        return chx + chx;
      }).join("");
    }

    var r = parseInt(hex.substring(0, 2), 16);
    var g = parseInt(hex.substring(2, 4), 16);
    var b = parseInt(hex.substring(4, 6), 16);

    return {"r": r, "g": g, "b": b};
  }

  function get_contrast_color(r, g, b) {
    const yiq = ((r * 299) + (g * 587) + (b * 114)) / 1000;
    return (yiq >= 128) ? 'black' : 'white';
  }
}