import QtQuick
import QtQuick.Shapes
import qs.services

// A slanted meter in one of the four element colours, like Pixygarden's elemental bars.
// value runs 0..1; label sits on the left, the number on the right.
Item {
	id: root
	property real value: 0
	property color color: Theme.cyan
	property string label: ""
	property string readout: Math.round(value * 100) + "%"
	property real slant: height * 0.6
	implicitWidth: 120
	implicitHeight: 12

	Shape {
		anchors.fill: parent
		preferredRendererType: Shape.CurveRenderer
		ShapePath {   // the track
			fillColor: "#80000814"
			strokeColor: Theme.edge
			strokeWidth: 1
			startX: root.slant; startY: 0
			PathLine { x: root.width; y: 0 }
			PathLine { x: root.width - root.slant; y: root.height }
			PathLine { x: 0; y: root.height }
			PathLine { x: root.slant; y: 0 }
		}
		ShapePath {   // the fill
			readonly property real w: Math.max(root.slant, (root.width - root.slant) * Math.min(1, Math.max(0, root.value)) + root.slant)
			fillColor: root.color
			strokeColor: "transparent"
			startX: root.slant; startY: 1.5
			PathLine { x: w - 1; y: 1.5 }
			PathLine { x: w - root.slant; y: root.height - 1.5 }
			PathLine { x: 1; y: root.height - 1.5 }
			PathLine { x: root.slant; y: 1.5 }
		}
	}
}
