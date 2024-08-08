#Requires AutoHotkey v2.0

class Debug {
	static _disabledText := false
	static _running := false
	static _notepadPID := 0
	static _controlId := 1

	__New(message) {
		if(Debug._running) {
			timestamp := "[" A_YYYY "-" A_MM "-" A_DD " " A_Hour ":" A_Min ":" A_Sec "]"
			currentText := ControlGetText("Edit1", "ahk_pid " Debug._notepadPID)
			ControlSetText(currentText timestamp " " message "`n", "Edit1", "ahk_pid " Debug._notepadPID)
			ControlSend("^{End}", Debug._controlId)
		}
	}
	static Start() {
		Run("notepad.exe",,, &notepadPID)
		WinWaitActive("ahk_pid " notepadPID)
		WinSetTitle("Debug", "ahk_pid " notepadPID)
		ControlSetEnabled(!Debug._disabledText, "Edit1", "ahk_pid " notepadPID)
		Debug._controlId := ControlGetFocus("ahk_pid " notepadPID)
		OnExit(Debug.Stop.Bind(Debug))
		Debug._notepadPID := notepadPID
		Debug._running := true
	}
	static Stop(*) {
		if(ProcessExist(Debug._notepadPID))
			ProcessClose(Debug._notepadPID)
	}
}