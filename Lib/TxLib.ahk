#Requires AutoHotkey v2.0.0+

LatestVersion(pattern := "ODX*", folder := "C:\Program Files\TimeXtender") {

    FileList := ""
    Loop Files folder "\" pattern, "D"
        FileList .= A_LoopFilePath "`n"
    LatestVersion := StrSplit(Sort(FileList, "R"), "`n", , 2)[1]

    return StrSplit(Sort(FileList, "R"), "`n", , 2)[1]
}

LogFileName := A_ScriptName . ".log"
if FileExist(LogFileName) {
    FileDelete LogFileName
}
LogMsg(msg, LogFileName := A_ScriptName . ".log") {
    global create_log
    if (create_log)
    {
        FileAppend FormatTime(, "yyyy-MM-dd HH:mm:ss") . " - " . msg . "`r`n", LogFileName
    }
}

StrJoin(arr, concat := ", ", beforeEach := "", afterEach := "", before := "", after := "") {
    value := ""
    Loop arr.Length {
        value .= (A_Index > 1 ? concat : "") . beforeEach . arr[A_Index] . afterEach
    }
    return (StrLen(value) == 0 ? value : before . value . after)
}

InArray(arr, search) {
    loop arr.Length {
        if arr[A_Index] == search {
            return A_Index
        }
    }
    return 0
}