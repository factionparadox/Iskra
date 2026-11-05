pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris

// The four elements, live, each 0..1:
//   wind  = power (battery charge)        earth = memory in use
//   fire  = processor temperature         water = the song playing (how far through it)
// Also sound volume and the song's title, for the HUD's counter and ♪ line.
Singleton {
	id: root

	property real cpu: 0
	property real memory: 0
	property real temperature: 0          // °C
	readonly property real heat: Math.max(0, Math.min(1, (temperature - 30) / 70))   // 30 °C empty, 100 °C full
	readonly property real volume: Pipewire.defaultAudioSink?.audio?.volume ?? 0
	readonly property bool muted: Pipewire.defaultAudioSink?.audio?.muted ?? false
	readonly property var battery: UPower.displayDevice
	readonly property real charge: battery ? (battery.percentage > 1 ? battery.percentage / 100 : battery.percentage) : 0
	readonly property bool charging: battery !== null && battery.state === UPowerDeviceState.Charging
	readonly property bool hasBattery: battery !== null && battery.isLaptopBattery

	readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
	readonly property string song: player ? (player.trackTitle || "") : ""
	readonly property bool playing: player !== null && player.isPlaying
	property real songProgress: 0
	Timer {   // MPRIS doesn't push the position: ask for it each second while something plays
		interval: 1000; repeat: true
		running: root.player !== null
		onTriggered: {
			const p = root.player
			if (!p) { root.songProgress = 0; return }
			p.positionChanged()
			root.songProgress = p.length > 0 ? Math.min(1, p.position / p.length) : 0
		}
	}

	PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

	// processor: the busy share of /proc/stat's first line, between two readings
	property var lastCpu: null
	FileView { id: stat; path: "/proc/stat" }
	FileView { id: meminfo; path: "/proc/meminfo" }
	// the package temperature: x86_pkg_temp (or coretemp's Package id 0) found once at start
	property string tempPath: ""
	Process {
		running: true
		command: ["sh", "-c", "for z in /sys/class/thermal/thermal_zone*; do [ \"$(cat $z/type 2>/dev/null)\" = x86_pkg_temp ] && { echo $z/temp; exit; }; done; for h in /sys/class/hwmon/hwmon*; do [ \"$(cat $h/name)\" = coretemp ] && { echo $h/temp1_input; exit; }; done; echo /sys/class/thermal/thermal_zone0/temp"]
		stdout: StdioCollector { onStreamFinished: root.tempPath = text.trim() }
	}
	FileView { id: temp; path: root.tempPath }

	Timer {
		interval: 2000
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: {
			stat.reload()
			meminfo.reload()
			if (root.tempPath !== "") {
				temp.reload()
				const t = parseInt(temp.text())
				if (!isNaN(t)) root.temperature = t / 1000
			}
			const f = stat.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
			if (f.length >= 4) {
				const idle = f[3] + (f[4] || 0)
				const total = f.reduce((a, b) => a + b, 0)
				if (root.lastCpu) {
					const dt = total - root.lastCpu.total
					root.cpu = dt > 0 ? 1 - (idle - root.lastCpu.idle) / dt : 0
				}
				root.lastCpu = { idle: idle, total: total }
			}
			const m = {}
			for (const line of meminfo.text().split("\n")) {
				const kv = line.split(":")
				if (kv.length === 2) m[kv[0]] = parseInt(kv[1])
			}
			if (m.MemTotal) root.memory = 1 - (m.MemAvailable ?? m.MemFree) / m.MemTotal
		}
	}
}
