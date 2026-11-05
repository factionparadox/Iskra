import QtQuick
import QtQuick.Shapes
import qs.services

// A Garden System panel: deep navy glass with cut corners and a thin bright border, the shape of
// Pixygarden's HUD boxes. cutTopLeft... choose which corners are cut.
Item {
	id: root
	property color fill: Theme.panel
	property color stroke: Theme.edge
	property real strokeWidth: 1.5
	property real cut: Theme.cut
	property bool cutTopLeft: true
	property bool cutTopRight: false
	property bool cutBottomLeft: false
	property bool cutBottomRight: true
	property bool glow: false
	default property alias content: inner.data

	readonly property real tl: cutTopLeft ? cut : 0
	readonly property real tr: cutTopRight ? cut : 0
	readonly property real bl: cutBottomLeft ? cut : 0
	readonly property real br: cutBottomRight ? cut : 0

	Shape {
		anchors.fill: parent
		preferredRendererType: Shape.CurveRenderer
		ShapePath {
			fillColor: root.fill
			strokeColor: root.glow ? Theme.cyan : root.stroke
			strokeWidth: root.strokeWidth
			joinStyle: ShapePath.MiterJoin
			startX: root.tl; startY: 0
			PathLine { x: root.width - root.tr; y: 0 }
			PathLine { x: root.width; y: root.tr }
			PathLine { x: root.width; y: root.height - root.br }
			PathLine { x: root.width - root.br; y: root.height }
			PathLine { x: root.bl; y: root.height }
			PathLine { x: 0; y: root.height - root.bl }
			PathLine { x: 0; y: root.tl }
			PathLine { x: root.tl; y: 0 }
		}
	}

	Item {
		id: inner
		anchors.fill: parent
		anchors.margins: root.cut * 0.6
	}
}
