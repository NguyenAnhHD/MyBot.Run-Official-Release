; #FUNCTION# ====================================================================================================================
; Name ..........: MyBot.run Bot API functions
; Description ...: Register Windows Message and provides functions to communicate between bots and manage bot application
; Author ........: cosote (12-2016)
; Modified ......:
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2017
;                  MyBot is distributed under the terms of the GNU GPL
;                  Read/write memory: https://www.autoitscript.com/forum/topic/104117-shared-memory-variables-demo/
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================

Global $g_ahManagedMyBotHosts[0] ; Contains array of registered MyBot.run host Window Handle and TimerHandle of last communication
GUIRegisterMsg($WM_MYBOTRUN_API_1_0, "WM_MYBOTRUN_API_1_0_CLIENT")

Func WM_MYBOTRUN_API_1_0_CLIENT($hWind, $iMsg, $wParam, $lParam)

	If $hWind <> $g_hFrmBot Then Return 0

	If $g_iDebugWindowMessages Then SetDebugLog("API-CLIENT: $hWind=" & $hWind & ",$iMsg=" & $iMsg & ",$wParam=" & $wParam & ",$lParam=" & $lParam)

	$hWind = 0
	Local $wParamHi = 0
	If $g_bRunState = True Then $wParamHi += 1
	If $g_bBotPaused = True Then $wParamHi += 2
	If Not $g_iBotLaunchTime = 0 Then $wParamHi += 4 ; bot launched

	Local $wParamLo = BitAND($wParam, 0xFFFF)

	Switch $wParamLo

		; Post Message to Manage Farm App and consume message
		Case 0x0100 ; query bot detailed state
			$iMsg = $WM_MYBOTRUN_STATE_1_0
			$hWind = HWnd($lParam)
			$lParam = $g_hFrmBot
			$wParam = DllStructGetPtr($tBotState)
			PrepareStructBotState($tBotState)
		Case 0x1000 ; start bot
			$hWind = HWnd($lParam)
			$lParam = $g_hFrmBot
			$wParam = $wParamLo + 1
			If $g_bRunState = False Then
				$wParamHi = 1
				If $g_bBotPaused = True Then $wParamHi += 2
				If Not $g_iBotLaunchTime = 0 Then $wParamHi += 4 ; bot launched
				btnStart()
			EndIf
			$wParam += BitShift($wParamHi, -16)

		Case 0x1010 ; stop bot
			$hWind = HWnd($lParam)
			$lParam = $g_hFrmBot
			$wParam = $wParamLo + 1
			If $g_bRunState = True Then
				$wParamHi = 0
				If $g_bBotPaused = True Then $wParamHi += 2
				If Not $g_iBotLaunchTime = 0 Then $wParamHi += 4 ; bot launched
				btnStop()
			EndIf
			$wParam += BitShift($wParamHi, -16)

		Case 0x1020 ; resume bot
			$hWind = HWnd($lParam)
			$lParam = $g_hFrmBot
			$wParam = $wParamLo + 1
			If $g_bBotPaused = True And $g_bRunState = True Then
				$wParamHi = 0
				If $g_bRunState = True Then $wParamHi += 1
				;If $g_bBotPaused = True Then $wParamHi += 2
				If Not $g_iBotLaunchTime = 0 Then $wParamHi += 4 ; bot launched
				TogglePauseImpl("ManageFarm")
			EndIf
			$wParam += BitShift($wParamHi, -16)

		Case 0x1030 ; pause bot
			$hWind = HWnd($lParam)
			$lParam = $g_hFrmBot
			$wParam = $wParamLo + 1
			If $g_bBotPaused = False And $g_bRunState = True Then
				$wParamHi = 2
				If $g_bRunState = True Then $wParamHi += 1
				;If $g_bBotPaused = True Then $wParamHi += 2
				If Not $g_iBotLaunchTime = 0 Then $wParamHi += 4 ; bot launched
				TogglePauseImpl("ManageFarm", True)
				#cs
					$wParam += BitShift($wParamHi, -16)
					_WinAPI_PostMessage($hWind, $iMsg, $wParam, $lParam)
					TogglePauseImpl("ManageFarm", True)
					;_Timer_SetTimer($g_hFrmBot, 25, "WM_MYBOTRUN_API_1_0_CLIENT_TogglePause")
					Return
				#ce
			EndIf
			$wParam += BitShift($wParamHi, -16)

		Case 0x1040 ; close bot
			$hWind = HWnd($lParam)
			$lParam = $g_hFrmBot
			$wParam = $wParamLo + 1
			$wParamHi = 0
			BotCloseRequest()
			$wParam += BitShift($wParamHi, -16)

		Case 0x1050 ; take photo
			$hWind = HWnd($lParam)
			$lParam = $g_hFrmBot
			$wParam = $wParamLo + 1
			$wParamHi = 0
			If $g_bRunState = True Then $wParamHi += 1
			If $g_bBotPaused = True Then $wParamHi += 2
			If Not $g_iBotLaunchTime = 0 Then $wParamHi += 4 ; bot launched
			btnMakeScreenshot()
			$wParam += BitShift($wParamHi, -16)

		Case Else ;Case 0x0000 ; query bot run and pause state
			If $wParam < 0x100 Then
				$hWind = HWnd($lParam)
				$lParam = $g_hFrmBot
				Local $iActiveBots = BitAND($wParam, 0xFF)
				If $iActiveBots < 255 Then
					If $g_BotInstanceCount <> $iActiveBots Then SetDebugLog($iActiveBots & " running bot instances detected")
					$g_BotInstanceCount = $iActiveBots
				EndIf
				$wParam = 1
				$wParamHi = 0
				If $g_bRunState = True Then $wParamHi += 1
				If $g_bBotPaused = True Then $wParamHi += 2
				If Not $g_iBotLaunchTime = 0 Then $wParamHi += 4 ; bot launched
				$wParam += BitShift($wParamHi, -16)
			EndIf
	EndSwitch

	If $hWind <> 0 Then
		Local $a = GetManagedMyBotHost($hWind, True)
		_WinAPI_PostMessage($hWind, $iMsg, $wParam, $lParam)
	EndIf

	Return 1

