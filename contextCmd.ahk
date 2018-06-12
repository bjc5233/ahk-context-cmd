;说明
;  效率工具，上下文环境命令助手
;    启用方式1： 监听``之间输入的命令 {在任何环境下都可以检测到【输入框\桌面】}
;    启用方式2： 双击Ctrl弹出输入框，输入命令
;  配置说明
;    图标右键->修改菜单-> 新增\编辑\删除\保存命令树
;    => g.bat 快捷跳转命令
;    => get.bat 快捷复制命令
;    => q.bat qq联系人跳转
;    => do.bat
;    => 其他系统级别的命令、快捷方式 【calc notepad...】
;  主题说明
;    1.auto模式(默认), 根据系统当前壁纸配置颜色, 窗口位置中间【需要第三方命令行工具imagemagick-convert.exe】
;    2.blur模式, AeroGlass风格, 由于在偏白色背景下无法看清文字, 因此位置放置在左下角
;    3.custom模式, 配置的固定几种颜色风格, 每次展示时随机颜色风格, 窗口位置中间
;备注
;  1. {vkC0}表示`
;  2. 配置命令的[执行]文本框中, 在第一行输入[目标语言注释符号 execLang= 目标语言]格式, 
;       ::execLang=bat
;     会将此文本框文本保存到bat文件, 并执行该bat
;TODO
;  1.添加命令时判断是否重复
;  2.增加菜单搜索命令
;  3.为命令添加权重，被使用次数越多的命令排的更加靠前
;  4.数据存储到sqlite
;========================= 环境配置 =========================
#Persistent
#NoEnv
#SingleInstance, Force
SetBatchLines, 10ms
#HotkeyInterval 1000
DetectHiddenWindows, On
SetTitleMatchMode, 2
SetKeyDelay, -1
StringCaseSense, off
CoordMode, Menu
#Include <JSON> 
#Include <PRINT>
#Include <TIP>
#Include <CuteWord>
global confs := Object()
global themeConfs := Object
global themeConfType := "auto"

global rootBranchId :=
global jsonTree := Object()
global jsonTreeKV := Object()
;global jsonTreeKV2 := Object()  ;<g, <cmd, branchId>>

global jsonCmdTree := Object()
global jsonCmdTreeKV := Object()
global jsonCmdPath := Object()
global execLangPathBase := A_ScriptDir "\cache"
IfNotExist, %execLangPathBase%
    FileCreateDir, %execLangPathBase%
LoadConf()
LoadJsonConf()
LoadCmdPathConf()
MenuTray()
;========================= 环境配置 =========================



;========================= 配置热键 =========================
MButton::   gosub, GuiInputCmdBar
#R::        gosub, GuiInputCmdBar
~RControl:: HotKeyConfControl()
~`::        HotKeyConfWave()

global InputCmdMode :=
global HotKeyControlCount := 0
HotKeyConfControl() {
	(HotKeyControlCount < 1 && A_TimeSincePriorHotkey > 80 && A_TimeSincePriorHotkey < 400 && A_PriorHotkey = A_ThisHotkey) ? HotKeyControlCount ++ : (HotKeyControlCount := 0)
	if (HotKeyControlCount > 0)
        gosub, GuiInputCmdBar
}
HotKeyConfWave() {
    Input, inputCmd, V T10, {vkC0},
    if (!inputCmd)
        return
    InputCmdMode := "hotkey"
    InputCmdExec(inputCmd)
}
;========================= 配置热键 =========================




