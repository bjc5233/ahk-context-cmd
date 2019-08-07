;说明
;  效率工具，上下文环境命令助手
;    启用方式1： 监听``之间输入的命令 {在任何环境下都可以检测到【输入框\桌面】}
;    启用方式2： 双击Ctrl弹出输入框，输入命令
;  配置说明
;    图标右键->修改菜单-> 新增\编辑\删除\保存命令树
;    => g   快捷跳转命令
;    => get 快捷复制命令
;    => q   qq联系人跳转
;    => do  综合性处理命令
;    => -   contextCmd内建指令【theme[切换主题] tree[编辑命令树] history[历史命令] reload[重启脚本] quit[关闭界面] exit[退出脚本]】 
;    => 其他系统级别的命令、快捷方式 【calc notepad...】
;  主题说明
;    1.auto模式(默认), 根据系统当前壁纸配置颜色, 窗口位置中间【需要第三方命令行工具imagemagick-convert.exe】
;    2.blur模式, AeroGlass风格, 由于在偏白色背景下无法看清文字, 因此位置放置在左下角
;    3.custom模式, 配置的固定几种颜色风格, 每次展示时随机颜色风格, 窗口位置中间
;  输入框界面快捷键说明
;    1.总界面   - F1键      - 打开命令树管理
;    2.总界面   - Esc键     - 关闭
;    3.候选列表 - Up\Down键 - 在输入框\候选命令列表上下移动
;    4.候选列表 - Right键   - 将当前选中的命令复制到输入框中
;    5.输入框   - Tab键     - 将候选列表中第一个结果复制到输入框中
;  DB表字段说明
;    1.config表 
;       [InputCmdLastValue 输入框上次值]
;       [LastWallpaperColor 上次壁纸主色调]
;       [LastWallpaperPath 上次壁纸路径]
;       [LastWallpaperTimeStamp 上次壁纸修改时间戳]
;       [theme 主题配置]
;    2.cmd表 
;       [name 名称]
;       [cmd 命令名]
;       [exec 命令执行代码]
;       [treeSort 命令树中排序字段]
;       [hit 命令命中次数]
;       [pid 父级命令编号]
;       [topPid 顶级命令编号<g get do q>]
;    3.systemCmd表 
;       [name 系统命令文件名<无扩展名>]
;       [desc 系统命令文件描述]
;       [hit 命令命中次数]
;       [show 是否展示在搜索候选栏中<对于完全不会用到的命令设值0>]
;       TODO 是否需要加入文件全路径
;    3.historyCmd表 
;       [name 名称]
;       [cmd 命令名]
;备注
;  1. {vkC0}表示`
;  2. 配置命令的[执行]文本框中, 在第一行输入[目标语言注释符号 $execLang= 目标语言$]格式, 
;       ::$execLang=bat$
;     会将此文本框文本保存到bat文件, 并执行该bat
;  3. 当命令命中次数到达阀值[ICBCmdHitThreshold\ICBSystemCmdHitThreshold], 将重新构建ICB变量, 使得命中次数多的命令可以在匹配结果中更加靠前

;========================= 环境配置 =========================
#NoEnv
#Persistent
#ErrorStdOut
#SingleInstance, Force
#HotkeyInterval 1000
SetBatchLines, 10ms
DetectHiddenWindows, On
SetTitleMatchMode, 2
SetKeyDelay, -1
StringCaseSense, off
CoordMode, Menu
#Include <JSON> 
#Include <PRINT>
#Include <TIP>
#Include <CuteWord>
#Include <OrderedArray>
#Include <DBA>

;========================= 初始化 =========================
global CurrentDB := Object()
global Config := Object()
global ConfigExecLangPathBase := A_ScriptDir "\cache"

;命令树变量 TV => TreeView
global TVIdCmdObjMap := Object()
global TVPidChildIdsMap := Object()
global TVBranchIdIdMap := Object()
global TVIdBranchIdMap := Object()
global TVCmdCount := 0

;命令输入框变量 ICB => InputCmdBar
global ICBIdCmdObjMap := Object()
global ICBTopPNamePidMap := Object()
global ICBTopPidChildCmdMap := Object()
global ICBHistoryCmds := Object()
global ICBCmdHitCount := 0
global ICBCmdHitThreshold := 5
global ICBSystemPaths := [{"path": "C:\WINDOWS\System32\*.exe", "type": "system"}, {"path": "C:\WINDOWS\*.exe", "type": "system"}, {"path": "C:\path\*", "type": "custom"}, {"path": "C:\path\bat\*", "type": "custom"}]
global ICBSystemCmdMap := new OrderedArray()
global ICBSystemCmdHitCount := 0
global ICBSystemCmdHitThreshold := 5
global ICBBuildInCmdMap := new OrderedArray()

MenuTray()
DBConnect()
PrepareConfigData()
PrepareICBData()
PrepareSystemCmdData()
print("contextCmd is working")
;========================= 初始化 =========================



;========================= 配置热键 =========================
#R:: 
MButton::   gosub, GuiInputCmdBar
~RControl:: HotKeyConfControl()
~`::        HotKeyConfWave()
^!R::       OpenRunDialog()   ;Win+R被占用, 使用Ctrl+Alt+R应对运行对话框临时使用

global InputCmdMode :=
global HotKeyControlCount := 0
HotKeyConfControl() {
	(HotKeyControlCount < 1 && A_TimeSincePriorHotkey > 80 && A_TimeSincePriorHotkey < 400 && A_PriorHotkey = A_ThisHotkey) ? HotKeyControlCount ++ : (HotKeyControlCount := 0)
	if (HotKeyControlCount > 0)
        gosub, GuiInputCmdBar
}
HotKeyConfWave() {
    Input, inputCmd, V T10, {vkC0},
    if (!inputCmd || InStr(inputCmd, "`n", true))             ;如输入文本为空\输入文本中包含换行, 则不是有效命令
        return
    InputCmdMode := "hotkey"
    InputCmdExec(inputCmd)
}
;========================= 配置热键 =========================






;========================= 输入Bar =========================
global InputCmdBarExist := false
global InputCmdEdit :=
global InputCmdLV :=
global InputCmdMatchText :=
global InputCmdLastValue :=
;GuiInputCmdBar未采用函数调用原因: AeroGlass在函数模式未生效
GuiInputCmdBar:
    ;if (WinExist("contextCmd.ahk ahk_class AutoHotkeyGUI")) {}
    if (InputCmdBarExist) {
        Gui, InputCmdBar:Default
        Gui, InputCmdBar:Submit, NoHide
        Config.InputCmdLastValue := InputCmdEdit
        Gui, InputCmdBar:Hide
        InputCmdBarExist := false
        return
    }
    ActiveEnglishKeyboard() ;确保当前为英文输入法
       
       
    global InputCmdBarHwnd := "inputCmdBar"
    InputCmdBarExist := true
    InputCmdMode := "inputBar"
    InputCmdLastValue := Config.InputCmdLastValue
    InputCmdBarThemeConf(themeType, themeBgColor, themeFontColor, themeX, themeY)
    OnMessage(0x0201, "WM_LBUTTONDOWN")
    Gui, InputCmdBar:New, +LastFound -Caption -Border +Owner +AlwaysOnTop +hWnd%InputCmdBarHwnd%
    Gui, InputCmdBar:Margin, 5, 5
    Gui, InputCmdBar:Color, %themeBgColor%, %themeBgColor%
    Gui, InputCmdBar:Font, c%themeFontColor% s16 wbold, Microsoft YaHei
    Gui, InputCmdBar:Add, Edit, w490 h38 vInputCmdEdit gInputCmdEditHandler, %InputCmdLastValue%
    Gui, InputCmdBar:Font, s10 -w, Microsoft YaHei
    Gui, InputCmdBar:Add, ListView, AltSubmit -Hdr -Multi ReadOnly w490 r9 vInputCmdLV gInputCmdLVHandler, cmd|name
    Gui, InputCmdBar:Font, s7, Microsoft YaHei
    Gui, InputCmdBar:Add, Text, xm+5 w450 vInputCmdMatchText
    Gui, InputCmdBar:Add, Button, Default w0 h0 Hidden gInputCmdSubmitHandler
    
    if (!IsEnglishKeyboard())
        ActiveEnglishKeyboard2() ;show之前再次确保当前为英文输入法
    
    guiX := 10
    guiY := A_ScreenHeight/2 - 150
    Winset, Transparent, 238
    if (themeX && themeY) {
        Gui, InputCmdBar:Show, w500 h48 x%themeX% y%themeY%
    } else {
        Gui, InputCmdBar:Show, w500 h48 xCenter y%guiY%
    }
    LV_ModifyCol(1, 180)
    LV_ModifyCol(2, 250)
    if (themeType == "blur")
        EnableBlur(InputCmdBarHwnd)
    InputCmdEditHandler()
