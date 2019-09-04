print(text := "") {
	if (!WinExist("ahk_class SciTEWindow"))
		return
	SciObj := ComObjActive("SciTE4AHK.Application")
	if (StrLen(text))
		SciObj.Output(text "`r`n")
	else
		SciObj.Output("================================================`r`n")
}
printClear() {
	if (!WinExist("ahk_class SciTEWindow"))
		return
    SciObj := ComObjActive("SciTE4AHK.Application")
    SendMessage, SciObj.Message(0x111, 420)
}