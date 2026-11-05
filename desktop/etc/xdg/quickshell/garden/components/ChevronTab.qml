import QtQuick
import QtQuick.Shapes
import qs.services

// A menu tab with chevron ends, teal fading to navy, white bold label: Pixygarden's
// Tutorial / Mission / Pixy Tree buttons. Lights up cyan when selected or hovered.
Item {
	id: root
	property string text: ""
	property string glyph: ""
	property bool selected: false
	property int fontSize: Theme.normal
	property real point: height * 0.38
	signal clicked()

	implicitWidth: label.implicitWidth + point * 2 + (glyph ? 26 : 0) + 24
	implicitHeight: 30

	readonly property bool lit: selected || mouse.containsMouse

	Shape {
		anchors.fill: parent
		preferredRendererType: Shape.CurveRenderer
		ShapePath {
			strokeColor: root.lit ? Theme.cyan : Theme.edge
			strokeWidth: 1.2
			fillGradient: LinearGradient {
				x1: 0; y1: 0; x2: 0; y2: root.height
				GradientStop { position: 0; color: root.lit ? "#3fa6c4" : Theme.tabTop }
				GradientStop { position: 1; color: root.lit ? "#163a5c" : Theme.tabBottom }
			}
			startX: root.point; startY: 0
			PathLine { x: root.width - root.point; y: 0 }
			PathLine { x: root.width; y: root.height / 2 }
			PathLine { x: root.width - root.point; y: root.height }
			PathLine { x: root.point; y: root.height }
			PathLine { x: 0; y: root.height / 2 }
			PathLine { x: root.point; y: 0 }
		}
	}

	Row {
		anchors.centerIn: parent
		spacing: 8
		Text {
			visible: root.glyph !== ""
			text: root.glyph
			color: Theme.ice
			font.family: Theme.font
			font.pixelSize: root.fontSize
			font.bold: true
		}
		Text {
			id: label
			text: root.text
			color: Theme.text
			font.family: Theme.font
			font.pixelSize: root.fontSize
			font.bold: true
			style: Text.Raised
			styleColor: "#000814"
		}
	}

	MouseArea {
		id: mouse
		anchors.fill: parent
		hoverEnabled: true
		cursorShape: Qt.PointingHandCursor
		onClicked: root.clicked()
	}

	Behavior on opacity { NumberAnimation { duration: Theme.quick } }
}