return

InputCmdSubmitHandler(CtrlHwnd, GuiEvent, EventInfo) {
    Gui, InputCmdBar:Default
    Gui, InputCmdBar:Submit, NoHide
    GuiControlGet, focusedControl, FocusV
    if (focusedControl == "InputCmdEdit") {
        inputCmd := InputCmdEdit
    } else if (focusedControl == "InputCmdLV") {
        rowNum := LV_GetNext(0, "Focused")
        if (!rowNum)
            return
        LV_GetText(inputCmd, rowNum, 1)
    }
    Gui, InputCmdBar:Hide
    InputCmdLastValue := inputCmd
    InputCmdExec(inputCmd)
    InputCmdBarExist := false
    Config.InputCmdLastValue := inputCmd
}

InputCmdBarGuiEscape:
    Gui, InputCmdBar:Submit, NoHide
    if (InputCmdEdit)
        Config.InputCmdLastValue := InputCmdEdit
    Gui, InputCmdBar:Hide
    InputCmdBarExist := false
return

InputCmdEditHandler(CtrlHwnd:="", GuiEvent:="", EventInfo:="") {
    Gui, InputCmdBar:Default
    Gui, InputCmdBar:Submit, NoHide
    Gui, InputCmdBar:Show, h48
    LV_Delete()
    inputCmd := RegExReplace(LTrim(InputCmdEdit), "\s+", " ")      ;去除首位空格, 将字符串内多个连续空格替换为单个空格
    inputCmdArray := StrSplit(inputCmd, A_Space)
    inputCmdArrayLen := inputCmdArray.Length()
    if (!inputCmd || inputCmd == " " || inputCmd == "- history") {
        for index, historyCmd in ICBHistoryCmds {
            LV_Add(, historyCmd.cmd, historyCmd.name)
        }
    } else if (inputCmdArrayLen == 1) {
        if (inputCmd == "-") {
            for cmdName, cmdDesc in ICBBuildInCmdMap {
                if (RegExMatch(cmdName, "i)^" inputCmdValue))
                    LV_Add(, "- " cmdName, cmdDesc)
            }
        } else {
            for systemCmdName, systemCmdObj in ICBSystemCmdMap {
                if (RegExMatch(systemCmdName, "i)^" inputCmd))
                    LV_Add(, systemCmdName, systemCmdObj.desc)
            }
        }
    } else if (inputCmdArrayLen  >= 2) {
        inputCmdKey := inputCmdArray[1]
        inputCmdValue := inputCmdArray[2]
        if (inputCmdKey == "-") {
            for cmdName, cmdDesc in ICBBuildInCmdMap {
                if (RegExMatch(cmdName, "i)^" inputCmdValue))
                    LV_Add(, "- " cmdName, cmdDesc)
            }
        } else {
            topPid := ICBTopPNamePidMap[inputCmdKey]
            if (!topPid)
                return
            topChildCmds := ICBTopPidChildCmdMap[topPid]
            if (!topChildCmds)
                return
            inputCmdValue := inputCmdArray[2]
            for cmdKey, cmdId in topChildCmds {
                if (RegExMatch(cmdKey, "i)^" inputCmdValue))
                    LV_Add(, inputCmdKey " " cmdKey, ICBIdCmdObjMap[cmdId].name)
            }
        }
    }
    if (LV_GetCount()) {
        GuiControl, ,InputCmdMatchText, % "match: " LV_GetCount()
        Gui, InputCmdBar:Show, h270
    }
}
InputCmdLVHandler(CtrlHwnd, GuiEvent, EventInfo) {
	if (GuiEvent == "DoubleClick") {
        InputCmdSubmitHandler(CtrlHwnd, GuiEvent, EventInfo)
	} else if (GuiEvent == "K") {
        if (EventInfo == 32) {  ;空格键切换回输入框继续编辑
            Gui, InputCmdBar:Default
            rowNum := LV_GetNext(0, "Focused")
            if (rowNum)
                LV_Modify(rowNum, "-Focus -Select")
            GuiControl, Focus, InputCmdEdit
        }
    }
}


#If WinActive(A_ScriptName) and WinActive("ahk_class AutoHotkeyGUI")
    ~Up::    InputCmdBarKeyUp()
    ~Down::  InputCmdBarKeyDown()
    ~Right:: InputCmdBarKeyRight()
    Tab::    InputCmdBarKeyTab()
    F1::     GuiTV()
#If
InputCmdBarKeyUp() {
    Gui, InputCmdBar:Default
    GuiControlGet, focusedControl, FocusV
    if (focusedControl == "InputCmdEdit") {
        if (LV_GetCount()) {
            GuiControl, InputCmdBar:Focus, InputCmdLV
            Send, ^{End}
        }
    } else if (focusedControl == "InputCmdLV") {
        rowNum := LV_GetNext(0, "Focused")
        if (rowNum == 1) {
            LV_Modify(1, "-Focus -Select")
            GuiControl, Focus, InputCmdEdit
        }
    }
}
InputCmdBarKeyDown() {
    Gui, InputCmdBar:Default
    GuiControlGet, focusedControl, FocusV
    if (focusedControl == "InputCmdEdit") {
        if (LV_GetCount()) {
            GuiControl, InputCmdBar:Focus, InputCmdLV
            Send, ^{Home}
        }
    } else if (focusedControl == "InputCmdLV") {
        rowNum := LV_GetNext(0, "Focused")
        if (rowNum == LV_GetCount()) {
            LV_Modify(rowNum, "-Focus -Select")
            GuiControl, Focus, InputCmdEdit
        }
    }
}
InputCmdBarKeyRight() {
    Gui, InputCmdBar:Default
    GuiControlGet, focusedControl, FocusV
    if (focusedControl == "InputCmdLV") {
        rowNum := LV_GetNext(0, "Focused")
        if (!rowNum)
            return
        LV_Modify(rowNum, "-Focus -Select")
        LV_GetText(cmd, rowNum, 1)
        GuiControl,, InputCmdEdit, %cmd%
        GuiControl, Focus, InputCmdEdit
        Send, {End}
    }
}
InputCmdBarKeyTab() {
    Gui, InputCmdBar:Default
    GuiControlGet, focusedControl, FocusV
    if (focusedControl == "InputCmdEdit") {
        if (LV_GetCount()) {
            LV_GetText(cmd, 1, 1)
            GuiControl,, InputCmdEdit, %cmd%
            Send, {End}
        }
    }
}


