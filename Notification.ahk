#Requires AutoHotkey v2.0

/*

    Notification(title, text, [soundId, clickCallback, timeoutCallback])

    Valid sounds:
        Notification.SOUND_MUTED
        Notification.SOUND_INFO
        Notification.SOUND_QUESTION
        
*/

class Notification {
    static WIDTH := 364
    static HEIGHT := 111
    static POSITION_X := A_ScreenWidth - Notification.WIDTH - 16
    static POSITION_Y := A_ScreenHeight - Notification.HEIGHT - 53
    static DURATION := 5000

    static BACKGROUND_COLOR := "3E3E3E"
    static FONT_COLOR := "FFFFFF"
    static TITLE_SIZE := 10
    static TEXT_SIZE := 10

    static FADE_IN_DURATION := 100
    static FADE_OUT_DURATION := 250

    static queue := Array()

    __New(text:="", title:="", soundId:=Notification.SOUND_MUTED, clickCallback:="", rightClickCallback:="", timeoutCallback:="", duration:=Notification.DURATION) {
        this.gui := Gui("+AlwaysOnTop -Caption +ToolWindow")
        this.hwnd := this.gui.Hwnd
		this.gui.BackColor := Notification.BACKGROUND_COLOR
        this.alive := false

        this.title := this.gui.AddText("W" Notification.WIDTH-15 " H" Notification.HEIGHT " X15 Y15", title)
        this.title.SetFont("C" Notification.FONT_COLOR " S" Notification.TITLE_SIZE " W700")
        this.text := this.gui.AddText("W" Notification.WIDTH-25 " H" Notification.HEIGHT " X25 Y45", text)
        this.text.SetFont("c" Notification.FONT_COLOR " s" Notification.TITLE_SIZE)

        this.clickCallback := clickCallback
        this.clickEvent := ObjBindMethod(this, "OnClick")
        OnMessage(0x201, this.clickEvent)

        this.rightClickCallback := rightClickCallback
        this.rightClickEvent := ObjBindMethod(this, "OnRightClick")
        OnMessage(0x204, this.rightClickEvent)

        this.timeoutCallback := timeoutCallback
        this.soundId := soundId
        this.duration := duration

        Notification.queue.Push(this)
        if(Notification.queue.Length==1) {
            this.Show()
        }
    }

    OnClick(*) {
        if(this.alive) {
            this.alive := false
            if(this.HasOwnProp("lifeTimer"))
                SetTimer(this.lifeTimer, 0)
            this.FadeOut()
            if(this.clickCallback != "")
                this.clickCallback.Call()
        }
    }
    OnRightClick(*) {
        if(this.alive) {
            this.alive := false
            if(this.HasOwnProp("lifeTimer"))
                SetTimer(this.lifeTimer, 0)
            this.FadeOut()
            if(this.rightClickCallback != "")
                this.rightClickCallback.Call()
        }
    }
    OnTimeout() {
        if(this.alive) {
            this.alive := false
            this.FadeOut()
            if(this.timeoutCallback != "")
                this.timeoutCallback.Call()
        }
    }
    OnDecay() {
        SetTimer(this.fadeTimer, 0)
        OnMessage(0x201, this.clickEvent, 0)
        OnMessage(0x204, this.rightClickEvent, 0)
        this.gui.Hide()
        this.gui.Destroy()

        Notification.queue.RemoveAt(1)
        if(Notification.queue.Length > 0) {
            Notification.queue[1].Show()
        }
    }

    Show() {
        this.alive := true
        if(this.soundId!="" && Notification._VALID_SOUND[this.soundId])
            SoundPlay(this.soundId)
        this.FadeIn()
    }
    FadeIn() {
        this.gui.Show("NoActivate W" Notification.WIDTH " H" Notification.HEIGHT " X" Notification.POSITION_X " Y" Notification.POSITION_Y)
        WinSetTransparent(0, "ahk_id " this.hwnd)

        this.fadeDuration := Notification.FADE_IN_DURATION
        this.fadeLeft := Notification.FADE_IN_DURATION
        this.opacity := 0
        this.fadeTimer := ObjBindMethod(this, "FadeInTick")
        SetTimer(this.fadeTimer, 10)
    }
    FadeInTick() {
        this.fadeLeft -= 10
        if(this.fadeLeft<=0) {
            SetTimer(this.fadeTimer, 0)
            WinSetTransparent(255, "ahk_id " this.hwnd)

            if(this.duration>0) {
                this.lifeTimer := ObjBindMethod(this, "OnTimeout")
                SetTimer(this.lifeTimer, this.duration * -1)
            }
            return
        }

        this.opacity := (1 - (this.fadeLeft/this.fadeDuration)) * 255
        WinSetTransparent(Integer(this.opacity), "ahk_id " this.hwnd)
    }

    FadeOut() {
        this.alive := false
        this.fadeDuration := Notification.FADE_OUT_DURATION
        this.fadeLeft := Notification.FADE_OUT_DURATION
        this.opacity := 255
        this.fadeTimer := ObjBindMethod(this, "FadeOutTick")
        SetTimer(this.fadeTimer, 10)
    }
    FadeOutTick() {
        this.fadeLeft -= 10
        if(this.fadeLeft<=0) {
            SetTimer(this.fadeTimer, 0)
            this.OnDecay()
            return
        }

        this.opacity := (this.fadeLeft/this.fadeDuration) * 255
        WinSetTransparent(Integer(this.opacity), "ahk_id " this.hwnd)
    }

    static SOUND_MUTED {
        get  {
            return ""
        }
    }
    static SOUND_QUESTION {
        get  {
            return "*16"
        }
    }
    static SOUND_INFO {
        get  {
            return "*64"
        }
    }
    static _VALID_SOUND[type] {
        get {
            return type==Notification.SOUND_MUTED || Map(
                Notification.SOUND_QUESTION, "QUESTION",
                Notification.SOUND_INFO, "INFO"
            ).Has(type)
        }
    }
}