;========================= 构建界面 =========================
global jsonTreeModifyFlag := false
global jsonTreeCmdCount := 0
global JsonTreeView := 0
GuiTV(ItemName, ItemPos, MenuName) {
    imageList := IL_Create(5)
    IL_Add(imageList, "shell32.dll", 74)
    IL_Add(imageList, "shell32.dll", 4)
    IL_Add(imageList, "shell32.dll", 135)
    Gui, GuiJsonTV:New
    Gui, GuiJsonTV:Font,, Microsoft YaHei
    Gui, GuiJsonTV:Add, TreeView, vJsonTreeView w450 r30 Readonly AltSubmit Checked HScroll hwndHTV gTVHandler ImageList%imageList%
    GuiControl, GuiJsonTV:-Redraw, JsonTreeView
    TVParse(0, jsonTree)
    GuiControl, GuiJsonTV:+Redraw, JsonTreeView
    Gui, GuiJsonTV:Add, StatusBar
    
    Menu, JsonTVMenu, Add, 添加, TVAdd
    Menu, JsonTVMenu, Icon, 添加, SHELL32.dll, 1
    Menu, JsonTVMenu, Add, 保存, TVSave
    Menu, JsonTVMenu, Icon, 保存, SHELL32.dll, 259
    Menu, JsonTVMenu, Add, 编辑, TVEdit
    Menu, JsonTVMenu, Icon, 编辑, SHELL32.dll, 134
    Menu, JsonTVMenu, Add, 删除, TVDelete
    Menu, JsonTVMenu, Icon, 删除, SHELL32.dll, 132
    Menu, JsonTVMenu, Add, 上移, TVUp
    Menu, JsonTVMenu, Icon, 上移, SHELL32.dll, 247
    Menu, JsonTVMenu, Add, 下移, TVDown
    Menu, JsonTVMenu, Icon, 下移, SHELL32.dll, 248
    Gui, Menu, JsonTVMenu
    Gui, GuiJsonTV:Show, , 命令树管理
    SB_SetText("总计" jsonTreeCmdCount "条命令")
}

TVHandler(CtrlHwnd, GuiEvent, EventInfo) {
	if (A_GuiEvent == "K") {
		if (A_EventInfo = 46)
			TVDelete("", "", "")
	} else if (A_GuiEvent == "DoubleClick") {
        TVEdit("", "", "")
	} else if (A_GuiControl = "JsonTreeView") {
        TV_Modify(A_EventInfo, "Select Vis")
	}
}
;========================= 构建界面 =========================



