pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// What Mango is doing, from its IPC (mmsg): each monitor's workstations (tags), the focused
// window and the keyboard layout. mmsg's watch mode sends one JSON line per change.
Singleton {
	id: root

	// monitor name -> [{ index, is_active, is_urgent, layout, client_count }]
	property var tags: ({})
	property string title: ""
	property string appId: ""
	property string layout: "gb"

	function tagsFor(monitor) {
		return root.tags[monitor] ?? root.tags[Object.keys(root.tags)[0]] ?? []
	}
	function view(tag) { dispatch.exec(["mmsg", "dispatch", "view," + tag + ",0"]) }
	function run(fn) { dispatch.exec(["mmsg", "dispatch", fn]) }

	Process {
		id: dispatch
	}

	Process {
		id: tagWatch
		running: true
		command: ["mmsg", "watch", "all-tags"]
		stdout: SplitParser {
			onRead: line => {
				try {
					const all = JSON.parse(line).all_tags ?? []
					const t = {}
					for (const m of all) t[m.monitor] = m.tags
					root.tags = t
				} catch (e) {}
			}
		}
		onExited: restartTags.start()
	}
	// if Mango's socket isn't up yet (or it restarts), try again shortly
	Timer { id: restartTags; interval: 2000; onTriggered: tagWatch.running = true }

	Process {
		running: true
		command: ["mmsg", "watch", "focusing-client"]
		stdout: SplitParser {
			onRead: line => {
				try {
					const f = JSON.parse(line)
					root.title = f.title ?? ""
					root.appId = f.appid ?? ""
				} catch (e) {}
			}
		}
	}

	Process {
		running: true
		command: ["mmsg", "watch", "keyboardlayout"]
		stdout: SplitParser {
			onRead: line => {
				try {
					const k = JSON.parse(line)
					const name = (k.keyboardlayout ?? k.layout ?? "").toLowerCase()
					root.layout = name.includes("russian") ? "ru" : "gb"
				} catch (e) {}
			}
		}
	}
}
