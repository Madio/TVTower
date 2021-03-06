﻿Function RegisterRoomHandlers()
	'=== (re-)initialize all known room handlers
	RoomHandler_Office.GetInstance().RegisterHandler()
	RoomHandler_News.GetInstance().RegisterHandler()
	RoomHandler_Boss.GetInstance().RegisterHandler()
	RoomHandler_Archive.GetInstance().RegisterHandler()
	RoomHandler_Studio.GetInstance().RegisterHandler()

	RoomHandler_AdAgency.GetInstance().RegisterHandler()
	RoomHandler_ScriptAgency.GetInstance().RegisterHandler()
	RoomHandler_MovieAgency.GetInstance().RegisterHandler()
	RoomHandler_RoomAgency.GetInstance().RegisterHandler()

	RoomHandler_Betty.GetInstance().RegisterHandler()

	RoomHandler_ElevatorPlan.GetInstance().RegisterHandler()
	RoomHandler_Roomboard.GetInstance().RegisterHandler()

	RoomHandler_Supermarket.GetInstance().RegisterHandler()

	RoomHandler_Credits.GetInstance().RegisterHandler()
End Function



Include "game.screen.stationmap.bmx"
Include "game.screen.programmeplanner.bmx"
Include "game.screen.financials.bmx"
Include "game.screen.statistics.bmx"

