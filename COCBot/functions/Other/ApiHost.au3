; #FUNCTION# ====================================================================================================================
; Name ..........: MyBot.run Bot API functions
; Description ...: Register Windows Message and provides functions to communicate between bots and manage bot application
; Author ........: cosote (12-2016)
; Modified ......: CodeSlinger69 (2017)
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2017
;                  MyBot is distributed under the terms of the GNU GPL
;                  Read/write memory: https://www.autoitscript.com/forum/topic/104117-shared-memory-variables-demo/
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================

#include-once
#include "_Memory.au3"

Global $g_ahManagedMyBotDetails[0] ; Contains array of MemoryHandleArray - frmBot - Timer Handle of last response - Command line of bot - Bot Window Title - RunState - TPaused - Verify count
GUIRegisterMsg($WM_MYBOTRUN_API_1_0, "WM_MYBOTRUN_API_1_0_HOST")
GUIRegisterMsg($WM_MYBOTRUN_STATE_1_0, "WM_MYBOTRUN_STATE_1_0")

Func WM_MYBOTRUN_API_1_0_HOST($hWind, $iMsg, $wParam, $lParam)

	If $g_iDebugWindowMessages Then SetDebugLog("API-HOST: $hWind=" & $hWind & ",$iMsg=" & $iMsg & ",$wParam=" & $wParam & ",$lParam=" & $lParam)

	$hWind = 0
	Switch BitAND($wParam, 0xFFFF)

		; Post Message to Manage Farm App and consume message

		Case 0x1040 + 2
			; unregister bot
			Local $_frmBot = $lParam
			Local $wParamHi = BitShift($wParam, 16)
			UnregisterManagedMyBotClient($_frmBot)

		Case Else ;Case 0x0000 + 1
			Local $_frmBot = HWnd($lParam)
			Local $wParamHi = BitShift($wParam, 16)
			Local $_RunState = BitAND($wParamHi, 1) > 0
			Local $_TPaused = BitAND($wParamHi, 2) > 0
			Local $_bLaunched = BitAND($wParamHi, 4) > 0
			GetManagedMyBotDetails($_frmBot, $g_WatchOnlyClientPID, $_RunState, $_TPaused, $_bLaunched)

	EndSwitch

	If $hWind <> 0 Then
		_WinAPI_PostMessage($hWind, $iMsg, $wParam, $lParam)
	EndIf

EndFunc   ;==>WM_MYBOTRUN_API_1_0_HOST

Func WM_MYBOTRUN_STATE_1_0($hWind, $iMsg, $wParam, $lParam)

	If $g_iDebugWindowMessages Then SetDebugLog("API-HOST-STATE: $hWind=" & $hWind & ",$iMsg=" & $iMsg & ",$wParam=" & $wParam & ",$lParam=" & $lParam)

	; Read state from process
	Local $_frmBot = HWnd($lParam)
	Local $pid = WinGetProcess($_frmBot)
	If $pid Then
		; Process exists
		Local $hMem = _MemoryOpen($pid)
		If _MemoryReadStruct($wParam, $hMem, $tBotState) = 1 Then
			; update state struct
			Local $_RunState = DllStructGetData($tBotState, "RunState")
			Local $_TPaused = DllStructGetData($tBotState, "Paused")
			Local $_bLaunched = DllStructGetData($tBotState, "Launched")
			GetManagedMyBotDetails($_frmBot, $g_WatchOnlyClientPID, $_RunState, $_TPaused, $_bLaunched, Default, $tBotState, $hMem)
		Else
			SetDebugLog("API-HOST-STATE: Cannot read memory from process: " & $pid)
		EndIf
		_MemoryClose($hMem)
	Else
		SetDebugLog("API-HOST-STATE: Cannot access PID for Window Handle: " & $lParam)
	EndIf

EndFunc   ;==>WM_MYBOTRUN_STATE_1_0

