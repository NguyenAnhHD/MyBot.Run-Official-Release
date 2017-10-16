; #FUNCTION# ====================================================================================================================
; Name ..........: _GUICtrlSetState
; Description ...: Wrapper calling GUICtrlSetState
; Syntax ........:
; Parameters ....: See GUICtrlSetState
; Return values .: See GUICtrlSetState
; Author ........: osote 2017-10
; Modified ......:
;
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2017
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================

Func _GUICtrlSetState($controlID, $state)
	If $controlID <> 0 And $controlID <> -1 Then Return GUICtrlSetState($controlID, $state)
	Return 0
EndFunc