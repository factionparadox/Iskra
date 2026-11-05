import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications
import qs.services
import qs.components

// Notifications: the Garden System is the notification daemon. Each one appears top-right as a
// HUD panel with the program's name on a mint plate; it fades after a few seconds (urgent ones stay
// until clicked). Click to dismiss.
Scope {
	id: root

	NotificationServer {
		id: server
		keepOnReload: false
		bodySupported: true
		bodyMarkupSupported: false
		actionsSupported: true
		imageSupported: true
		onNotification: n => n.tracked = true
	}

	PanelWindow {
		visible: server.trackedNotifications.values.length > 0
		anchors { top: true; right: true }
		margins { top: Theme.barHeight + 18; right: 14 }
		implicitWidth: 380
		implicitHeight: column.implicitHeight
		exclusionMode: ExclusionMode.Ignore
		color: "transparent"
		WlrLayershell.layer: WlrLayer.Overlay
		WlrLayershell.namespace: "garden-notifications"

		Column {
			id: column
			width: parent.width
			spacing: 10

			Repeater {
				model: server.trackedNotifications
				delegate: HudPanel {
					id: card
					required property var modelData
					width: column.width
					height: body.implicitHeight + 64
					glow: modelData.urgency === NotificationUrgency.Critical
					stroke: modelData.urgency === NotificationUrgency.Critical ? Theme.magenta : Theme.edge

					NamePlate {
						id: app
						text: (card.modelData.appName || "Avalon").toUpperCase()
						fontSize: Theme.small
					}
					Text {
						id: summary
						anchors { left: parent.left; right: parent.right; top: app.bottom; topMargin: 6 }
						text: card.modelData.summary
						color: Theme.text
						font.family: Theme.font
						font.pixelSize: Theme.normal
						font.bold: true
						elide: Text.ElideRight
					}
					Text {
						id: body
						anchors { left: parent.left; right: parent.right; top: summary.bottom; topMargin: 2 }
						text: card.modelData.body
						color: Theme.mist
						font.family: Theme.font
						font.pixelSize: Theme.small + 1
						wrapMode: Text.Wrap
						maximumLineCount: 4
						elide: Text.ElideRight
					}
					MouseArea {
						anchors.fill: parent
						onClicked: card.modelData.dismiss()
					}
					Timer {
						running: card.modelData.urgency !== NotificationUrgency.Critical
						interval: card.modelData.expireTimeout > 0 ? card.modelData.expireTimeout * 1000 : 6000
						onTriggered: card.modelData.expire()
					}
				}
			}
		}
	}
}