EndFunc   ;==>WM_MYBOTRUN_API_1_0_CLIENT

Func WM_MYBOTRUN_API_1_0_CLIENT_TogglePause($hWnd, $iMsg, $iIDTimer, $iTime)
	#forceref $hWnd, $iMsg, $iIDTimer, $iTime
	_Timer_KillTimer($hWnd, $iIDTimer)
	TogglePauseImpl("ManageFarm")
EndFunc   ;==>WM_MYBOTRUN_API_1_0_CLIENT_TogglePause

Func GetManagedMyBotHost($hFrmHost = Default, $bUpdateTime = False)

	If $hFrmHost = Default Then
		Return $g_ahManagedMyBotHosts
	EndIf

	If IsHWnd($hFrmHost) = 0 Then Return -1

	For $i = 0 To UBound($g_ahManagedMyBotHosts) - 1
		Local $a = $g_ahManagedMyBotHosts[$i]
		If $a[0] = $hFrmHost Then
			If $bUpdateTime Then
				$a[1] = __TimerInit()
				$g_ahManagedMyBotHosts[$i] = $a
			EndIf
			Return $a
		EndIf
	Next

	Local $i = UBound($g_ahManagedMyBotHosts)
	ReDim $g_ahManagedMyBotHosts[$i + 1]
	Local $a[2]
	$a[0] = $hFrmHost
	If $bUpdateTime Then $a[1] = __TimerInit()
	$g_ahManagedMyBotHosts[$i] = $a
	SetDebugLog("New Bot Host Window Handle registered: " & $hFrmHost)
	Return $a
EndFunc   ;==>GetManagedMyBotHost

Func LaunchWatchdog()
	Local $hMutex = CreateMutex($sWatchdogMutex)
	If $hMutex = 0 Then
		; already running
		SetDebugLog("Watchdog already running")
		Return 0
	EndIf
	ReleaseMutex($hMutex)
	Local $cmd = """" & @ScriptDir & "\MyBot.run.Watchdog.exe"""
	If @Compiled = 0 Then $cmd = """" & @AutoItExe & """ /AutoIt3ExecuteScript """ & @ScriptDir & "\MyBot.run.Watchdog.au3" & """"
	Local $pid = Run($cmd, @ScriptDir, @SW_HIDE)
	If $pid = 0 Then
		SetLog("Cannot launch watchdog", $COLOR_RED)
		Return 0
	EndIf
	If $g_bDebugSetlog Then
		SetDebugLog("Watchdog launched, PID = " & $pid)
	Else
		SetLog("Watchdog launched")
	EndIf
	Return $pid
EndFunc   ;==>LaunchWatchdog

Func PrepareStructBotState(ByRef $tBotState, $eStructType = $g_eSTRUCT_NONE, $pStructPtr = 0)
	DllStructSetData($tBotState, "BotHWnd", $g_hFrmBot) ; Bot Main Window Handle
	DllStructSetData($tBotState, "AndroidHWnd", $g_hAndroidWindow) ; Android Window Handle
	DllStructSetData($tBotState, "RunState", $g_bRunState) ; Boolean
	DllStructSetData($tBotState, "Paused", $g_bBotPaused) ; Boolean
	DllStructSetData($tBotState, "Launched", Not $g_iBotLaunchTime = 0) ; Boolean
	DllStructSetData($tBotState, "Profile", $g_sProfileCurrentName) ; String
	DllStructSetData($tBotState, "AndroidEmulator", $g_sAndroidEmulator) ; String
	DllStructSetData($tBotState, "AndroidInstance", $g_sAndroidInstance) ; String
	DllStructSetData($tBotState, "StructType", $eStructType)
	DllStructSetData($tBotState, "StructPtr", $pStructPtr)
