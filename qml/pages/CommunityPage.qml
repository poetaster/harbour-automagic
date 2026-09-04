import QtQuick 2.2
import Sailfish.Silica 1.0

Page {
  id: page

  property var users: []
  property bool loading: true

  SilicaListView {
    anchors.fill: parent
    model: page.users

    header: PageHeader {
      title: "Community Library"
    }

    delegate: ListItem {
      id: delegate
      contentHeight: Theme.itemSizeMedium
      onClicked: pageStack.push(Qt.resolvedUrl("UserLibraryPage.qml"), { displayName: modelData.display_name })

      Icon {
        source: "../../icons/arrow_forward.svg"
        height: Theme.iconSizeSmall; width: height
        anchors { verticalCenter: parent.verticalCenter; right: parent.right; rightMargin: Theme.horizontalPageMargin }
        color: Theme.primaryColor
      }

      Column {
        anchors {
          left: parent.left; leftMargin: Theme.horizontalPageMargin
          right: parent.right; rightMargin: Theme.horizontalPageMargin + Theme.iconSizeSmall + Theme.paddingMedium
          verticalCenter: parent.verticalCenter
        }

        Label {
          text: modelData.display_name
          color: modelData.owner ? Theme.highlightColor : (delegate.highlighted ? Theme.highlightColor : Theme.primaryColor)
          width: parent.width
          truncationMode: TruncationMode.Fade
        }

        Label {
          text: modelData.example_count + (modelData.example_count === 1 ? " example" : " examples")
          font.pixelSize: Theme.fontSizeExtraSmall
          color: modelData.owner ? Theme.highlightColor : Theme.secondaryColor
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
      text: "Fetching community library..."
    }

    ViewPlaceholder {
      enabled: !page.loading && page.users.length === 0
      text: "No contributions yet"
    }

    PullDownMenu {
      MenuItem {
        text: "Refresh"
        onClicked: fetchUsers()
      }
    }
  }

  function fetchUsers() {
    page.loading = true
    var xhr = new XMLHttpRequest()
    xhr.onreadystatechange = function() {
      if (xhr.readyState !== XMLHttpRequest.DONE) return
      page.loading = false
      if (xhr.status === 200) {
        try {
          page.users = JSON.parse(xhr.responseText)
        } catch (e) {
          app.signal_error('CommunityPage', 'fetchUsers', 'Error parsing response')
        }
      } else {
        app.signal_error('CommunityPage', 'fetchUsers', 'Could not connect to library server (Status: ' + xhr.status + ')')
      }
    }
    var token = (app.settings && app.settings.library_token) ? encodeURIComponent(app.settings.library_token) : ""
    xhr.open("GET", "https://qml.app/automagic/library_users.php" + (token ? "?token=" + token : ""))
    xhr.send()
  }

  Component.onCompleted: fetchUsers()
}