'Office: handling the players room
Type RoomHandler_Office extends TRoomHandler
	'=== OFFICE ROOM ===
	Global StationsToolTip:TTooltip
	Global PlannerToolTip:TTooltip
	Global SafeToolTip:TTooltip

	Global _instance:RoomHandler_Office
	Global _initDone:int = False
	Global _eventListeners:TLink[]


	Function GetInstance:RoomHandler_Office()
		if not _instance then _instance = new RoomHandler_Office
		return _instance
	End Function

	
	Method Initialize:Int()
		'=== RESET TO INITIAL STATE ===
		CleanUp()


		'reset/initialize screens (event connection etc.)
		TScreenHandler_Financials.Initialize()
		TScreenHandler_ProgrammePlanner.Initialize()
		TScreenHandler_StationMap.Initialize()
		TScreenHandler_Statistics.Initialize()		
		TScreenHandler_OfficeAchievements.GetInstance().Initialize()		


		'=== REGISTER HANDLER ===
		RegisterHandler()


		'=== EVENTS ===
		'=== remove all registered event listeners
		EventManager.unregisterListenersByLinks(_eventListeners)
		_eventListeners = new TLink[0]

		'=== register event listeners
		'handle the "office" itself (not computer etc)
		'using this approach avoids "tooltips" to be visible in subscreens
		_eventListeners :+ _RegisterScreenHandler( onUpdateOffice, onDrawOffice, ScreenCollection.GetScreen("screen_office") )

		'(re-)localize content
		'disabled as the screens are setting their language during "initialize()"
		'too.
		'reenable if doing more localization there
		'SetLanguage()
	End Method


	Method CleanUp()
		'=== unset cross referenced objects ===
		StationsToolTip = null
		PlannerToolTip = null
		SafeToolTip = null

		'=== remove obsolete gui elements ===
		'
		
		'=== remove all registered instance specific event listeners
		'EventManager.unregisterListenersByLinks(_localEventListeners)
		'_localEventListeners = new TLink[0]
	End Method


	Method RegisterHandler:int()
		if GetInstance() <> self then self.CleanUp()
		GetRoomHandlerCollection().SetHandler("office", GetInstance())
	End Method


	Method SetLanguage()
		TScreenHandler_Financials.SetLanguage()
		TScreenHandler_ProgrammePlanner.SetLanguage()
		TScreenHandler_StationMap.SetLanguage()
		TScreenHandler_Statistics.SetLanguage()
		TScreenHandler_OfficeAchievements.GetInstance().SetLanguage()
	End Method


	'override: clear the screen (remove dragged elements)
	Method AbortScreenActions:Int()
		'abort handling dragged elements in the planner
		TScreenHandler_ProgrammePlanner.AbortScreenActions()

		return False
	End Method


	Method onDrawRoom:int( triggerEvent:TEventBase )
		'
	End Method


	Method onUpdateRoom:int( triggerEvent:TEventBase )
		'
	End Method


	Function onDrawOffice:int( triggerEvent:TEventBase )
		'local screen:TScreen	= TScreen( triggerEvent._sender )
		local room:TRoom = TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0

		'if room.GetBackground() then room.GetBackground().draw(0, 0)

		'allowed for owner only - or with key
		If GetPlayer().HasMasterKey() OR IsPlayersRoom(room)
			If StationsToolTip Then StationsToolTip.Render()
			'allowed for all - if having keys
			If PlannerToolTip Then PlannerToolTip.Render()

			If SafeToolTip Then SafeToolTip.Render()
		EndIf
	End Function


	Function onUpdateOffice:int( triggerEvent:TEventBase )
		local room:TRoom = TRoom( triggerEvent.GetData().get("room") )
		if not room then return 0


		GetPlayer().GetFigure().fromroom = Null
		If MOUSEMANAGER.IsClicked(1)
			'emulated right click or clicked door
			If MOUSEMANAGER.IsLongClicked(1) or THelper.MouseIn(25,40,150,295)
				GetPlayer().GetFigure().LeaveRoom()
				MOUSEMANAGER.resetKey(1)
			EndIf
		EndIf


		'allowed for owner only - or with key
		If GetPlayer().HasMasterKey() OR IsPlayersRoom(room)
			GetGameBase().cursorstate = 0

			'only if player does not want to leave room
			if not MouseManager.IsLongClicked(1)
				'safe - reachable for all
				If THelper.MouseIn(165,85,70,100)
					If not SafeToolTip Then SafeToolTip = TTooltip.Create(GetLocale("ROOM_SAFE"), GetLocale("FOR_PRIVATE_AFFAIRS"), 140, 100,-1,-1)
					SafeToolTip.enabled = 1
					SafeToolTip.SetMinTitleAndContentWidth(90, 120)
					SafeToolTip.Hover()
					GetGameBase().cursorstate = 1
					If MOUSEMANAGER.IsClicked(1)
						MOUSEMANAGER.resetKey(1)
						GetGameBase().cursorstate = 0

						ScreenCollection.GoToSubScreen("screen_office_safe")
					endif
				EndIf

				'planner - reachable for all
				If THelper.MouseIn(600,140,128,210)
					If not PlannerToolTip
						PlannerToolTip = TTooltip.Create(GetLocale("ROOM_PROGRAMMEPLANNER"), GetLocale("AND_STATISTICS"), 580, 140)
						PlannerTooltip._minContentWidth = 150
					endif
					PlannerToolTip.enabled = 1
					PlannerToolTip.Hover()
					GetGameBase().cursorstate = 1
					If MOUSEMANAGER.IsClicked(1)
						MOUSEMANAGER.resetKey(1)
						GetGameBase().cursorstate = 0
						ScreenCollection.GoToSubScreen("screen_office_programmeplanner")
					endif
				EndIf

				If THelper.MouseIn(732,45,160,170)
					If not StationsToolTip
						StationsToolTip = TTooltip.Create(GetLocale("ROOM_STATIONMAP"), GetLocale("BUY_AND_SELL"), 650, 80, 0, 0)
						StationsToolTip._minContentWidth = 150
					endif
						
					StationsToolTip.enabled = 1
					StationsToolTip.Hover()
					GetGameBase().cursorstate = 1
					If MOUSEMANAGER.IsClicked(1)
						MOUSEMANAGER.resetKey(1)
						GetGameBase().cursorstate = 0
						ScreenCollection.GoToSubScreen("screen_office_stationmap")
					endif
				EndIf
			endif

			If StationsToolTip Then StationsToolTip.Update()
			If PlannerToolTip Then PlannerToolTip.Update()
			If SafeToolTip Then SafeToolTip.Update()
		EndIf
	End Function
