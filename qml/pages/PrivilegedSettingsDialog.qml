import QtQuick 2.2
import Sailfish.Silica 1.0

Dialog {
  id: privileged_dialog

  ListModel { id: userModel }

  SilicaFlickable {
    anchors.fill: parent
    contentHeight: column.height + Theme.paddingLarge

    Column {
      id: column
      width: parent.width

      DialogHeader { title: "Privileged Execution" }

      Label {
        width: parent.width - 2 * Theme.horizontalPageMargin
        x: Theme.horizontalPageMargin
        wrapMode: Text.WordWrap
        color: Theme.secondaryColor
        font.pixelSize: Theme.fontSizeSmall
        text: "Users that actions and sources are allowed to run as via 'Run As User'. Saving requires device authentication."
      }

      SectionHeader { text: "Allowed Users" }

      Repeater {
        model: userModel
        delegate: Row {
          width: parent.width
          TextField {
            width: parent.width - deleteUserBtn.width
            label: "Username"
            text: model.name
            inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhLatinOnly
            onTextChanged: if (focus) userModel.setProperty(index, "name", text)
          }
          IconButton {
            id: deleteUserBtn
            icon.source: "image://theme/icon-m-clear"
            anchors.verticalCenter: parent.verticalCenter
            onClicked: userModel.remove(index)
          }
        }
      }

      Button {
        text: "Add User"
        anchors.horizontalCenter: parent.horizontalCenter
        preferredWidth: Theme.buttonWidthSmall
        onClicked: userModel.append({ "name": "" })
      }

      Item { width: 1; height: Theme.paddingLarge }
    }
  }

  Component.onCompleted: {
    var allowed = (app.settings_privileged && app.settings_privileged.allowed_run_as) || []
    for (var i = 0; i < allowed.length; i++) {
      userModel.append({ "name": allowed[i] })
    }
  }

  onAccepted: {
    var users = []
    for (var i = 0; i < userModel.count; i++) {
      var name = userModel.get(i).name.trim()
      if (name !== "" && users.indexOf(name) === -1) {
        users.push(name)
      }
    }
    python.update_privileged_config(users)
  }
}