InputCmdExec(inputCmd) {
    WinGet, inputCmdCurWinId, ID, A
    inputCmd := RegExReplace(Trim(inputCmd), "\s+", " ")      ;去除首位空格, 将字符串内多个连续空格替换为单个空格
    inputCmdArray := StrSplit(inputCmd, A_Space)
    inputCmdArrayLen := inputCmdArray.Length()
    if (inputCmdArrayLen == 1) {
        ExecNativeCmd(inputCmd)
        return
    } else if (inputCmdArrayLen >= 2) {
        inputCmdKey := inputCmdArray[1]
        inputCmdValue := inputCmdArray[2]
        if (inputCmdArrayLen >= 3) {
            posTemp := InStr(inputCmd, A_Space, true, 1, 2)
            inputCmdValueExtra := SubStr(inputCmd, posTemp+1)
        }
    }
    if (!inputCmdKey)
        return
    if (inputCmdKey == "-") {
        ExecBuildInCmd(inputCmdKey, inputCmdValue, inputCmdValueExtra)
        return
    }
    
    topPid := ICBTopPNamePidMap[inputCmdKey]
    if (!topPid) {
        ExecNativeCmd(inputCmdKey, inputCmdValue, inputCmdValueExtra)
        return
    }
    topChildCmds := ICBTopPidChildCmdMap[topPid]
    if (!topChildCmds) {
        ExecNativeCmd(inputCmdKey, inputCmdValue, inputCmdValueExtra)
        return
    }
    
    cmdId := topChildCmds[inputCmdValue]
    if (!cmdId) {
        TryExecMatchedCmdWhenMissing("未找到匹配的命令!")
        return
    }
    cmdObj := ICBIdCmdObjMap[cmdId]
    if (!cmdObj)
        return
    cmd := cmdObj.cmd
    if (!cmd)
        return
    exec := cmdObj.exec
    if (!exec)
        return
    execLangFlag := InStr(exec, "execLang=", true)      ;检查当前的脚本语言类型 bat\ahk
    execWinMode := "normal"
    if (execLangFlag) {
        RegExMatch(exec, "U)execLang=.*\s", execLang)
        execLang := RegExReplace(StrReplace(execLang, "execLang="), "\s?")
        execLangPath := ConfigExecLangPathBase "\" inputCmdKey "_" cmd "." execLang
        FileDelete, %execLangPath%
        FileEncoding
        FileAppend, %exec%, %execLangPath%
        if (InStr(exec, "execWinMode=", true)) {          ;检查当前的脚本运行窗口模式 max\min\normal\hide, 默认值为normal
            RegExMatch(exec, "U)execWinMode=.*\s", execWinMode)
            execWinMode := RegExReplace(StrReplace(execWinMode, "execWinMode="), "\s?")
        } else {
            execWinMode := "hide"
        }
    }
    
    if (inputCmdKey == "g") {
        if (execLangFlag) {
            if (inputCmdValueExtra)
                run, %execLangPath% %inputCmdValueExtra%, , %execWinMode%
            else
                run, %execLangPath%, ,  %execWinMode%
        } else {
            run, %exec%, ,  %execWinMode%
        }
    } else if (inputCmdKey == "get") {
        needBackKeyCount := StrLen(inputCmd) + 2    ;``符号也需要计算在退格值内，自加2
        WinGet, inputCmdCurWinId2, ID, A            ;窗口发生变化时，在新窗口中不处理退格
        isWinChanged := (inputCmdCurWinId == inputCmdCurWinId2 ? false : true)
        
        ;常量替换
        if (InStr(exec, "$cuteWord$", true)) {
            cuteWord := GetCuteWord()
            exec := StrReplace(exec, "$cuteWord$", cuteWord)
        }

        if (execLangFlag) {
            RunWait, %execLangPath% %inputCmdValueExtra%, , %execWinMode%
            if (InputCmdMode == "hotkey") {
                if (isWinChanged)
                    SendInput, ^v
                else
                    SendInput, {backspace %needBackKeyCount%}^v
            }
        } else {
            Clipboard := exec
            if (InputCmdMode == "hotkey") {
                if (isWinChanged)
                    SendInput, ^v
                else
                    SendInput, {backspace %needBackKeyCount%}^v
            }
        }
        InputCmdMode :=

    } else if (inputCmdKey == "do") {
        if (execLangFlag) {
            run, %execLangPath% %inputCmdValueExtra%, , %execWinMode%
        } else {
            run, %exec%, , %execWinMode%
        }
        
    } else if (inputCmdKey == "q") {
        if (execLangFlag) {
            run, %execLangPath% %inputCmdValueExtra%, , %execWinMode%
        } else {
            exec := "tencent://message/?uin=" exec
            run, %exec%, , %execWinMode%
        }
    }
    
    
    newHistoryCmdObj := Object()
    newHistoryCmdObj.name := cmdObj.name
    newHistoryCmdObj.cmd := inputCmd
    ICBHistoryCmds.InsertAt(1, newHistoryCmdObj)
    DBHistoryCmdNew(newHistoryCmdObj)
    
    ICBCmdHitCount += 1
    DBCmdIncreaseHit(cmdId)
    if (ICBCmdHitCount >= ICBCmdHitThreshold)
        PrepareICBData()
}

;执行系统级支持的命令  eg: notepad、calc...
;注意
;  执行[rgbcolor]成功
;  执行[rgbcolor -m random]失败
;  执行[rgbcolor.bat -m random]成功
;因此，在执行失败时尝试增加.bat后缀
ExecNativeCmd(inputCmdKey, inputCmdValue:="", inputCmdValueExtra:="") {
    if (!inputCmdKey)
        return
    inputCmd := inputCmdKey
    if (StrLen(inputCmdValue))      ;注意: 此处必须通过StrLen来判断参数是否存在, 因此存在如下情况：[param=0   if(param)为false]
        inputCmd .= " " inputCmdValue
    if (StrLen(inputCmdValueExtra))
        inputCmd .= " " inputCmdValueExtra
    run, %inputCmd%,, UseErrorLevel
    if (ErrorLevel == "ERROR") {
        inputCmd := inputCmdKey ".bat " inputCmdValue " " inputCmdValueExtra
        run, %inputCmd%,, UseErrorLevel
        if (ErrorLevel == "ERROR") {
            TryExecMatchedCmdWhenMissing("找不到指定的命令!")
            return
        }
    }
    
    newHistoryCmdObj := Object()
    newHistoryCmdObj.cmd := inputCmd
    systemCmdObj := ICBSystemCmdMap[inputCmdKey]
    if (systemCmdObj) {
        newHistoryCmdObj.name := systemCmdObj.desc
        ICBSystemCmdHitCount += 1
        DBSystemCmdIncreaseHit(systemCmdObj.id)
        if (ICBSystemCmdHitCount >= ICBSystemCmdHitThreshold)
            PrepareSystemCmdData()
    }
    ICBHistoryCmds.InsertAt(1, newHistoryCmdObj)
    DBHistoryCmdNew(newHistoryCmdObj)
}



ExecBuildInCmd(inputCmdKey, inputCmdValue, inputCmdValueExtra:="") {
    if (inputCmdValue == "theme") {
        if (!inputCmdValueExtra)
            return
        if (inputCmdValueExtra == "random" || inputCmdValueExtra == "auto" || inputCmdValueExtra == "blur" || inputCmdValueExtra == "custom") {
            Config.themeType := inputCmdValueExtra
        }
    } else if (inputCmdValue == "tree") {
        GuiTV()
    } else if (inputCmdValue == "history") {
        return
    } else if (inputCmdValue == "reload") {
        MenuTrayReload()
    } else if (inputCmdValue == "quit") {
        gosub, GuiInputCmdBar
    } else if (inputCmdValue == "exit") {
        MenuTrayExit()
    } else {
        TryExecMatchedCmdWhenMissing("未找到匹配的内建命令!")
    }
}



;当找不到命令时, 尝试从InputCmdLV加载第一个命令, 仍然失败则提示用户
TryExecMatchedCmdWhenMissing(msg) {
    if (LV_GetCount()) {
        LV_GetText(inputCmd, 1, 1)
        LV_Delete()        ;删除InputCmdLV中全部行, 防止递归调用
        InputCmdLastValue := inputCmd
        InputCmdExec(inputCmd)
        InputCmdBarExist := false
        Config.InputCmdLastValue := inputCmd
    } else {
        Tip(msg)
    }
}
;========================= 输入Bar =========================












