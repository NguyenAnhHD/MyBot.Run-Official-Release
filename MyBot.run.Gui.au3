; #FUNCTION# ====================================================================================================================
; Name ..........: MBR Bot Gui only
; Description ...: This file contains the initialization and main loop sequences f0r the MBR Bot
; Author ........:  (2014)
; Modified ......:
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2017
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================

; AutoIt pragmas
#RequireAdmin
#AutoIt3Wrapper_UseX64=7n
;#AutoIt3Wrapper_Res_HiDpi=Y ; HiDpi will be set during run-time!
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/rsln /MI=3
;/SV=0

;#AutoIt3Wrapper_Change2CUI=y
;#pragma compile(Console, true)
#include "MyBot.run.version.au3"
#pragma compile(ProductName, My Bot)
#pragma compile(Out, MyBot.run.Gui.exe) ; Required

; Enforce variable declarations
Opt("MustDeclareVars", 1)

Global $g_sBotTitle = "" ;~ Don't assign any title here, use Func UpdateBotTitle()
Global $g_hFrmBot = 0 ; The main GUI window

; MBR includes
#include "COCBot\MBR Global Variables.au3"

; Autoit Options
Opt("GUIResizeMode", $GUI_DOCKALL) ; Default resize mode for dock android support
Opt("GUIEventOptions", 1) ; Handle minimize and restore for dock android support
Opt("GUICloseOnESC", 0) ; Don't send the $GUI_EVENT_CLOSE message when ESC is pressed.
Opt("WinTitleMatchMode", 3) ; Window Title exact match mode
Opt("GUIOnEventMode", 1)
Opt("MouseClickDelay", 10)
Opt("MouseClickDownDelay", 10)
Opt("TrayMenuMode", 3)
Opt("TrayOnEventMode", 1)

