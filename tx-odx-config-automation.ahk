#Requires AutoHotkey v2.0.0+
#SingleInstance Force

;
; Elevated permissions are required to access the wizard UIs
; since the wizards also enforce them
;

full_command_line := DllCall("GetCommandLine", "str")

if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)"))
{
    try
    {
        if A_IsCompiled
            Run '*RunAs "' A_ScriptFullPath '" /restart'
        else
            Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"'
    }
    ExitApp
}

;
; some config
;

SetWorkingDir A_ScriptDir
SetTitleMatchMode 1
SetTitleMatchMode "Slow"
SetWinDelay 1000
SetControlDelay 100

exe_name := "ODXServerConfiguration.exe"
win_title := "ODX Server Configuration"


if A_Args.Length > 0 {
    TxUserName := A_Args[1]
    TxPassword := A_Args[2]
    TxOdxInstanceName := A_Args[3]
} else {
    TxUserName := EnvGet("TxUserName")
    TxPassword := EnvGet("TxPassword")
    TxOdxInstanceName := EnvGet("TxOdxInstanceName")
}

#Include Lib\TxLib.ahk
#Include Lib\UIA.ahk

;
; SCRIPT STARTS HERE
;

if not WinExist("ahk_exe " exe_name) {
    LogMsg(exe_name " not running, starting...")
    Run LatestVersion("ODX*") "\" exe_name
    WinWait "ahk_exe " exe_name
} else {
    LogMsg(exe_name " already running...")
}

WinActivate win_title

if WinWaitActive(win_title, "Welcome", 5) {
    ControlClick "Next >"
}

if WinWaitActive(win_title, "Proxy Server Settings", 5) {
    ControlClick "Next >"
}

if WinWaitActive(win_title, "Sign In", 5) {
    ControlClick "Sign In"
}

if WinWaitActive("Sign In", , 5) {
    LogMsg("Sign in")
    ; TODO: implement logging in

    WinWaitClose "Sign In", , 5
}

WinActivate win_title

if WinWaitActive(win_title, "Instance", 5) {
    RootEl := UIA.ElementFromHandle(win_title)
    el := RootEl.WaitElement({
        Type: "ComboBox"
    })
    el.Expand()
    for el in RootEl.FindAll({
        Type: "ListItem"
    }) {
        if el.Name == TxOdxInstanceName {
            el.ControlClick()
            break
        }
    }

    ControlClick "Next >", win_title
}

if WinWait("Instance is locked", , 5) {
    ControlClick("&Yes")
}

if WinWaitActive(win_title, "Advanced Options", 5) {
    ControlClick "Next >"
}

if WinWaitActive(win_title, "Windows Service", 5) {
    ControlClick "Next >"
}

if WinWaitActive(win_title, "Configuration Complete", 5) {
    ControlClick "Save"
}