;========================= 命令树->总界面 =========================
global JsonTreeView :=
GuiTV(ItemName:="", ItemPos:="", MenuName:="") {
    PrepareTVData()
    imageList := IL_Create(5)
    IL_Add(imageList, "shell32.dll", 74)
    IL_Add(imageList, "shell32.dll", 4)
    IL_Add(imageList, "shell32.dll", 135)
    Gui, GuiTV:New
    Gui, GuiTV:Font,, Microsoft YaHei
    Gui, GuiTV:Add, TreeView, vJsonTreeView w450 r30 Readonly AltSubmit Checked HScroll hwndHTV gTVHandler ImageList%imageList%
    GuiControl, GuiTV:-Redraw, JsonTreeView
    TVParse(0, 0)
    GuiControl, GuiTV:+Redraw, JsonTreeView
    Gui, GuiTV:Add, StatusBar
    
    Menu, GuiTVMenu, Add, 添加, TVAdd
    Menu, GuiTVMenu, Icon, 添加, SHELL32.dll, 1
    Menu, GuiTVMenu, Add, 刷新, TVRefresh 
    Menu, GuiTVMenu, Icon, 刷新, SHELL32.dll, 239
    Menu, GuiTVMenu, Add, 编辑, TVEdit
    Menu, GuiTVMenu, Icon, 编辑, SHELL32.dll, 134
    Menu, GuiTVMenu, Add, 删除, TVDelete
    Menu, GuiTVMenu, Icon, 删除, SHELL32.dll, 132
    Menu, GuiTVMenu, Add, 上移, TVUp
    Menu, GuiTVMenu, Icon, 上移, SHELL32.dll, 247
    Menu, GuiTVMenu, Add, 下移, TVDown
    Menu, GuiTVMenu, Icon, 下移, SHELL32.dll, 248
    Menu, GuiTVMenu, Add, 搜索, TVSearch
    Menu, GuiTVMenu, Icon, 搜索, SHELL32.dll, 56
    
    Gui, Menu, GuiTVMenu
    Gui, GuiTV:Show, , 命令树管理
    SB_SetText("总计" TVCmdCount "条命令")
}

TVHandler(CtrlHwnd, GuiEvent, EventInfo) {
	if (A_GuiEvent == "K") {
		if (A_EventInfo = 46)
			TVDelete()
	} else if (A_GuiEvent == "DoubleClick") {
        TVEdit()
	} else if (A_GuiControl = "JsonTreeView") {
        TV_Modify(A_EventInfo, "Select Vis")
	}
}
;========================= 命令树->总界面 =========================
;========================= 命令树->添加 =========================
global TVAddBranchNameEdit :=
global TVAddBranchCmdEdit :=
global TVAddBranchExecEdit :=
global TVAddCmdObj :=
TVAdd(ItemName, ItemPos, MenuName) {
    Gui, GuiTV:Default
	branchId := TV_GetSelection()
    if (branchId) {
        cmdId := TVBranchIdIdMap[branchId]
        TVAddCmdObj := TVIdCmdObjMap[cmdId]
        if (TVAddCmdObj.cmd) {
            ;选择叶子命令
            parentBranchId := TV_GetParent(branchId)
            parentCmdId := TVBranchIdIdMap[parentBranchId]
            parentBranchName := TVIdCmdObjMap[parentCmdId].name
        } else {
            ;选择树枝命令
            parentBranchName := TVAddCmdObj.name
        }
    } else {
        ;未选择
        TVAddCmdObj :=
        parentBranchName := "root"
    }
    Gui, GuiTVAdd:New
	Gui, GuiTVAdd:Margin, 20, 20
	Gui, GuiTVAdd:Font,, Microsoft YaHei
	Gui, GuiTVAdd:Add, GroupBox, xm y+10 w500 h210
    Gui, GuiTVAdd:Add, Text, xm+10 y+15 y35 w60, 父级：
	Gui, GuiTVAdd:Add, Text, x+5 yp-3 w400, %parentBranchName%
	Gui, GuiTVAdd:Add, Text, xm+10 y+15 w60, 名称：
	Gui, GuiTVAdd:Add, Edit, x+5 yp-3 w400 vTVAddBranchNameEdit,
	Gui, GuiTVAdd:Add, Text, xm+10 y+15 w60, 命令：
	Gui, GuiTVAdd:Add, Edit, x+5 yp-3 w400 vTVAddBranchCmdEdit,
  	Gui, GuiTVAdd:Add, Text, xm+10 y+15 w60, 执行：
	Gui, GuiTVAdd:Add, Edit, x+5 yp-3 w400 r10 vTVAddBranchExecEdit,
	Gui, GuiTVAdd:Add, Button, Default xm+180 y+15 w50 gTVAddSaveHandler, 确定
	Gui, GuiTVAdd:Add, Button, x+20 w50 gTVAddCancelHandler, 取消
	Gui, GuiTVAdd:Show, ,添加命令
}

