pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris

// The four elements, live: earth = memory, water = sound, wind = battery, fire = processor.
// Each runs 0..1. Also the song that's playing, for the HUD's ♪ line.
Singleton {
	id: root

	property real cpu: 0
	property real memory: 0
	readonly property real volume: Pipewire.defaultAudioSink?.audio?.volume ?? 0
	readonly property bool muted: Pipewire.defaultAudioSink?.audio?.muted ?? false
	readonly property var battery: UPower.displayDevice
	readonly property real charge: battery ? (battery.percentage > 1 ? battery.percentage / 100 : battery.percentage) : 0
	readonly property bool charging: battery !== null && battery.state === UPowerDeviceState.Charging
	readonly property bool hasBattery: battery !== null && battery.isLaptopBattery

	readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null
	readonly property string song: player ? (player.trackTitle || "") : ""

	PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

	// processor: the busy share of /proc/stat's first line, between two readings
	property var lastCpu: null
	FileView { id: stat; path: "/proc/stat" }
	FileView { id: meminfo; path: "/proc/meminfo" }

	Timer {
		interval: 2000
		running: true
		repeat: true
		triggeredOnStart: true
		onTriggered: {
			stat.reload()
			meminfo.reload()
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
