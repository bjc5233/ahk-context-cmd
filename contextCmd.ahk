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
;备注
;  1. {vkC0}表示`
;  2. 配置命令的[执行]文本框中, 在第一行输入[目标语言注释符号 execLang= 目标语言]格式, 
;       ::execLang=bat
;     会将此文本框文本保存到bat文件, 并执行该bat
;TODO
;  1.添加命令时判断是否重复
;  2.exec中加入execLang= 设定编程语言, 目前写死bat, 后续动态
;  3.增加菜单搜索命令
;  3.增加菜单判断命令是否已经存在
;  4.label方式调用，导致global变量太多过于混乱，修改为函数调用
;      注意:Gui, AddBranchItem:Add, Text, x+5 yp-3 w400 vAddBranchParent, %parentBranchName%
;           vAddBranchParent必须为global类型
;   5.inputCmdBar窗口大小目前写死, 使用变量定制
;========================= 环境配置 =========================
#Persistent
#NoEnv
#SingleInstance, Force
SetBatchLines, -1
SetKeyDelay, -1
StringCaseSense, off
CoordMode, Menu
#Include <JSON> 
#Include <PRINT>
#Include <CuteWord>

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
LoadJsonConf()
LoadCmdPathConf()
gosub, GuiMenuTray
;========================= 环境配置 =========================



;========================= 配置热键 =========================
global InputCmd :=
global InputCmdMode :=
global InputCmdLastValue :=
#R::
    gosub, GuiInputCmdBar
return
~RControl::
	(Count < 1 && A_TimeSincePriorHotkey > 80 && A_TimeSincePriorHotkey < 400 && A_PriorHotkey = A_ThisHotkey) ? Count ++ : (Count := 0)
	if (Count > 0)
        gosub, GuiInputCmdBar
return

~`::
    Input, InputCmd, V T10, {vkC0},
    if (!InputCmd)
        return
    InputCmdMode := "hotkey"
    InputCmdExec(InputCmd)
return
;========================= 配置热键 =========================




;========================= 构建界面 =========================
GuiMenuTray:
	Menu, Tray, NoStandard
    Menu, Tray, add, 修改菜单, GuiTV
	Menu, Tray, add, 命令输入, GuiInputCmdBar
	Menu, Tray, add
	Menu, Tray, add, 重启, MenuTrayReload
	Menu, Tray, add, 退出, MenuTrayExit
    Menu, Tray, Default, 修改菜单
return

GuiTV:
    global jsonTreeModifyFlag := false
    global jsonTreeCmdCount := 0
    tvImageList := IL_Create(5)
    IL_Add(tvImageList, "shell32.dll", 74)
    IL_Add(tvImageList, "shell32.dll", 4)
    IL_Add(tvImageList, "shell32.dll", 135)
    Gui, JsonTreeView:Destroy
    Gui, JsonTreeView:New
    Gui, JsonTreeView:Font,, Microsoft YaHei
    Gui, JsonTreeView:Add, TreeView, vJsonTreeView w450 r30 Readonly AltSubmit Checked HScroll hwndHTV gTVClick ImageList%tvImageList%
    GuiControl, JsonTreeView:-Redraw, JsonTreeView
    TVParse(0, jsonTree)
    GuiControl, JsonTreeView:+Redraw, JsonTreeView
    Gui, JsonTreeView:Add, StatusBar
    
    Menu, JsonTreeMenu, Add, 添加, TVAdd
    Menu, JsonTreeMenu, Icon, 添加, SHELL32.dll, 1
    Menu, JsonTreeMenu, Add, 保存, TVSave
    Menu, JsonTreeMenu, Icon, 保存, SHELL32.dll, 259
    Menu, JsonTreeMenu, Add, 编辑, TVEdit
    Menu, JsonTreeMenu, Icon, 编辑, SHELL32.dll, 134
    Menu, JsonTreeMenu, Add, 删除, TVDelete
    Menu, JsonTreeMenu, Icon, 删除, SHELL32.dll, 132
    Menu, JsonTreeMenu, Add, 上移, TVUp
    Menu, JsonTreeMenu, Icon, 上移, SHELL32.dll, 247
    Menu, JsonTreeMenu, Add, 下移, TVDown
    Menu, JsonTreeMenu, Icon, 下移, SHELL32.dll, 248
    Gui, Menu, JsonTreeMenu
    Gui, JsonTreeView:Show, , 命令树管理
    SB_SetText("总计" . jsonTreeCmdCount . "条命令")