TVAddSaveHandler(CtrlHwnd, GuiEvent, EventInfo) {
    Gui, GuiTVAdd:Default
    Gui, GuiTVAdd:Submit, NoHide
    if (!TVAddBranchNameEdit) {
        MsgBox, 必须填写[名称]
        return
    }
    if (InStr(TVAddBranchNameEdit, " ", true)) {
        MsgBox, [名称]中不能包含空格
        return
    }
    
    if (TVAddCmdObj) {
        topPid := TVAddCmdObj.topPid
        if (topPid == 0) {
            ;当topPid值为0说明TVAddCmdObj目前是顶级节点(g get...)
            topPid := TVAddCmdObj.id
        }
        ;命令重复性检查
        if (TVAddBranchCmdEdit) {
            topParentCmdObj := TVIdCmdObjMap[topPid]
            if (DBCmdTopPidCount(topPid, TVAddBranchCmdEdit)) {
                MsgBox, % "[" topParentCmdObj.name "]顶级分类下已有命令[" TVAddBranchCmdEdit "]，不能添加"
                return
            }
        }
        if (TVAddCmdObj.cmd) {
            ;选择叶子命令
            pid := TVAddCmdObj.pid
            DBCmdIncreaseTreeSort(pid, TVAddCmdObj.treeSort)
            treeSort := TVAddCmdObj.treeSort + 1
        } else {
            ;选择树枝命令
            pid := TVAddCmdObj.id
            treeSort := DBCmdNextTreeSort(TVAddCmdObj.id)
        }
    } else {
        pid := 0
        topPid := 0
        ;顶级命令名称重复性检查
        if (DBCmdTopCmdCount(TVAddBranchNameEdit)) {
            MsgBox, % "已存在名称为[" TVAddBranchNameEdit "]的顶级命令，不能添加"
            return
        }
        treeSort := DBCmdTopCmdCount() + 1
    }
    
    newCmdObj := Object()
    newCmdObj.name := TVAddBranchNameEdit
    newCmdObj.cmd := TVAddBranchCmdEdit
    newCmdObj.exec := TVAddBranchExecEdit
    newCmdObj.pid := pid
    newCmdObj.topPid := topPid
    newCmdObj.hit := 0
    newCmdObj.treeSort := treeSort
    DBCmdNew(newCmdObj)
    Gui, GuiTVAdd:Destroy
    TVRefresh()
    if (pid)
        TV_Modify(TVIdBranchIdMap[pid], "Select Vis Expand")
}
TVAddCancelHandler(CtrlHwnd, GuiEvent, EventInfo) {
    Gui, GuiTVAdd:Destroy
    Gui, GuiTV:Default
}
;========================= 命令树->添加 =========================
;========================= 命令树->编辑 =========================
global TVEditBranchNameEdit :=
global TVEditBranchCmdEdit :=
global TVEditBranchExecEdit :=
global TVEditBranchId :=
TVEdit(ItemName:="", ItemPos:="", MenuName:="") {
	TVEditBranchId := TV_GetSelection()
    if (!TVEditBranchId)
        return
    
    cmdId := TVBranchIdIdMap[TVEditBranchId]
    cmdObj := TVIdCmdObjMap[cmdId]
    branchName := cmdObj.name
    branchExec := cmdObj.exec
    branchCmd := cmdObj.cmd
    Gui, GuiTVEdit:New
	Gui, GuiTVEdit:Margin, 20, 20
	Gui, GuiTVEdit:Font,, Microsoft YaHei
	Gui, GuiTVEdit:Add, GroupBox, xm y+10 w500 h210
	Gui, GuiTVEdit:Add, Text, xm+10 y+30 y35 w60, 名称：
	Gui, GuiTVEdit:Add, Edit, x+5 yp-3 w400 vTVEditBranchNameEdit, %branchName%
	Gui, GuiTVEdit:Add, Text, xm+10 y+15 w60, 命令：
	Gui, GuiTVEdit:Add, Edit, x+5 yp-3 w400 vTVEditBranchCmdEdit, %branchCmd%
  	Gui, GuiTVEdit:Add, Text, xm+10 y+15 w60, 执行：
	Gui, GuiTVEdit:Add, Edit, x+5 yp-3 w400 r10 vTVEditBranchExecEdit, %branchExec%
	Gui, GuiTVEdit:Add, Button, Default xm+180 y+15 w50 gTVEditSaveHandler, 确定
	Gui, GuiTVEdit:Add, Button, x+20 w50 gTVEditCancelHandler,取消
	Gui, GuiTVEdit:Show, ,编辑命令 - %branchName%
}
TVEditSaveHandler(CtrlHwnd, GuiEvent, EventInfo) {
    Gui, GuiTVEdit:Default
    Gui, GuiTVEdit:Submit, NoHide
    if (!TVEditBranchNameEdit) {
        MsgBox, 必须填写[名称]
        return
    }
    
    cmdId := TVBranchIdIdMap[TVEditBranchId]
    cmdObj := TVIdCmdObjMap[cmdId]
    cmdObj.name := TVEditBranchNameEdit
    cmdObj.exec := TVEditBranchExecEdit
    cmdObj.cmd := TVEditBranchCmdEdit
    if (!DBCmdUpdate(cmdObj)) {
        MsgBox, 修改失败！
        return
    }
    Gui, GuiTVEdit:Destroy
    Gui, GuiTV:Default
    if (cmdObj.cmd)
        TV_Modify(TVEditBranchId, "-Bold Icon1", cmdObj.name " - " cmdObj.cmd)
    else
        TV_Modify(TVEditBranchId, "Bold Icon2", cmdObj.name)
}
TVEditCancelHandler(CtrlHwnd, GuiEvent, EventInfo) {
    Gui, GuiTVEdit:Destroy
    Gui, GuiTV:Default
}
;========================= 命令树->编辑 =========================
;========================= 命令树->删除 =========================
TVDelete(ItemName:="", ItemPos:="", MenuName:="") {
    Gui, GuiTV:Default
	deleteTipStr := ""
    deleteCmdIds := []
	deleteBranchId = 0
    deleteCmdObjPid :=
	Loop
	{
		deleteBranchId := TV_GetNext(deleteBranchId, "Checked")
		if (!deleteBranchId)
			break
        
        cmdId := TVBranchIdIdMap[deleteBranchId]
        cmdObj := TVIdCmdObjMap[cmdId]
        if (DBCmdPidCount(cmdId)) {
            MsgBox, % "要删除[ " cmdObj.name " ]节点, 请先删除其下所有子节点"
            return
        }
        if (!deleteCmdObjPid)
            deleteCmdObjPid := cmdObj.pid
        deleteCmdIds.Push(cmdId)
		deleteTipStr .= "  " cmdObj.name "`n"
	}
    if (!deleteCmdIds.Length()) {
        MsgBox, 请勾选要删除的项目
        return
    }
    
	MsgBox, 1, 删除, 是否要删除勾选项以及其下所有子项?`n`n%deleteTipStr%
	IfMsgBox OK
	{
        DBCodeDel(deleteCmdIds)
        TVRefresh()
        TV_Modify(TVIdBranchIdMap[deleteCmdObjPid], "Select Vis Expand")
	}
}
;========================= 命令树->删除 =========================
;========================= 命令树->上移 =========================
TVUp(ItemName, ItemPos, MenuName) {
    Gui, GuiTV:Default
	branchId := TV_GetSelection()
    if (!branchId)
        return
    prevBranchId := TV_GetPrev(branchId)
    if (!prevBranchId)
        return
    cmdId := TVBranchIdIdMap[branchId]
    cmdObj := TVIdCmdObjMap[cmdId]
    prevCmdId := TVBranchIdIdMap[prevBranchId]
    prevCmdObj := TVIdCmdObjMap[prevCmdId]
    
    DBCmdUpdate({"id": cmdId, "treeSort": prevCmdObj.treeSort})
    DBCmdUpdate({"id": prevCmdId, "treeSort": cmdObj.treeSort})
    TVRefresh()
    TV_Modify(TVIdBranchIdMap[cmdObj.pid], "Select Vis Expand")
}
;========================= 命令树->上移 =========================
;========================= 命令树->下移 =========================
TVDown(ItemName, ItemPos, MenuName) {
    Gui, GuiTV:Default
	branchId := TV_GetSelection()
    if (!branchId)
        return
    nextBranchId := TV_GetNext(branchId)
    if (!nextBranchId)
        return
    cmdId := TVBranchIdIdMap[branchId]
    cmdObj := TVIdCmdObjMap[cmdId]
    nextCmdId := TVBranchIdIdMap[nextBranchId]
    nextCmdObj := TVIdCmdObjMap[nextCmdId]
  
    DBCmdUpdate({"id": cmdId, "treeSort": nextCmdObj.treeSort})
    DBCmdUpdate({"id": nextCmdId, "treeSort": cmdObj.treeSort})
    TVRefresh()
    TV_Modify(TVIdBranchIdMap[cmdObj.pid], "Select Vis Expand")
}
;========================= 命令树->下移 =========================
;========================= 命令树->搜索 =========================
global TVSearchEdit :=
global TVSearchLV :=
TVSearch(ItemName, ItemPos, MenuName) {
    Gui, GuiTVSearch:New
	Gui, GuiTVSearch:Margin, 20, 20
	Gui, GuiTVSearch:Font,, Microsoft YaHei
    Gui, GuiTVSearch:Add, Edit, w570 vTVSearchEdit gTVSearchEditHandler
    Gui, GuiTVSearch:Add, ListView, AltSubmit -Multi ReadOnly w570 r12 vTVSearchLV gTVSearchLVHandler, id|命令|名称|父级名称|顶级名称
    LV_ModifyCol(1, 0)
    LV_ModifyCol(2, 150)
    LV_ModifyCol(3, 150)
    LV_ModifyCol(4, 150)
    LV_ModifyCol(5, 100)
	Gui, GuiTVSearch:Show, ,搜索命令
}
TVSearchEditHandler(CtrlHwnd, GuiEvent, EventInfo) {
    Gui, GuiTVSearch:Default
    Gui, GuiTVSearch:Submit, NoHide
    if (!TVSearchEdit)
        return
    LV_Delete()
    searchStr := Trim(TVSearchEdit)
    for cmdId, cmdObj in TVIdCmdObjMap {
        if (InStr(cmdObj.cmd, searchStr)) {
            parentCmdObj := TVIdCmdObjMap[cmdObj.pid]
            topParentCmdObj := TVIdCmdObjMap[cmdObj.topPid]
            LV_Add(, cmdId, cmdObj.cmd, cmdObj.name, parentCmdObj.name, topParentCmdObj.name)
        }
    }
}
TVSearchLVHandler(CtrlHwnd, GuiEvent, EventInfo) {
	if (GuiEvent == "DoubleClick") {
        Gui, GuiTVSearch:Default
        LV_GetText(cmdId, A_EventInfo, 1)
        branchId := TVIdBranchIdMap[cmdId]
        if (!branchId)
            return
        Gui, GuiTV:Default
        TV_Modify(branchId, "Select Vis")
	}
}
;========================= 命令树->搜索 =========================


