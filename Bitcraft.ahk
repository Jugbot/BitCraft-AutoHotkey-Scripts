#Requires AutoHotkey v2.0

#include "./OCR-2.0-alpha.4/Lib/OCR.ahk"

bitcraftHWND := WinExist("BitCraft")
if 0 == bitcraftHWND {
    MsgBox("BitCraft window not found!")
    ExitApp
}
OutputDebug("BitCraft HWND: " bitcraftHWND)
WinGetPos(&mainX, &mainY, &mainW, &mainH, "BitCraft")

; Sample positions taken at 1720x1440 resolution
; Most of these don't mattter anymore besides the colors
craftW := 1415
craftH := 955
claimX := 1534
claimY := 385
staminaX := 890
staminaY := 1240
staminaFullX := 1225
staminaFullY := staminaY
staminaColor := 0xCCAA00
primaryColor := 0xE9DfC4
statusColor := 0x11B64A
statusColorSecondary := 0x53E785
statusY := 1187
status1X := 786
status2X := 731
status3X := 676
itemX := 885
itemY := 505
actionX := itemX
actionY := 990
staminaRegenTime := 30000

configFile := "config.ini"
configSection := {
    stamina: "Stamina",
    item: "Item",
    action: "Action",
    workbench: "Workbench",
    complete: "Complete"
}
CoordMode 'Pixel', 'Screen'
CoordMode 'Mouse', 'Screen'

WaitForColorChange(targetColor, posX, posY, timeout := 5000) {
    startTime := A_TickCount
    while (A_TickCount - startTime < timeout) {
        currentColor := PixelGetColor(posX, posY)
        if (currentColor = targetColor) {
            return true
        }
        Sleep(100)
    }
    return false
}

; Clicks at (x, y) in the specified window using ControlClick, without focusing it
ClickInBackground(winTitle, x, y) {
    if (!winTitle)
        winTitle := "A"
    SetControlDelay -1
    ControlClick(
        "x" x " y" y,
        winTitle,
        , , ,
        "NA"
    )
}

DrawRect(x, y, w, h, text := "", resizeX := false, resizeY := false, aspectRatio := unset) {
    rect := { x: x, y: y, w: w, h: h }, dragging := false, offsetX := 0, offsetY := 0

    if !IsSet(rectGui) {
        maxWidth := (resizeX) ? A_ScreenWidth : w
        maxHeight := (resizeY) ? A_ScreenHeight : h
        minWidth := (resizeX) ? 0 : w
        minHeight := (resizeY) ? 0 : h
        rectGui := Gui('+AlwaysOnTop -Caption +LastFound +E0x20 +OwnDialogs +Resize +MinSize' minWidth 'x' minHeight ' +MaxSize' maxWidth 'x' maxHeight
        )
        rectGui.BackColor := 'ea00ff'
        rectGui.SetFont('s12', 'Segoe UI')
        rectGui.Show('x' rect.x ' y' rect.y ' w' rect.w ' h' rect.h ' NoActivate')
    }

    WM_LBUTTONDOWN(wParam, lParam, msg, hwnd) {
        try {
            if (IsSet(rectGui) && hwnd = rectGui.Hwnd) {
                MouseGetPos(&mx, &my)
                dragging := true

                PostMessage(0xA1, 2, , , 'A')
            }
        }
    }

    WM_LBUTTONUP(wParam, lParam, msg, hwnd) {
        dragging := false
    }

    WM_MOUSEMOVE(wParam, lParam, msg, hwnd) {
        try {
            if (IsSet(rectGui) && hwnd == rectGui.Hwnd && !IsSet(rectTooltip)) {
                rectTooltip := ToolTip(text, 0, -25)
            } else if (IsSet(rectTooltip)) {
                ToolTip()
                rectTooltip := unset
            }
        }
    }

    OnMessage(0x200, WM_MOUSEMOVE)
    OnMessage(0x201, WM_LBUTTONDOWN)
    OnMessage(0x202, WM_LBUTTONUP)

    rectGui.OnEvent("Close", (*) =>
        OnMessage(0x200, 0)
        OnMessage(0x201, 0)
        OnMessage(0x202, 0))

    return rectGui
}

