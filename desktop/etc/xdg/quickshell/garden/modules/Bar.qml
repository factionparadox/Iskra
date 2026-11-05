import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import qs.services
import qs.components

// The Garden System's bar: workstations on the left as crystal markers, the focused window on a
// mint name plate in the middle, and on the right the element meters (battery, sound), the
// keyboard layout and the clock, in a HUD panel.
Variants {
	model: Quickshell.screens
	delegate: Component {
		PanelWindow {
			id: bar
			required property var modelData
			screen: modelData
			anchors { top: true; left: true; right: true }
			implicitHeight: Theme.barHeight + 10
			color: "transparent"
			WlrLayershell.namespace: "garden-bar"

			readonly property var tags: Mango.tagsFor(modelData.name)

			PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
			SystemClock { id: clock; precision: SystemClock.Minutes }

			// ---- left: Avalon and the workstations
			HudPanel {
				id: left
				anchors { left: parent.left; top: parent.top; leftMargin: 10; topMargin: 6 }
				height: Theme.barHeight
				width: leftRow.implicitWidth + 30
				cutTopLeft: false; cutBottomLeft: true; cutTopRight: true; cutBottomRight: false

				RowLayout {
					id: leftRow
					anchors.verticalCenter: parent.verticalCenter
					spacing: 10
					Text {
						text: "AVALON"
						color: Theme.ice
						font.family: Theme.font
						font.pixelSize: Theme.small
						font.bold: true
						font.letterSpacing: 2
					}
					Repeater {
						model: bar.tags.length > 0 ? bar.tags : [1, 2, 3, 4, 5].map(i => ({ index: i, is_active: i === 1, is_urgent: false, client_count: 0 }))
						delegate: Item {
							required property var modelData
							required property int index
							implicitWidth: 16; implicitHeight: 20
							visible: modelData.is_active || modelData.client_count > 0 || modelData.index <= 5
							// a little crystal: the active one glows cyan, the urgent one magenta,
							// occupied ones take their element's colour, empty ones are outlines
							Rectangle {
								anchors.centerIn: parent
								width: modelData.is_active ? 11 : 8
								height: width
								rotation: 45
								color: modelData.is_urgent ? Theme.magenta
									: modelData.is_active ? Theme.cyan
									: modelData.client_count > 0 ? Theme.elements[(modelData.index - 1) % 4]
									: "transparent"
								border.color: modelData.is_active ? Theme.ice : Theme.edgeBright
								border.width: 1
								Behavior on width { NumberAnimation { duration: Theme.quick } }
							}
							MouseArea {
								anchors.fill: parent
								cursorShape: Qt.PointingHandCursor
								onClicked: Mango.view(modelData.index)
							}
						}
					}
				}
			}

			// ---- middle: the focused window
			NamePlate {
				anchors.horizontalCenter: parent.horizontalCenter
				anchors.top: parent.top
				anchors.topMargin: 6 + (Theme.barHeight - height) / 2
				visible: Mango.title !== ""
				text: Mango.title.length > 60 ? Mango.title.slice(0, 57) + "…" : Mango.title
				fontSize: Theme.small + 1
			}

			// ---- right: element meters, layout, clock
			HudPanel {
				anchors { right: parent.right; top: parent.top; rightMargin: 10; topMargin: 6 }
				height: Theme.barHeight
				width: rightRow.implicitWidth + 34
				cutTopLeft: true; cutBottomLeft: false; cutTopRight: false; cutBottomRight: true

				RowLayout {
					id: rightRow
					anchors.verticalCenter: parent.verticalCenter
					anchors.right: parent.right
					spacing: 14

					// sound: water
					RowLayout {
						spacing: 5
						readonly property var sink: Pipewire.defaultAudioSink
						visible: sink !== null
						Text { text: "水"; color: Theme.water; font.pixelSize: Theme.small; font.bold: true }
						ElementMeter {
							implicitWidth: 64
							color: parent.sink?.audio?.muted ? Theme.textDim : Theme.water
							value: parent.sink?.audio?.volume ?? 0
						}
					}

					// battery: wind (green), fire when low
					RowLayout {
						spacing: 5
						readonly property var dev: UPower.displayDevice
						readonly property real level: dev ? (dev.percentage > 1 ? dev.percentage / 100 : dev.percentage) : 0
						readonly property bool charging: dev && dev.state === UPowerDeviceState.Charging
						visible: dev !== null && dev.isLaptopBattery
						Text { text: parent.charging ? "⚡" : "風"; color: Theme.wind; font.pixelSize: Theme.small; font.bold: true }
						ElementMeter {
							implicitWidth: 64
							color: parent.level < 0.15 ? Theme.fire : Theme.wind
							value: parent.level
						}
						Text {
							text: Math.round(parent.level * 100)
							color: Theme.text
							font.family: Theme.fontMono
							font.pixelSize: Theme.small
						}
					}

					// keyboard layout
					Text {
						text: Mango.layout === "ru" ? "РУ" : "GB"
						color: Mango.layout === "ru" ? Theme.magenta : Theme.ice
						font.family: Theme.font
						font.pixelSize: Theme.small
						font.bold: true
					}

					// the clock, in the style of "12days left"
					Column {
						spacing: -2
						Text {
							text: Qt.formatTime(clock.date, "HH:mm")
							color: Theme.text
							font.family: Theme.fontMono
							font.pixelSize: Theme.normal + 1
							font.bold: true
							anchors.right: parent.right
						}
						Text {
							text: Qt.formatDate(clock.date, "ddd dd MMM").toUpperCase()
							color: Theme.textDim
							font.family: Theme.font
							font.pixelSize: 9
							font.letterSpacing: 1
							anchors.right: parent.right
						}
					}
				}
			}
		}
	}
}
