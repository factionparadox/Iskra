//@ pragma UseQApplication
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules

// The Garden System: Avalon's desktop shell, run by garden-session as  quickshell -c garden.
// Each panel answers  garden <name>  (Quickshell IPC): launcher, lock, power, keyhelp, neredy.
ShellRoot {
	Wallpaper {}
	Bar {}
	Notifications {}

	Launcher { id: launcher }
	PowerMenu { id: power; onLockRequested: lock.lock() }
	KeyHelp { id: keyhelp }
	Neredy { id: neredy }
	Lock { id: lock }

	IpcHandler { target: "launcher"; function toggle(): void { launcher.toggle() } }
	IpcHandler { target: "power";    function toggle(): void { power.toggle() } }
	IpcHandler { target: "keyhelp";  function toggle(): void { keyhelp.toggle() } }
	IpcHandler { target: "neredy";   function toggle(): void { neredy.toggle() } }
	IpcHandler { target: "lock";     function toggle(): void { lock.lock() } }
}