;========================= 公共函数 =========================
MenuTray() {
	Menu, Tray, NoStandard
    Menu, Tray, add, 修改命令, GuiTV
	Menu, Tray, add, 命令输入, GuiInputCmdBar
	Menu, Tray, add, 定位文件, MenuTrayLocation
	Menu, Tray, add
	Menu, Tray, add, 重启, MenuTrayReload
	Menu, Tray, add, 退出, MenuTrayExit
    Menu, Tray, Default, 修改命令
}

MenuTrayReload(ItemName:="", ItemPos:="", MenuName:="") {
    Config.delete("theme")
    DBConfigUpdate(Config)
    CurrentDB.Close()
    Reload
}
MenuTrayExit(ItemName:="", ItemPos:="", MenuName:="") {
    Config.delete("theme")
    DBConfigUpdate(Config)
    CurrentDB.Close()
    Gui, GuiTV:Destroy
    Gui, InputCmdBar:Destroy
    ExitApp
}
MenuTrayLocation(ItemName, ItemPos, MenuName) {
    Run, % "explorer /select," A_ScriptFullPath
}
GuiTVGuiClose(GuiHwnd) {
    Gui, GuiTV:Destroy
}

PrepareConfigData() {
    print("PrepareConfigData start...")
    Config := Object()
    Config := DBConfigFind()
    Config.theme := JSON.Load(Config.theme)
    if (!Config.themeType)
        Config.themeType := "random"
    
    IfNotExist, %ConfigExecLangPathBase%
        FileCreateDir, %ConfigExecLangPathBase%
    print("PrepareConfigData finish...")
}
PrepareICBData() {
    print("PrepareICBData start...")
    ICBIdCmdObjMap := Object()
    ICBTopPNamePidMap := Object()
    ICBTopPidChildCmdMap := Object()
    ICBCmdHitCount := 0
    
    cmdObjs := DBCmdFind2()
    for index, cmdObj in cmdObjs {
        id := cmdObj.id
        cmd := cmdObj.cmd
        topPid := cmdObj.topPid
        ICBIdCmdObjMap[id] := cmdObj
        if (cmdObj.topPid == 0) {
            ICBTopPNamePidMap[cmdObj.name] := id
        } else {
            if (!cmd)
                continue
            childCmds := ICBTopPidChildCmdMap[topPid]
            if (childCmds) {
                childCmds[cmd] := id
            } else {
                childCmds := new OrderedArray()    
                childCmds[cmd] := id
                ICBTopPidChildCmdMap[topPid] := childCmds
            }
        }
    }
    
    ICBHistoryCmds := DBHistoryCmdFind()
    ICBBuildInCmdMap := new OrderedArray()
    ICBBuildInCmdMap["theme"] := "切换主题[random\auto\blur\custom]"
    ICBBuildInCmdMap["tree"] := "编辑命令树"
    ICBBuildInCmdMap["history"] := "历史命令"
    ICBBuildInCmdMap["reload"] := "重启脚本"
    ICBBuildInCmdMap["quit"] := "关闭界面"
    ICBBuildInCmdMap["exit"] := "退出脚本"
    print("PrepareICBData finish...")
}

PrepareTVData() {
    print("PrepareTVData start...")
    TVIdCmdObjMap := Object()
    TVPidChildIdsMap := Object()
    TVBranchIdIdMap := Object()
    TVIdBranchIdMap := Object()
    TVCmdCount := 0
    
    cmdObjs := DBCmdFind()
    for index, cmdObj in cmdObjs {
        id := cmdObj.id
        pid := cmdObj.pid
        TVIdCmdObjMap[id] := cmdObj

        childIds := TVPidChildIdsMap[pid]
        if (childIds) {
            childIds.push(id)
        } else {
            TVPidChildIdsMap[pid] := [id]
        }
    }
    print("PrepareTVData finish...")
}


TVParse(pBranchId, id) {
    cmdObj := TVIdCmdObjMap[id]
    if (cmdObj) {
        if (cmdObj.cmd) {
            branchId := TV_Add(cmdObj.name  " - " cmdObj.cmd, pBranchId, "Icon1")
            TVCmdCount += 1
        } else {
            branchId := TV_Add(cmdObj.name, pBranchId, "Bold Icon2")
        }
        TVBranchIdIdMap[branchId] := id
        TVIdBranchIdMap[id] := branchId
    } else {
        branchId := 0
    }
    
    childIds := TVPidChildIdsMap[id]
    if (childIds) {
        for index, childId in childIds {
            TVParse(branchId, childId)
        }
    }
}


TVRefresh(ItemName:="", ItemPos:="", MenuName:="") {
    Gui, GuiTV:Default
    TV_Delete()
    PrepareTVData()
    TVParse(0, 0)
}


Array2Str(array) {
    if (!array || !array.Length())
        return
    str := ""
    for index, element in array {
        if (index == array.Length())
          str .= element
        else
          str .= element ","
    }
    return str
}

InputCmdBarThemeConf(ByRef themeType, ByRef themeBgColor, ByRef themeFontColor, ByRef themeX, ByRef themeY) {
    if (Config.themeType == "random") {
        themeTypes := ["auto", "blur", "custom"]
        Random, themeTypesIndex, themeTypes.MinIndex(), themeTypes.MaxIndex()
        themeType := themeTypes[themeTypesIndex]
    } else {
        themeType := Config.themeType
    }
    themeConf := Config["theme"][themeType]
    if (themeType == "auto") {
        RegRead, wallpaperPath, HKEY_CURRENT_USER\Control Panel\Desktop, WallPaper
        FileGetTime, wallpaperTimeStamp, %wallpaperPath%, M
        if (wallpaperPath != Config.LastWallpaperPath || wallpaperTimeStamp != Config.LastWallpaperTimeStamp) {
            wallpaperHex := ImgGetDominantColor(wallpaperPath)
            Config.LastWallpaperPath := wallpaperPath
            Config.LastWallpaperTimeStamp := wallpaperTimeStamp
            Config.LastWallpaperColor := wallpaperHex
            themeBgColor := wallpaperHex
        } else {
            themeBgColor := Config.LastWallpaperColor
        }
        themeFontColor := themeConf.fontColor
        themeX := themeY :=
    } else if (themeType == "blur") {
        themeBgColor := themeConf.bgColor
        themeFontColor := themeConf.fontColor
        themeX := themeConf.x
        themeY := themeConf.y
    } else if (themeType == "custom") {
        Random, themeConfCustomIndex, themeConf.MinIndex(), themeConf.MaxIndex()
        themeConfCustom := themeConf[themeConfCustomIndex]
        themeBgColor := themeConfCustom.bgColor
        themeFontColor := themeConfCustom.fontColor
        themeX := themeY :=
    }
}


