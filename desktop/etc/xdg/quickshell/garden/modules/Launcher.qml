import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// The launcher (Super+Space), laid out like Pixygarden's main menu: Pasha in a blue spotlight
// on the left, the programs as a column of chevron tabs beside him, a search plate on top.
// Type to search, arrows to move, Enter to start, Escape to close.
PanelWindow {
	id: launcher
	property bool open: false
	function toggle() { open = !open }

	visible: open
	anchors { top: true; bottom: true; left: true; right: true }
	exclusionMode: ExclusionMode.Ignore
	color: "transparent"
	WlrLayershell.layer: WlrLayer.Overlay
	WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
	WlrLayershell.namespace: "garden-launcher"

	onOpenChanged: if (open) { search.text = ""; list.currentIndex = 0; search.forceActiveFocus() }

	readonly property var matches: {
		const q = search.text.trim().toLowerCase()
		const apps = DesktopEntries.applications.values.filter(a => !a.noDisplay)
		const hits = q === "" ? apps : apps.filter(a =>
			a.name.toLowerCase().includes(q)
			|| (a.genericName ?? "").toLowerCase().includes(q)
			|| (a.keywords ?? []).some(k => k.toLowerCase().includes(q)))
		return hits.sort((a, b) => {
			const as = a.name.toLowerCase().startsWith(q), bs = b.name.toLowerCase().startsWith(q)
			return as === bs ? a.name.localeCompare(b.name) : (as ? -1 : 1)
		}).slice(0, 9)
	}

	function launch(entry) {
		if (!entry) return
		entry.execute()
		open = false
	}

	// dim the garden behind
	Rectangle {
		anchors.fill: parent
		color: "#a0050812"
		MouseArea { anchors.fill: parent; onClicked: launcher.open = false }
	}

	Item {
		id: stage
		width: 760; height: 480
		anchors.centerIn: parent

		// Pasha in the spotlight
		Item {
			id: keeper
			width: 220; height: parent.height
			Rectangle {   // the spotlight's pool of light
				width: 190; height: 46
				radius: height / 2
				anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 18 }
				gradient: Gradient {
					orientation: Gradient.Horizontal
					GradientStop { position: 0.0; color: "transparent" }
					GradientStop { position: 0.5; color: "#c05fd8f0" }
					GradientStop { position: 1.0; color: "transparent" }
				}
			}
			Rectangle {   // the beam
				width: 150; height: parent.height - 30
				anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 38 }
				gradient: Gradient {
					GradientStop { position: 0.0; color: "#103a6a9a" }
					GradientStop { position: 1.0; color: "#4d3a8fd0" }
				}
			}
			Image {
				source: "file:///usr/share/avalon/pasha-portrait.png"
				width: 200; height: 200
				fillMode: Image.PreserveAspectFit
				anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 34 }
				smooth: true
			}
		}

		// the search plate
		HudPanel {
			id: searchPanel
			anchors { left: keeper.right; right: parent.right; top: parent.top }
			height: 46
			glow: search.activeFocus
			TextInput {
				id: search
				anchors.fill: parent
				verticalAlignment: TextInput.AlignVCenter
				color: Theme.text
				selectionColor: Theme.cyan
				font.family: Theme.font
				font.pixelSize: Theme.large
				focus: launcher.open
				Text {
					visible: search.text === ""
					text: "› start…"
					color: Theme.textDim
					font: search.font
					anchors.verticalCenter: parent.verticalCenter
				}
				Keys.onEscapePressed: launcher.open = false
				Keys.onDownPressed: list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1)
				Keys.onUpPressed: list.currentIndex = Math.max(0, list.currentIndex - 1)
				Keys.onReturnPressed: launcher.launch(launcher.matches[list.currentIndex])
				Keys.onEnterPressed: launcher.launch(launcher.matches[list.currentIndex])
				onTextChanged: list.currentIndex = 0
			}
		}

		// the programs, as menu tabs
		ListView {
			id: list
			anchors { left: keeper.right; leftMargin: 20; top: searchPanel.bottom; topMargin: 18; right: parent.right; bottom: parent.bottom }
			spacing: 8
			clip: true
			model: launcher.matches
			interactive: false
			delegate: ChevronTab {
				required property var modelData
				required property int index
				width: Math.min(list.width, Math.max(240, implicitWidth))
				height: 34
				text: modelData.name
				glyph: Theme.elementGlyphs[index % 4]
				selected: ListView.isCurrentItem
				onClicked: launcher.launch(modelData)
				x: ListView.isCurrentItem ? 14 : 0
				Behavior on x { NumberAnimation { duration: Theme.quick; easing.type: Easing.OutCubic } }
			}
		}

		// a plate saying what's selected
		NamePlate {
			anchors { right: parent.right; bottom: parent.bottom }
			visible: launcher.matches.length > 0
			text: launcher.matches[list.currentIndex]?.comment || launcher.matches[list.currentIndex]?.genericName || ""
			fontSize: Theme.small
			opacity: text === "" ? 0 : 1
		}
	}
}
