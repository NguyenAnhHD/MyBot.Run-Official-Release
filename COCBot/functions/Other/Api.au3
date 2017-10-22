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

Global $sWatchdogMutex = "MyBot.run/ManageFarm"
Global $tagSTRUCT_BOT_STATE = "struct;hwnd BotHWnd;hwnd AndroidHWnd;boolean RunState;boolean Paused;boolean Launched;char Profile[64];char AndroidEmulator[32];char AndroidInstance[32];int StructType;ptr StructPtr;endstruct"
Global Enum $g_eSTRUCT_NONE = 0, $g_eSTRUCT_STATUS_BAR, $g_eSTRUCT_UPDATE_STATS
Global $tagSTRUCT_STATUS_BAR = "struct;char Text[255];endstruct"
Global $tagSTRUCT_UPDATE_STATS = "struct;" & _
									"LONG g_aiCurrentLoot[" & UBound($g_aiCurrentLoot) & "]" & _
									";LONG g_iFreeBuilderCount" & _
									";LONG g_iTotalBuilderCount" & _
									";LONG g_iGemAmount" & _
									";LONG g_iStatsTotalGain[" & UBound($g_iStatsTotalGain) & "]" & _
									";LONG g_iStatsLastAttack[" & UBound($g_iStatsLastAttack) & "]" & _
									";LONG g_iStatsBonusLast[" & UBound($g_iStatsBonusLast) & "]" & _
								";endstruct"
Global $tBotState = DllStructCreate($tagSTRUCT_BOT_STATE)
Global $tStatusBar = DllStructCreate($tagSTRUCT_STATUS_BAR)
Global $tUpdateStats = DllStructCreate($tagSTRUCT_UPDATE_STATS)
Global $WM_MYBOTRUN_API_1_0 = _WinAPI_RegisterWindowMessage("MyBot.run/API/1.1")
;SetDebugLog("MyBot.run/API/1.0 Message = " & $WM_MYBOTRUN_API_1_0)
Global $WM_MYBOTRUN_STATE_1_0 = _WinAPI_RegisterWindowMessage("MyBot.run/STATE/1.1")
;SetDebugLog("MyBot.run/STATE/1.0 Message = " & $WM_MYBOTRUN_STATE_1_0)

Func _DllStructSetData(ByRef $Struct, $Element, $value, $index = Default)
	If IsArray($value) Then
		Local $Result[UBound($value)]
		For $i = 0 To UBound($value) - 1
			$Result[$i] = DllStructSetData($Struct, $Element, $value[$i], $i + 1)
		Next
		Return $Result
	Else
		Return DllStructSetData($Struct, $Element, $value, $index)
	EndIf
EndFunc

Func _DllStructLoadData(ByRef $Struct, $Element, ByRef $value)
	If IsArray($value) Then
		For $i = 0 To UBound($value) - 1
			$value[$i] = DllStructGetData($Struct, $Element, $i + 1)
		Next
		Return 1
	Else
		$value = DllStructGetData($Struct, $Element)
		Return 0
	EndIf
EndFunc

