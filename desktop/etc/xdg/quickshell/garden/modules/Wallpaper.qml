import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

// The garden itself, behind every window: Avalon's wallpaper on each screen.
Variants {
	model: Quickshell.screens
	delegate: Component {
		PanelWindow {
			required property var modelData
			screen: modelData
			anchors { top: true; bottom: true; left: true; right: true }
			exclusionMode: ExclusionMode.Ignore
			color: Theme.night
			WlrLayershell.layer: WlrLayer.Background
			WlrLayershell.namespace: "garden-wallpaper"

			Image {
				anchors.fill: parent
				source: "file:///usr/share/avalon/garden-wallpaper.png"
				fillMode: Image.PreserveAspectCrop
				asynchronous: true
				smooth: true
			}
		}
	}
}
