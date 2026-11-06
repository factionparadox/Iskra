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
				// your own picture (Avalon Control links it here), else the garden
				readonly property string garden: "file:///usr/share/avalon/garden-wallpaper.png"
				source: "file://" + Quickshell.env("HOME") + "/.config/avalon/wallpaper"
				onStatusChanged: if (status === Image.Error) source = garden
				fillMode: Image.PreserveAspectCrop
				asynchronous: true
				smooth: true
			}
		}
	}
}