Func GetManagedMyBotDetails($hFrmBot = Default, $iFilterPID = Default, $_RunState = Default, $_TPaused = Default, $_bLaunched = Default, $iVerifyCount = Default, $_tBotState = Default, $hMem = Default)

	If $hFrmBot = Default Then Return $g_ahManagedMyBotDetails
	If $iVerifyCount = Default Then $iVerifyCount = 2

	If IsHWnd($hFrmBot) = 0 Then Return -1
	If $iFilterPID <> Default And WinGetProcess($hFrmBot) <> $iFilterPID Then Return -2 ; not expected bot process
	Local $pid = WinGetProcess($hFrmBot)
	Local $sTitle = WinGetTitle($hFrmBot)
	If $pid = -1 Then SetLog("Process not found for Window Handle: " & $hFrmBot)

	For $i = 0 To UBound($g_ahManagedMyBotDetails) - 1
		If $i > UBound($g_ahManagedMyBotDetails) - 1 Then ExitLoop ; array could have been reduced in size
		Local $a = $g_ahManagedMyBotDetails[$i]
		If $a[0] = $hFrmBot Then
			$a[1] = __TimerInit()
			$a[3] = $sTitle
			If $_RunState <> Default Then $a[4] = $_RunState
			If $_TPaused <> Default Then $a[5] = $_TPaused
			If $_bLaunched <> Default Then $a[6] = $_bLaunched
			$a[7] = $iVerifyCount ; verify count bot is really crashed (used to compensate computer sleep etc.)
			If $_tBotState <> Default Then
				$a[8] = $_tBotState
				Local $tStruct = 0
				If $hMem <> Default Then
					; check for additional struct
					Local $eStructType = DllStructGetData($tBotState, "StructType")
					Local $pStructPtr = DllStructGetData($tBotState, "StructPtr")
					Switch $eStructType
						Case $g_eSTRUCT_STATUS_BAR
							If $g_iDebugWindowMessages Then SetDebugLog("GetManagedMyBotDetails: Reading StatusBar Text")
							If _MemoryReadStruct($pStructPtr, $hMem, $tStatusBar) = 1 Then
								$tStruct = $tStatusBar
								SetDebugLog("StatusBar Text: " & DllStructGetData($tStatusBar, "Text"))
							EndIf
						Case $g_eSTRUCT_UPDATE_STATS
							If $g_iDebugWindowMessages Then SetDebugLog("GetManagedMyBotDetails: Reading Update Stats")
							If _MemoryReadStruct($pStructPtr, $hMem, $tUpdateStats) = 1 Then
								$tStruct = $tUpdateStats
								If $g_iDebugWindowMessages Then SetDebugLog("GetManagedMyBotDetails: Update Stats read")
							EndIf
					EndSwitch
				EndIf
				$a[9] = $tStruct
			EndIf
			$g_ahManagedMyBotDetails[$i] = $a
			If $g_iDebugWindowMessages Then SetDebugLog("Bot Window state received: " & GetManagedMyBotInfoString($a))
			Execute("UpdateManagedMyBot($a)")
			Return $a
		EndIf
		If $a[3] = $sTitle Then
			SetDebugLog("Remove registered Bot Window Handle " & $a[0] & ", as new instance detected")
			_ArrayDelete($g_ahManagedMyBotDetails, $i)
			$i -= 1
		EndIf
	Next

	Local $i = UBound($g_ahManagedMyBotDetails)
	ReDim $g_ahManagedMyBotDetails[$i + 1]
	Local $a[10]
	; Register new bot
	$a[0] = $hFrmBot
	$a[1] = __TimerInit()
	$a[2] = ProcessGetCommandLine($pid)
	$a[3] = $sTitle
	$a[4] = $_RunState
	$a[5] = $_TPaused
	$a[6] = $_bLaunched
	$a[7] = $iVerifyCount ; verify count bot is really crashed (used to compensate computer sleep etc.)
	$a[8] = 0 ; $tBotState
	$a[9] = 0 ; Additional StructType
	If $a[2] = -1 Then SetLog("Command line not found for Window Handle/PID: " & $hFrmBot & "/" & $pid)
	$g_ahManagedMyBotDetails[$i] = $a
	SetDebugLog("New Bot Window Handle registered: " & GetManagedMyBotInfoString($a))
	Execute("UpdateManagedMyBot($a)")
	Return $a
