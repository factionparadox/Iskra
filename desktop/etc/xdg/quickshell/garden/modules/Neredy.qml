import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// Neredy (Super+N): Avalon's local assistant, with Pasha as its face. For now it says whether
// a model is installed; the conversation panel and the Russian tutor mode come next.
PanelWindow {
	id: neredy
	property bool open: false
	function toggle() { open = !open }

	visible: open
	anchors { top: true; right: true; bottom: true }
	margins { top: Theme.barHeight + 18; right: 14; bottom: 14 }
	implicitWidth: 420
	exclusionMode: ExclusionMode.Ignore
	color: "transparent"
	WlrLayershell.layer: WlrLayer.Overlay
	WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
	WlrLayershell.namespace: "garden-neredy"

	HudPanel {
		anchors.fill: parent
		Column {
			anchors.fill: parent
			spacing: 14
			NamePlate { text: "NEREDY"; fontSize: Theme.normal }
			Image {
				anchors.horizontalCenter: parent.horizontalCenter
				source: "file:///usr/share/avalon/pasha-portrait.png"
				width: 160; height: 160
				fillMode: Image.PreserveAspectFit
			}
			Text {
				width: parent.width
				wrapMode: Text.Wrap
				text: "Neredy isn't set up yet. Once a model is downloaded (avalon neredy setup), "
					+ "Pasha will answer here, and teach Russian when you ask."
				color: Theme.mist
				font.family: Theme.font
				font.pixelSize: Theme.normal
			}
		}
	}
}
