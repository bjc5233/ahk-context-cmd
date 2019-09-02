tip(msg := "") {
	if (msg) {
		ToolTip, %msg%, A_CaretX+20, A_CaretY+20
		SetTimer, Tip, 2000
	} else {
		SetTimer, Tip, Off
		ToolTip
	}
}