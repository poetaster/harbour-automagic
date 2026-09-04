import QtQuick 2.2
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0

Dialog {
  id: settings_dialog

  property string startupTab: "1"
  property int logLimit: 100
  property string exportBasePath: ""
  property string displayName: ""

  SilicaFlickable {
    anchors.fill: parent
    contentHeight: column.height + Theme.paddingLarge

    Column {
      id: column
      width: parent.width

      DialogHeader {
        title: "Settings"
      }

      SectionHeader { text: "Tabs" }

      ComboBox {
        id: startup_combo
        width: parent.width
        label: "Startup Tab"
        
        menu: ContextMenu {
          MenuItem {
            text: "Sources"
            onClicked: startupTab = "0"
          }
          MenuItem {
            text: "Flows"
            onClicked: startupTab = "1"
          }
          MenuItem {
            text: "Actions"
            onClicked: startupTab = "2"
          }
          MenuItem {
            text: "States / Log / Remote"
            onClicked: startupTab = "3"
          }
        }
      }

      SectionHeader { text: "Log" }

      Slider {
        id: log_slider
        width: parent.width
        label: "Log History Limit"
        minimumValue: 50
        maximumValue: 1000
        stepSize: 50
        value: logLimit
        valueText: value + " lines"
        onValueChanged: logLimit = value
      }

      SectionHeader { text: "Library" }

      TextField {
        width: parent.width
        label: "Display Name"
        placeholderText: "Your name in the community library"
        text: settings_dialog.displayName
        inputMethodHints: Qt.ImhNoPredictiveText
        onTextChanged: settings_dialog.displayName = text.trim()
      }

      SectionHeader { text: "Export" }

      ValueButton {
        width: parent.width
        label: "Export Path"
        value: settings_dialog.exportBasePath
        onClicked: pageStack.push(folderPickerComponent)
      }

      Component {
        id: folderPickerComponent
        FolderPickerPage {
          dialogTitle: "Export Path"
          onSelectedPathChanged: settings_dialog.exportBasePath = selectedPath
        }
      }

      SectionHeader { text: "Privileged Execution" }

      Label {
        width: parent.width - 2 * Theme.horizontalPageMargin
        x: Theme.horizontalPageMargin
        wrapMode: Text.WordWrap
        color: Theme.secondaryColor
        font.pixelSize: Theme.fontSizeSmall
        text: {
          var p = app.settings_privileged || {}
          if (!p.exists) return "Not configured - actions cannot run as a different user."
          if (!p.secure) return "Configured, but not securely (check ownership/permissions) - denied."
          if (!p.allowed_run_as || p.allowed_run_as.length === 0) return "Configured, but no users allowed."
          return "Allowed: " + p.allowed_run_as.join(", ")
        }
      }

      ValueButton {
        width: parent.width
        label: "Allowed Users"
        value: "Edit"
        onClicked: pageStack.push(Qt.resolvedUrl("PrivilegedSettingsDialog.qml"))
      }
    }
  }

  Component.onCompleted: {
    var s = app.settings || {}
    
    startupTab = s.startup_tab || "1"
    startup_combo.currentIndex = parseInt(startupTab)
    
    if (s.log_limit !== undefined) {
      logLimit = s.log_limit
    }

    exportBasePath = s.export_base_path || ""
    displayName = s.display_name || ""
  }

  onAccepted: {
    var s = app.settings || {}
    
    s.startup_tab = startupTab
    s.log_limit = logLimit
    s.export_base_path = exportBasePath
    s.display_name = displayName

    app.settings = s
    python.save_settings()
  }
}
