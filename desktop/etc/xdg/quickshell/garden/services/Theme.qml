pragma Singleton
import QtQuick
import Quickshell

// The Garden System's palette and type. One place to change the look of everything.
Singleton {
	// night and panels
	readonly property color night:      "#070b16"   // behind everything
	readonly property color panel:      "#d90c1426" // deep navy glass (alpha first)
	readonly property color panelSolid: "#0c1426"
	readonly property color panelLift:  "#e6142040"
	readonly property color edge:       "#3a5a8c"   // thin panel border
	readonly property color edgeBright: "#8fd6ff"

	// light
	readonly property color cyan:     "#5fd8f0"     // focus, selection, the crystal glow
	readonly property color ice:      "#bfeaf7"
	readonly property color magenta:  "#ff3fa4"     // urgent, the minimap cursor
	readonly property color mint:     "#bfe3d6"     // name plates
	readonly property color mintText: "#0c1426"
	readonly property color text:     "#eef4fb"
	readonly property color textDim:  "#8fa0bf"
	readonly property color mist:     "#c8c4d8"

	// the four elements: earth, water, wind, fire
	readonly property color earth: "#c9a35a"
	readonly property color water: "#4a64c8"
	readonly property color wind:  "#5bc85b"
	readonly property color fire:  "#e0705a"
	readonly property var elements: [earth, water, wind, fire]
	readonly property var elementGlyphs: ["土", "水", "風", "火"]

	// gradients of the menu tabs (Tutorial / Mission / Pixy Tree...)
	readonly property color tabTop:    "#2f6f8c"
	readonly property color tabBottom: "#10203c"

	// type: a heavy sans for the HUD, a monospace for numbers
	readonly property string font:     "DejaVu Sans"
	readonly property string fontMono: "DejaVu Sans Mono"
	readonly property int small:  11
	readonly property int normal: 13
	readonly property int large:  17

	// geometry: PlayStation-era cut corners
	readonly property int cut: 10
	readonly property int barHeight: 34
	readonly property int gap: 14

	// timing
	readonly property int quick: 140
	readonly property int calm: 260
}