Rectangle(x, y, w, h) {
    return { x: x, y: y, w: w, h: h, center: { x: x + w // 2, y: y + h // 2 } }
}

GetHWNDRect(hwnd) {
    WinGetPos(&x, &y, , , "ahk_id " hwnd)
    WinGetClientPos(, , &w, &h, "ahk_id " hwnd)
    return Rectangle(x, y, w, h)
}

SaveRect(rect, name) {
    IniWrite(rect.x, configFile, name, "x")
    IniWrite(rect.y, configFile, name, "y")
    IniWrite(rect.w, configFile, name, "w")
    IniWrite(rect.h, configFile, name, "h")
}

LoadRect(name) {
    x := IniRead(configFile, name, "x", "")
    y := IniRead(configFile, name, "y", "")
    w := IniRead(configFile, name, "w", "")
    h := IniRead(configFile, name, "h", "")
    if (x = "" || y = "" || w = "" || h = "") {
        OutputDebug("Failed to load rectangle: " name)
        return false
    }
    return Rectangle(Number(x), Number(y), Number(w), Number(h))
}

LoadRectStrict(name) {
    rect := LoadRect(name)
    if (!IsSet(rect)) {
        throw Error("Failed to load: " name)
    }
    return rect
}

DrawSavedRect(name) {
    rect := LoadRect(name)
    if (!rect) {
        OutputDebug("No saved rectangle found for: " name)
        return DrawRect
    }
    Substitute(_x, _y, w, h, args*) {
        return DrawRect(rect.x, rect.y, rect.w, rect.h, args*)
    }
    return Substitute
}

CreateWindows() {
    staminaWindow := DrawSavedRect(configSection.stamina)(mainX + staminaX, mainY + staminaY, 70, 20, "Stamina", true)
    itemWindow := DrawSavedRect(configSection.item)(mainX + itemX, mainY + itemY, 200, 50, "Item")
    actionWindow := DrawSavedRect(configSection.action)(mainX + actionX, mainY + actionY, 200, 50, "Action")
    completeWindow := DrawSavedRect(configSection.complete)(mainX + claimX, mainY + claimY, 200, 50, "Claim", true)
    workbenchWindow := DrawSavedRect(configSection.workbench)(mainX + mainW / 2, mainY + mainH / 2, 100, 100,
        "Workbench")
    button := workbenchWindow.AddButton("Default", "Start")

    SubmitCallback(*) {
        staminaRect := GetHWNDRect(staminaWindow.Hwnd)
        SaveRect(staminaRect, configSection.stamina)
        itemRect := GetHWNDRect(itemWindow.Hwnd)
        SaveRect(itemRect, configSection.item)
        actionRect := GetHWNDRect(actionWindow.Hwnd)
        SaveRect(actionRect, configSection.action)
        workbenchRect := GetHWNDRect(workbenchWindow.Hwnd)
        SaveRect(workbenchRect, configSection.workbench)
        completeRect := GetHWNDRect(completeWindow.Hwnd)
        SaveRect(completeRect, configSection.complete)

        ; Close all GUIs created by DrawRect
        try staminaWindow.Destroy()
        try itemWindow.Destroy()
        try actionWindow.Destroy()
        try workbenchWindow.Destroy()
        try completeWindow.Destroy()
        staminaWindow := unset
        itemWindow := unset
        actionWindow := unset
        workbenchWindow := unset
        completeWindow := unset
    }

    button.OnEvent("Click", SubmitCallback)
}

WorkbenchTask() {
    OutputDebug("Starting Workbench Task...")

    staminaRect := LoadRectStrict(configSection.stamina)
    staminaStartPos := { x: staminaRect.x, y: staminaRect.center.y }
    staminaEndPos := { x: staminaRect.x + staminaRect.w, y: staminaRect.center.y }

    positions := {
        staminaStartPos: staminaStartPos,
        staminaEndPos: staminaEndPos,
        itemPos: LoadRectStrict(configSection.item).center,
        actionPos: LoadRectStrict(configSection.action).center,
        workbenchPos: LoadRectStrict(configSection.workbench).center,
        completeRect: LoadRectStrict(configSection.complete)
    }

    MainLoop() {

        ocrResult := OCR.FromRect(
            positions.completeRect.x + positions.completeRect.w / 2,
            positions.completeRect.y,
            positions.completeRect.w / 2,
            positions.completeRect.h,
        )
        if InStr(ocrResult.Text, "claim") {
            OutputDebug("Found 'claim' in OCR text: `"" ocrResult.text "`"")
            Sleep(500)
            Click(positions.completeRect.x + positions.completeRect.w - 15, positions.completeRect.center.y)
            OutputDebug("Resource available, collecting and exiting...")
            SoundPlay("*48")
            SetTimer(MainLoop, 0)
            return
        }

        currentColor := PixelGetColor(positions.staminaStartPos.x, positions.staminaStartPos.y)
        if (staminaColor != currentColor) {
            OutputDebug("Stamina not full at (" positions.staminaStartPos.x ", " positions.staminaStartPos.y "), color: " currentColor "`n"
            )
            OutputDebug("Stamina not full, performing actions...")
            Sleep(1000)

            ; Stop task
            ; NOTE: Just clicking doesn't work sometimes, use interact hotkey instead
            MouseMove(positions.workbenchPos.x, positions.workbenchPos.y)
            Sleep(200)
            Send("n")
            Sleep(2000)
            Click(positions.itemPos.x, positions.itemPos.y)
            Sleep(500)
            Click(positions.actionPos.x, positions.actionPos.y)
            Sleep(500)

            ; Sleep(staminaRegenTime)
            OutputDebug("Waiting for stamina to regenerate...")
            success := WaitForColorChange(staminaColor, positions.staminaEndPos.x, positions.staminaEndPos.y, 60000)
            if (!success) {
                OutputDebug("[warn] Stamina did not regenerate in time")
                SoundPlay("*48")
            }

            ; Resume task
            Click(positions.actionPos.x, positions.actionPos.y)
        }
    }

    SetTimer(MainLoop, 100)
}

EatFood() {
    userInput := InputBox("Enter food duration in minutes:", "Food Duration Input", , "15").Value
    OutputDebug("User input: " userInput)
    if IsNumber(userInput)
        userInput := Number(userInput)
    else
        return MsgBox("Invalid input. Please enter a number.")
    if (userInput < 15) {
        return MsgBox("Enter a number at or above 15 minutes.")
    }
    EatFood() {
        OutputDebug("Eating food for " userInput " minutes")
        WinActivate("ahk_id " bitcraftHWND)
        Sleep(200)
        Send("+e")
    }
    SetTimer(EatFood, 1000 * 60 * userInput)
}

F1:: CreateWindows()

F2:: WorkbenchTask()

F3:: EatFood()

F4:: {
    OutputDebug("Exiting Thread")
    Exit(1)
}

F5:: {
    OutputDebug("Exiting")
    ExitApp()
}
