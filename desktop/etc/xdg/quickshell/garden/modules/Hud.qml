import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// The Garden System's HUD, laid out like a game screen around the garden:
//   top right     the day counter: the time and date, a 0-40 scale (battery), ♪ what's playing ♪
//   top centre    the focused window's name plate
//   bottom left   the planet panel: AVALON, its planet, the four elements live: wind = power,
//                 earth = memory, fire = processor temperature (°C), water = the song playing
//   bottom right  the minimap: your workstations, a dot per window, the magenta line where you are
// Two strips per screen (top and bottom) reserve their space, so windows sit between them and
// never cover the HUD.
Variants {
	model: Quickshell.screens
	delegate: Component {
		Scope {
			id: screenHud
			required property var modelData
			readonly property var tags: Mango.tagsFor(modelData.name)
			SystemClock { id: clock; precision: SystemClock.Minutes }

			// ================================================================ top strip
			PanelWindow {
				screen: screenHud.modelData
				anchors { top: true; left: true; right: true }
				implicitHeight: 74
				color: "transparent"
				WlrLayershell.namespace: "garden-hud"

				// the focused window
				NamePlate {
					anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 22 }
					visible: Mango.title !== ""
					text: Mango.title.length > 64 ? Mango.title.slice(0, 61) + "…" : Mango.title
					fontSize: Theme.normal
				}

				// the day counter
				Item {
					anchors { right: parent.right; top: parent.top; rightMargin: 22; topMargin: 8 }
					width: 300; height: 64

					Row {
						id: counter
						spacing: 8
						anchors.left: parent.left
						Text {
							text: Qt.formatTime(clock.date, "HH:mm")
							color: Theme.text
							font.family: Theme.fontMono
							font.pixelSize: 22
							font.bold: true
							style: Text.Raised; styleColor: "#000814"
						}
						Text {
							y: 8
							text: Qt.formatDate(clock.date, "ddd d MMM").toLowerCase()
							color: Theme.text
							font.family: Theme.font
							font.pixelSize: Theme.small + 1
							font.bold: true
							style: Text.Raised; styleColor: "#000814"
						}
					}
					HudPanel {
						anchors { top: counter.bottom; topMargin: 2; left: parent.left; right: parent.right }
						height: 28
						cut: 8
						cutTopLeft: true; cutBottomRight: true
						Row {
							anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: -4 }
							Repeater {
								model: [
									{ glyph: "風", color: Theme.wind,  value: () => Stats.charge,       number: () => Math.round(Stats.charge * 100) },
									{ glyph: "土", color: Theme.earth, value: () => Stats.memory,       number: () => Math.round(Stats.memory * 100) },
									{ glyph: "火", color: Theme.fire,  value: () => Stats.heat,         number: () => Math.round(Stats.temperature) },
									{ glyph: "水", color: Theme.water, value: () => Stats.songProgress, number: () => Stats.playing ? Math.round(Stats.songProgress * 100) : 0 }
								]
								delegate: Row {
									required property var modelData
									spacing: 6
									Text {
										text: modelData.glyph
										color: modelData.color
										font.pixelSize: 10
										font.bold: true
									}
									ElementMeter {
										implicitWidth: 78; implicitHeight: 9
										color: modelData.color
										value: modelData.value()
									}
									Text {
										width: 26
										horizontalAlignment: Text.AlignRight
										text: modelData.number()
										color: Theme.text
										font.family: Theme.fontMono
										font.pixelSize: 10
										font.bold: true
									}
								}
							}
						}
					}
				}

				// ---- the minimap: your workstations
				Item {
					id: minimap
					anchors { right: parent.right; bottom: parent.bottom; rightMargin: 22; bottomMargin: 14 }
					width: 340; height: 100
					readonly property var shown: screenHud.tags.length > 0 ? screenHud.tags
						: [1, 2, 3, 4, 5, 6, 7, 8, 9].map(i => ({ index: i, is_active: i === 1, is_urgent: false, client_count: 0 }))

					Shape {
						anchors.fill: parent
						preferredRendererType: Shape.CurveRenderer
						ShapePath {
							fillColor: "#d80a1218"
							strokeColor: "#46765a"
							strokeWidth: 1.5
							startX: 28; startY: 0
							PathLine { x: minimap.width - 28; y: 0 }
							PathLine { x: minimap.width; y: minimap.height / 2 }
							PathLine { x: minimap.width - 28; y: minimap.height }
							PathLine { x: 28; y: minimap.height }
							PathLine { x: 0; y: minimap.height / 2 }
							PathLine { x: 28; y: 0 }
						}
					}
					Row {
						id: cells
						anchors.centerIn: parent
						spacing: 6
						Repeater {
							model: minimap.shown
							delegate: Item {
								id: cell
								required property var modelData
								width: 26; height: 26
								// the workstation's square: green outline, filled when it has windows
								Rectangle {
									anchors.fill: parent
									color: cell.modelData.client_count > 0 ? "#3062d66e" : "transparent"
									border.color: cell.modelData.is_urgent ? Theme.magenta : "#62d66e"
									border.width: 1
								}
								// a dot per window, blue; red when urgent
								Flow {
									anchors.fill: parent
									anchors.margins: 4
									spacing: 3
									Repeater {
										model: Math.min(9, cell.modelData.client_count)
										delegate: Rectangle {
											width: 4; height: 4
											color: cell.modelData.is_urgent ? "#f05050" : "#5a86ff"
										}
									}
								}
								// where you are: the magenta line
								Rectangle {
									visible: cell.modelData.is_active
									anchors.horizontalCenter: parent.horizontalCenter
									y: -32; width: 3; height: 90
									color: Theme.magenta
								}
								Text {
									anchors { horizontalCenter: parent.horizontalCenter; top: parent.bottom; topMargin: 2 }
									text: cell.modelData.index
									color: cell.modelData.is_active ? Theme.text : Theme.textDim
									font.family: Theme.fontMono
									font.pixelSize: 9
								}
								MouseArea {
									anchors.fill: parent
									cursorShape: Qt.PointingHandCursor
									onClicked: Mango.view(cell.modelData.index)
								}
							}
						}
					}
				}
			}
		}
	}
}
