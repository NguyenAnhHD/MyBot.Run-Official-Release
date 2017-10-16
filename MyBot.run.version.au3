﻿; #FUNCTION# ====================================================================================================================
; Name ..........: MBR Bot Version
; Description ...: This file contains the initialization and main loop sequences f0r the MBR Bot
; Author ........:  (2014)
; Modified ......:
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2017
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================

; AutoIt version pragmas
#pragma compile(Icon, "Images\MyBot.ico")
#pragma compile(FileDescription, Clash of Clans Bot - A Free Clash of Clans bot - https://mybot.run)
#pragma compile(ProductVersion, 7.2.6)
#pragma compile(FileVersion, 7.2.6)
#pragma compile(LegalCopyright, © https://mybot.run)

Global $g_sBotVersion = "v7.2.6" ;~ Don't add more here, but below. Version can't be longer than vX.y.z because it is also use on Checkversion()