#Requires AutoHotkey v2.0

; Run as Admin
if !A_IsAdmin {
    Run("*RunAs " . A_ScriptFullPath)
    ExitApp()
}

; Registry Key Name
SystemReg := "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\System"

; Default Disable Windows Lock
RegWrite("1", "REG_DWORD", SystemReg, "DisableLockWorkstation")

; Toggle Windows Lock
ToggleWinLock() {
    global SystemReg
    Locked := RegRead(SystemReg, "DisableLockWorkstation")
    RegWrite(!Locked, "REG_DWORD", SystemReg, "DisableLockWorkstation")
    MsgBox("Workstation Lock is now: " . (!Locked ? "Disabled" : "Enabled"))
}
#^!+l::ToggleWinLock()
; ScrollLock::ToggleWinLock()
