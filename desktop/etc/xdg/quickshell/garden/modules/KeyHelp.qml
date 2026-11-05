import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// The key reference (Super+/): every Garden System key, grouped like a game's controls screen.
// Any key or click closes it.
PanelWindow {
	id: help
	property bool open: false
	function toggle() { open = !open }

	visible: open
	anchors { top: true; bottom: true; left: true; right: true }
	exclusionMode: ExclusionMode.Ignore
	color: "transparent"
	WlrLayershell.layer: WlrLayer.Overlay
	WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
	WlrLayershell.namespace: "garden-keyhelp"
	onOpenChanged: if (open) closer.forceActiveFocus()

	readonly property var groups: [
		{ title: "Workstations", keys: [
			["Super + 1 … 9", "Go to workstation 1 … 9"],
			["Super + Shift + 1 … 9", "Send the window to workstation 1 … 9"],
			["Super + Tab", "Overview of workstations and windows"],
			["Super + scroll", "Previous / next workstation"] ] },
		{ title: "Applications", keys: [
			["Super + Space", "Launcher"],
			["Super + T", "kitty"],
			["Super + W", "Firefox"],
			["Super + E", "Files"],
			["Super + D", "Discord"],
			["Super + V", "Video"],
			["Super + A", "ani-cli"],
			["Super + P", "Proton VPN"],
			["Super + N", "Neredy"] ] },
		{ title: "Windows", keys: [
			["Super + Q", "Close the window"],
			["Super + F", "Column full width"],
			["Super + R", "Column width: 33 → 50 → 67 → 100%"],
			["Super + Shift + Space", "Floating / tiled"],
			["Super + arrows", "Move focus"],
			["Super + Shift + ← →", "Swap with the neighbour"],
			["Super + drag", "Move (left) / resize (right)"],
			["3 fingers ← →", "Scroll the columns"],
			["4 fingers ← →", "Next / previous workstation"] ] },
		{ title: "Session", keys: [
			["Super + X", "Lock"],
			["Super + Z", "Suspend"],
			["Super + Shift + Esc", "Power menu"],
			["Super + Shift + S", "Screenshot of an area"],
			["Super + Shift + R", "Reload Mango's settings"],
			["Alt + Shift", "Keyboard: GB ⇄ РУ"],
			["Super + /", "This reference"] ] }
	]

	Rectangle {
		anchors.fill: parent
		color: "#c0050812"
		MouseArea { anchors.fill: parent; onClicked: help.open = false }
	}
	Item {
		id: closer
		focus: help.open
		Keys.onPressed: help.open = false
	}

	GridLayout {
		anchors.centerIn: parent
		columns: 2
		columnSpacing: 30
		rowSpacing: 24

		Repeater {
			model: help.groups
			delegate: HudPanel {
				required property var modelData
				required property int index
				Layout.preferredWidth: 440
				Layout.preferredHeight: keyCol.implicitHeight + 60
				stroke: Theme.elements[index % 4]

				Column {
					id: keyCol
					width: parent.width
					spacing: 6
					NamePlate { text: modelData.title.toUpperCase(); fontSize: Theme.small }
					Repeater {
						model: modelData.keys
						delegate: Row {
							required property var modelData
							spacing: 12
							Text {
								width: 170
								text: modelData[0]
								color: Theme.cyan
								font.family: Theme.fontMono
								font.pixelSize: Theme.small + 1
								font.bold: true
							}
							Text {
								text: modelData[1]
								color: Theme.text
								font.family: Theme.font
								font.pixelSize: Theme.small + 1
							}
						}
					}
				}
			}
		}
	}
}
