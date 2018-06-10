tip(msg := "") {
	if (msg) {
		ToolTip, %msg%, %A_CaretX%,  %A_CaretY%
		SetTimer, Tip, 2000
	} else {
		SetTimer, Tip, Off
		ToolTip
	}
}