;========================= 树菜单->添加 =========================
global TVAddBranchNameEdit :=
global TVAddBranchCmdEdit :=
global TVAddBranchExecEdit :=
global TVAddBranchIndex :=
global TVAddParentBranchId :=
TVAdd(ItemName, ItemPos, MenuName) {
    Gui, GuiJsonTV:Default
	selectBranchId := TV_GetSelection()
    if (!selectBranchId)
        selectBranchId := rootBranchId
    selectBranch := jsonTreeKV[selectBranchId]
    if (selectBranch.cmd) {
        TVAddBranchIndex := selectBranchId
        TVAddParentBranchId := TV_GetParent(selectBranchId)
        parentBranch := jsonTreeKV[TVAddParentBranchId]
        parentBranchName := parentBranch.name
    } else {
        TVAddBranchIndex :=
        TVAddParentBranchId := selectBranch.BranchId
        parentBranchName := selectBranch.name
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
    
    Gui, GuiJsonTV:Default
    if (TVAddBranchCmdEdit) {
        ;检查命令重复性
        ;注意jsonCmdTree中的branchId(文件中读取的)与jsonTreeKV中的branchId(每次新创建)是不一致的
        ;topChildBranchId := GetTopChildBranchId(parentBranchId)
        ;if (!topChildBranchId)
        ;    return
        ;topChildBranch := jsonTreeKV[topChildBranchId]
        ;if (!topChildBranch)
        ;    return
        ;
        ;topChildCmds := jsonCmdTree[topChildBranch.name]
        ;for cmdKey, branchId in topChildCmds {
        ;    if (cmdKey == TVAddBranchCmdEdit) {
        ;        cmd := jsonTreeKV[branchId]
        ;        MsgBox, % "该命令[" cmdKey "]已存在, 其名称为[" cmd.name "]!"
        ;        return
        ;    }
        ;}
        newBranchId := TV_Add(TVAddBranchNameEdit " - " TVAddBranchCmdEdit, TVAddParentBranchId, "Icon1 " TVAddBranchIndex)
    } else {
        newBranchId := TV_Add(TVAddBranchNameEdit, TVAddParentBranchId, "Bold Icon2 " TVAddBranchIndex)
    }
    
    Gui, GuiTVAdd:Destroy
    TV_Modify(TVAddParentBranchId, "Expand")
    newBranch := Object("branchId", newBranchId, "name", TVAddBranchNameEdit)
    if (TVAddBranchCmdEdit)
        newBranch.cmd := TVAddBranchCmdEdit
    if (TVAddBranchExecEdit)
        newBranch.exec := TVAddBranchExecEdit
    jsonTreeKV[newBranchId] := newBranch
    
    
    ;在children中指定位置插入新branch， 否则重启后位置又变为最后了
    parentBranch := jsonTreeKV[TVAddParentBranchId]
    parentBranchChildren := parentBranch.children
    if (parentBranchChildren) {
        if (TVAddBranchIndex) {
            for index, child in parentBranchChildren {
                if (child.branchId == TVAddBranchIndex) {
                    parentBranchChildren.InsertAt(index+1, newBranch)
                    break
                }
            }
        } else {
            parentBranchChildren.Push(newBranch)
        }
    } else {
        parentBranch.children := [newBranch]
    }
    jsonTreeModifyFlag := true
}
TVAddCancelHandler(CtrlHwnd, GuiEvent, EventInfo) {
    Gui, GuiTVAdd:Destroy
    Gui, GuiJsonTV:Default
}
;========================= 树菜单->添加 =========================


;========================= 树菜单->编辑 =========================
global TVEditBranchNameEdit :=
global TVEditBranchCmdEdit :=
global TVEditBranchExecEdit :=
global TVEditBranchId :=
TVEdit(ItemName, ItemPos, MenuName) {
	TVEditBranchId := TV_GetSelection()
    if (TVEditBranchId == rootBranchId)
        return        
    branch := jsonTreeKV[TVEditBranchId]
    branchName := branch.name
    branchExec := branch.exec
    branchCmd := branch.cmd
	Gui, GuiTVEdit:Destroy
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
    branch := jsonTreeKV[TVEditBranchId]
    branch.name := TVEditBranchNameEdit
    if (TVEditBranchExecEdit)
        branch.exec := TVEditBranchExecEdit
    else
        branch.delete("exec")
    if (TVEditBranchCmdEdit)
        branch.cmd := TVEditBranchCmdEdit
    else
        branch.delete("cmd")    
    Gui, GuiTVEdit:Destroy
    Gui, GuiJsonTV:Default
    if (branch.cmd)
        TV_Modify(TVEditBranchId, "-Bold Icon1", branch.name " - " branch.cmd)
    else
        TV_Modify(TVEditBranchId, "Bold Icon2", branch.name)
    jsonTreeModifyFlag := true
}
TVEditCancelHandler(CtrlHwnd, GuiEvent, EventInfo) {
    Gui, GuiTVEdit:Destroy
    Gui, GuiJsonTV:Default
}
;========================= 树菜单->编辑 =========================


;========================= 树菜单->删除 =========================
TVDelete(ItemName, ItemPos, MenuName) {
    Gui, GuiJsonTV:Default
	deleteTipStr := ""
	checkBranchIds := Object()
	checkBranchId = 0
	Loop
	{
		checkBranchId := TV_GetNext(checkBranchId, "Checked")
		if (!checkBranchId)
			break
        if (checkBranchId == rootBranchId) {
            MsgBox, root项不能删除
            return
        }
        checkBranchIds.Push(checkBranchId)
        checkBranch := jsonTreeKV[checkBranchId]
        if (checkBranch.children) {
            MsgBox, % "要删除[ " checkBranch.name " ]节点, 请先删除其下所有子节点"
            return
        }
		deleteTipStr .= "  " checkBranch.name "`n"
	}
    if (!checkBranchIds.Length()) {
        MsgBox, 请勾选要删除的项目
        return
    }
	MsgBox, 1, 删除, 是否要删除勾选项以及其下所有子项?`n`n%deleteTipStr%
	IfMsgBox OK
	{
        for index, checkBranchId in checkBranchIds {
            parentBranchId := TV_GetParent(checkBranchId)
            parentBranch := jsonTreeKV[parentBranchId]
            children := parentBranch.children
            for index, child in children {
                if (child.branchId == checkBranchId) {
                    children.RemoveAt(index)
                    break
                }
            }
            if (!children.Length())
                parentBranch.delete("children")
            TV_Delete(checkBranchId)
        }
        jsonTreeModifyFlag := true
	}
}
;========================= 树菜单->删除 =========================


;========================= 树菜单->上移 =========================
TVUp(ItemName, ItemPos, MenuName) {
    Gui, GuiJsonTV:Default
	upBranchId := TV_GetSelection()
    if (!upBranchId || upBranchId == rootBranchId)
        return
    upBranch := jsonTreeKV[branchId]
    upBranchPrevId := TV_GetPrev(upBranchId)
    if (!upBranchPrevId)
        return
    
    upBranchParentId := TV_GetParent(upBranchId)
    upBranchParent := jsonTreeKV[upBranchParentId]
    upBranchParentChildren := upBranchParent.children
    for index, child in upBranchParentChildren {
        if (child.branchId == upBranchId)
            upBranchIdIndex := index
        if (child.branchId == upBranchPrevId)
            upBranchIdIndex2 := index
    }
    upBranchTemp := upBranchParentChildren[upBranchIdIndex]
    upBranchParentChildren[upBranchIdIndex] := upBranchParentChildren[upBranchIdIndex2]
    upBranchParentChildren[upBranchIdIndex2] := upBranchTemp
    

    upBranchLevelNames := Object()
    TVExpandLevelBefore(upBranchLevelNames, upBranchParent)
    TV_Delete()
    jsonTreeKV := Object()
    jsonTreeCmdCount := 0
    TVParse(0, jsonTree)
    TVExpandLevelAfter(upBranchLevelNames, jsonTree, 1)
    jsonTreeModifyFlag := true
}
;========================= 树菜单->上移 =========================


;========================= 树菜单->下移 =========================
TVDown(ItemName, ItemPos, MenuName) {
    Gui, GuiJsonTV:Default
	downBranchId := TV_GetSelection()
    if (!downBranchId || downBranchId == rootBranchId)
        return
    downBranch := jsonTreeKV[branchId]
    downBranchNextId := TV_GetNext(downBranchId)
    if (!downBranchNextId)
        return
    
    downBranchParentId := TV_GetParent(downBranchId)
    downBranchParent := jsonTreeKV[downBranchParentId]
    downBranchParentChildren := downBranchParent.children
    for index, child in downBranchParentChildren {
        if (child.branchId == downBranchId)
            downBranchIdIndex := index
        if (child.branchId == downBranchNextId)
            downBranchIdIndex2 := index
    }
    
    downBranchTemp := downBranchParentChildren[downBranchIdIndex]
    downBranchParentChildren[downBranchIdIndex] := downBranchParentChildren[downBranchIdIndex2]
    downBranchParentChildren[downBranchIdIndex2] := downBranchTemp
    

    downBranchLevelNames := Object()
    TVExpandLevelBefore(downBranchLevelNames, downBranchParent)
    TV_Delete()
    jsonTreeKV := Object()
    jsonTreeCmdCount := 0
    TVParse(0, jsonTree)
    TVExpandLevelAfter(downBranchLevelNames, jsonTree, 1)
    jsonTreeModifyFlag := true
}
;========================= 树菜单->下移 =========================


;========================= 树菜单->保存 =========================
TVSave(ItemName, ItemPos, MenuName) {
    if (jsonTreeModifyFlag) {
        jsonTreeStr := JSON.Dump(jsonTree)
        FileDelete, %jsonFilePath%
        FileAppend, %jsonTreeStr%, %jsonFilePath%
        LoadJsonConf()
        MsgBox, 保存成功
        jsonTreeModifyFlag := false
    } else {
        MsgBox, 未修改不保存
    }
}
;========================= 树菜单->保存 =========================



;========================= 输入Bar =========================
global InputCmdBarExist := false
global InputCmdEdit :=
global InputCmdLV :=
global InputCmdMatchText :=
global InputCmdLastValue :=
;GuiInputCmdBar未采用函数调用原因: AeroGlass在函数模式未生效
GuiInputCmdBar:
    if (InputCmdBarExist) {
        Gui, InputCmdBar:Default
        Gui, InputCmdBar:Submit, NoHide
        confs.InputCmdLastValue := InputCmdEdit
        Gui, InputCmdBar:Hide
        InputCmdBarExist := false
        return
    }
    global InputCmdBarHwnd := "inputCmdBar"
    InputCmdBarExist := true
    InputCmdMode := "inputBar"
    InputCmdLastValue := confs.InputCmdLastValue
    InputCmdBarThemeConf(themeBgColor, themeFontColor, themeX, themeY)
    OnMessage(0x0201, "WM_LBUTTONDOWN")
    Gui, InputCmdBar:New, +LastFound -Caption -Border +AlwaysOnTop +hWnd%InputCmdBarHwnd%
    Gui, InputCmdBar:Margin, 5, 5
    Gui, InputCmdBar:Color, %themeBgColor%, %themeBgColor%
    Gui, InputCmdBar:Font, c%themeFontColor% s16 wbold, Microsoft YaHei
    Gui, InputCmdBar:Add, Edit, w450 h38 vInputCmdEdit gInputCmdEditHandler, %InputCmdLastValue%
    Gui, InputCmdBar:Font, s10 -w, Microsoft YaHei
    Gui, InputCmdBar:Add, ListView, AltSubmit -Hdr -Multi ReadOnly Hidden w450 r9 vInputCmdLV gInputCmdLVHandler, cmd|name
    Gui, InputCmdBar:Font, s8, Microsoft YaHei
    Gui, InputCmdBar:Add, Text, w450 vInputCmdMatchText
    Gui, InputCmdBar:Add, Button, Default w0 h0 Hidden gInputCmdSubmitHandler
    guiX := 10
    guiY := A_ScreenHeight - 500
    Winset, Transparent, 238
    if (themeX && themeY)
        Gui, InputCmdBar:Show, w460 h48 x%themeX% y%themeY%
    else
        Gui, InputCmdBar:Show, w460 h48 center
    LV_ModifyCol(1, 180)
    LV_ModifyCol(2, 250)
    if (themeConfType == "blur")
        EnableBlur(InputCmdBarHwnd)
    if (InputCmdLastValue)
        InputCmdEditHandler("", "", "")
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
    confs.InputCmdLastValue := inputCmd
    SaveConf()
}