EndFunc   ;==>GetManagedMyBotDetails

Func GetManagedMyBotInfoString(ByRef $a)

	If UBound($a) < 8 Then Return "unknown"
	Return $a[0] & ", " & $a[2] & ", " & $a[3] & ", " & ($a[4] ? "running" : "not running") & ", " & ($a[5] ? "paused" : "not paused") & ", " & ($a[6] ? "launched" : "launching")

EndFunc   ;==>GetManagedMyBotInfoString

Func ClearManagedMyBotDetails()
	ReDim $g_ahManagedMyBotDetails[0]
EndFunc   ;==>ClearManagedMyBotDetails

Func UnregisterManagedMyBotClient($hFrmBot)

	SetDebugLog("Try to un-register Bot Window Handle: " & $hFrmBot)

	For $i = 0 To UBound($g_ahManagedMyBotDetails) - 1
		Local $a = $g_ahManagedMyBotDetails[$i]
		If $a[0] = $hFrmBot Then
			_ArrayDelete($g_ahManagedMyBotDetails, $i)
			Local $Result = 1
			If IsHWnd($hFrmBot) Then
				SetDebugLog("Bot Window Handle un-registered: " & $hFrmBot)
			Else
				SetDebugLog("Inaccessible Bot Window Handle un-registered: " & $hFrmBot)
				$Result = -1
			EndIf
			If $bCloseWhenAllBotsUnregistered = True And UBound($g_ahManagedMyBotDetails) = 0 Then
				SetLog("Closing " & $g_sBotTitle & "as all bots closed")
				Exit (1)
			EndIf
			Return $Result
		EndIf
	Next

	SetDebugLog("Bot Window Handle not un-registered: " & $hFrmBot, $COLOR_RED)

	Return 0

EndFunc   ;==>UnregisterManagedMyBotClient

Func CheckManagedMyBot($iTimeout)

	; Launch crashed bot again
	For $i = 0 To UBound($g_ahManagedMyBotDetails) - 1
		Local $a = $g_ahManagedMyBotDetails[$i]
		If __TimerDiff($a[1]) > $iTimeout Then
			If $a[6] > 0 Then
				; not verified inresponsive, decrease counter
				$a[6] -= 1
				; update array
				$g_ahManagedMyBotDetails[$i] = $a
				ContinueLoop
			EndIf
			_ArrayDelete($g_ahManagedMyBotDetails, $i)
			; check if bot has been already restarted manually
			Local $cmd = $a[2]
			Local $g_sAndroidTitle = $a[3]
			For $j = 0 To UBound($g_ahManagedMyBotDetails) - 1
				$a = $g_ahManagedMyBotDetails[$j]
				If $a[3] = $g_sAndroidTitle Then
					SetDebugLog("Bot already restarted, window title: " & $g_sAndroidTitle)
					Return WinGetProcess($a[0])
				EndIf
			Next
			If StringInStr($cmd, " /restart") = 0 Then $cmd &= " /restart"
			If $a[4] Then
				; bot was started, autostart again
				If StringInStr($cmd, " /autostart") = 0 Then $cmd &= " /autostart"
			EndIf
			SetDebugLog("Restarting bot: " & $cmd)
			Return Run($cmd)
		EndIf
	Next

	Return 0
EndFunc   ;==>CheckManagedMyBot

Func GetActiveMyBotCount($iTimeout)

	Local $iCount = 0
	For $i = 0 To UBound($g_ahManagedMyBotDetails) - 1
		Local $a = $g_ahManagedMyBotDetails[$i]
		If __TimerDiff($a[1]) <= $iTimeout Then
			$iCount += 1
		Else
			SetDebugLog("Bot not responding with Window Handle: " & $a[0])
		EndIf
	Next

	Return $iCount
EndFunc   ;==>GetActiveMyBotCount