End Type


'Chief: credit and emmys - your boss :D
Type RoomHandler_Boss extends TRoomHandler
	'smoke effect
	Global smokeEmitter:TSpriteParticleEmitter

	Global _instance:RoomHandler_Boss
	Global _initDone:int = False


	Function GetInstance:RoomHandler_Boss()
		if not _instance then _instance = new RoomHandler_Boss
		return _instance
	End Function


	Method Initialize:int()
		'=== RESET TO INITIAL STATE ===
		CleanUp()


		'=== REGISTER HANDLER ===
		RegisterHandler()


		'=== CREATE ELEMENTS ===
		if not smokeEmitter
			local smokeConfig:TData = new TData
			smokeConfig.Add("sprite", GetSpriteFromRegistry("gfx_misc_smoketexture"))
			smokeConfig.AddNumber("velocityMin", 25)
			smokeConfig.AddNumber("velocityMax", 40)
			smokeConfig.AddNumber("lifeMin", 0.3)
			smokeConfig.AddNumber("lifeMax", 2.5)
			smokeConfig.AddNumber("scaleMin", 0.2)
			smokeConfig.AddNumber("scaleMax", 0.3)
			smokeConfig.AddNumber("scaleRate", 1.2)
			smokeConfig.AddNumber("alphaMin", 0.5)
			smokeConfig.AddNumber("alphaMax", 0.8)
			smokeConfig.AddNumber("alphaRate", -0.90)
			smokeConfig.AddNumber("angleMin", 165)
			smokeConfig.AddNumber("angleMax", 195)
			smokeConfig.AddNumber("xRange", 2)
			smokeConfig.AddNumber("yRange", 2)

			local emitterConfig:TData = new TData
			emitterConfig.Add("area", new TRectangle.Init(44, 335, 0, 0))
			emitterConfig.AddNumber("particleLimit", 70)
			emitterConfig.AddNumber("spawnEveryMin", 0.45)
			emitterConfig.AddNumber("spawnEveryMax", 0.70)

			smokeEmitter = new TSpriteParticleEmitter.Init(emitterConfig, smokeConfig)
		endif
	End Method


	Method CleanUp()
		'
	End Method


	Method RegisterHandler:int()
		if GetInstance() <> self then self.CleanUp()
		GetRoomHandlerCollection().SetHandler("boss", GetInstance())
	End Method
	

	Method onDrawRoom:int( triggerEvent:TEventBase )
		smokeEmitter.Draw()

		local room:TRoom = TRoom(triggerEvent.GetSender())
		'only handle custom elements for players room
		'if room.owner <> GetPlayerCollection().playerID then return FALSE


		local boss:TPlayerBoss = GetPlayerBoss(room.owner)
		if not boss then return False
		For Local dialog:TDialogue = EachIn boss.Dialogues
			dialog.Draw()
		Next
	End Method


	Method onUpdateRoom:int( triggerEvent:TEventBase )
		GetPlayer().GetFigure().fromroom = Null

		smokeEmitter.Update()

		local room:TRoom = TRoom(triggerEvent._sender)
		'only handle custom elements for players room
		'if room.owner <> GetPlayerCollection().playerID then return FALSE

		
		local boss:TPlayerBoss = GetPlayerBoss(room.owner)
		if not boss then return False


		'generate the dialogue if not done yet (and not just leaving)
		if boss.Dialogues.Count() <= 0 and ..
		   not GetPlayerBase().GetFigure().isLeavingRoom() and ..
		   GetPlayerBase().GetFigure().GetInRoomID() > 0

			boss.GenerateDialogues(GetPlayer().playerID)
		endif

		For Local dialog:TDialogue = EachIn boss.Dialogues
			If dialog.Update() = 0
				GetPlayer().GetFigure().LeaveRoom()
				boss.Dialogues.Remove(dialog)
			endif
		Next
	End Method
End Type





