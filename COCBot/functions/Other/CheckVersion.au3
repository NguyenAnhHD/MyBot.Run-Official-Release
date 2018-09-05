; #FUNCTION# ====================================================================================================================
; Name ..........: CheckVersion
; Description ...: Check if we have last version of program
; Syntax ........:
; Parameters ....: None
; Return values .: None
; Author ........: Sardo (2015-06)
; Modified ......: CodeSlinger69 (2017)
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2018
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================
#include-once

Func CheckVersion()

	If not $g_bCheckVersion Then Return

	; Get the last Version from API
	Local $g_sBotGitVersion = ""
	Local $GetdataGithub = "https://api.github.com/repos/MyBotRun/MyBot/releases/latest"

	Local $Temp = __HttpGet($GetdataGithub)

	If $Temp <> "" And Not @error Then
		Local $g_aBotVersionN = StringSplit($g_sBotVersion, " ", 2)
		If @error Then
			Local $g_iBotVersionN = StringReplace($g_sBotVersion, "v", "")
		Else
			Local $g_iBotVersionN = StringReplace($g_aBotVersionN[0], "v", "")
		EndIf
		Local $version = GetLastVersion($Temp)
		$g_sBotGitVersion = StringReplace($version[0], "MBR_v", "")
		SetDebugLog("Last GitHub version is " & $g_sBotGitVersion )
		SetDebugLog("Your version is " & $g_iBotVersionN )

		If _VersionCompare($g_iBotVersionN, $g_sBotGitVersion) = -1 Then
			SetLog("WARNING, YOUR VERSION (" & $g_iBotVersionN & ") IS OUT OF DATE.", $COLOR_INFO)
			Local $ChangelogTXT = GetLastChangeLog($Temp)
			Local $Changelog = StringSplit($ChangelogTXT[0], '\r\n', $STR_ENTIRESPLIT + $STR_NOCOUNT)
			For $i = 0 To UBound($Changelog) - 1
				SetLog($Changelog[$i] )
			Next
			PushMsg("Update")
		ElseIf _VersionCompare($g_iBotVersionN, $g_sBotGitVersion) = 0 Then
			SetLog("WELCOME CHIEF, YOU HAVE THE LATEST MYBOT VERSION", $COLOR_SUCCESS)
		Else
			SetLog("YOU ARE USING A FUTURE VERSION CHIEF!", $COLOR_ACTION)
		EndIf
	Else
		SetDebugLog($Temp)
	EndIf
EndFunc   ;==>CheckVersion

Func __HttpGet($sURL, $sData = '')
	Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")
	If IsObj($oHTTP) Then
		$oHTTP.Open("GET", $sURL & "?" & $sData, False)
		If (@error) Then Return SetError(1, 0, "__HttpGet/Get Error")
		$oHTTP.Send()
		If (@error) Then Return SetError(2, 0, "__HttpGet/Send Error")
		If ($oHTTP.Status <> 200) Then Return SetError(3, 0, $oHTTP.Status)
		Return SetError(0, 0, $oHTTP.ResponseText)
	Else
		Return SetError(1, 0, "__HttpGet/ObjCreation Error")
	EndIf
EndFunc   ;==>__HttpGet

Func GetLastVersion($txt)
	Return _StringBetween($txt, '"tag_name":"', '","')
EndFunc   ;==>GetLastVersion

Func GetLastChangeLog($txt)
	Return _StringBetween($txt, '"body":"', '"}')
EndFunc   ;==>GetLastChangeLog

Func GetVersionNormalized($VersionString, $Chars = 5)
	If StringLeft($VersionString, 1) = "v" Then $VersionString = StringMid($VersionString, 2)
	Local $a = StringSplit($VersionString, ".", 2)
	Local $i
	For $i = 0 To UBound($a) - 1
		If StringLen($a[$i]) < $Chars Then $a[$i] = _StringRepeat("0", $Chars - StringLen($a[$i])) & $a[$i]
	Next
	Return _ArrayToString($a, ".")
EndFunc   ;==>GetVersionNormalized
