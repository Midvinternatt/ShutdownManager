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

; Debug.Start()

ShutdownMenu := Menu()

ShutDownManager()

ShutDownManager() {
    Settings.Load()
    ShutdownHandler.Init()
    
	A_IconTip := TRAY_TITLE
	TraySetIcon(TRAY_ICON)

    ShutdownMenu.Add("Cancel shutdown", MenuEvent.CancelShutdown.Bind(MenuEvent))
    ShutdownMenu.Add("Delay 1 hr", MenuEvent.DelayOneHour.Bind(MenuEvent))
    ShutdownMenu.Add("Delay 2 hr", MenuEvent.DelayTwoHours.Bind(MenuEvent))
    ShutdownMenu.Add("Delay 3 hr", MenuEvent.DelayThreeHours.Bind(MenuEvent))
    ShutdownMenu.Add("Choose delay", MenuEvent.DelayInputTime.Bind(MenuEvent))
    ShutdownMenu.Disable("Cancel shutdown")
    ShutdownMenu.Disable("Choose delay") ; Not implemented

	A_TrayMenu.Delete()

	A_TrayMenu.Add("Shutdown", ShutdownMenu)
	
	; A_TrayMenu.Add("Notification message", MenuEvent.Dummy.Bind(MenuEvent))
	; if(Settings.MessageNotification)
	; 	A_TrayMenu.Check("Notification message")
	
	; A_TrayMenu.Add("Notification audio", MenuEvent.Dummy.Bind(MenuEvent))
	; if(Settings.AudioNotification)
	; 	A_TrayMenu.Check("Notification audio")

    A_TrayMenu.Add("Auto Shutdown: " Settings.AutoShutdownTimeString, MenuEvent.Dummy.Bind(MenuEvent))
	if(Settings.AutoShutdown)
		A_TrayMenu.Check("Auto Shutdown: " Settings.AutoShutdownTimeString)

	A_TrayMenu.Add()
	A_TrayMenu.Add("Open settings", MenuEvent.OpenSettings.Bind(MenuEvent))
	A_TrayMenu.Add()
	A_TrayMenu.Add("Exit", MenuEvent.Exit.Bind(MenuEvent))
}

class ShutdownHandler {
    static _warnTimer := ObjBindMethod(ShutdownHandler, "IssueWarning")
    static _executeTimer := ObjBindMethod(ShutdownHandler, "Execute")

    static Init() {
        ; ((((24 + Goal_Hour - A_Hour) * 60 + Goal_Min - A_Min) * 60 + Goal_Sec - A_Sec) * 1000 + Goal_MSec - A_MSec
        ; SetTimer(ShutdownHandler._timer, Mod((((24 + Settings.AutoShutdownTime - A_Hour) * 60 - A_Min) * 60 - A_Sec) * 1000 - A_MSec, 86400000))
        ShutdownHandler.StartTimer(Mod((((24 + Settings.AutoShutdownTime - A_Hour) * 60 - A_Min) * 60 - A_Sec) * 1000 - A_MSec, 86400000))
    }
    static StartTimer(delay) {
        SetTimer(ShutdownHandler._warnTimer, 0)
        SetTimer(ShutdownHandler._executeTimer, 0)
        SetTimer(ShutdownHandler._warnTimer, delay)
    }
    static IssueWarning() {
        SetTimer(ShutdownHandler._warnTimer, 0)
        SetTimer(ShutdownHandler._executeTimer, 0)
        SetTimer(ShutdownHandler._executeTimer, 5 * 60 * 1000)
        MsgBox("Computer will shutdown in 5 minutes",,"T295")
        Log("Issued 5 minute warning")
        ShutdownMenu.Enable("Cancel shutdown")

    }
    static Cancel() {
        SetTimer(ShutdownHandler._warnTimer, 0)
        SetTimer(ShutdownHandler._executeTimer, 0)
        Log("Canceled scheduled shutdown")
    }
    static Execute() {
        SetTimer(ShutdownHandler._executeTimer, 0)
        Log("Computer shutting down")
        ; MsgBox("Computer shutting down")

        ; if(WinExist("ahk_exe firefox.exe")) {
        ;     Log("Firefox open")
            ; WinWaitClose("ahk_exe firefox.exe")
        ;     Log("firefox exited")
        ; }

        ; Log("Shutting")

        ; Shutdown(8)
        DllCall("PowrProf\SetSuspendState", "Int", 1, "Int", 0, "Int", 0)
    }
}

class MenuEvent {
    static CancelShutdown(*) {
        ShutdownMenu.Disable("Cancel shutdown")
        ShutdownHandler.Cancel()
        Notification("Scheduled shutdown canceled")
    }
    static DelayOneHour(*) {
        ShutdownMenu.Enable("Cancel shutdown")
        ShutdownHandler.StartTimer(1 * 3600 * 1000)
        Notification("Computer will shutdown in 1 hr")
    }
    static DelayTwoHours(*) {
        ShutdownMenu.Enable("Cancel shutdown")
        ShutdownHandler.StartTimer(2 * 3600 * 1000)
        Notification("Computer will shutdown in 2 hrs")
    }
    static DelayThreeHours(*) {
        ShutdownMenu.Enable("Cancel shutdown")
        ShutdownHandler.StartTimer(3 * 3600 * 1000)
        Notification("Computer will shutdown in 3 hrs")
    }
    static DelayInputTime(*) {
        Debug("Custom time event")
    }
    ; static CheckAutoShutdown(*) {

    ; }
    static OpenSettings(*) {
        Settings.Open()
    }
    static Dummy(*) {
    }
    static Exit(*) {
        ; Debug("Exit event")
        ExitApp()
    }
}

class Settings {
    static Load() {
        file := FileOpen(SETTINGS_FILEPATH, "r")
		data := file.Read()
		file.Close()
		Settings._data := JSON_Load(data)
    }
    static Open() {
		RunWait("notepad.exe " SETTINGS_FILEPATH,,, &processId)
		WinWaitClose("ahk_pid " processId)
		TrayTip("Updated settings", TRAY_TITLE)
		Reload()
    }
    static AutoShutdown {
        get {
			return Settings._data["autoShutdown"]
		}
    }
    static AutoShutdownTime {
        get {
            return Floor(Settings._data["autoShutdownTime"]) + Round(((Settings._data["autoShutdownTime"]) - Floor(Settings._data["autoShutdownTime"])) / 0.6, 2)
		}
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