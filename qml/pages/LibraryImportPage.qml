import QtQuick 2.2
import Sailfish.Silica 1.0

Page {
  id: page

  property var example: null
  property var importData: ({})
  property var itemList: []

  Component.onCompleted: {
    if (!example) return
    importData = {
      flows:        (example.flows        && example.flows.data)        ? example.flows.data        : [],
      data_sources: (example.data_sources && example.data_sources.data) ? example.data_sources.data : [],
      actions:      (example.actions      && example.actions.data)      ? example.actions.data      : [],
      value_maps:   (example.value_maps   && example.value_maps.data)   ? example.value_maps.data   : {},
      remotes:      (example.remotes      && example.remotes.data)      ? example.remotes.data      : []
    }
    itemList = _listItems(importData)
  }

  SilicaFlickable {
    anchors.fill: parent
    contentHeight: column.height

    Column {
      id: column
      width: parent.width

      PageHeader { title: "Import" }

      Label {
        x: Theme.horizontalPageMargin
        width: parent.width - 2 * Theme.horizontalPageMargin
        text: example ? (example.name || "") : ""
        visible: text.length > 0
        color: Theme.primaryColor
        truncationMode: TruncationMode.Fade
      }

      Label {
        x: Theme.horizontalPageMargin
        width: parent.width - 2 * Theme.horizontalPageMargin
        text: example ? (example.description || "") : ""
        visible: text.length > 0
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.secondaryColor
        wrapMode: Text.WordWrap
        maximumLineCount: 30
      }

      Item { width: parent.width; height: Theme.paddingLarge }

      Button {
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Import"
        onClicked: _doImport()
      }

      Item { width: parent.width; height: Theme.paddingLarge }

      Item { width: parent.width; height: Theme.paddingMedium }

      Repeater {
        model: page.itemList
        Label {
          x: Theme.horizontalPageMargin
          width: parent.width - 2 * Theme.horizontalPageMargin
          text: "• " + modelData
          color: Theme.primaryColor
          font.pixelSize: Theme.fontSizeSmall
          wrapMode: Text.WordWrap
        }
      }
    }
  }

  function _listItems(data) {
    var items = []
    var flows = data.flows || []
    for (var i = 0; i < flows.length; i++)
      items.push("Flow: " + (flows[i].name || flows[i].id))
    var sources = data.data_sources || []
    for (var j = 0; j < sources.length; j++)
      items.push("Source: " + (sources[j].name || sources[j].id))
    var actions = data.actions || []
    for (var k = 0; k < actions.length; k++)
      items.push("Action: " + (actions[k].name || actions[k].id))
    var maps = data.value_maps || {}
    for (var key in maps)
      items.push("Value Map: " + key)
    var remotes = data.remotes || []
    for (var r = 0; r < remotes.length; r++)
      items.push("Remote: " + (remotes[r].name || remotes[r].id))
    return items
  }

  function _findConflicts(data) {
    var conflicts = []
    var flows = data.flows || []
    for (var i = 0; i < flows.length; i++)
      for (var fi = 0; fi < app.flows.length; fi++)
        if (app.flows[fi].id === flows[i].id) { conflicts.push("Flow: " + (flows[i].name || flows[i].id)); break }
    var sources = data.data_sources || []
    for (var j = 0; j < sources.length; j++)
      for (var si = 0; si < app.data_sources.length; si++)
        if (app.data_sources[si].id === sources[j].id) { conflicts.push("Source: " + (sources[j].name || sources[j].id)); break }
    var actions = data.actions || []
    for (var k = 0; k < actions.length; k++)
      for (var ai = 0; ai < app.actions.length; ai++)
        if (app.actions[ai].id === actions[k].id) { conflicts.push("Action: " + (actions[k].name || actions[k].id)); break }
    var maps = data.value_maps || {}
    for (var key in maps)
      if (app.value_maps[key] !== undefined) conflicts.push("Value Map: " + key)
    var remotes = data.remotes || []
    for (var r = 0; r < remotes.length; r++)
      for (var ri = 0; ri < app.remotes.length; ri++)
        if (app.remotes[ri].id === remotes[r].id) { conflicts.push("Remote: " + (remotes[r].name || remotes[r].id)); break }
    return conflicts
  }

  function _doImport() {
    var conflicts = _findConflicts(importData)
    if (conflicts.length > 0) {
      var dialog = pageStack.push(Qt.resolvedUrl("ConflictDialog.qml"), {
        "importData": importData,
        "conflictList": conflicts
      })
      dialog.accepted.connect(function() { _applyImport(dialog.importData, true) })
    } else {
      _applyImport(importData, false)
    }
  }

  function _applyImport(data, overwrite) {
    var flows = data.flows || []
    var sources = data.data_sources || []
    var actions = data.actions || []
    var maps = data.value_maps || {}

    if (flows.length > 0) {
      var flwList = app.flows
      for (var i = 0; i < flows.length; i++) {
        if (overwrite)
          for (var fi = flwList.length - 1; fi >= 0; fi--)
            if (flwList[fi].id === flows[i].id) { flwList.splice(fi, 1); break }
        flwList.push(flows[i])
      }
      app.flows = []; app.flows = flwList
      python.save_flows()
    }

    if (sources.length > 0) {
      var srcList = app.data_sources
      for (var j = 0; j < sources.length; j++) {
        if (overwrite)
          for (var si = srcList.length - 1; si >= 0; si--)
            if (srcList[si].id === sources[j].id) { srcList.splice(si, 1); break }
        srcList.push(sources[j])
      }
      app.data_sources = []; app.data_sources = srcList
      python.save_data_sources()
    }

    if (actions.length > 0) {
      var actList = app.actions
      for (var k = 0; k < actions.length; k++) {
        if (overwrite)
          for (var ai = actList.length - 1; ai >= 0; ai--)
            if (actList[ai].id === actions[k].id) { actList.splice(ai, 1); break }
        actList.push(actions[k])
      }
      app.actions = []; app.actions = actList
      python.save_actions()
    }

    if (Object.keys(maps).length > 0) {
      var currentMaps = app.value_maps
      for (var key in maps) currentMaps[key] = maps[key]
      app.value_maps = {}; app.value_maps = currentMaps
      python.save_value_maps()
    }

    var remotes = data.remotes || []
    if (remotes.length > 0) {
      var remList = app.remotes.slice()
      for (var ri = 0; ri < remotes.length; ri++) {
        if (overwrite)
          for (var rj = remList.length - 1; rj >= 0; rj--)
            if (remList[rj].id === remotes[ri].id) { remList.splice(rj, 1); break }
        remList.push(remotes[ri])
      }
      app.remotes = remList
      python.save_remotes()
      app.signal_update_remotes(app.remotes)
    }

    python.load_data()
    pageStack.pop()
  }
}