;读取DB 构建对象<path, Obj>
;读取文件列表构建对象<>, 判断是否存在DB对象中,------否： desc是否变更--update\continue
;是 --- insert数据库
;====================
;遍历DB对象，查看是否不再文件对象中 ----- 是则删除该命令记录
PrepareSystemCmdData() {
    print("PrepareSystemCmdData start...")
    systemCmdFileMap := Object()
    systemCmdDBMap := Object()
    
    ;从文件构建systemCmdFileMap对象
    FileEncoding
    for index, systemPath in ICBSystemPaths {
        fileDescPrefix := (systemPath.type == "system" ? "*" : " ")
        Loop, Files, % systemPath.path, F
        {
            filePath := fileName := fileExt := fileDesc := fileContent := ""
            SplitPath, A_LoopFileFullPath,,, fileExt, fileName
            if (!A_LoopFileExt)     ;文件夹\无扩展名文件
                continue
            if (A_LoopFileExt == "lnk") {
                FileGetShortcut, %A_LoopFileFullPath%, filePath,,,fileDesc
                if (!filePath || !FileExist(filePath)) {    ;有些快捷方式是网络路径\不存在源文件(run.lnk) -> 不做处理
                    if (!fileDesc)
                        fileDesc := fileName
                    systemCmdFileMap[fileName] := fileDescPrefix fileDesc
                    continue
                }
            } else {
                filePath := A_LoopFileFullPath
                fileExt := A_LoopFileExt
            }
            
            if (!fileDesc) {
                SplitPath, filePath,,, fileExt
                if (fileExt == "exe") {
                    if (!fileDesc)
                        fileDesc := FileGetDesc(filePath)
                } else if (fileExt == "bat") {
                    FileRead, fileContent, %filePath%
                    RegExMatch(fileContent, "U)title\s.*\s", fileDesc)
                    fileDesc := StrReplace(StrReplace(StrReplace(fileDesc, "title "), "&"), "`r")
                } else if (fileExt == "vbs" || fileExt == "swf" || fileExt == "ahk") {
                    fileDesc := fileName
                } else {
                    continue
                }
            }
            systemCmdFileMap[fileName] := fileDescPrefix fileDesc
        }
    }
    ;从DB构建systemCmdDBMap对象
    systemCmds := DBSystemCmdFind()
    for index, systemCmdObj in systemCmds {
        systemCmdDBMap[systemCmdObj.name] := systemCmdObj
    }
    ;以ICBSystemCmdFileMap为基准, 不存在ICBSystemCmdDBMap中则添加记录
    for fileName, fileDesc in systemCmdFileMap {
        dbSystemCmdObj := systemCmdDBMap[fileName]
        if (!dbSystemCmdObj) {
            newSystemCmdObj := Object()
            newSystemCmdObj.name := fileName
            newSystemCmdObj.desc := fileDesc
            newSystemCmdObj.hit := 0
            DBSystemCmdNew(newSystemCmdObj)
            continue
        }
        if (dbSystemCmdObj.desc != fileDesc) {
            newSystemCmdObj := Object()
            newSystemCmdObj.desc := fileDesc
            DBSystemCmdUpdate(newSystemCmdObj)
            continue
        }
    }
    ;以systemCmdDBMap为基准, 不存在systemCmdFileMap中则添加记录
    systemCmdDelIds := Object()
    for dbFileName, dbSystemCmdObj in systemCmdDBMap {
        fileDesc := systemCmdFileMap[dbFileName]
        if (!fileDesc)
            systemCmdDelIds.push(dbSystemCmdObj.id)
    }
    DBSystemCmdDel(systemCmdDelIds)
    ;重新读取DB构建数据
    ICBSystemCmdMap := new OrderedArray()
    systemCmds := DBSystemCmdFind2()
    for index, systemCmdObj in systemCmds {
        ICBSystemCmdMap[systemCmdObj.name] := systemCmdObj
    }
    print("PrepareSystemCmdData finish...")
}

