//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules

// The Garden System: Avalon's desktop shell, run by garden-session as  quickshell -c garden.
// Each panel answers  garden <name>  (Quickshell IPC): launcher, starsystem, lock, power, keyhelp, neredy, command.
ShellRoot {
	Wallpaper {}
	Hud {}
	Notifications {}

	Launcher { id: launcher }
	PowerMenu { id: power; onLockRequested: lock.lock() }
	KeyHelp { id: keyhelp }
	StarSystem { id: starsystem }
	Neredy { id: neredy }
	Lock { id: lock }
	CommandMode { id: command; neredy: neredy; lock: lock }

	IpcHandler { target: "launcher"; function toggle(): void { launcher.toggle() } }
	IpcHandler { target: "power";    function toggle(): void { power.toggle() } }
	IpcHandler { target: "keyhelp";  function toggle(): void { keyhelp.toggle() } }
	IpcHandler { target: "neredy";   function toggle(): void { neredy.toggle() } }
	IpcHandler { target: "starsystem"; function toggle(): void { starsystem.toggle() } }
	IpcHandler { target: "lock";     function toggle(): void { lock.lock() } }
	IpcHandler { target: "command";  function toggle(): void { command.toggle() } }
}