return
TVClick:
	if (A_GuiEvent == "K") {
		if (A_EventInfo = 46)
			gosub, TVDelete
	} else if (A_GuiEvent == "DoubleClick") {
        gosub, TVEdit
	} else if (A_GuiControl = "JsonTreeView") {
        TV_Modify(A_EventInfo, "Select Vis")
	}
return
;========================= 构建界面 =========================



;========================= 树菜单->添加 =========================
TVAdd:
	selectBranchId := TV_GetSelection()
    if (!selectBranchId)
        selectBranchId := rootBranchId
    selectBranch := jsonTreeKV[selectBranchId]
    if (selectBranch.cmd) {
        addBranchIndex := selectBranchId
        parentBranchId := TV_GetParent(selectBranchId)
        parentBranch := jsonTreeKV[parentBranchId]
        parentBranchName := parentBranch.name
    } else {
        addBranchIndex :=
        parentBranchId := selectBranch.BranchId
        parentBranchName := selectBranch.name
    }
	Gui, AddBranchItem:Destroy
    Gui, AddBranchItem:New
	Gui, AddBranchItem:Margin, 20, 20
	Gui, AddBranchItem:Font,, Microsoft YaHei
	Gui, AddBranchItem:Add, GroupBox, xm y+10 w500 h210
    Gui, AddBranchItem:Add, Text, xm+10 y+15 y35 w60, 父级：
	Gui, AddBranchItem:Add, Text, x+5 yp-3 w400 vAddBranchParent, %parentBranchName%
	Gui, AddBranchItem:Add, Text, xm+10 y+15 w60, 名称：
	Gui, AddBranchItem:Add, Edit, x+5 yp-3 w400 vAddBranchName,
	Gui, AddBranchItem:Add, Text, xm+10 y+15 w60, 命令：
	Gui, AddBranchItem:Add, Edit, x+5 yp-3 w400 vAddBranchCmd,
  	Gui, AddBranchItem:Add, Text, xm+10 y+15 w60, 执行：
	Gui, AddBranchItem:Add, Edit, x+5 yp-3 w400 r10 vAddBranchExec,
	Gui, AddBranchItem:Add, Button, Default xm+180 y+15 w75 gTVAddSave, 确定(&Y)
	Gui, AddBranchItem:Add, Button, x+20 w75 gTVAddCancel, 取消(&C)
	Gui, AddBranchItem:Show, ,添加命令
