#Requires AutoHotkey v2.0

#include "./OCR-2.0-alpha.4/Lib/OCR.ahk"

; Function to get pixel color at a coordinate that scales relative to active window height
; Parameters:
;   relativeY: Y coordinate as a percentage of window height (0.0 to 1.0)
;   offsetFromBottom: Distance from bottom of window (in pixels or as percentage if < 1.0)
;   elementWidth: Width of the UI element (optional, for centering calculation)
;   elementHeight: Height of the UI element (optional, for aspect ratio)
GetScaledPixelColor(relativeY := 0.5, offsetFromBottom := 0, elementWidth := 0, elementHeight := 0) {
    ; Get the active window
    activeWindow := WinGetID("A")
    if (!activeWindow) {
        throw Error("No active window found")
    }

    ; Get window position and dimensions
    WinGetPos(&winX, &winY, &winWidth, &winHeight, activeWindow)

    ; Calculate the scaled Y coordinate
    ; If offsetFromBottom is specified, calculate from bottom
    if (offsetFromBottom > 0) {
        if (offsetFromBottom < 1.0) {
            ; Treat as percentage
            scaledY := winY + winHeight - (winHeight * offsetFromBottom)
        } else {
            ; Treat as pixel offset
            scaledY := winY + winHeight - offsetFromBottom
        }

        ; If element height is provided, adjust for aspect ratio
        if (elementHeight > 0) {
            scaledY -= elementHeight / 2
        }
    } else {
        ; Use relative position from top
        scaledY := winY + (winHeight * relativeY)
    }

    ; Center horizontally
    scaledX := winX + (winWidth / 2)

    ; If element width is provided, adjust for centering
    if (elementWidth > 0) {
        scaledX -= elementWidth / 2
    }

    ; Ensure coordinates are within window bounds
    scaledX := Max(winX, Min(winX + winWidth - 1, scaledX))
    scaledY := Max(winY, Min(winY + winHeight - 1, scaledY))

    ; Get pixel color at the calculated position
    pixelColor := PixelGetColor(scaledX, scaledY)

    ; Return both the color and the coordinates for debugging
    return {
        color: pixelColor,
        x: scaledX,
        y: scaledY,
        windowWidth: winWidth,
        windowHeight: winHeight
    }
}

; Example usage function
ExampleGetUIElementColor() {
    ; Example: Get color of UI element that's 20% from bottom, centered horizontally
    result := GetScaledPixelColor(, 0.2)  ; 20% from bottom

    ; Display the result
    MsgBox("Pixel Color: " . result.color . "`n" .
        "Coordinates: (" . result.x . ", " . result.y . ")`n" .
        "Window Size: " . result.windowWidth . "x" . result.windowHeight)

    return result.color
}

; Hotkey example - Press F1 to get the color
; F1::ExampleGetUIElementColor()

; More specific example for a UI element with known dimensions
GetSpecificUIElementColor() {
    ; Example: UI element that's 100 pixels wide, 50 pixels tall,
    ; positioned 15% from the bottom of the window
    result := GetScaledPixelColor(, 0.15, 100, 50)

    return result.color
}

; Hotkey for specific UI element - Press F2
; F2::GetSpecificUIElementColor()

WaitForColorChange(targetColor, posX, posY, timeout := 5000) {
    startTime := A_TickCount
    while (A_TickCount - startTime < timeout) {
        currentColor := PixelGetColor(posX, posY)  ; Replace with actual coordinates if needed
        if (currentColor = targetColor) {
            return true
        }
        Sleep(100)  ; Check every 100 ms
    }
    return false
}

; Clicks at (x, y) in the specified window using ControlClick, without focusing it
; winTitle: Window title or ahk_id
; x, y: Coordinates relative to the window's client area
ClickInBackground(winTitle, x, y) {
    ; Default to active window if winTitle is empty
    if (!winTitle)
        winTitle := "A"
    SetControlDelay -1
    ; Use ControlClick with no control (clicks client area)
    ControlClick(
        "x" x " y" y,
        winTitle,
        , , ,
        "NA"
    )
}

