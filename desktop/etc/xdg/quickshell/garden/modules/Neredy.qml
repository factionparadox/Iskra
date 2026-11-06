import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.components

// Neredy (Super+N): Avalon's local assistant, laid out like the game's ship-AI screen:
// Pasha in a blue spotlight on the left, the conversation in navy dialogue boxes, and two modes
// on chevron tabs: Neredy herself, and the Russian tutor. The model runs on this laptop
// (llama.cpp, started by `neredy start`, stopping itself after 15 idle minutes).
PanelWindow {
	id: neredy
	property bool open: false
	function toggle() { open = !open }

	visible: open
	anchors { top: true; bottom: true; left: true; right: true }
	exclusionMode: ExclusionMode.Ignore
	color: "transparent"
	WlrLayershell.layer: WlrLayer.Overlay
	WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
	WlrLayershell.namespace: "garden-neredy"

	readonly property string api: "http://127.0.0.1:11434"
	property string status: "stopped"     // no-model, stopped, starting, ready, thinking
	property string mode: "neredy"        // neredy or tutor
	property var history: []              // the messages sent to the model
	ListModel { id: shown }               // what's on screen: { who, text }

	readonly property var prompts: ({
		"neredy": "You are Neredy, the assistant built into Avalon, a Linux system on a Framework laptop. "
			+ "Your face is Pasha, a little arctic wolf pup who keeps the garden. Be warm, brief and practical; "
			+ "write in British English; when asked about the system, Avalon is an image-based system on Fedora "
			+ "(Universal Blue), with MangoWC and Quickshell; Metamelayer builds and updates it.",
		"tutor": "You are Neredy, here as a patient Russian tutor for an adult English speaker who is a "
			+ "beginner (around A1-A2). Reply mostly in simple Russian. After each Russian sentence give its "
			+ "transliteration in brackets and a short English gloss. Gently correct any mistakes in the "
			+ "learner's Russian, explaining the rule in one line. Keep replies short and end with a small question."
	})

	onOpenChanged: if (open) {
		input.forceActiveFocus()
		if (status !== "ready") starter.running = true
	}

	function setMode(m) {
		if (mode === m) return
		mode = m
		history = []
		shown.clear()
		shown.append({ who: "pasha", text: m === "tutor"
			? "Привет! (Privet!) Hello! Let's practise. Как тебя зовут? (Kak tebya zovut?) What's your name?"
			: "I'm here. What would you like?" })
	}

	// --------------------------------------------------- the server: start, then wait until ready
	Process {
		id: starter
		command: ["neredy", "start"]
		stdout: StdioCollector {
			onStreamFinished: {
				if (text.trim() === "no-model") neredy.status = "no-model"
				else { neredy.status = "starting"; health.start() }
			}
		}
	}
	Timer {
		id: health
		interval: 1000; repeat: true
		onTriggered: {
			const x = new XMLHttpRequest()
			x.onreadystatechange = () => {
				if (x.readyState === XMLHttpRequest.DONE && x.status === 200) {
					neredy.status = "ready"
					health.stop()
				}
			}
			x.open("GET", neredy.api + "/health")
			x.send()
		}
	}
	Process { id: toucher; command: ["neredy", "touch"] }

	// reading aloud: the Russian in a reply, through Piper
	property bool readAloud: true
	Process { id: voice }
	function say(text) {
		voice.running = false
		voice.command = ["neredy", "say", text]
		voice.running = true
	}

	// ------------------------------------------------------ talking: streamed, word by word
	function send(text) {
		if (text.trim() === "" || status !== "ready") return
		shown.append({ who: "you", text: text })
		history = history.concat([{ role: "user", content: text }])
		shown.append({ who: "pasha", text: "" })
		const row = shown.count - 1
		status = "thinking"
		toucher.running = true

		const x = new XMLHttpRequest()
		let seen = 0, reply = ""
		const take = () => {
			const body = x.responseText
			const lines = body.slice(seen).split("\n")
			// keep a partial last line for next time
			const complete = body.endsWith("\n") ? lines : lines.slice(0, -1)
			for (const line of complete) {
				seen += line.length + 1
				if (!line.startsWith("data: ")) continue
				const data = line.slice(6).trim()
				if (data === "[DONE]") continue
				try {
					const delta = JSON.parse(data).choices?.[0]?.delta?.content ?? ""
					reply += delta
					shown.setProperty(row, "text", reply.replace(/<think>[\s\S]*?<\/think>\s*/g, ""))
				} catch (e) {}
			}
		}
		x.onreadystatechange = () => {
			if (x.readyState === 3) take()
			if (x.readyState === XMLHttpRequest.DONE) {
				take()
				if (x.status !== 200 && reply === "") shown.setProperty(row, "text", "(Pasha couldn't reach the model: is it still starting?)")
				history = history.concat([{ role: "assistant", content: reply }])
				status = "ready"
				if (mode === "tutor" && readAloud && reply !== "") say(reply)
				toucher.running = true
				list.positionViewAtEnd()
			}
		}
		x.open("POST", api + "/v1/chat/completions")
		x.setRequestHeader("Content-Type", "application/json")
		x.send(JSON.stringify({
			stream: true,
			messages: [{ role: "system", content: prompts[mode] }].concat(history),
			chat_template_kwargs: { enable_thinking: false }
		}))
	}

	// ============================================================== the screen
	Rectangle {
		anchors.fill: parent
		gradient: Gradient {
			GradientStop { position: 0; color: "#f0081440" }
			GradientStop { position: 1; color: "#f8020408" }
		}
		MouseArea { anchors.fill: parent }
	}

	// Pasha in the spotlight
	Item {
		id: keeper
		x: 70; y: 60
		width: 300; height: neredy.height - 120
		Rectangle {   // the beam
			width: 210; height: parent.height - 40
			anchors.horizontalCenter: parent.horizontalCenter
			gradient: Gradient {
				GradientStop { position: 0.0; color: "#103a6aaa" }
				GradientStop { position: 1.0; color: "#663a8fe0" }
			}
		}
		Rectangle {   // the pool of light
			width: 250; height: 54; radius: 27
			anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 10 }
			gradient: Gradient {
				orientation: Gradient.Horizontal
				GradientStop { position: 0.0; color: "transparent" }
				GradientStop { position: 0.5; color: "#e05fe8ff" }
				GradientStop { position: 1.0; color: "transparent" }
			}
		}
		Image {
			source: "file:///usr/share/avalon/pasha-portrait.png"
			width: 280; height: 280
			fillMode: Image.PreserveAspectFit
			anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 30 }
		}
		NamePlate {
			anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 20 }
			text: "ネレディー  NEREDY"
			fontSize: Theme.normal
		}
	}

	// the modes
	Row {
		x: keeper.x + keeper.width + 40; y: 64
		spacing: 14
		ChevronTab { text: "Neredy"; glyph: "風"; selected: neredy.mode === "neredy"; onClicked: neredy.setMode("neredy"); height: 36 }
		ChevronTab { text: "Russian tutor"; glyph: "火"; selected: neredy.mode === "tutor"; onClicked: neredy.setMode("tutor"); height: 36 }
		ChevronTab {
			visible: neredy.mode === "tutor"
			text: neredy.readAloud ? "read aloud: on" : "read aloud: off"
			glyph: "♪"
			selected: neredy.readAloud
			onClicked: neredy.readAloud = !neredy.readAloud
			height: 36
		}
	}
	Text {
		anchors { right: parent.right; rightMargin: 70; top: parent.top; topMargin: 72 }
		text: ({ "no-model": "no model yet", "stopped": "asleep", "starting": "waking up…", "ready": "listening", "thinking": "thinking…" })[neredy.status]
		color: neredy.status === "ready" ? Theme.cyan : Theme.textDim
		font.family: Theme.font
		font.pixelSize: Theme.small + 1
		font.letterSpacing: 2
	}

	// the conversation
	ListView {
		id: list
		x: keeper.x + keeper.width + 40; y: 120
		width: neredy.width - x - 70
		height: neredy.height - y - 150
		spacing: 14
		clip: true
		model: shown
		onCountChanged: positionViewAtEnd()
		delegate: Item {
			id: msg
			required property string who
			required property string text
			width: list.width
			height: box.height
			readonly property bool mine: who === "you"

			Rectangle {   // a navy dialogue box for Pasha, a slate plate for you
				id: box
				width: msg.mine ? Math.min(list.width * 0.7, said.implicitWidth + 40) : list.width * 0.86
				height: said.implicitHeight + 34
				anchors.right: msg.mine ? parent.right : undefined
				border.color: msg.mine ? Theme.edge : "#5f74c8"
				border.width: 1
				gradient: Gradient {
					GradientStop { position: 0; color: msg.mine ? "#e0223048" : "#f0202a78" }
					GradientStop { position: 1; color: msg.mine ? "#e0182238" : "#f00c1240" }
				}
				Text {
					id: said
					x: 20; y: 17
					width: box.width - 40
					text: msg.text === "" ? "…" : msg.text
					wrapMode: Text.Wrap
					color: Theme.text
					font.family: Theme.font
					font.pixelSize: msg.mine ? Theme.normal + 1 : Theme.large + 1
					lineHeight: 1.15
				}
			}
			Rectangle {   // read this one aloud
				visible: !msg.mine && msg.text !== ""
				anchors { left: box.right; leftMargin: 10; top: box.top }
				width: 34; height: 34; radius: 17
				color: speak.containsMouse ? "#3a5a8c" : "#22304e"
				border.color: Theme.edgeBright; border.width: 1
				Text { anchors.centerIn: parent; text: "♪"; color: Theme.ice; font.pixelSize: 16; font.bold: true }
				MouseArea { id: speak; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: neredy.say(msg.text) }
			}
		}
	}

	// the first thing she says, or how to wake her
	Text {
		anchors.centerIn: list
		visible: shown.count === 0
		width: list.width * 0.7
		horizontalAlignment: Text.AlignHCenter
		wrapMode: Text.Wrap
		text: neredy.status === "no-model"
			? "Neredy has no model yet. In a terminal:\n\nneredy setup small      (about 2.5 GB, quick)\nneredy setup large      (about 22 GB, the best tutor)"
			: neredy.status === "ready" ? "I'm here. What would you like?" : "Pasha is waking up…"
		color: Theme.mist
		font.family: Theme.font
		font.pixelSize: Theme.large
	}

	// what you type
	HudPanel {
		x: list.x; y: neredy.height - 110
		width: list.width; height: 54
		glow: input.activeFocus
		TextInput {
			id: input
			anchors.fill: parent
			verticalAlignment: TextInput.AlignVCenter
			color: Theme.text
			selectionColor: Theme.cyan
			font.family: Theme.font
			font.pixelSize: Theme.large
			focus: neredy.open
			Text {
				visible: input.text === ""
				anchors.verticalCenter: parent.verticalCenter
				text: neredy.mode === "tutor" ? "› напиши по-русски… (or ask in English)" : "› ask Neredy…"
				color: Theme.textDim
				font: input.font
			}
			Keys.onEscapePressed: neredy.open = false
			Keys.onReturnPressed: { neredy.send(text); text = "" }
			Keys.onEnterPressed: { neredy.send(text); text = "" }
		}
	}

	// ok / cancel, as in the game's dialogs
	Row {
		anchors { right: parent.right; rightMargin: 70; bottom: parent.bottom; bottomMargin: 26 }
		spacing: 20
		HexButton { width: 170; height: 36; text: "send"; icon: "circle"; onClicked: { neredy.send(input.text); input.text = "" } }
		HexButton { width: 170; height: 36; text: "close"; icon: "cross"; onClicked: neredy.open = false }
	}
}