InputCmdBarGuiEscape:
    Gui, InputCmdBar:Submit, NoHide
    if (InputCmdEdit)
        confs.InputCmdLastValue := InputCmdEdit
    Gui, InputCmdBar:Hide
    InputCmdBarExist := false
return

InputCmdEditHandler(CtrlHwnd, GuiEvent, EventInfo) {
    Gui, InputCmdBar:Submit, NoHide
    Gui, InputCmdBar:Show, h48
    GuiControl, InputCmdBar:Hide, InputCmdLV
    LV_Delete()
    inputCmd := RegExReplace(LTrim(InputCmdEdit), "\s+", " ")      ;去除首位空格, 将字符串内多个连续空格替换为单个空格
    inputCmdArray := StrSplit(inputCmd, A_Space)
    inputCmdArrayLen := inputCmdArray.Length()
    if (inputCmdArrayLen == 1) {
        ;在path命令中进行匹配
        for fileName, fileDesc in jsonCmdPath {
            if (RegExMatch(fileName, "i)^" inputCmd))
                LV_Add(, fileName, fileDesc)
        }
    } else if (inputCmdArrayLen >= 2) {
        inputCmdKey := inputCmdArray[1]
        if (inputCmdKey not in g,get,do,q)
            return
        topChildCmds := jsonCmdTree[inputCmdKey]
        if (!topChildCmds)
            return
        inputCmdValue := inputCmdArray[2]
        for cmdKey, branchId in topChildCmds {
            if (RegExMatch(cmdKey, "i)^" inputCmdValue))
                LV_Add(, inputCmdKey " " cmdKey, jsonCmdTreeKV[branchId].name)
        }
    }
    if (LV_GetCount()) {
        Gui, InputCmdBar:Show, h270
        GuiControl, InputCmdBar:Show, InputCmdLV
        GuiControl, ,InputCmdMatchText, % "match result: " LV_GetCount()
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
    ~Up::   InputCmdBarKeyUp()
    ~Down:: InputCmdBarKeyDown()
    F1::    GuiTV("", "", "")
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
;========================= 输入Bar =========================




;========================= 公共函数 =========================
MenuTray() {
	Menu, Tray, NoStandard
    Menu, Tray, add, 修改菜单, GuiTV
	Menu, Tray, add, 命令输入, GuiInputCmdBar
	Menu, Tray, add, 定位文件, MenuTrayLocation
	Menu, Tray, add
	Menu, Tray, add, 重启, MenuTrayReload
	Menu, Tray, add, 退出, MenuTrayExit
    Menu, Tray, Default, 修改菜单
}

MenuTrayReload(ItemName, ItemPos, MenuName) {
    Reload    
}
MenuTrayExit(ItemName, ItemPos, MenuName) {
    gosub, InputCmdBarGuiEscape
    TVExit()
    ExitApp
}
MenuTrayLocation(ItemName, ItemPos, MenuName) {
    Run, % "explorer /select," A_ScriptFullPath
}
TVExit() {
	if (jsonTreeModifyFlag) {
		MsgBox, 51, 关闭, 命令已修改，是否保存后再退出？
		IfMsgBox Yes
            TVSave("", "", "")
	}
    Gui, GuiJsonTV:Destroy
}
GuiJsonTVGuiClose(GuiHwnd) {
    TVExit()
}

LoadJsonConf() {
    FileEncoding, UTF-8
    global jsonFilePath := A_ScriptDir "\contextCmd.json"
    jsonFile := FileOpen(jsonFilePath, "r")
    if (!IsObject(jsonFile))
        throw Exception("Can't access file for JSONFile instance: " jsonFile, -1)
    try {
        jsonTree := JSON.Load(jsonFile.Read())
    } catch e {
        MsgBox, JSON文件格式错误，请检查[%jsonFilePath%]
        return
    }
    jsonFile.Close()
    for index, topChild in jsonTree.children {
        topChildCmds := Object()
        LoadJsonConfLoop(topChildCmds, topChild.children)
        jsonCmdTree[topChild.name] := topChildCmds
    }
}
LoadJsonConfLoop(childCmds, branchs) {
    for index, branch in branchs {
        branchId := branch.branchId
        if (branch.cmd)
            childCmds[branch.cmd] := branchId
        if (branch.children)
            LoadJsonConfLoop(childCmds, branch.children)
        jsonCmdTreeKV[branchId] := branch
    }
}


;读取path目录中的命令
LoadCmdPathConf() {
    FileEncoding
    pathConfs := [{"path": "C:\WINDOWS\System32\*.exe", "type": "system"}, {"path": "C:\WINDOWS\*.exe", "type": "system"}, {"path": "C:\path\*", "type": "custom"}, {"path": "C:\path\bat\*", "type": "custom"}]
    for index, pathConf in pathConfs {
        if (pathConf.type == "system")
            fileDescPrefix := "*"
        else
            fileDescPrefix := " "
        Loop, Files, % pathConf.path, F
        {
            filePath := fileName := fileExt := fileDesc := fileLnkDesc :=
            SplitPath, A_LoopFileFullPath,,, fileExt, fileName
            if (!A_LoopFileExt) {
                fileDesc := fileName
            } else if (A_LoopFileExt == "lnk") {
                FileGetShortcut, %A_LoopFileFullPath%, filePath,,,fileDesc
                if (!filePath || !FileExist(filePath)) {
                    filePath := A_LoopFileFullPath
                    fileDesc := fileName
                }
            } else {
                filePath := A_LoopFileFullPath
                fileExt := A_LoopFileExt
            }
            
            if (!fileDesc) {
                SplitPath, filePath,,, fileExt
                if (fileExt == "exe") {
                    fileDesc := FileGetDesc(filePath)
                } else if (fileExt == "bat") {
                    file := FileOpen(filePath, "r")
                    RegExMatch(file.Read(), "U)title\s.*\s", fileDesc)
                    fileDesc := StrReplace(StrReplace(fileDesc, "title "), "&")
                    file.Close()
                } else if (fileExt == "vbs") {
                    fileDesc := fileName
                } else {
                    continue
                }
            }
            jsonCmdPath[fileName] := fileDescPrefix fileDesc
        }
    }
}

LoadConf() {
    FileEncoding, UTF-8
    confsFilePath := A_ScriptDir "\contextCmdConf.json"
    confsFile := FileOpen(confsFilePath, "r")
    if !IsObject(confsFile)
        throw Exception("Can't access file for JSONFile instance: " confsFile, -1)
    try {
        confs := JSON.Load(confsFile.Read())
        themeConfs := confs.theme
    } catch e {
        MsgBox, JSON文件格式错误，请检查[%confsFilePath%]
        return
    }
    confFile.Close()
}
SaveConf() {
    FileEncoding, UTF-8
    confsFilePath := A_ScriptDir "\contextCmdConf.json"
    confsStr := JSON.Dump(confs)
    FileDelete, %confsFilePath%
    FileAppend, %confsStr%, %confsFilePath%
}


InputCmdBarThemeConf(ByRef themeBgColor, ByRef themeFontColor, ByRef themeX, ByRef themeY) {
    themeConf := themeConfs[themeConfType]
    if (themeConfType == "auto") {
        RegRead, wallpaperPath, HKEY_CURRENT_USER\Control Panel\Desktop, WallPaper
        FileGetTime, wallpaperTimeStamp , %wallpaperPath%, M
        if (wallpaperPath != confs.LastWallpaperPath || wallpaperTimeStamp != confs.LastWallpaperTimeStamp) {
            wallpaperHex := ImgGetDominantColor(wallpaperPath)
            confs.LastWallpaperPath := wallpaperPath
            confs.LastWallpaperTimeStamp := wallpaperTimeStamp
            confs.LastWallpaperColor := wallpaperHex
            SaveConf()
            themeBgColor := wallpaperHex
        } else {
            themeBgColor := confs.LastWallpaperColor
        }
        themeFontColor := themeConf.fontColor
        themeX := themeY :=
    } else if (themeConfType == "blur") {
        themeBgColor := themeConf.bgColor
        themeFontColor := themeConf.fontColor
        themeX := themeConf.x
        themeY := themeConf.y
    } else if (themeConfType == "custom") {
        Random, themeConfCustomIndex, themeConf.MinIndex(), themeConf.MaxIndex()
        themeConfCustom := themeConf[themeConfCustomIndex]
        themeBgColor := themeConfCustom.bgColor
        themeFontColor := themeConfCustom.fontColor
        themeX := themeY :=
    }
}


InputCmdExec(inputCmd) {
    WinGet, inputCmdCurWinId, ID, A
    inputCmd := RegExReplace(Trim(inputCmd), "\s+", " ")      ;去除首位空格, 将字符串内多个连续空格替换为单个空格
    inputCmdArray := StrSplit(inputCmd, A_Space)
    inputCmdArrayLen := inputCmdArray.Length()
    if (inputCmdArrayLen == 1) {
        ExecNativeCmd(inputCmd, inputCmdKey, inputCmdValue)
        return
    } else if (inputCmdArrayLen >= 2) {
        inputCmdKey := inputCmdArray[1]
        inputCmdValue := inputCmdArray[2]
        if (inputCmdArrayLen == 3)
            inputCmdValueExtra := inputCmdArray[3]
    }
    if (!inputCmdKey)
        return
    topChildCmds := jsonCmdTree[inputCmdKey]
    if (!topChildCmds) {
        ExecNativeCmd(inputCmd, inputCmdKey, inputCmdValue)
        return
    }
    cmdBranchId := topChildCmds[inputCmdValue]
    if (!cmdBranchId) {
        tip("未找到匹配的命令")
        return
    }
    cmdBranch := jsonCmdTreeKV[cmdBranchId]
    if (!cmdBranch)
        return
    cmd := cmdBranch.cmd
    if (!cmd)
        return
    exec := cmdBranch.exec
    if (!exec)
        return
    execLangFlag := InStr(exec, "execLang=", true)
    if (execLangFlag) {
        RegExMatch(exec, "U)execLang=.*\s", execLang)
        execLang := StrReplace(StrReplace(execLang, "execLang="), "`n")
        execLangPath := execLangPathBase "\" inputCmdKey "_" cmd "." execLang
        FileDelete, %execLangPath%
        FileEncoding
        FileAppend, %exec%, %execLangPath%
    }
    
    if (inputCmdKey == "g") {
        if (execLangFlag) {
            if (inputCmdValueExtra)
                run, %execLangPath% %inputCmdValueExtra%
            else
                run, %execLangPath%
        } else {
            run, %exec%
        }
    } else if (inputCmdKey == "get") {
        needBackKeyCount := StrLen(inputCmd) + 2    ;``符号也需要计算在退格值内，自加2
        WinGet, inputCmdCurWinId2, ID, A  ;窗口发生变化时，在新窗口中不处理退格
        isWinChanged := (inputCmdCurWinId == inputCmdCurWinId2 ? false : true)
        
        ;常量替换
        if (InStr(exec, "$cuteWord$", true)) {
            cuteWord := GetCuteWord()
            exec := StrReplace(exec, "$cuteWord$", cuteWord)
        }

        if (execLangFlag) {
            RunWait, %execLangPath% %inputCmdValueExtra%
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
            run, %execLangPath% %inputCmdValueExtra%
        } else {
            run, %exec%
        }
        
    } else if (inputCmdKey == "q") {
        if (execLangFlag) {
            run, %execLangPath% %inputCmdValueExtra%
        } else {
            exec := "tencent://message/?uin=" exec
            run, %exec%
        }
    }
}

;执行系统级支持的命令  eg: notepad、calc...
;注意
;  执行[rgbcolor]成功
;  执行[rgbcolor -m random]失败
;  执行[rgbcolor.bat -m random]成功
;因此，在执行失败时尝试增加.bat后缀
ExecNativeCmd(inputCmd, inputCmdKey, inputCmdValue) {
    run, %inputCmd%,, UseErrorLevel
    if (ErrorLevel == ERROR) {
        run, %inputCmdKey%.bat %inputCmdValue%,, UseErrorLevel
        if (ErrorLevel == ERROR)
            Tip("找不到指定的命令 !")
    }
}

TVParse(parentId, branch) {
    if (branch.cmd) {
        branchId := TV_Add(branch.name . " - " . branch.cmd, parentId, "Icon1")
        jsonTreeCmdCount += 1
    } else {
        if (parentId == 0)
            rootBranchId := branchId := TV_Add(branch.name, parentId, "Bold Icon3 Expand")
        else
            branchId := TV_Add(branch.name, parentId, "Bold Icon2")
    }
    children := branch.children
    if (children) {
        for index, child in children {
            TVParse(branchId, child)
        }
    }
    branch.branchId := branchId
    jsonTreeKV[branchId] := branch
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

TVExpandLevelBefore(branchNames, branch) {
    branchNames.InsertAt(1, branch.name)
    parentBranchId := TV_GetParent(branch.branchId)
    if (parentBranchId)
        TVExpandLevelBefore(branchNames, jsonTreeKV[parentBranchId])
}

TVExpandLevelAfter(cacheBranchNames, branch, level) {
    cacheBranchName := cacheBranchNames[level]
    if (branch.name != cacheBranchName)
        return
    
    TV_Modify(branch.branchId, "Expand")
    children := branch.children
    if (children) {
        for index, child in children {
            TVExpandLevelAfter(cacheBranchNames, child, level+1)
        }
    }
}


GetTopChildBranchId(branchId) {
    parentBranchId := TV_GetParent(branchId)
    if (parentBranchId == 0)
        return 0        
    if (parentBranchId == rootBranchId)
        return branchId
    return GetTopChildBranchId(parentBranchId)
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
;========================= 公共函数 =========================
