#Requires AutoHotkey v2.0

#Include Debug.ahk
#Include Log.ahk
#Include JSON.ahk
#Include Notification.ahk
Persistent
#SingleInstance Force

TRAY_TITLE := "Shutdown Manager"
TRAY_ICON := "trayicon.ico"
SETTINGS_FILEPATH := "settings.json"

ShutdownMenu := Menu()

ShutDownManager()

ShutDownManager() {
    Settings.Load()
    
	A_IconTip := TRAY_TITLE
	TraySetIcon(TRAY_ICON)
	A_TrayMenu.Delete()

    ShutdownMenu.Add("Delay 1 hr", MenuEvent.DelayHours.Bind(1))
    ShutdownMenu.Add("Delay 2 hrs", MenuEvent.DelayHours.Bind(2))
    ShutdownMenu.Add("Delay 3 hrs", MenuEvent.DelayHours.Bind(3))
    ShutdownMenu.Add("Choose delay", MenuEvent.DelayInputTime.Bind(MenuEvent))

	A_TrayMenu.Add("Shutdown", ShutdownMenu)
    A_TrayMenu.Add("Auto Shutdown: " Settings.AutoShutdownTimeString, MenuEvent.CheckAutoShutdown.Bind(MenuEvent))
	if(Settings.AutoShutdown)
		A_TrayMenu.Check("Auto Shutdown: " Settings.AutoShutdownTimeString)
    A_TrayMenu.Add("Cancel shutdown", MenuEvent.CancelShutdown.Bind(MenuEvent))

	A_TrayMenu.Add()
	A_TrayMenu.Add("Open settings", MenuEvent.OpenSettings.Bind(MenuEvent))
	A_TrayMenu.Add()
	A_TrayMenu.Add("Exit", MenuEvent.Exit.Bind(MenuEvent))

    timeUntilAutoshutdown := Mod((((24 + Settings.AutoShutdownTime - A_Hour) * 60 - A_Min) * 60 - A_Sec) * 1000 - A_MSec, 86400000)
    ShutdownHandler.StartTimer(timeUntilAutoshutdown)
    A_TrayMenu.Disable("Cancel shutdown")
}

class ShutdownHandler {
    static _warnTimer := ObjBindMethod(ShutdownHandler, "IssueWarning")
    static _executeTimer := ObjBindMethod(ShutdownHandler, "Execute")

    static StartTimer(delay, message := "") {
        A_TrayMenu.Enable("Cancel shutdown")
        SetTimer(ShutdownHandler._warnTimer, 0)
        SetTimer(ShutdownHandler._executeTimer, 0)
        SetTimer(ShutdownHandler._warnTimer, delay)
        if(message != "")
            Notification(message)
    }
    static IssueWarning() {
        A_TrayMenu.Enable("Cancel shutdown")
        SetTimer(ShutdownHandler._warnTimer, 0)
        SetTimer(ShutdownHandler._executeTimer, 0)
        SetTimer(ShutdownHandler._executeTimer, 5 * 60 * 1000)
        Log("Issued 5 minute warning")
        MsgBox("Computer will shutdown in 5 minutes",,"T295")
    }
    static Cancel(message := "") {
        A_TrayMenu.Disable("Cancel shutdown")
        SetTimer(ShutdownHandler._warnTimer, 0)
        SetTimer(ShutdownHandler._executeTimer, 0)
        Log("Canceled scheduled shutdown")
        if(message != "")
            Notification(message)
    }
    static Execute() {
        SetTimer(ShutdownHandler._executeTimer, 0)
        Log("Computer shutting down")
        DllCall("PowrProf\SetSuspendState", "Int", 1, "Int", 0, "Int", 0)
    }
}

class MenuEvent {
    static CancelShutdown(*) {
        ShutdownHandler.Cancel("Scheduled shutdown canceled")
    }
    static DelayHours(menuItem, hours, menuObj) {
        ShutdownHandler.StartTimer(hours * 3600 * 1000, "Computer will shutdown in " (hours>1?hours " hrs":hours " hr"))
    }
    static DelayInputTime(*) {
        inputResult := InputBox("Minutes until shutdown", TRAY_TITLE, "W200 H100")
        if(inputResult.Result == "OK") {
            if(IsInteger(inputResult.Value)) {
                ShutdownHandler.StartTimer(inputResult.Value * 60 * 1000, "Computer will shutdown in " inputResult.Value " minutes")
            }
        }
    }
    static CheckAutoShutdown(*) {
        Settings.AutoShutdown := not Settings.AutoShutdown
        Settings.Save()
        A_TrayMenu.ToggleCheck("Auto Shutdown: " Settings.AutoShutdownTimeString)
    }
    static OpenSettings(*) {
        Settings.Open()
    }
    static Exit(*) {
        ExitApp()
    }
}

class Settings {
    static Load() {
        try {
            file := FileOpen(SETTINGS_FILEPATH, "r")
            data := file.Read()
            file.Close()
            Settings._data := JSON_Load(data)
        }
        catch {
            MsgBox("Failed to load settings, exiting program")
            ExitApp()
        }
    }
    static Save() {
        try {
            file := FileOpen(SETTINGS_FILEPATH, "w")
            data := JSON_Dump(Settings._data, 4)
            file.Write(data)
            file.Close()
        }
        catch {
            MsgBox("Failed to save settings")
        }
    }
    static Open() {
		RunWait("notepad.exe " SETTINGS_FILEPATH,,, &processId)
		WinWaitClose("ahk_pid " processId)
		Reload()
    }
    static AutoShutdown {
        get => Settings._data["autoShutdown"]
        set => Settings._data["autoShutdown"] := value
    }
    static AutoShutdownTime {
        get => Floor(Settings._data["autoShutdownTime"]) + Round(((Settings._data["autoShutdownTime"]) - Floor(Settings._data["autoShutdownTime"])) / 0.6, 2)
    }
    static AutoShutdownTimeString {
        get {
            result := ""
            if(Settings._data["autoShutdownTime"] < 10)
                result .= "0"
            result .= Floor(Settings._data["autoShutdownTime"]) ":"
            result .= SubStr(Round(Settings._data["autoShutdownTime"] - Floor(Settings._data["autoShutdownTime"]), 2), 3)
            return result
		}
    }
}

#HotIf (not A_IsCompiled)
^r:: {
	Reload()
}