print(text) {
    SciObj := ComObjActive("SciTE4AHK.Application")
    SciObj.Output(text)
    SciObj.Output("`r`n")
}
printSplitLine() {
    SciObj := ComObjActive("SciTE4AHK.Application")
    SciObj.Output(text)
    SciObj.Output("================================================`r`n")
}
printClear() {
    SciObj := ComObjActive("SciTE4AHK.Application")
    SendMessage, SciObj.Message(0x111, 420)
}