WM_LBUTTONDOWN(wParam, lParam, msg, hWnd) {
    if (hWnd = %InputCmdBarHwnd%)
		DllCall("user32.dll\PostMessage", "Ptr", hWnd, "UInt", 0xA1, "Ptr", 2, "Ptr", 0)
}
EnableBlur(hWnd) {
    ; WindowCompositionAttribute
    WCA_ACCENT_POLICY := 19
 
    ; AccentState
    ACCENT_DISABLED := 0,
    ACCENT_ENABLE_GRADIENT := 1,
    ACCENT_ENABLE_TRANSPARENTGRADIENT := 2
    ACCENT_ENABLE_BLURBEHIND := 3
    ACCENT_INVALID_STATE := 4
 
    accentStructSize := VarSetCapacity(AccentPolicy, 4*14, 0)
    NumPut(ACCENT_ENABLE_BLURBEHIND, AccentPolicy, 0, "UInt")
 
    padding := A_PtrSize == 8 ? 4 : 0
    VarSetCapacity(WindowCompositionAttributeData, 4 + padding + A_PtrSize + 4 + padding)
    NumPut(WCA_ACCENT_POLICY, WindowCompositionAttributeData, 0, "UInt")
    NumPut(&AccentPolicy, WindowCompositionAttributeData, 4 + padding, "Ptr")
    NumPut(accentStructSize, WindowCompositionAttributeData, 4 + padding + A_PtrSize, "UInt")
    DllCall("SetWindowCompositionAttribute", "Ptr", %hWnd%, "Ptr", &WindowCompositionAttributeData)
}
FileGetDesc(lptstrFilename) {
	dwLen := DllCall("Version.dll\GetFileVersionInfoSize", "Str", lptstrFilename, "Ptr", 0)
	dwLen := VarSetCapacity( lpData, dwLen + A_PtrSize)
	DllCall("Version.dll\GetFileVersionInfo", "Str", lptstrFilename, "UInt", 0, "UInt", dwLen, "Ptr", &lpData) 
	DllCall("Version.dll\VerQueryValue", "Ptr", &lpData, "Str", "\VarFileInfo\Translation", "PtrP", lplpBuffer, "PtrP", puLen )
	sLangCP := Format("{:04X}{:04X}", NumGet(lplpBuffer+0, "UShort"), NumGet(lplpBuffer+2, "UShort"))
    DllCall("Version.dll\VerQueryValue", "Ptr", &lpData, "Str", "\StringFileInfo\" sLangCp "\FileDescription", "PtrP", lplpBuffer, "PtrP", puLen )
		? i := StrGet(lplpBuffer, puLen) : ""
	return i
}

ImgGetDominantColor(imgPath) {
    rgb := StdoutToVar_CreateProcess("C:\path\bat\batlearn\loadExes\imagemagick\imagemagick-convert.exe """ imgPath """ -scale 1x1 -format %[pixel:u] info:-")
    rgb := StrReplace(rgb, "srgb(")
    rgb := StrReplace(rgb, ")")
    rgbArray := StrSplit(rgb, ",")
    return Rgb2Hex(rgbArray)
}
Rgb2Hex(rgbArray) {
    return Format("{:X}", rgbArray[1]) Format("{:X}", rgbArray[2]) Format("{:X}", rgbArray[3])
}
StdoutToVar_CreateProcess(sCmd, sEncoding:="CP0", sDir:="", ByRef nExitCode:=0) {
    DllCall( "CreatePipe",           PtrP,hStdOutRd, PtrP,hStdOutWr, Ptr,0, UInt,0 )
    DllCall( "SetHandleInformation", Ptr,hStdOutWr, UInt,1, UInt,1                 )

            VarSetCapacity( pi, (A_PtrSize == 4) ? 16 : 24,  0 )
    siSz := VarSetCapacity( si, (A_PtrSize == 4) ? 68 : 104, 0 )
    NumPut( siSz,      si,  0,                          "UInt" )
    NumPut( 0x100,     si,  (A_PtrSize == 4) ? 44 : 60, "UInt" )
    NumPut( hStdOutWr, si,  (A_PtrSize == 4) ? 60 : 88, "Ptr"  )
    NumPut( hStdOutWr, si,  (A_PtrSize == 4) ? 64 : 96, "Ptr"  )

    If ( !DllCall( "CreateProcess", Ptr,0, Ptr,&sCmd, Ptr,0, Ptr,0, Int,True, UInt,0x08000000
                                  , Ptr,0, Ptr,sDir?&sDir:0, Ptr,&si, Ptr,&pi ) )
        Return ""
      , DllCall( "CloseHandle", Ptr,hStdOutWr )
      , DllCall( "CloseHandle", Ptr,hStdOutRd )

    DllCall( "CloseHandle", Ptr,hStdOutWr ) ; The write pipe must be closed before reading the stdout.
    While ( 1 )
    { ; Before reading, we check if the pipe has been written to, so we avoid freezings.
        If ( !DllCall( "PeekNamedPipe", Ptr,hStdOutRd, Ptr,0, UInt,0, Ptr,0, UIntP,nTot, Ptr,0 ) )
            Break
        If ( !nTot )
        { ; If the pipe buffer is empty, sleep and continue checking.
            Sleep, 100
            Continue
        } ; Pipe buffer is not empty, so we can read it.
        VarSetCapacity(sTemp, nTot+1)
        DllCall( "ReadFile", Ptr,hStdOutRd, Ptr,&sTemp, UInt,nTot, PtrP,nSize, Ptr,0 )
        sOutput .= StrGet(&sTemp, nSize, sEncoding)
    }
    
    ; * SKAN has managed the exit code through SetLastError.
    DllCall( "GetExitCodeProcess", Ptr,NumGet(pi,0), UIntP,nExitCode )
    DllCall( "CloseHandle",        Ptr,NumGet(pi,0)                  )
    DllCall( "CloseHandle",        Ptr,NumGet(pi,A_PtrSize)          )
    DllCall( "CloseHandle",        Ptr,hStdOutRd                     )
    Return sOutput
}

IsEnglishKeyboard() {
    keyboardName :=
    VarSetCapacity(keyboardName, 50)
    DllCall("GetKeyboardLayoutName", "Str", keyboardName)
    return (keyboardName == "00000409")
}
ActiveEnglishKeyboard() {
    DllCall("SendMessage", UInt, WinActive("A"), UInt, 80, UInt, 1, UInt, DllCall("LoadKeyboardLayout", Str, "00000409", UInt, 1))
}
ActiveEnglishKeyboard2() {
    Send, #{Space}
}
OpenRunDialog() {
    runPath:=A_AppData . "\Microsoft\Windows\Start Menu\Programs\System Tools\run.lnk"
    run, %runPath%
}
;========================= 公共函数 =========================


;========================= DB-DAO =========================
DBConfigFind() {
    return QueryOne("select * from config")
}
DBConfigUpdate(configObj) {
    flag := CurrentDB.Update(configObj, "config")
    return flag
}
DBCmdFind() {
    return Query("select id, name, cmd, exec, treeSort, hit, pid, topPid from cmd order by pid, treeSort")
}
DBCmdFind2() {
    return Query("select id, name, cmd, exec, treeSort, hit, pid, topPid from cmd order by topPid ASC, hit DESC")
}
DBCmdTopCmdCount(name:="") {
    sql := "select count(id) as count from cmd"
    if (name)
        sql := sql " where name = '" name "'"
    resultSet := QueryOne(sql)
    return resultSet["count"]
}
DBCmdTopPidCount(topPid, cmd) {
    resultSet := QueryOne("select count(id) as count from cmd where topPid = " topPid " AND cmd='" cmd "'")
    return resultSet["count"]
}
DBCmdPidCount(pid) {
    resultSet := QueryOne("select count(id) as count from cmd where pid = " pid)
    return resultSet["count"]
}
DBCmdNew(cmdObj) {
    resultSet := QueryOne("select ifnull(max(id) + 1, 1) as cmdId from cmd")
    cmdId := resultSet["cmdId"]
    cmdObj.id := cmdId
    FormatTime, datetime, , yyyy-MM-dd HH:mm:ss
    cmdObj.datetime := datetime
    CurrentDB.Insert(cmdObj, "cmd")
    return cmdId
}
DBCmdUpdate(cmdObj) {
    flag := CurrentDB.Update(cmdObj, "cmd")
    return flag
}
DBCmdNextTreeSort(pid) {
    resultSet := QueryOne("select ifnull(max(treeSort) + 1, 1) as treeSort from cmd where pid = " pid)
    return resultSet["treeSort"]
}
DBCmdIncreaseTreeSort(pid, treeSortStart) {
    affectedRows := CurrentDB.Query("update cmd set treeSort = treeSort + 1 where pid = " pid " AND treeSort > " treeSortStart)
}
DBCmdIncreaseHit(cmdId) {
    affectedRows := CurrentDB.Query("update cmd set hit = hit + 1 where id = " cmdId)
}
DBCodeDel(cmdIds) {
    cmdIdsStr := Array2Str(cmdIds)
    affectedRows := CurrentDB.Query("delete from cmd where id in (" cmdIdsStr ")")
}
DBSystemCmdFind() {
    return Query("select id, name, desc from systemCmd order by hit DESC")
}
DBSystemCmdFind2() {
    return Query("select id, name, desc from systemCmd where show = 1 order by hit DESC")
}
DBSystemCmdNew(systemCmdObj) {
    resultSet := QueryOne("select ifnull(max(id) + 1, 1) as systemCmdId from systemCmd")
    systemCmdId := resultSet["systemCmdId"]
    systemCmdObj.id := systemCmdId
    FormatTime, datetime, , yyyy-MM-dd HH:mm:ss
    systemCmdObj.datetime := datetime
    CurrentDB.Insert(systemCmdObj, "systemCmd")
    return systemCmdId
}
DBSystemCmdUpdate(systemCmdObj) {
    flag := CurrentDB.Update(systemCmdObj, "systemCmd")
    return flag
}
DBSystemCmdDel(systemCmdIds) {
    systemCmdIdsStr := Array2Str(systemCmdIds)
    affectedRows := CurrentDB.Query("delete from systemCmd where id in (" systemCmdIdsStr ")")
}
DBSystemCmdIncreaseHit(systemCmdId) {
    affectedRows := CurrentDB.Query("update systemCmd set hit = hit + 1 where id = " systemCmdId)
}

DBHistoryCmdFind() {
    return Query("select id, name, cmd from historyCmd order by id DESC limit 50")
}
DBHistoryCmdNew(historyCmdObj) {
    resultSet := QueryOne("select ifnull(max(id) + 1, 1) as historyCmdId from historyCmd")
    historyCmdId := resultSet["historyCmdId"]
    historyCmdObj.id := historyCmdId
    FormatTime, datetime, , yyyy-MM-dd HH:mm:ss
    historyCmdObj.datetime := datetime
    CurrentDB.Insert(historyCmdObj, "historyCmd")
    return historyCmdId
}
;========================= DB-DAO =========================


;========================= DB-Base =========================
DBConnect() {
	connectionString := A_ScriptDir "\contextCmd.db"
	try {
		CurrentDB := DBA.DataBaseFactory.OpenDataBase("SQLite", connectionString)
	} catch e
		MsgBox,16, Error, % "Failed to create connection. Check your Connection string and DB Settings!`n`n" ExceptionDetail(e)
}
QueryOne(SQL){
    objs := Query(SQL)
    if (objs.Length())
        return objs[1]
}
Query(SQL){
	if (!IsObject(CurrentDB)) {
        MsgBox, 16, Error, No Connection avaiable. Please connect to a db first!
        return
	}
    SQL := Trim(SQL)
    if (!SQL)
        return
    try {
        resultSet := CurrentDB.OpenRecordSet(SQL)
        if (!is(resultSet, DBA.RecordSet))
            throw Exception("RecordSet Object expected! resultSet was of type: " typeof(resultSet), -1)
        return DBResultSet2Obj(resultSet)
    } catch e {
        MsgBox,16, Error, % "OpenRecordSet Failed.`n`n" ExceptionDetail(e) ;state := "!# " e.What " " e.Message
    }
}

DBResultSet2Obj(resultSet) {
    colNames := resultSet.getColumnNames()
    if (!colNames.Length())
        return Object()
    objs := Object()
    while(!resultSet.EOF){
        obj := Object()
        for index, colName in colNames {
            val := resultSet[colName]
            if (val != DBA.DataBase.NULL)
                obj[colName] := val
        }
        objs.Push(obj)
        resultSet.MoveNext()
    }
    return objs
}
;========================= DB-Base =========================