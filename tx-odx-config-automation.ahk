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

create_log := false

exe_name := "ODXServerConfiguration.exe"
win_title := "ODX Server Configuration"
cred_name := "https://timextender-saas.eu.auth0.com"

#Include Lib\TxLib.ahk
#Include Lib\UIA.ahk
;#include Lib\UIA_Browser.ahk
#Include Lib\CredMgr.ahk

TxUserName := ""
TxPassword := ""

; first, try to read credentials from command line arguments
if A_Args.Length > 1 {
    TxUserName := A_Args[2]
    TxPassword := A_Args[3]

    ; secondly, try to read from windows credential store
} else if (cred := CredRead(cred_name)) {
    TxUserName := cred.username
    TxPassword := cred.password

    ; then, get them from environment variables
} else {
    TxUserName := EnvGet("TxUserName")
    TxPassword := EnvGet("TxPassword")
}

; lastly, prompt the user for credentials
if TxUserName == "" {
    TxUserName := InputBox("TimeXtender Portal user name").Value
}

if TxPassword == "" {
    TxPassword := InputBox("TimeXtender Portal password", , "Password*").Value
}


if A_Args.Length > 0 {
    TxOdxInstanceName := A_Args[1]

} else if not (TxOdxInstanceName := EnvGet("TxOdxInstanceName")) {
    TxOdxInstanceName := InputBox("TimeXtender ODX instance name").Value

}


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

    WinWaitActive("Sign In", , 5)
    if (!WinWaitClose("Sign In", , 5)) {
        ; window still exists

        Sleep 5000

        rootEl := UIA.ElementFromHandle("Sign In")

        el := rootEl.WaitElement({ Name: "Email", Type: "Edit" }, 10)

        el.SetFocus()
        el.ControlClick()
        el.value := ""
        Sleep 100
        Send "{Text}" . TxUserName
        Sleep 1000

        el := rootEl.FindElement({ Name: "Password", Type: "Edit" })

        el.SetFocus()
        el.ControlClick()
        el.value := ""
        Sleep 100
        Send "{Raw}" . TxPassword
        Sleep 100

        Sleep 100
        rootEl.FindElement({ Name: "Sign in", Type: "Button" }).ControlClick()

        WinWaitClose "Sign In", , 5
    }
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