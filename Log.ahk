#Requires AutoHotkey v2.0

class Log {
    static _logFile := "log.txt"
	static _enabled := true

    __New(message) {
        if(Log._enabled)
			Log._Print(message, "MESSAGE")
    }
    static Message(message) {
        Log(message)
    }
    static Warning(message) {
        if(Log._enabled)
			Log._Print(message, "WARNING")
    }
    static Error(message) {
        if(Log._enabled)
			Log._Print(message, "ERROR")
    }
    static Start() {
        Log._enabled := true
    }
    static Stop() {
        Log._enabled := false
    }
    static Clear() {
        FileDelete(Log._logFile)
    }
    
    static _Print(message, messageType) {
        try
            file := FileOpen(Log._logFile, "a", "UTF-8")
        catch as e {
            return
        }

        timestamp := "[" A_YYYY "-" A_MM "-" A_DD " " A_Hour ":" A_Min ":" A_Sec "]"
        file.WriteLine(timestamp " [" messageType "]: " message)
        file.Close()
    }
}