PostClick(x, y, win := "A") {
    lParam := x & 0xFFFF | (y & 0xFFFF) << 16
    PostMessage(0x201, , lParam, , win) ;WM_LBUTTONDOWN
    PostMessage(0x202, , lParam, , win) ;WM_LBUTTONUP
}

DrawRect(x, y, w, h, text := "", resizeX := false, resizeY := false, aspectRatio := unset) {
    ; Draw a draggable rectangle overlay on the screen
    rect := { x: x, y: y, w: w, h: h }, dragging := false, offsetX := 0, offsetY := 0

    if !IsSet(rectGui) {
        maxWidth := (resizeX) ? A_ScreenWidth : w
        maxHeight := (resizeY) ? A_ScreenHeight : h
        rectGui := Gui('+AlwaysOnTop -Caption +LastFound +E0x20 +OwnDialogs +Resize +MinSize' w 'x' h ' +MaxSize' maxWidth 'x' maxHeight
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

GetHWNDRect(hwnd) {
    WinGetPos(&x, &y, &w, &h, "ahk_id " hwnd)
    return {
        x: x,
        y: y,
        w: w,
        h: h,
        center: {
            x: x + w // 2,
            y: y + h // 2
        }
    }
}

craftW := 1415
craftH := 955
; craftWindow := DrawRect(0, 0, craftW, craftH)
bitcraftHWND := WinExist("BitCraft")
if 0 == bitcraftHWND {
    MsgBox("BitCraft window not found!")
    ExitApp
}
OutputDebug("BitCraft HWND: " bitcraftHWND)
; craftWindow.Opt("+Owner" bitcraftHWND)

; Positions taken at half 3440x1440 resolution (left side)
WinGetPos(&mainX, &mainY, &mainW, &mainH, "BitCraft")
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

CoordMode 'Pixel', 'Screen'
CoordMode 'Mouse', 'Screen'

CreateWindows() {
    staminaWindow := DrawRect(mainX + staminaX, mainY + staminaY, 70, 20, "Stamina", true)
    itemWindow := DrawRect(mainX + itemX, mainY + itemY, 200, 50, "Item")
    actionWindow := DrawRect(mainX + actionX, mainY + actionY, 200, 50, "Action")
    completeWindow := DrawRect(mainX + claimX, mainY + claimY, 200, 50, "Claim", true)
    workbenchWindow := DrawRect(mainX + mainW / 2, mainY + mainH / 2, 100, 100, "Workbench")
    button := workbenchWindow.AddButton("Default", "Start")

    SubmitCallback(*) {
        staminaRect := GetHWNDRect(staminaWindow.Hwnd)
        IniWrite(staminaRect.x, configFile, "StaminaPosition", "x")
        IniWrite(staminaRect.y, configFile, "StaminaPosition", "y")
        IniWrite(staminaRect.w, configFile, "StaminaPosition", "w")
        staminaStartPos := { x: staminaRect.x, y: staminaRect.center.y }
        staminaEndPos := { x: staminaRect.x + staminaRect.w, y: staminaRect.center.y }
        itemRect := GetHWNDRect(itemWindow.Hwnd)
        actionRect := GetHWNDRect(actionWindow.Hwnd)
        workbenchRect := GetHWNDRect(workbenchWindow.Hwnd)
        completeRect := GetHWNDRect(completeWindow.Hwnd)

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

        ; WorkbenchTask({
        ;     staminaStartPos: staminaStartPos,
        ;     staminaEndPos: staminaEndPos,
        ;     itemPos: itemRect.center,
        ;     actionPos: actionRect.center,
        ;     workbenchPos: workbenchRect.center,
        ;     completeRect: completeRect
        ; })
    }

    button.OnEvent("Click", SubmitCallback)
}

WorkbenchTask(positions) {
    ToolTip("Starting Workbench Task...")

    while true {
        Sleep(100)  ; Check every 100 ms

        text := OCR.FromRect(
            positions.completeRect.x + positions.completeRect.w / 2, 
            positions.completeRect.y, 
            positions.completeRect.w /2, 
            positions.completeRect.h,
        )
        if InStr(text.Text, "claim") {
            OutputDebug("Found 'claim' in OCR text: `"" text "`"")
            Sleep(500)
            Click(positions.completeRect.x + positions.completeRect.w - 15, positions.completeRect.center.y)
            break
        }
        OutputDebug("OCR text: " text.Text)

        currentColor := PixelGetColor(positions.staminaStartPos.x, positions.staminaStartPos.y)
        if (staminaColor != currentColor) {
            OutputDebug("Stamina not full at (" positions.staminaStartPos.x ", " positions.staminaStartPos.y "), color: " currentColor "`n"
            )
            ToolTip("Stamina not full, performing actions...")
            Sleep(1000)

            ; Stop task
            Click(positions.workbenchPos.x, positions.workbenchPos.y)
            Sleep(1000)
            Click(positions.itemPos.x, positions.itemPos.y)
            Sleep(500)
            Click(positions.actionPos.x, positions.actionPos.y)
            Sleep(500)

            ; Sleep(staminaRegenTime)
            OutputDebug("Waiting for stamina to regenerate...")
            success := WaitForColorChange(staminaColor, positions.staminaEndPos.x, positions.staminaEndPos.y, 60000)
            if (!success) {
                ToolTip("[warn] Stamina did not regenerate in time")
                SoundPlay("*48")
            }

            ; Resume task
            Click(positions.actionPos.x, positions.actionPos.y)
        }

        ; statusColor1 := PixelGetColor(status1X, statusY)
        ; statusColor2 := PixelGetColor(status2X, statusY)
        ; statusColor3 := PixelGetColor(status3X, statusY)
        ; statusCount := (statusColor1 == statusColor) + (statusColor2 == statusColor) + (statusColor3 == statusColor)
        ; If (statusCount < 2 && statusCount > 0) {
        ;     OutputDebug("Missing statuses, found " statusColor1 ", " statusColor2 ", " statusColor3 "`n")
        ;     Send("+e")
        ;     SoundBeep()
        ; }
    }
    ToolTip("Resource available, collecting and exiting...")
    SoundPlay("*48")
}

CollectionTask() {
    ; Record position of mouse cursor
    MouseGetPos(&mouseX, &mouseY)
    while true {
        Sleep(100)  ; Check every 100 ms
        staminaFullColor := PixelGetColor(staminaFullX, staminaFullY)
        if (staminaFullColor == staminaColor) {
            Click(mouseX, mouseY)
            Sleep(10000)
        }
    }
}

F2:: CreateWindows()

; F3::{
;     If not A_IsAdmin ;force the script to run as admin
;     {
;         Run '*RunAs "' A_ScriptFullPath '"'
;         ExitApp
;     }

;     MouseGetPos(&mouseX, &mouseY)
;     ToolTip("Clicking in background window...")
;     Sleep(1000)
;     ; ClickInBackground("BitCraft", 49,1337)
;     PostClick(49,1337, "BitCraft")
; }

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
    while true {
        Sleep(1000 * 60 * userInput)
        OutputDebug("Eating food for " userInput " minutes")
        Send("+e")
    }
}

F3::EatFood()

F4:: {
    OutputDebug("Exiting")
    Exit(1)
}

F5:: {
    rect1 := DrawRect(100, 100, 200, 100)
    rect2 := DrawRect(300, 300, 200, 100)

    while true {
        Sleep(1000)
        rect1Pos := GetHWNDRect(rect1.Hwnd)
        rect2Pos := GetHWNDRect(rect2.Hwnd)
        ToolTip("Rect1: " rect1Pos.x ", " rect1Pos.y "`nRect2: " rect2Pos.x ", " rect2Pos.y)
    }
}
