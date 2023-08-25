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

exe_name := "TimeXtender.Job.Execution.Configuration.exe"
win_title := "Execution Server Configuration"


if A_Args.Length > 0 {
    TxUserName := A_Args[1]
    TxPassword := A_Args[2]
    TxExecutionServerInstanceNames := StrSplit(A_Args[3], ",")
} else {
    TxUserName := EnvGet("TxUserName")
    TxPassword := EnvGet("TxPassword")
    TxExecutionServerInstanceNames := StrSplit(EnvGet("TxExecutionServerInstanceNames"), ",")
}

#Include tx-lib.ahk
#Include Lib\UIA.ahk

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

if WinWaitActive("Sign In", , 5) {
    LogMsg("Sign in")
    ; TODO: implement logging in

    WinWaitClose "Sign In", , 5
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