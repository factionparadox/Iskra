import QtQuick
import QtQuick.Shapes
import qs.services

// A pale mint plate with a slanted right end, like the name tags over Pixygarden's pixies.
Item {
	id: root
	property string text: ""
	property int fontSize: Theme.normal
	implicitWidth: label.implicitWidth + 40
	implicitHeight: fontSize + 14

	Shape {
		anchors.fill: parent
		preferredRendererType: Shape.CurveRenderer
		ShapePath {
			fillColor: Theme.mint
			strokeColor: "#ffffff"
			strokeWidth: 1
			startX: root.height * 0.5; startY: 0
			PathLine { x: root.width - root.height * 0.5; y: 0 }
			PathLine { x: root.width; y: root.height / 2 }
			PathLine { x: root.width - root.height * 0.5; y: root.height }
			PathLine { x: root.height * 0.5; y: root.height }
			PathLine { x: 0; y: root.height / 2 }
			PathLine { x: root.height * 0.5; y: 0 }
		}
	}
	Text {
		id: label
		anchors.verticalCenter: parent.verticalCenter
		x: root.height * 0.7
		text: root.text
		color: Theme.mintText
		font.family: Theme.font
		font.pixelSize: root.fontSize
		font.bold: true
	}
}
