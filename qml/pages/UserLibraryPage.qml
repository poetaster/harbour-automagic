import QtQuick 2.2
import Sailfish.Silica 1.0

Page {
  id: page

  property string displayName: ""
  property var examples: []
  property bool loading: true
  property bool owner: false

  SilicaListView {
    anchors.fill: parent
    model: page.examples

    header: PageHeader {
      title: page.displayName
    }

    delegate: ListItem {
      id: delegate
      contentHeight: layout.height + Theme.paddingMedium
      onClicked: pageStack.push(Qt.resolvedUrl("LibraryImportPage.qml"), { example: modelData })
      menu: page.owner ? context_menu : null

      Component {
        id: context_menu
        ContextMenu {
          MenuItem {
            text: "Delete"
            onClicked: {
              var slug = modelData.id
              var fn = deleteExample
              delegate.remorseAction("Deleted", function() { fn(slug) })
            }
          }
        }
      }

      Icon {
        source: "../../icons/arrow_forward.svg"
        height: Theme.iconSizeSmall; width: height
        anchors { verticalCenter: parent.verticalCenter; right: parent.right; rightMargin: Theme.horizontalPageMargin }
        color: Theme.primaryColor
      }

      Column {
        id: layout
        anchors {
          left: parent.left; leftMargin: Theme.horizontalPageMargin
          right: parent.right; rightMargin: Theme.horizontalPageMargin + Theme.iconSizeSmall + Theme.paddingMedium
          verticalCenter: parent.verticalCenter
        }

        Label {
          text: modelData.name
          color: delegate.highlighted ? Theme.highlightColor : Theme.primaryColor
          width: parent.width
          truncationMode: TruncationMode.Fade
        }

        Label {
          text: modelData.description || ""
          font.pixelSize: Theme.fontSizeExtraSmall
          color: Theme.secondaryColor
          width: parent.width
          wrapMode: Text.WordWrap
          maximumLineCount: 3
          visible: text.length > 0
        }

        Row {
          spacing: Theme.paddingSmall
          anchors.topMargin: Theme.paddingSmall
          visible: !!modelData.data_sources || !!modelData.actions || !!modelData.flows || !!modelData.value_maps || !!modelData.remotes

          Rectangle {
            visible: !!modelData.data_sources
            width: sourceLabel.width + Theme.paddingMedium; height: sourceLabel.height + Theme.paddingSmall
            color: Theme.rgba(Theme.primaryColor, 0.1); radius: Theme.paddingSmall / 2; opacity: 0.5
            Label { id: sourceLabel; anchors.centerIn: parent; text: "Source"; font.pixelSize: Theme.fontSizeExtraSmall; color: Theme.primaryColor }
          }
          Rectangle {
            visible: !!modelData.actions
            width: actionLabel.width + Theme.paddingMedium; height: actionLabel.height + Theme.paddingSmall
            color: Theme.rgba(Theme.primaryColor, 0.1); radius: Theme.paddingSmall / 2; opacity: 0.5
            Label { id: actionLabel; anchors.centerIn: parent; text: "Action"; font.pixelSize: Theme.fontSizeExtraSmall; color: Theme.primaryColor }
          }
          Rectangle {
            visible: !!modelData.flows
            width: flowLabel.width + Theme.paddingMedium; height: flowLabel.height + Theme.paddingSmall
            color: Theme.rgba(Theme.primaryColor, 0.1); radius: Theme.paddingSmall / 2; opacity: 0.5
            Label { id: flowLabel; anchors.centerIn: parent; text: "Flow"; font.pixelSize: Theme.fontSizeExtraSmall; color: Theme.primaryColor }
          }
          Rectangle {
            visible: !!modelData.value_maps
            width: mapLabel.width + Theme.paddingMedium; height: mapLabel.height + Theme.paddingSmall
            color: Theme.rgba(Theme.primaryColor, 0.1); radius: Theme.paddingSmall / 2; opacity: 0.5
            Label { id: mapLabel; anchors.centerIn: parent; text: "Value Maps"; font.pixelSize: Theme.fontSizeExtraSmall; color: Theme.primaryColor }
          }
          Rectangle {
            visible: !!modelData.remotes
            width: remoteLabel.width + Theme.paddingMedium; height: remoteLabel.height + Theme.paddingSmall
            color: Theme.rgba(Theme.primaryColor, 0.1); radius: Theme.paddingSmall / 2; opacity: 0.5
            Label { id: remoteLabel; anchors.centerIn: parent; text: "Remote"; font.pixelSize: Theme.fontSizeExtraSmall; color: Theme.primaryColor }
          }
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
    }

    ViewPlaceholder {
      enabled: page.loading
      text: "Fetching examples..."
    }

    ViewPlaceholder {
      enabled: !page.loading && page.examples.length === 0
      text: "No examples found"
    }

    PullDownMenu {
      MenuItem {
        text: "Refresh"
        onClicked: fetchExamples()
      }
    }
  }

  function fetchExamples() {
    page.loading = true
    var xhr = new XMLHttpRequest()
    xhr.onreadystatechange = function() {
      if (xhr.readyState !== XMLHttpRequest.DONE) return
      page.loading = false
      if (xhr.status === 200) {
        try {
          var data = JSON.parse(xhr.responseText)
          if (data.length > 0) {
            page.examples = data[0].examples || []
            page.owner    = !!data[0].owner
          } else {
            page.examples = []
          }
        } catch (e) {
          app.signal_error('UserLibraryPage', 'fetchExamples', 'Error parsing response')
        }
      } else {
        app.signal_error('UserLibraryPage', 'fetchExamples', 'Could not connect to library server (Status: ' + xhr.status + ')')
      }
    }
    var token = (app.settings && app.settings.library_token) ? encodeURIComponent(app.settings.library_token) : ""
    var url = "https://qml.app/automagic/library.php?user=" + encodeURIComponent(displayName)
    if (token) url += "&token=" + token
    xhr.open("GET", url)
    xhr.send()
  }

  function deleteExample(slug) {
    var xhr = new XMLHttpRequest()
    xhr.onreadystatechange = function() {
      if (xhr.readyState !== XMLHttpRequest.DONE) return
      if (xhr.status === 200) {
        var resp = JSON.parse(xhr.responseText)
        if (resp.ok) {
          fetchExamples()
        } else {
          app.signal_error('UserLibraryPage', 'deleteExample', resp.message || 'Delete failed')
        }
      } else {
        app.signal_error('UserLibraryPage', 'deleteExample', 'Delete failed (HTTP ' + xhr.status + ')')
      }
    }
    xhr.open("POST", "https://qml.app/automagic/library_upload.php")
    xhr.setRequestHeader("Content-Type", "application/json")
    xhr.send(JSON.stringify({
      action: "delete",
      token:  (app.settings && app.settings.library_token) || "",
      slug:   slug
    }))
  }

  Component.onCompleted: fetchExamples()
}
