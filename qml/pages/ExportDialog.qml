import QtQuick 2.2
import Sailfish.Silica 1.0

Dialog {
  id: root

  property string mode: "export"  // "export" or "upload"

  canAccept: mode === "upload"
    ? nameField.text.trim().length > 0
    : exportPathField.text.trim().length > 0

  ListModel { id: flowsModel }
  ListModel { id: sourcesModel }
  ListModel { id: actionsModel }
  ListModel { id: valueMapsModel }
  ListModel { id: remotesModel }

  function _populateModels() {
    flowsModel.clear()
    for (var i = 0; i < app.flows.length; i++) {
      var f = app.flows[i]
      flowsModel.append({ "itemId": f.id, "itemName": f.name || f.id, "isChecked": false })
    }
    sourcesModel.clear()
    for (var j = 0; j < app.data_sources.length; j++) {
      var s = app.data_sources[j]
      sourcesModel.append({ "itemId": s.id, "itemName": s.name || s.id, "isChecked": false })
    }
    actionsModel.clear()
    for (var k = 0; k < app.actions.length; k++) {
      var a = app.actions[k]
      actionsModel.append({ "itemId": a.id, "itemName": a.name || a.id, "isChecked": false })
    }
    valueMapsModel.clear()
    for (var key in app.value_maps) {
      valueMapsModel.append({ "itemId": key, "itemName": key, "isChecked": false })
    }
    remotesModel.clear()
    for (var r = 0; r < app.remotes.length; r++) {
      var rem = app.remotes[r]
      remotesModel.append({ "itemId": rem.id, "itemName": rem.name || rem.id, "isChecked": false })
    }
  }

  function _selectAll(selected) {
    for (var i = 0; i < flowsModel.count; i++) flowsModel.setProperty(i, "isChecked", selected)
    for (var j = 0; j < sourcesModel.count; j++) sourcesModel.setProperty(j, "isChecked", selected)
    for (var k = 0; k < actionsModel.count; k++) actionsModel.setProperty(k, "isChecked", selected)
    for (var l = 0; l < valueMapsModel.count; l++) valueMapsModel.setProperty(l, "isChecked", selected)
    for (var m = 0; m < remotesModel.count; m++) remotesModel.setProperty(m, "isChecked", selected)
  }

  function syncFlowDependencies(flowId, checked) {
    var flow = null
    for (var i = 0; i < app.flows.length; i++) {
      if (app.flows[i].id === flowId) { flow = app.flows[i]; break }
    }

    if (!flow) return

    var sourceIds = {}
    var actionIds = {}
    var triggers = flow.triggers || []
    for (var t = 0; t < triggers.length; t++) sourceIds[triggers[t]] = true
    var steps = flow.steps || []

    for (var s = 0; s < steps.length; s++) {
      if (steps[s].type === "get" && steps[s].source) sourceIds[steps[s].source] = true
      if (steps[s].type === "action" && steps[s].action) actionIds[steps[s].action] = true
    }

    for (var si = 0; si < sourcesModel.count; si++) {
      if (sourceIds[sourcesModel.get(si).itemId]) {
        sourcesModel.setProperty(si, "isChecked", checked)
        syncSourceValueMaps(sourcesModel.get(si).itemId, checked)
      }
    }
    for (var ai = 0; ai < actionsModel.count; ai++) {
      if (actionIds[actionsModel.get(ai).itemId]) {
        actionsModel.setProperty(ai, "isChecked", checked)
      }
    }
  }

  function syncSourceValueMaps(sourceId, checked) {
    for (var i = 0; i < app.data_sources.length; i++) {
      if (app.data_sources[i].id !== sourceId) continue
      var transforms = app.data_sources[i].transformations || []
      for (var t = 0; t < transforms.length; t++) {
        if (transforms[t].type !== "value_map" || !transforms[t].map) continue
        var mapName = transforms[t].map
        for (var v = 0; v < valueMapsModel.count; v++) {
          if (valueMapsModel.get(v).itemId === mapName) {
            valueMapsModel.setProperty(v, "isChecked", checked)
            break
          }
        }
      }
      break
    }
  }

  function _buildSelected() {
    var selFlowIds = {}, selSrcIds = {}, selActIds = {}, selVmKeys = {}, selRemIds = {}
    var i
    for (i = 0; i < flowsModel.count; i++) if (flowsModel.get(i).isChecked) selFlowIds[flowsModel.get(i).itemId] = true
    for (i = 0; i < sourcesModel.count; i++) if (sourcesModel.get(i).isChecked) selSrcIds[sourcesModel.get(i).itemId] = true
    for (i = 0; i < actionsModel.count; i++) if (actionsModel.get(i).isChecked) selActIds[actionsModel.get(i).itemId] = true
    for (i = 0; i < valueMapsModel.count; i++) if (valueMapsModel.get(i).isChecked) selVmKeys[valueMapsModel.get(i).itemId] = true
    for (i = 0; i < remotesModel.count; i++) if (remotesModel.get(i).isChecked) selRemIds[remotesModel.get(i).itemId] = true

    var selectedMaps = {}, hasVm = false
    for (var key in selVmKeys) {
      if (app.value_maps[key] !== undefined) { selectedMaps[key] = app.value_maps[key]; hasVm = true }
    }

    return {
      flows:   app.flows.filter(function(f) { return selFlowIds[f.id] }),
      sources: app.data_sources.filter(function(s) { return selSrcIds[s.id] }),
      actions: app.actions.filter(function(a) { return selActIds[a.id] }),
      maps:    selectedMaps,
      hasVm:   hasVm,
      remotes: app.remotes.filter(function(r) { return selRemIds[r.id] })
    }
  }

  SilicaFlickable {
    anchors.fill: parent
    contentHeight: mainColumn.height

    Column {
      id: mainColumn
      width: parent.width

      DialogHeader {
        title: mode === "upload" ? "Upload to Library" : "Export"
        acceptText: mode === "upload" ? "Upload" : "Export"
      }

      TextField {
        id: exportPathField
        width: parent.width
        visible: mode === "export"
        height: visible ? implicitHeight : 0
        label: "Export Folder Name"
        inputMethodHints: Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText | Qt.ImhLatinOnly
      }

      TextField {
        id: nameField
        width: parent.width
        label: mode === "upload" ? "Example Name" : "Example Name (optional)"
        inputMethodHints: Qt.ImhNoPredictiveText
      }

      TextField {
        id: descriptionField
        width: parent.width
        label: "Description (optional)"
        inputMethodHints: Qt.ImhNoPredictiveText
      }

      Label {
        visible: mode === "upload"
        x: Theme.horizontalPageMargin
        width: parent.width - 2 * Theme.horizontalPageMargin
        text: "Uploads are public. Remove or replace any IP addresses, passwords, or other sensitive data before uploading."
        font.pixelSize: Theme.fontSizeExtraSmall
        color: Theme.secondaryHighlightColor
        wrapMode: Text.WordWrap
      }

      Item { width: 1; height: Theme.paddingSmall; visible: mode === "upload" }

      TextSwitch {
        width: parent.width
        text: "Select All"
        onCheckedChanged: _selectAll(checked)
      }

      ExpandingSection {
        title: "Flows"
        expanded: flowsModel.count < 10
        content.sourceComponent: Component {
          Column {
            width: parent.width
            Repeater {
              model: flowsModel
              delegate: TextSwitch {
                property bool modelChecked: model.isChecked
                width: parent.width
                text: model.itemName
                checked: modelChecked
                onModelCheckedChanged: checked = modelChecked
                onCheckedChanged: {
                  if (modelChecked === checked) return
                  flowsModel.setProperty(index, "isChecked", checked)
                  syncFlowDependencies(model.itemId, checked)
                }
              }
            }
          }
        }
      }

      ExpandingSection {
        title: "Sources"
        expanded: sourcesModel.count < 10
        content.sourceComponent: Component {
          Column {
            width: parent.width
            Repeater {
              model: sourcesModel
              delegate: TextSwitch {
                property bool modelChecked: model.isChecked
                width: parent.width
                text: model.itemName
                checked: modelChecked
                onModelCheckedChanged: checked = modelChecked
                onCheckedChanged: {
                  if (modelChecked === checked) return
                  sourcesModel.setProperty(index, "isChecked", checked)
                  syncSourceValueMaps(model.itemId, checked)
                }
              }
            }
          }
        }
      }

      ExpandingSection {
        title: "Actions"
        expanded: actionsModel.count < 10
        content.sourceComponent: Component {
          Column {
            width: parent.width
            Repeater {
              model: actionsModel
              delegate: TextSwitch {
                property bool modelChecked: model.isChecked
                width: parent.width
                text: model.itemName
                checked: modelChecked
                onModelCheckedChanged: checked = modelChecked
                onCheckedChanged: {
                  if (modelChecked === checked) return
                  actionsModel.setProperty(index, "isChecked", checked)
                }
              }
            }
          }
        }
      }

      ExpandingSection {
        title: "Value Maps"
        expanded: valueMapsModel.count < 10
        content.sourceComponent: Component {
          Column {
            width: parent.width
            Repeater {
              model: valueMapsModel
              delegate: TextSwitch {
                property bool modelChecked: model.isChecked
                width: parent.width
                text: model.itemName
                checked: modelChecked
                onModelCheckedChanged: checked = modelChecked
                onCheckedChanged: {
                  if (modelChecked === checked) return
                  valueMapsModel.setProperty(index, "isChecked", checked)
                }
              }
            }
          }
        }
      }

      ExpandingSection {
        title: "Remotes"
        expanded: remotesModel.count < 10
        content.sourceComponent: Component {
          Column {
            width: parent.width
            Repeater {
              model: remotesModel
              delegate: TextSwitch {
                property bool modelChecked: model.isChecked
                width: parent.width
                text: model.itemName
                checked: modelChecked
                onModelCheckedChanged: checked = modelChecked
                onCheckedChanged: {
                  if (modelChecked === checked) return
                  remotesModel.setProperty(index, "isChecked", checked)
                }
              }
            }
          }
        }
      }

      Item { width: 1; height: Theme.paddingLarge }
    }
  }

  Component.onCompleted: {
    _populateModels()
    if (mode === "export") {
      var now = new Date()
      var stamp = Qt.formatDate(now, "yyyyMMdd") + "_" + Qt.formatTime(now, "HHmmss")
      exportPathField.text = "automagic-export-" + stamp
    }
    if (app.settings && app.settings.display_name)
      nameField.text = ""  // name is per-example, not pre-filled
  }

  onAccepted: {
    var sel = _buildSelected()
    var name = nameField.text.trim()
    var description = descriptionField.text.trim()

    if (mode === "export") {
      var base = (app.settings && app.settings.export_base_path) ? app.settings.export_base_path : ""
      var folder = base + "/" + exportPathField.text.trim() + "/"

      if (name.length > 0) python.save_json_file({ name: name, description: description }, folder + "info.json")
      if (sel.flows.length > 0)   python.save_json_file(sel.flows,   folder + "flows.json")
      if (sel.sources.length > 0) python.save_json_file(sel.sources, folder + "data_sources.json")
      if (sel.actions.length > 0) python.save_json_file(sel.actions, folder + "actions.json")
      if (sel.hasVm)              python.save_json_file(sel.maps,    folder + "value_maps.json")
      if (sel.remotes.length > 0) python.save_json_file(sel.remotes, folder + "remotes.json")

    } else {
      var payload = {
        token:        (app.settings && app.settings.library_token) || "",
        display_name: (app.settings && app.settings.display_name) || "Anonymous",
        name:         name,
        description:  description
      }
      if (sel.flows.length > 0)   payload.flows        = { version: 1, data: sel.flows }
      if (sel.sources.length > 0) payload.data_sources = { version: 1, data: sel.sources }
      if (sel.actions.length > 0) payload.actions      = { version: 1, data: sel.actions }
      if (sel.hasVm)              payload.value_maps   = { version: 1, data: sel.maps }
      if (sel.remotes.length > 0) payload.remotes      = { version: 1, data: sel.remotes }

      var xhr = new XMLHttpRequest()
      xhr.onreadystatechange = function() {
        if (xhr.readyState !== XMLHttpRequest.DONE) return
        if (xhr.status === 200) {
          var resp = JSON.parse(xhr.responseText)
          if (!resp.ok) app.signal_error('ExportDialog', 'upload', resp.message || 'Upload failed')
        } else {
          app.signal_error('ExportDialog', 'upload', 'Upload failed (HTTP ' + xhr.status + ')')
        }
      }
      xhr.open("POST", "https://qml.app/automagic/library_upload.php")
      xhr.setRequestHeader("Content-Type", "application/json")
      xhr.send(JSON.stringify(payload))
    }
  }
}
