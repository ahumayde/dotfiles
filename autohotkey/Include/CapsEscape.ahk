#Requires AutoHotkey v2.0

; Default Not Suspended
Suspended := False

; Remap CapsLock to Escape
CapsLock::Esc 

; Suspends the Script
SuspendCapsEscape() {
    global Suspended
    MsgBox("Caps Lock is now: " . (!Suspended ? "Enabled" : "Disabled"))
    Suspended := !Suspended
    Suspend
}

; Toggle Caps Lock -> Escape Keybind
#SuspendExempt
^Esc::SuspendCapsEscape()