return
TVAddSave:
    Gui, AddBranchItem:Submit, NoHide
    if (!AddBranchName) {
        MsgBox, 必须填写[名称]
        return
    }
    
    Gui, JsonTreeView:Default
    if (AddBranchCmd) {
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
        ;    if (cmdKey == AddBranchCmd) {
        ;        cmd := jsonTreeKV[branchId]
        ;        MsgBox, % "该命令[" cmdKey "]已存在, 其名称为[" cmd.name "]!"
        ;        return
        ;    }
        ;}
        newBranchId := TV_Add(AddBranchName " - " AddBranchCmd, parentBranchId, "Icon1 " addBranchIndex)
    } else {
        newBranchId := TV_Add(AddBranchName, parentBranchId, "Bold Icon2 " addBranchIndex)
    }
    
    Gui, AddBranchItem:Destroy
    TV_Modify(parentBranchId, "Expand")
    newBranch := Object("branchId", newBranchId, "name", AddBranchName)
    if (AddBranchCmd)
        newBranch.cmd := AddBranchCmd
    if (AddBranchExec)
        newBranch.exec := AddBranchExec
    jsonTreeKV[newBranchId] := newBranch
    
    
    ;在children中指定位置插入新branch， 否则重启后位置又变为最后了
    parentBranch := jsonTreeKV[parentBranchId]
    parentBranchChildren := parentBranch.children
    if (parentBranchChildren) {
        if (addBranchIndex) {
            for index, child in parentBranchChildren {
                if (child.branchId == addBranchIndex) {
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
return
TVAddCancel:
    Gui, AddBranchItem:Destroy
    Gui, JsonTreeView:Default
return
;========================= 树菜单->添加 =========================


;========================= 树菜单->编辑 =========================
TVEdit:
	branchId := TV_GetSelection()
    if (branchId == rootBranchId)
        return        
    branch := jsonTreeKV[branchId]
    branchName := branch.name
    branchExec := branch.exec
    branchCmd := branch.cmd
	Gui, EditBranchItem:Destroy
    Gui, EditBranchItem:New
	Gui, EditBranchItem:Margin, 20, 20
	Gui, EditBranchItem:Font,, Microsoft YaHei
	Gui, EditBranchItem:Add, GroupBox, xm y+10 w500 h210
	Gui, EditBranchItem:Add, Text, xm+10 y+30 y35 w60, 名称：
	Gui, EditBranchItem:Add, Edit, x+5 yp-3 w400 vEditBranchName, %branchName%
	Gui, EditBranchItem:Add, Text, xm+10 y+15 w60, 命令：
	Gui, EditBranchItem:Add, Edit, x+5 yp-3 w400 vEditBranchCmd, %branchCmd%
  	Gui, EditBranchItem:Add, Text, xm+10 y+15 w60, 执行：
	Gui, EditBranchItem:Add, Edit, x+5 yp-3 w400 r10 vEditBranchExec, %branchExec%
	Gui, EditBranchItem:Add, Button, Default xm+180 y+15 w75 gTVEditSave, 确定(&Y)
	Gui, EditBranchItem:Add, Button, x+20 w75 gTVEditCancel,取消(&C)
	Gui, EditBranchItem:Show, ,编辑命令 - %branchName%
return
TVEditSave:
    Gui, EditBranchItem:Submit, NoHide
    if (!EditBranchName) {
        MsgBox, 必须填写[名称]
        return
    }   
    branch := jsonTreeKV[branchId]
    branch.name := EditBranchName
    if (EditBranchExec)
        branch.exec := EditBranchExec
    else
        branch.delete("exec")
    if (EditBranchCmd)
        branch.cmd := EditBranchCmd
    else
        branch.delete("cmd")    
    Gui, EditBranchItem:Destroy
    Gui, JsonTreeView:Default
    if (branch.cmd)
        TV_Modify(branchId, "-Bold Icon1", branch.name " - " branch.cmd)
    else
        TV_Modify(branchId, "Bold Icon2", branch.name)
    jsonTreeModifyFlag := true
return
TVEditCancel:
    Gui, EditBranchItem:Destroy
    Gui, JsonTreeView:Default
return
;========================= 树菜单->编辑 =========================

;========================= 树菜单->保存 =========================
TVSave:
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
return
;========================= 树菜单->保存 =========================


;========================= 树菜单->删除 =========================
TVDelete:
	deleteTip := ""
	checkBranchIds := Object()
	checkBranchId = 0
	Loop
	{
		checkBranchId := TV_GetNext(checkBranchId, "Checked")
		if not checkBranchId
			break
        if (checkBranchId == rootBranchId) {
            MsgBox, root项不能删除
            return
        }
        checkBranchIds.Push(checkBranchId)
        checkBranch := jsonTreeKV[checkBranchId]
        if (checkBranch.children) {
            MsgBox, % "要删除[ " . checkBranch.name . " ]节点, 请先删除其所有子节点"
            return
        }
		deleteTip .= "  " checkBranch.name "`n"
	}
    if (!checkBranchIds.Length()) {
        MsgBox, 请勾选要删除的项目
        return
    }
	MsgBox, 1, 删除, 是否要删除勾选项以及其下所有子项?`n`n%deleteTip%
	IfMsgBox OK
	{
        Gui, JsonTreeView:Default
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
return
;========================= 树菜单->删除 =========================


;========================= 树菜单->上移 =========================
TVUp:
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
    Gui, JsonTreeView:Default
    TV_Delete()
    jsonTreeKV := Object()
    jsonTreeCmdCount := 0
    TVParse(0, jsonTree)
    TVExpandLevelAfter(upBranchLevelNames, jsonTree, 1)
    jsonTreeModifyFlag := true
return
;========================= 树菜单->上移 =========================


;========================= 树菜单->下移 =========================
TVDown:
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
    Gui, JsonTreeView:Default
    TV_Delete()
    jsonTreeKV := Object()
    jsonTreeCmdCount := 0
    TVParse(0, jsonTree)
    TVExpandLevelAfter(downBranchLevelNames, jsonTree, 1)
    jsonTreeModifyFlag := true
return
;========================= 树菜单->下移 =========================









;========================= 输入Bar =========================
GuiInputCmdBar:
    if (InputCmdBarExist) {
        Gui, InputCmdBar:Submit, NoHide
        InputCmdLastValue := InputCmd
        Gui, InputCmdBar:Hide
        InputCmdBarExist := false
        return
    }
    InputCmdMode := "inputBar"
    global InputCmdBarHwnd := "inputCmdBar"
    global InputCmdBarExist := true
    OnMessage(0x0201, "WM_LBUTTONDOWN")
    Gui, InputCmdBar:New, +LastFound -Caption -Border +hWnd%InputCmdBarHwnd%
    Gui, InputCmdBar:Margin, 5, 5
    Gui, InputCmdBar:Color, 000000, 000000
    WinSet, TransColor, 000000, InputCmdBar
    Gui, InputCmdBar:Font, s16, Microsoft YaHei
    Gui, InputCmdBar:Add, Edit, w400 h38 cFFFFFF vInputCmd gInputCmdEditHandler, %InputCmdLastValue%
    Gui, InputCmdBar:Font, s11, Microsoft YaHei
    Gui, InputCmdBar:Add, ListView, AltSubmit -Hdr -Multi ReadOnly Hidden LV0x8000 Background000000 cFFFFFF w400 r9 vInputCmdLV gInputCmdLVHandler, cmd|name
    Gui, InputCmdBar:Add, Button, Default w0 h0 Hidden vButton gInputCmdSubmit
    guiX := 10
    guiY := A_ScreenHeight - 500
    Gui, InputCmdBar:Show, w410 h48 x%guiX% y%guiY%
    LV_ModifyCol(1, 180)
    LV_ModifyCol(2, 200)
    EnableBlur(InputCmdBarHwnd)
return

InputCmdSubmit(CtrlHwnd, GuiEvent, EventInfo) {
    Gui, InputCmdBar:Submit, NoHide
    Gui, InputCmdBar:Default
    GuiControlGet, focusedControl, FocusV
    if (focusedControl == "InputCmd") {
    } else if (focusedControl == "InputCmdLV") {
        rowNum := LV_GetNext(0, "Focused")
        if (!rowNum)
            return
        LV_GetText(InputCmd, rowNum, 1)
    }
    Gui, InputCmdBar:Hide
    InputCmdLastValue := InputCmd
    InputCmdExec(InputCmd)
}
InputCmdBarGuiEscape:
    Gui, InputCmdBar:Submit, NoHide
    if (InputCmd)
        InputCmdLastValue := InputCmd
    Gui, InputCmdBar:Hide
    InputCmdBarExist := false
return

InputCmdEditHandler(CtrlHwnd, GuiEvent, EventInfo) {
    Gui, InputCmdBar:Submit, NoHide
    Gui, InputCmdBar:Show, h48
    GuiControl, InputCmdBar:Hide, InputCmdLV
    LV_Delete()
    InputCmd := LTrim(InputCmd)
    inputCmdSpacePos := InStr(InputCmd, " ", false)
    if (inputCmdSpacePos) {
        inputCmdKey := SubStr(InputCmd, 1, inputCmdSpacePos-1)
        if (inputCmdKey not in g,get,do,q)
            return
        topChildCmds := jsonCmdTree[inputCmdKey]
        if (!topChildCmds)
            return
        inputCmdValue := LTrim(SubStr(InputCmd, inputCmdSpacePos))
        for cmdKey, branchId in topChildCmds {
            if (RegExMatch(cmdKey, "i)^" inputCmdValue))
                LV_Add(, inputCmdKey " " cmdKey, jsonCmdTreeKV[branchId].name)
        }
    } else {
        for fileName, fileDesc in jsonCmdPath {
            if (RegExMatch(fileName, "i)^" InputCmd))
                LV_Add(, fileName, fileDesc)
        }
    }
    if (LV_GetCount()) {
        Gui, InputCmdBar:Show, h260
        GuiControl, InputCmdBar:Show, InputCmdLV
    }
}
InputCmdLVHandler(CtrlHwnd, GuiEvent, EventInfo) {
	if (GuiEvent == "DoubleClick") {
        InputCmdSubmit(CtrlHwnd, GuiEvent, EventInfo)
	} else if (GuiEvent == "K") {
        if (EventInfo == 32) {  ;空格键切换回输入框继续编辑
            Gui, InputCmdBar:Default
            rowNum := LV_GetNext(0, "Focused")
            if (rowNum)
                LV_Modify(rowNum, "-Focus -Select")
            GuiControl, Focus, InputCmd
        }
    }
}

#If WinActive(A_ScriptName) and WinActive("ahk_class AutoHotkeyGUI")
    ~Up::
        Gui, InputCmdBar:Default
        GuiControlGet, focusedControl, FocusV
        if (focusedControl == "InputCmd") {
            if (LV_GetCount()) {
                GuiControl, InputCmdBar:Focus, InputCmdLV
                Send, ^{End}
            }
        } else if (focusedControl == "InputCmdLV") {
            rowNum := LV_GetNext(0, "Focused")
            if (rowNum == 1) {
                LV_Modify(1, "-Focus -Select")
                GuiControl, Focus, InputCmd
            }
        }
    return
    ~Down::
        Gui, InputCmdBar:Default
        GuiControlGet, focusedControl, FocusV
        if (focusedControl == "InputCmd") {
            if (LV_GetCount()) {
                GuiControl, InputCmdBar:Focus, InputCmdLV
                Send, ^{Home}
            }
        } else if (focusedControl == "InputCmdLV") {
            rowNum := LV_GetNext(0, "Focused")
            if (rowNum == LV_GetCount()) {
                LV_Modify(rowNum, "-Focus -Select")
                GuiControl, Focus, InputCmd
            }
        }
    return
    F1::
        gosub, GuiTV
    return
#If
;========================= 输入Bar =========================


MenuTrayReload:
    Reload
return

MenuTrayExit:
    gosub, InputCmdBarGuiEscape
    gosub, TVExit
    ExitApp
return

TVExit:
	if (jsonTreeModifyFlag) {
		MsgBox, 51, 关闭, 命令已修改，是否保存后再退出？
		IfMsgBox Yes
            gosub, TVSave
	}
    Gui, JsonTreeView:Destroy
return

JsonTreeViewGuiClose:
    gosub, TVExit
return




;========================= 公共函数 =========================
LoadJsonConf() {
    FileEncoding, UTF-8
    global jsonFilePath := A_ScriptDir "\contextCmd.json"
    jsonFile := FileOpen(jsonFilePath, "r")
    if !IsObject(jsonFile)
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
    paths := ["C:\path", "C:\path\bat"]
    for index, path in paths {
        Loop, Files, %path%\*
        {
            filePath := fileName := fileExt := fileDesc :=
            if (A_LoopFileExt == "lnk") {
                FileGetShortcut, %A_LoopFileFullPath%, filePath
                if (!filePath || !FileExist(filePath))
                    continue
            } else {
                filePath := A_LoopFileFullPath
                fileExt := A_LoopFileExt
            }
            
            
            SplitPath, filePath,,, fileExt, fileName
            if (fileExt == "exe") {
                fileDesc := FileGetDesc(filePath)
            } else if (fileExt == "bat") {
                file := FileOpen(filePath, "r")
                fileContent := file.Read()
                RegExMatch(fileContent, "OU)title\s.*\s", fileDescMatch)
                fileDesc := fileDescMatch.value
                fileDesc := StrReplace(fileDesc, "title ")
                fileDesc := StrReplace(fileDesc, "&")
                jsonFile.Close()
            } else {
                continue
            }
            jsonCmdPath[fileName] := fileDesc
        }
    }
}



InputCmdExec(inputCmd) {
    WinGet, inputCmdCurWinId, ID, A
    inputCmd := LTrim(inputCmd)
    inputCmdSpacePos := InStr(inputCmd, " ", false)
    if (inputCmdSpacePos) {
        inputCmdKey := SubStr(inputCmd, 1, inputCmdSpacePos-1)
        inputCmdValue := LTrim(SubStr(inputCmd, inputCmdSpacePos))
        
        inputCmdSpacePos2 := InStr(inputCmdValue, " ", false)
        if (inputCmdSpacePos2) {
            inputCmdValueExtra := LTrim(SubStr(inputCmdValue, inputCmdSpacePos2))
            inputCmdValue := SubStr(inputCmdValue, 1, inputCmdSpacePos2-1)
        }
    } else {
        ExecNativeCmd(inputCmd, inputCmdKey, inputCmdValue)
        return
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
    
    if (inputCmdKey == "g") {
        StringGetPos, execFlag, exec, execLang=, L1
        if (ErrorLevel) {
            run, %exec%
        } else {
            execLangPath := execLangPathBase "\" inputCmdKey "_" cmd ".bat"
            FileDelete, %execLangPath%
            FileEncoding
            FileAppend, %exec%, %execLangPath%
            if (inputCmdValueExtra)
                run, %execLangPath% %inputCmdValueExtra%
            else
                run, %execLangPath%
        }
        
    } else if (inputCmdKey == "get") {
        StringLen, needBackKeyCount, inputCmd
        needBackKeyCount += 2  ;``符号也需要计算在退格值内，自加2
        isWinChanged := false
        WinGet, inputCmdCurWinId2, ID, A  ;窗口发生变化时，在新窗口中不处理退格
        if (inputCmdCurWinId != inputCmdCurWinId2)
            isWinChanged := true

        ;常量替换
        IfInString, exec, $cuteWord$ 
        {
            cuteWord := GetCuteWord()
            StringReplace, exec, exec, $cuteWord$, %cuteWord%, All
        }
        StringGetPos, execFlag, exec, execLang=, L1
        if (ErrorLevel) {
            Clipboard := exec
            if (InputCmdMode == "hotkey") {
                if (isWinChanged)
                    SendInput, ^v
                else
                    SendInput, {backspace %needBackKeyCount%}^v
            }
        } else {
            execLangPath := execLangPathBase "\" inputCmdKey "_" cmd ".bat"
            FileDelete, %execLangPath%
            FileEncoding
            FileAppend, %exec%, %execLangPath%
            RunWait, %execLangPath% %inputCmdValueExtra%
            if (InputCmdMode == "hotkey") {
                if (isWinChanged)
                    SendInput, ^v
                else
                    SendInput, {backspace %needBackKeyCount%}^v
            }
        }
        InputCmdMode :=
        
    } else if (inputCmdKey == "do") {
        StringGetPos, execFlag, exec, execLang=, L1
        if (ErrorLevel) {
            run, %exec%
        } else {
            execLangPath := execLangPathBase "\" inputCmdKey "_" cmd ".bat"
            FileDelete, %execLangPath%
            FileEncoding
            FileAppend, %exec%, %execLangPath%
            run, %execLangPath% %inputCmdValueExtra%
        }
        
    } else if (inputCmdKey == "q") {
        StringGetPos, execFlag, exec, execLang=, L1
        if (ErrorLevel) {
            exec := "tencent://message/?uin=" exec
            run, %exec%
        } else {
            execLangPath := execLangPathBase "\" inputCmdKey "_" cmd ".bat"
            FileDelete, %execLangPath%
            FileEncoding
            FileAppend, %exec%, %execLangPath%
            run, %execLangPath% %inputCmdValueExtra%
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


Tip(msg) {
	ToolTip, %msg%, %A_CaretX%,  %A_CaretY%
    SetTimer, TipRemove, 2000
}
TipRemove:
    SetTimer, TipRemove, Off
    ToolTip
return


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
;========================= 公共函数 =========================
