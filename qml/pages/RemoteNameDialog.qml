import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
  id: dialog

  property string remote_name: ""
  property string dialog_title: "Add Remote"

  canAccept: name_field.text.trim().length > 0

  onAccepted: {
    remote_name = name_field.text.trim()
  }

  Column {
    width: parent.width

    DialogHeader { title: dialog_title }

    TextField {
      id: name_field
      width: parent.width
      placeholderText: "Remote name"
      label: "Name"
      text: remote_name
      focus: true
      EnterKey.iconSource: "image://theme/icon-m-enter-accept"
      EnterKey.onClicked: dialog.accept()
    }
  }
}
