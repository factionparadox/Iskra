import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// The star system (Super+Tab): your workstations as planets around a star, to visit.
// The list on the left names them; arrows move between them, Enter (or ok) visits,
// Escape (or cancel) closes. Planets grow with the windows on them; yours has a cyan ring.
PanelWindow {
	id: sys
	property bool open: false
	function toggle() { open = !open }

	// the planets' names, one per workstation: rename them here
	readonly property var names: ["ISKRA", "ZARYA", "VOSTOK", "SOYUZ", "MIR", "LUNA", "KOSMOS", "BURAN", "SALYUT"]

	visible: open
	anchors { top: true; bottom: true; left: true; right: true }
	exclusionMode: ExclusionMode.Ignore
	color: "transparent"
	WlrLayershell.layer: WlrLayer.Overlay
	WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
	WlrLayershell.namespace: "garden-starsystem"

	readonly property var tags: Mango.tagsFor(screen?.name ?? "")
	readonly property var planets: (tags.length > 0 ? tags : [1, 2, 3, 4, 5, 6, 7, 8, 9].map(i => ({ index: i, is_active: i === 1, is_urgent: false, client_count: 0 })))
	property int current: 0
	property real spin: 0

	onOpenChanged: if (open) {
		current = Math.max(0, planets.findIndex(p => p.is_active))
		keys.forceActiveFocus()
	}
	function visit(i) {
		const p = planets[i]
		if (p) Mango.view(p.index)
		open = false
	}

	// the orbits turn only while the view is open
	NumberAnimation on spin { from: 0; to: 360; duration: 240000; loops: Animation.Infinite; running: sys.open }

	// deep space behind
	Rectangle {
		anchors.fill: parent
		gradient: Gradient {
			GradientStop { position: 0; color: "#f0081440" }
			GradientStop { position: 0.6; color: "#f2040812" }
			GradientStop { position: 1; color: "#f8020408" }
		}
	}
	Repeater {   // stars
		model: 140
		delegate: Rectangle {
			required property int index
			x: (index * 7919 % 997) / 997 * sys.width
			y: (index * 104729 % 991) / 991 * sys.height
			width: index % 9 === 0 ? 2 : 1; height: width
			color: index % 5 === 0 ? "#bfeaf7" : "#8090b0"
			opacity: 0.4 + (index % 7) / 10
		}
	}

	Item {
		id: keys
		anchors.fill: parent
		focus: sys.open
		Keys.onEscapePressed: sys.open = false
		Keys.onDownPressed: sys.current = (sys.current + 1) % sys.planets.length
		Keys.onRightPressed: sys.current = (sys.current + 1) % sys.planets.length
		Keys.onUpPressed: sys.current = (sys.current + sys.planets.length - 1) % sys.planets.length
		Keys.onLeftPressed: sys.current = (sys.current + sys.planets.length - 1) % sys.planets.length
		Keys.onReturnPressed: sys.visit(sys.current)
		Keys.onEnterPressed: sys.visit(sys.current)
		Keys.onPressed: e => { if (e.key >= Qt.Key_1 && e.key <= Qt.Key_9) sys.visit(e.key - Qt.Key_1) }
	}

	// ---------------------------------------------------------------- the title
	Row {
		x: 60; y: 60
		spacing: 6
		Text { text: "❛"; color: "#3a9cff"; font.pixelSize: 54; font.bold: true }
		Rectangle {
			width: title.implicitWidth + 24; height: 50
			anchors.verticalCenter: parent.verticalCenter
			gradient: Gradient {
				orientation: Gradient.Horizontal
				GradientStop { position: 0; color: "#1a3a8a" }
				GradientStop { position: 1; color: "#002a60c0" }
			}
			Text {
				id: title
				anchors.centerIn: parent
				text: "AVALON 星系"
				color: Theme.text
				font.family: Theme.font
				font.pixelSize: 36
				font.bold: true
			}
		}
		Text { text: "❜"; color: "#3a9cff"; font.pixelSize: 54; font.bold: true }
	}

	// ----------------------------------------------------------- the planet list
	Column {
		x: 66; y: 150
		spacing: 16
		Repeater {
			model: sys.planets
			delegate: Item {
				id: entry
				required property var modelData
				required property int index
				width: 380; height: 40
				readonly property bool chosen: index === sys.current
				Rectangle {   // the dark gradient bar under each name
					anchors.bottom: parent.bottom
					width: parent.width * 0.85; height: 22
					gradient: Gradient {
						orientation: Gradient.Horizontal
						GradientStop { position: 0; color: entry.chosen ? "#3a6ad0" : "#2a3050" }
						GradientStop { position: 1; color: "transparent" }
					}
				}
				Text {
					x: entry.chosen ? 12 : 0
					anchors.verticalCenter: parent.verticalCenter
					text: sys.names[(entry.modelData.index - 1) % sys.names.length]
					color: entry.chosen ? Theme.text : "#b8bccc"
					font.family: Theme.font
					font.pixelSize: 26
					font.bold: true
					font.letterSpacing: 4
					style: Text.Raised; styleColor: "#000814"
					Behavior on x { NumberAnimation { duration: Theme.quick } }
				}
				Text {
					anchors { right: parent.right; verticalCenter: parent.verticalCenter }
					text: entry.modelData.client_count > 0 ? entry.modelData.client_count + (entry.modelData.client_count === 1 ? " window" : " windows") : ""
					color: Theme.textDim
					font.family: Theme.font
					font.pixelSize: Theme.small
				}
				MouseArea {
					anchors.fill: parent
					hoverEnabled: true
					onEntered: sys.current = entry.index
					onClicked: sys.visit(entry.index)
				}
			}
		}
	}

	// ------------------------------------------------------------ the system
	Item {
		id: orrery
		x: sys.width * 0.36; y: sys.height * 0.18
		width: sys.width * 0.6; height: sys.height * 0.66
		readonly property real cx: width / 2
		readonly property real cy: height / 2
		readonly property real tilt: -0.14            // the orbital plane, tipped as in the game
		readonly property real squash: 0.36

		// the orbits
		Repeater {
			model: sys.planets.length
			delegate: Shape {
				id: orbit
				required property int index
				anchors.fill: parent
				preferredRendererType: Shape.CurveRenderer
				readonly property real a: (index + 1) * orrery.width * 0.052 + orrery.width * 0.04
				transform: Rotation { origin.x: orrery.cx; origin.y: orrery.cy; angle: orrery.tilt * 57.3 }
				ShapePath {
					strokeColor: index === sys.current ? "#4a5ab8" : "#2a2f6a"
					strokeWidth: index === sys.current ? 2 : 1.2
					fillColor: "transparent"
					PathAngleArc {
						centerX: orrery.cx; centerY: orrery.cy
						radiusX: orbit.a; radiusY: orbit.a * orrery.squash
						startAngle: 0; sweepAngle: 360
					}
				}
			}
		}

		// the star: Avalon's sun
		Rectangle {
			x: orrery.cx - 34; y: orrery.cy - 34; width: 68; height: 68; radius: 34
			gradient: Gradient {
				GradientStop { position: 0; color: "#80ffffff" }
				GradientStop { position: 1; color: "#00bfeaf7" }
			}
		}
		Rectangle {
			x: orrery.cx - 13; y: orrery.cy - 13; width: 26; height: 26; radius: 13
			color: "#ffffff"
		}

		// the planets, each on its orbit, turning slowly
		Repeater {
			model: sys.planets
			delegate: Item {
				id: planet
				required property var modelData
				required property int index
				readonly property real a: (index + 1) * orrery.width * 0.052 + orrery.width * 0.04
				readonly property real angle: (index * 47 + sys.spin * (1.6 - index * 0.12)) * Math.PI / 180
				readonly property real ox: Math.cos(angle) * a
				readonly property real oy: Math.sin(angle) * a * orrery.squash
				// tip the orbital plane
				readonly property real px: orrery.cx + ox * Math.cos(orrery.tilt) - oy * Math.sin(orrery.tilt)
				readonly property real py: orrery.cy + ox * Math.sin(orrery.tilt) + oy * Math.cos(orrery.tilt)
				readonly property real size: 14 + Math.min(6, modelData.client_count) * 4
				readonly property color tint: modelData.is_urgent ? Theme.magenta : Theme.elements[(modelData.index - 1) % 4]
				x: px - size / 2; y: py - size / 2
				width: size; height: size
				z: oy   // nearer the viewer in front

				Rectangle {   // the cyan ring: where you are
					visible: planet.modelData.is_active
					anchors.centerIn: parent
					width: parent.width + 14; height: width; radius: width / 2
					color: "transparent"
					border.color: Theme.cyan; border.width: 2
				}
				Rectangle {   // the world, lit from the star
					anchors.fill: parent
					radius: width / 2
					gradient: Gradient {
						GradientStop { position: 0; color: Qt.lighter(planet.tint, 1.5) }
						GradientStop { position: 0.6; color: planet.tint }
						GradientStop { position: 1; color: Qt.darker(planet.tint, 2.2) }
					}
					opacity: planet.modelData.client_count > 0 || planet.modelData.is_active ? 1 : 0.55
				}
				Rectangle {   // a band, as across the game's red planet
					visible: planet.index % 3 === 1
					anchors.centerIn: parent
					width: parent.width * 1.5; height: 3
					color: Qt.lighter(planet.tint, 1.4)
					opacity: 0.8
					rotation: -12
				}
				NamePlate {   // the chosen planet's name
					visible: planet.index === sys.current
					anchors { left: parent.right; leftMargin: 12; verticalCenter: parent.verticalCenter }
					text: sys.names[(planet.modelData.index - 1) % sys.names.length]
					fontSize: Theme.small
				}
				MouseArea {
					anchors.fill: parent
					anchors.margins: -8
					hoverEnabled: true
					onEntered: sys.current = planet.index
					onClicked: sys.visit(planet.index)
				}
			}
		}
	}

	// ------------------------------------------------------------- ok / cancel
	Column {
		anchors { right: parent.right; bottom: parent.bottom; rightMargin: 70; bottomMargin: 80 }
		spacing: 18
		HexButton { width: 240; height: 50; text: "ok"; icon: "circle"; onClicked: sys.visit(sys.current) }
		HexButton { x: -60; width: 240; height: 50; text: "cancel"; icon: "cross"; onClicked: sys.open = false }
	}
}
