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
            Run '*RunAs "' A_ScriptFullPath '" /restart' . StrJoin(A_Args, " ", '"', '"', " ")
        else
            Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"' . StrJoin(A_Args, " ", '"', '"', " ")
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

exe_name := "TimeXtender.Job.Execution.Configuration.exe"
win_title := "Execution Server Configuration"
cred_name := "https://timextender-saas.eu.auth0.com"

#Include Lib\TxLib.ahk
#Include Lib\UIA.ahk
#Include Lib\CredMgr.ahk

TxUserName := ""
TxPassword := ""

if A_Args.Length > 1 {
    TxUserName := A_Args[2]
    TxPassword := A_Args[3]

} else if (cred := CredRead(cred_name)) {
    TxUserName := cred.username
    TxPassword := cred.password

} else {
    TxUserName := EnvGet("TxUserName")
    TxPassword := EnvGet("TxPassword")
}

if TxUserName == "" {
    TxUserName := InputBox("TimeXtender Portal user name").Value
}

if TxPassword == "" {
    TxPassword := InputBox("TimeXtender Portal password", , "Password*").Value
}


if A_Args.Length > 0 {
    TxExecutionServerInstanceNames := StrSplit(A_Args[1], ",", " `t")

} else if TxExecutionServerInstanceNames := EnvGet("TxExecutionServerInstanceNames") {
    TxExecutionServerInstanceNames := StrSplit(TxExecutionServerInstanceNames, ",")

} else {
    TxExecutionServerInstanceNames := StrSplit(InputBox("TimeXtender instance names, separated by comma (',')").Value, ",", " `t")
    ;["MDW Local"]

}


;
; SCRIPT STARTS HERE
;

LogMsg "TxUserName: " TxUserName
LogMsg "TxExecutionServerInstanceNames: " StrJoin(TxExecutionServerInstanceNames)

if not WinExist("ahk_exe " exe_name) {
    LogMsg(exe_name " not running, starting...")
    Run LatestVersion("TimeXtender*") "\" exe_name
    WinWait win_title
} else {
    LogMsg(exe_name " already running...")
    WinActivate win_title
}

if WinWaitActive(win_title, "Welcome", 5) {
    ControlClick "Next"
}

if WinWaitActive(win_title, "Sign in", 5) {
    ControlClick "Sign in..."
}

if WinWaitActive("Sign In", , 10) {
    LogMsg("Sign in")

    WinWaitActive("Sign In", , 10)
    if (!WinWaitClose("Sign In", , 10)) {
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

if WinWaitActive(win_title, , 5) {

    LogMsg("Selecting Instances")
    RootEl := UIA.ElementFromHandle(win_title)

    RootEl.WaitElement({ Type: "ListItem" })

    for el in RootEl.FindAll({ Type: "ListItem" }) {

        if InArray(TxExecutionServerInstanceNames, el.Name) {
            if not el.ToggleState {
                el.Toggle()
                LogMsg Format("Instance '{1}' checked", el.Name)
            } else {
                LogMsg Format("Instance '{1}' already checked", el.Name)
            }
        } else {
            if el.ToggleState {
                el.Toggle()
                LogMsg Format("Instance '{1}' unchecked", el.Name)

            } else {
                LogMsg Format("Instance '{1}' already unchecked", el.Name)
            }
        }
        Sleep 50
    }

    LogMsg("Saving instances")
    ControlClick "Save"
}


if WinWait(win_title, "When you save the configuration, you will take the lock on these instances.", 10) {
    ControlClick "Yes"
    LogMsg("Confirming taking instance lock")
}