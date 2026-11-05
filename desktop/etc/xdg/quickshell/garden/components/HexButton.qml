import QtQuick
import QtQuick.Shapes
import qs.services

// A pale hexagonal button with its own hexagonal icon badge beside it, like the game's
// ok (○) and cancel (×) buttons. icon: "circle" or "cross".
Item {
	id: root
	property string text: "ok"
	property string icon: "circle"
	property bool lit: mouse.containsMouse
	signal clicked()
	implicitWidth: 200
	implicitHeight: 44

	readonly property real badge: height * 1.1
	readonly property real point: height * 0.42

	Shape {   // the label plate
		width: root.width - root.badge * 0.7
		height: root.height
		preferredRendererType: Shape.CurveRenderer
		ShapePath {
			strokeColor: root.lit ? Theme.cyan : "#9fb2a8"
			strokeWidth: 1.5
			fillGradient: LinearGradient {
				x1: 0; y1: 0; x2: 0; y2: root.height
				GradientStop { position: 0; color: "#e6efe9" }
				GradientStop { position: 1; color: "#b9c8c0" }
			}
			readonly property real w: root.width - root.badge * 0.7
			startX: root.point; startY: 0
			PathLine { x: w - root.point; y: 0 }
			PathLine { x: w; y: root.height / 2 }
			PathLine { x: w - root.point; y: root.height }
			PathLine { x: root.point; y: root.height }
			PathLine { x: 0; y: root.height / 2 }
			PathLine { x: root.point; y: 0 }
		}
	}
	Text {
		x: root.point + 6
		anchors.verticalCenter: parent.verticalCenter
		text: root.text
		color: "#141c24"
		font.family: Theme.font
		font.pixelSize: root.height * 0.46
		font.bold: true
		font.letterSpacing: 2
	}

	Item {   // the icon badge
		id: badgeBox
		x: root.width - root.badge
		y: root.height * 0.42
		width: root.badge; height: root.badge * 0.84
		Shape {
			anchors.fill: parent
			preferredRendererType: Shape.CurveRenderer
			ShapePath {
				strokeColor: "#9fb2a8"; strokeWidth: 1.5
				fillColor: "#d7e2dc"
				readonly property real q: badgeBox.width * 0.27
				startX: q; startY: 0
				PathLine { x: badgeBox.width - q; y: 0 }
				PathLine { x: badgeBox.width; y: badgeBox.height / 2 }
				PathLine { x: badgeBox.width - q; y: badgeBox.height }
				PathLine { x: q; y: badgeBox.height }
				PathLine { x: 0; y: badgeBox.height / 2 }
				PathLine { x: q; y: 0 }
			}
		}
		Rectangle {   // a dark disc holding the symbol
			anchors.centerIn: parent
			width: parent.height * 0.74; height: width; radius: width / 2
			color: "#2a2f38"
			Rectangle {
				visible: root.icon === "circle"
				anchors.centerIn: parent
				width: parent.width * 0.62; height: width; radius: width / 2
				color: "transparent"
				border.color: "#ff6a2a"; border.width: 3
			}
			Text {
				visible: root.icon === "cross"
				anchors.centerIn: parent
				text: "×"
				color: "#5aa8ff"
				font.pixelSize: parent.width * 0.8
			}
		}
	}

	MouseArea {
		id: mouse
		anchors.fill: parent
		hoverEnabled: true
		cursorShape: Qt.PointingHandCursor
		onClicked: root.clicked()
	}
}
