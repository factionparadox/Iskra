import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// Command Mode (Super+;): run the Garden by typing, in the game's dialogue box.
//   visit 3 · visit soyuz · send 2 · open web · run CMD · term [CMD] · volume 40 · brightness 60
//   wifi on · bluetooth off · night on · ask … (Neredy) · say … (in Russian) · settings [page]
//   update · lock · suspend · restart · off · shot · reload · help
// Type, and the commands that fit are listed: Up/Down choose, Tab fills in, Enter runs.
// With the line empty, Up/Down go back through what you ran before. Escape closes.
PanelWindow {
	id: cmd
	property bool open: false
	function toggle() { open = !open }

	// set by shell.qml: the panels some commands open
	property var neredy
	property var lock
	property var starNames: ["ISKRA", "ZARYA", "VOSTOK", "SOYUZ", "MIR", "LUNA", "KOSMOS", "BURAN", "SALYUT"]

	property string message: ""
	property bool failed: false
	property var history: []
	property int back: -1

	visible: open
	anchors { top: true; bottom: true; left: true; right: true }
	exclusionMode: ExclusionMode.Ignore
	color: "transparent"
	WlrLayershell.layer: WlrLayer.Overlay
	WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
	WlrLayershell.namespace: "garden-command"

	onOpenChanged: if (open) { line.text = ""; message = ""; failed = false; back = -1; list.currentIndex = 0; line.forceActiveFocus() }

	function sh(args) { Quickshell.execDetached(args) }
	function stay(args) { Quickshell.execDetached(args); return false }       // run it, keep the box open
	function tell(text, bad) { message = text; failed = !!bad; return false }  // false: stay open
	function percent(a) { const n = parseInt(a, 10); return isNaN(n) ? -1 : Math.max(0, Math.min(100, n)) }

	function planet(a) {
		const n = parseInt(a, 10)
		if (n >= 1 && n <= 9) return n
		const i = starNames.findIndex(s => s.toLowerCase() === (a ?? "").toLowerCase())
		return i >= 0 ? i + 1 : 0
	}

	// every command: its name, what it takes, what it does, and how. run() returns false to
	// keep Command Mode open (for help and mistakes), anything else closes it.
	readonly property var commands: [
		{ name: "visit", args: "1–9 or a planet", what: "go to a workstation", run: a => {
			const n = planet(a[0]); if (!n) return tell("visit which planet? 1–9, or " + starNames.join(", ").toLowerCase(), true)
			Mango.view(n) } },
		{ name: "send", args: "1–9 or a planet", what: "move this window to a workstation", run: a => {
			const n = planet(a[0]); if (!n) return tell("send it where? 1–9, or a planet's name", true)
			Mango.run("tag," + n + ",0") } },
		{ name: "open", args: "web, discord, video, files, anime, vpn, or any program", what: "start a program", run: a => {
			const q = a.join(" ").toLowerCase()
			if (["web", "discord", "video", "files", "anime", "vpn"].includes(q)) return sh(["avalon-open", q])
			const hit = DesktopEntries.applications.values.find(e => !e.noDisplay && e.name.toLowerCase().includes(q))
			if (!q || !hit) return tell(q ? "no program called " + q : "open what?", true)
			hit.execute() } },
		{ name: "run", args: "a command", what: "run a shell command", run: a => {
			if (!a.length) return tell("run what?", true)
			sh(["sh", "-c", a.join(" ")]) } },
		{ name: "term", args: "[a command]", what: "a terminal (running the command, if given)", run: a =>
			sh(a.length ? ["kitty", "--hold", "sh", "-c", a.join(" ")] : ["kitty"]) },
		{ name: "volume", args: "0–100, up, down, mute", what: "sound volume", run: a => {
			const s = "@DEFAULT_AUDIO_SINK@"
			if (a[0] === "up") return stay(["wpctl", "set-volume", "-l", "1.0", s, "5%+"])
			if (a[0] === "down") return stay(["wpctl", "set-volume", s, "5%-"])
			if (a[0] === "mute") return sh(["wpctl", "set-mute", s, "toggle"])
			const p = percent(a[0]); if (p < 0) return tell("volume: 0–100, up, down or mute", true)
			sh(["wpctl", "set-volume", s, p + "%"]) } },
		{ name: "brightness", args: "0–100, up, down", what: "screen brightness", run: a => {
			if (a[0] === "up") return stay(["brightnessctl", "set", "5%+"])
			if (a[0] === "down") return stay(["brightnessctl", "set", "5%-"])
			const p = percent(a[0]); if (p < 1) return tell("brightness: 1–100, up or down", true)
			sh(["brightnessctl", "set", p + "%"]) } },
		{ name: "wifi", args: "[on, off]", what: "Wi-Fi on or off; on its own, nmtui", run: a => {
			if (a[0] === "on" || a[0] === "off") return sh(["nmcli", "radio", "wifi", a[0]])
			sh(["kitty", "--title", "Wi-Fi", "nmtui"]) } },
		{ name: "bluetooth", args: "[on, off]", what: "Bluetooth on or off; on its own, its settings", run: a => {
			if (a[0] === "on" || a[0] === "off") return sh(["bluetoothctl", "power", a[0]])
			sh(["avalon-control", "bluetooth"]) } },
		{ name: "night", args: "on, off", what: "warmer colours at night (wlsunset)", run: a => {
			if (a[0] === "off") return sh(["pkill", "-x", "wlsunset"])
			sh(["sh", "-c", "pgrep -x wlsunset >/dev/null || exec wlsunset -t 3500 -T 6500"]) } },
		{ name: "ask", args: "a question", what: "ask Neredy", run: a => {
			if (!neredy) return tell("Neredy isn't here", true)
			neredy.open = true
			if (a.length) neredy.send(a.join(" ")) } },
		{ name: "say", args: "Russian text", what: "Neredy reads it aloud", run: a => {
			if (!a.length) return tell("say what? (in Russian)", true)
			sh(["neredy", "say", a.join(" ")]) } },
		{ name: "settings", args: "[page]", what: "Avalon Control (appearance, display, sound, network…)", run: a =>
			sh(["avalon-control"].concat(a.slice(0, 1))) },
		{ name: "update", args: "", what: "update Avalon (HECTAS, then Metamelayer), in a terminal", run: a =>
			sh(["kitty", "--hold", "avalon", "update"]) },
		{ name: "install", args: "a package", what: "install from Guix or Nonguix (HECTAS)", run: a => {
			if (!a.length) return tell("install what?", true)
			sh(["kitty", "--hold", "hectas", "install"].concat(a)) } },
		{ name: "nix", args: "a package", what: "install from nixpkgs (Metamelayer)", run: a => {
			if (!a.length) return tell("install what from nixpkgs?", true)
			sh(["kitty", "--hold", "metamelayer", "install"].concat(a)) } },
		{ name: "flatpak", args: "an app id", what: "install a Flatpak from Flathub (e.g. org.vinegarhq.Sober)", run: a => {
			if (!a.length) return tell("which Flatpak? e.g. org.vinegarhq.Sober", true)
			sh(["kitty", "--hold", "hectas", "flatpak", a[0]]) } },
		{ name: "lock", args: "", what: "lock the screen", run: a => { if (lock) lock.lock() } },
		{ name: "suspend", args: "", what: "sleep", run: a => sh(["avalon", "power", "suspend"]) },
		{ name: "restart", args: "", what: "restart the laptop", run: a => sh(["avalon", "power", "reboot"]) },
		{ name: "off", args: "", what: "turn the laptop off", run: a => sh(["avalon", "power", "off"]) },
		{ name: "shot", args: "", what: "screenshot of an area, to edit and save", run: a =>
			sh(["sh", "-c", "sleep 0.3; grim -g \"$(slurp)\" - | swappy -f -"]) },
		{ name: "reload", args: "", what: "restart the Garden System", run: a => sh(["garden", "reload"]) },
		{ name: "help", args: "", what: "every command", run: a => {
			line.text = ""; return tell("every command is listed: Up/Down to choose, Tab to fill in") } }
	]

	readonly property string word: line.text.trimStart().split(/\s+/)[0].toLowerCase()
	readonly property var matches: {
		const w = word
		const prefix = commands.filter(c => c.name.startsWith(w))
		const exact = commands.filter(c => c.name === w)
		// once you're typing what follows the name, just the command you're in
		return /\s/.test(line.text.trimStart()) && exact.length ? exact : prefix
	}

	function complete() {
		const c = matches[list.currentIndex]
		if (c) line.text = c.name + " "
	}

	function execute() {
		const text = line.text.trim()
		if (!text) return
		const parts = text.split(/\s+/)
		const w = parts[0].toLowerCase()
		let c = commands.find(k => k.name === w)
		const fits = commands.filter(k => k.name.startsWith(w))
		if (!c && fits.length === 1) c = fits[0]                        // "vol 40" → volume 40
		if (!c && fits.length > 1) { tell(w + "… could be " + fits.map(k => k.name).join(", "), true); return }
		if (!c) { tell("no command called " + parts[0] + " (help lists them)", true); return }
		history = [text].concat(history.filter(h => h !== text)).slice(0, 50)
		back = -1
		if (c.run(parts.slice(1)) !== false) open = false
	}

	// dim the garden behind
	Rectangle {
		anchors.fill: parent
		color: "#8c050812"
		MouseArea { anchors.fill: parent; onClicked: cmd.open = false }
	}

	// the dialogue box, as in the game: navy, lit at the top, a pale edge
	Rectangle {
		id: box
		width: Math.min(parent.width - 120, 980)
		height: 92 + Math.min(list.count, 7) * 40 + (cmd.message ? 34 : 0)
		anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: parent.height * 0.14 }
		border.color: "#4c50b4"
		border.width: 2
		gradient: Gradient {
			GradientStop { position: 0; color: "#f0222486" }
			GradientStop { position: 1; color: "#f010124a" }
		}
		Behavior on height { NumberAnimation { duration: Theme.quick; easing.type: Easing.OutCubic } }

		NamePlate {
			id: title
			text: "COMMAND"
			anchors { left: parent.left; leftMargin: 18; bottom: parent.top; bottomMargin: 8 }
		}

		// the line you type on
		Item {
			id: prompt
			anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 }
			height: 46
			Text {
				id: chevron
				text: "›"
				color: Theme.cyan
				font.family: Theme.font
				font.pixelSize: 30
				font.bold: true
				anchors.verticalCenter: parent.verticalCenter
			}
			TextInput {
				id: line
				anchors { left: chevron.right; leftMargin: 14; right: parent.right; verticalCenter: parent.verticalCenter }
				color: Theme.text
				selectionColor: Theme.cyan
				font.family: Theme.font
				font.pixelSize: 24
				focus: cmd.open
				Text {
					visible: line.text === ""
					text: "visit 2 · open web · volume 40 · ask … · help"
					color: Theme.textDim
					font: line.font
					anchors.verticalCenter: parent.verticalCenter
				}
				onTextChanged: { list.currentIndex = 0; if (cmd.message && !cmd.failed) cmd.message = "" }
				Keys.onEscapePressed: cmd.open = false
				Keys.onTabPressed: cmd.complete()
				Keys.onReturnPressed: cmd.execute()
				Keys.onEnterPressed: cmd.execute()
				Keys.onUpPressed: {
					if (line.text === "" || cmd.back >= 0) {
						if (cmd.back + 1 < cmd.history.length) { cmd.back++; line.text = cmd.history[cmd.back] }
					} else list.currentIndex = Math.max(0, list.currentIndex - 1)
				}
				Keys.onDownPressed: {
					if (cmd.back >= 0) {
						cmd.back--
						line.text = cmd.back >= 0 ? cmd.history[cmd.back] : ""
					} else list.currentIndex = Math.min(list.count - 1, list.currentIndex + 1)
				}
			}
		}
		Rectangle {
			anchors { left: parent.left; right: parent.right; top: prompt.bottom; leftMargin: 18; rightMargin: 18; topMargin: 6 }
			height: 1
			color: "#4c50b4"
		}

		// the commands that fit: the game's Pixy list, the chosen one on a violet chevron bar
		ListView {
			id: list
			anchors { left: parent.left; right: parent.right; top: prompt.bottom; topMargin: 16; leftMargin: 18; rightMargin: 18 }
			height: Math.min(count, 7) * 40
			clip: true
			interactive: false
			model: cmd.matches
			highlightMoveDuration: Theme.quick
			delegate: Item {
				required property var modelData
				required property int index
				width: list.width
				height: 40
				readonly property bool chosen: ListView.isCurrentItem
				Rectangle {   // the bar, with its pointed end
					visible: parent.chosen
					anchors.fill: parent
					anchors.rightMargin: 22
					color: "#5856de"
					Rectangle { width: 6; height: parent.height; color: "#96a0ff" }
				}
				Canvas {
					visible: parent.chosen
					width: 22; height: parent.height
					anchors.right: parent.right
					onPaint: {
						const g = getContext("2d"); g.reset(); g.fillStyle = "#5856de"
						g.beginPath(); g.moveTo(0, 0); g.lineTo(width, height / 2); g.lineTo(0, height); g.fill()
					}
				}
				Text {
					id: glyph
					x: 16
					anchors.verticalCenter: parent.verticalCenter
					text: Theme.elementGlyphs[index % 4]
					color: Theme.elements[index % 4]
					font.family: Theme.font
					font.pixelSize: 18
					font.bold: true
				}
				Text {
					id: name
					anchors { left: glyph.right; leftMargin: 14; verticalCenter: parent.verticalCenter }
					text: modelData.name
					color: parent.chosen ? "white" : Theme.ice
					font.family: Theme.font
					font.pixelSize: 19
					font.bold: true
				}
				Text {
					anchors { left: name.right; leftMargin: 12; verticalCenter: parent.verticalCenter }
					text: modelData.args
					color: parent.chosen ? "#dcdcff" : Theme.textDim
					font.family: Theme.font
					font.pixelSize: 15
					font.italic: true
				}
				Text {
					anchors { right: parent.right; rightMargin: 34; verticalCenter: parent.verticalCenter }
					text: modelData.what
					color: parent.chosen ? "white" : Theme.textDim
					font.family: Theme.font
					font.pixelSize: 15
					elide: Text.ElideLeft
					width: Math.min(implicitWidth, list.width * 0.45)
					horizontalAlignment: Text.AlignRight
				}
				MouseArea {
					anchors.fill: parent
					onClicked: { list.currentIndex = index; cmd.complete(); line.forceActiveFocus() }
				}
			}
		}

		Text {   // what happened, or what went wrong
			visible: cmd.message !== ""
			anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 18 }
			text: cmd.message
			color: cmd.failed ? Theme.magenta : Theme.mint
			font.family: Theme.font
			font.pixelSize: 16
			elide: Text.ElideRight
		}
	}

	// the game's ok / cancel, under the box
	Row {
		anchors { right: box.right; top: box.bottom; topMargin: 14 }
		spacing: 18
		HexButton { text: "run"; icon: "circle"; onClicked: cmd.execute() }
		HexButton { text: "close"; icon: "cross"; onClicked: cmd.open = false }
	}
}
