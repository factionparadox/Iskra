import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// The power menu (Super+Shift+Escape): a column of menu tabs with hexagonal ok/cancel feel.
// Arrows and Enter, or click; Escape closes.
PanelWindow {
	id: menu
	property bool open: false
	signal lockRequested()
	function toggle() { open = !open }

	visible: open
	anchors { top: true; bottom: true; left: true; right: true }
	exclusionMode: ExclusionMode.Ignore
	color: "transparent"
	WlrLayershell.layer: WlrLayer.Overlay
	WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
	WlrLayershell.namespace: "garden-power"

	readonly property var choices: [
		{ label: "Lock",      glyph: "土", run: () => menu.lockRequested() },
		{ label: "Suspend",   glyph: "水", run: () => Quickshell.execDetached(["avalon", "power", "suspend"]) },
		{ label: "Log out",   glyph: "風", run: () => Quickshell.execDetached(["mmsg", "dispatch", "quit"]) },
		{ label: "Restart",   glyph: "火", run: () => Quickshell.execDetached(["avalon", "power", "reboot"]) },
		{ label: "Power off", glyph: "火", run: () => Quickshell.execDetached(["avalon", "power", "off"]) }
	]
	property int current: 0
	onOpenChanged: if (open) { current = 0; keys.forceActiveFocus() }

	function choose(i) { open = false; choices[i].run() }

	Rectangle {
		anchors.fill: parent
		color: "#b0050812"
		MouseArea { anchors.fill: parent; onClicked: menu.open = false }
	}

	Item {
		id: keys
		anchors.centerIn: parent
		width: 300; height: column.implicitHeight
		focus: menu.open
		Keys.onEscapePressed: menu.open = false
		Keys.onDownPressed: menu.current = (menu.current + 1) % menu.choices.length
		Keys.onUpPressed: menu.current = (menu.current + menu.choices.length - 1) % menu.choices.length
		Keys.onReturnPressed: menu.choose(menu.current)
		Keys.onEnterPressed: menu.choose(menu.current)

		Column {
			id: column
			spacing: 10
			NamePlate { text: "SESSION"; fontSize: Theme.small }
			Repeater {
				model: menu.choices
				delegate: ChevronTab {
					required property var modelData
					required property int index
					width: 260; height: 38
					text: modelData.label
					glyph: modelData.glyph
					selected: index === menu.current
					x: selected ? 18 : 0
					Behavior on x { NumberAnimation { duration: Theme.quick; easing.type: Easing.OutCubic } }
					onClicked: menu.choose(index)
				}
			}
		}
	}
}