EndFunc   ;==>PrepareStructBotState

Func PrepareStatusBarManagedMyBotHost($hFrmHost, ByRef $iMsg, ByRef $wParam, ByRef $lParam, $sStatusBar)
	$iMsg = $WM_MYBOTRUN_STATE_1_0
	$lParam = $g_hFrmBot
	$wParam = DllStructGetPtr($tBotState)
	DllStructSetData($tStatusBar, "Text", $sStatusBar)
	PrepareStructBotState($tBotState, $g_eSTRUCT_STATUS_BAR, DllStructGetPtr($tStatusBar))
	;If $g_iDebugWindowMessages Then
	If $g_iDebugWindowMessages Then SetDebugLog("PrepareStatusBarManagedMyBotHost: $hFrmHost=" & $hFrmHost & ",$iMsg=" & $iMsg & ",$wParam=" & $wParam & ",$lParam=" & $lParam & ",$sStatusBar=" & $sStatusBar)
	Return True
EndFunc   ;==>PrepareStatusBarManagedMyBotHost

Func StatusBarManagedMyBotHost($sStatusBar)
	Return ManagedMyBotHostsPostMessage("PrepareStatusBarManagedMyBotHost", $sStatusBar)
EndFunc   ;==>StatusBarManagedMyBotHost

Func PrepareUnregisterManagedMyBotHost($hFrmHost, ByRef $iMsg, ByRef $wParam, ByRef $lParam)
	$iMsg = $WM_MYBOTRUN_API_1_0
	$wParam = 0x1040 + 2
	$lParam = $g_hFrmBot
	SetDebugLog("Bot Host Window Handle un-registered: " & $hFrmHost)
	Return True
EndFunc   ;==>PrepareUnregisterManagedMyBotHost

Func UnregisterManagedMyBotHost()
	Local $Result = ManagedMyBotHostsPostMessage("PrepareUnregisterManagedMyBotHost")
	ReDim $g_ahManagedMyBotHosts[0]
	Return $Result
EndFunc   ;==>UnregisterManagedMyBotHost

Func ManagedMyBotHostsPostMessage($sExecutePrepare, $Value1 = Default, $Value2 = Default, $Value3 = Default)
	Local $sAdditional = ""
	If $Value1 <> Default Or $Value2 <> Default Or $Value3 <> Default Then
		If $Value3 <> Default Then
			$sAdditional = ", $Value3"
		EndIf
		If $Value2 <> Default Then
			$sAdditional = ", $Value2" & $sAdditional
		ElseIf $sAdditional <> "" Then
			$sAdditional = ", Default" & $sAdditional
		EndIf
		If $Value1 <> Default Then
			$sAdditional = ", $Value1" & $sAdditional
		ElseIf $sAdditional <> "" Then
			$sAdditional = ", Default" & $sAdditional
		EndIf
	EndIf
	For $i = 0 To UBound($g_ahManagedMyBotHosts) - 1
		Local $a = $g_ahManagedMyBotHosts[$i]
		Local $hFrmHost = $a[0]
		$g_ahManagedMyBotHosts[$i] = $a
		If IsHWnd($hFrmHost) Then
			Local $iMsg = $WM_MYBOTRUN_API_1_0
			Local $wParam = 0x0000
			Local $lParam = $g_hFrmBot
			Local $sExecute = $sExecutePrepare & "($hFrmHost, $iMsg, $wParam, $lParam" & $sAdditional & ")"
			Local $bPostMessage = Execute($sExecute)
			If @error <> 0 And $bPostMessage = "" Then
				SetDebugLog("ManagedMyBotHostsPostMessage: Error executing " & $sExecute)
			ElseIf $bPostMessage = False Then
				If $g_iDebugWindowMessages Then SetDebugLog("ManagedMyBotHostsPostMessage: Not posting message to " & $hFrmHost)
			Else
				If $g_iDebugWindowMessages Then SetDebugLog("ManagedMyBotHostsPostMessage: Posting message to " & $hFrmHost)
				_WinAPI_PostMessage($hFrmHost, $iMsg, $wParam, $lParam)
			EndIf
		EndIf
	Next
EndFunc   ;==>ManagedMyBotHostsPostMessage

Func _GUICtrlStatusBar_SetTextEx($hWnd, $sText = "", $iPart = 0, $iUFlag = 0)
	If $hWnd Then _GUICtrlStatusBar_SetText($hWnd, $sText, $iPart, $iUFlag)
	StatusBarManagedMyBotHost($sText)
EndFunc   ;==>_GUICtrlStatusBar_SetTextEx

Func ReferenceApiClientFunctions()
	If True Then Return
	Local $hFrmHost = 0
	Local $iMsg = 0
	Local $wParam = 0
	Local $lParam = 0
	PrepareStatusBarManagedMyBotHost($hFrmHost, $iMsg, $wParam, $lParam, "")
EndFunc   ;==>ReferenceApiClientFunctions

ReferenceApiClientFunctions()
