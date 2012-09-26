'Basictype of all rooms
'Basictyp aller Raeume
Type TRooms
    Field background:TGW_Sprites       	'background, the image containing the whole room
	Field name:String            		'name of the room, eg. "archive" for archive room
    Field desc:String					'description, eg. "Bettys bureau" (used for tooltip)
    Field descTwo:String		=""		'description, eg. "name of the owner" (used for tooltip)
    Field DoorOpenTimer:Int		= 0
	Field DoorOpenTime:int		= 250
	Field Pos:TPosition					'x of the rooms door in the building, y as floornumber
    Field xpos:Int				= 0
    Field doortype:Int			=-1
    Field doorwidth:Int			= 38
    Field RoomSign:TRoomSigns
    Field owner:Int				=-1		'to draw the logo/symbol of the owner
    Field tooltip:TTooltip
    Field uniqueID:Int			= 1
	Field FadeAnimationActive:Int = 0
	Field RoomBoardX:Int		= 0
    Global ActiveRoom:TRooms			'which room is activated at the moment
    Global RoomList:TList				'global list of rooms
    Global LastID:Int			= 1
	Global doadraw:Int			= 0
	Global DoorsDrawnToBackground:Int = 0   'doors drawn to Pixmap of background
    Global ActiveBackground:TGW_Sprites
	Global ActiveBackgroundID:Int = 0
	Field Dialogues:TList = CreateList()

    Function ResetRoomSigns()
		For Local room:TRooms = EachIn TRooms.RoomList
			If room.RoomSign <> Null
				Room.RoomSign.Pos.SetPos(room.RoomSign.OrigPos)
				Room.RoomSign.StartPos.SetPos(room.RoomSign.OrigPos)
				room.RoomSign.dragged		= 0
			End If
		Next
		TRoomSigns.AdditionallyDragged = 0
    End Function

    'delete Room out of RoomList
    'Raum aus der Raumliste entfernen
    Method RemoveRoom()
		ListRemove RoomList,(Self)
    End Method

    Method CloseDoor()
		DoorOpenTimer = 0
    End Method

	Method getDoorType:int()
		if DoorOpenTimer = 0 then return self.doortype else return 5
	End Method

    Method OpenDoor()
		DoorOpenTimer = MilliSecs()+DoorOpenTime
    End Method

	Function CloseAllDoors()
		For Local room:TRooms = EachIn TRooms.RoomList
			room.CloseDoor()
		Next
	End Function

    Function DrawDoorToolTips:Int()
		If RoomList = Null Then Print "RoomList missing"
		For Local localroom:TRooms = EachIn RoomList
			If localroom <> Null
				If localroom.tooltip <> Null
					If localroom.tooltip.enabled Then localroom.tooltip.Draw()
				EndIf
    		EndIf
		Next
	End Function

    Function UpdateDoorToolTips:Int(deltaTime:float)
		Local foundtooltip:Int = 0
		For Local localroom:TRooms = EachIn RoomList
			foundtooltip = 0
			If localroom <> Null
				If localroom.tooltip <> Null
					If localroom.tooltip.enabled
						localroom.tooltip.pos.y = Building.pos.y + Building.GetFloorY(localroom.Pos.y) - Assets.GetSprite("gfx_building_Tueren").h - 20
						localroom.tooltip.Update(deltaTime)
					EndIf
				EndIf


				If foundtooltip = 0 And Players[Game.playerID].Figure.inRoom = Null And functions.IsIn(MouseX(), MouseY(), localroom.Pos.x, Building.pos.y + Building.GetFloorY(localroom.Pos.y) - Assets.GetSprite("gfx_building_Tueren").h, localroom.doorwidth, 54)
					If localroom.tooltip = Null
						localroom.tooltip = TTooltip.Create(localroom.desc, localroom.descTwo, 100, 140, 0, 0)
					else
						localroom.tooltip.Hover()
					endif
					localroom.tooltip.pos.y = Building.pos.y + Building.GetFloorY(localroom.Pos.y) - Assets.GetSprite("gfx_building_Tueren").h - 20
					localroom.tooltip.pos.x = localroom.Pos.x + localroom.doorwidth/2 - localroom.tooltip.GetWidth()/2
					localroom.tooltip.enabled = 1
					If localroom.name = "chief" Then localroom.tooltip.tooltipimage = 2
					If localroom.name = "news" Then localroom.tooltip.tooltipimage = 4
					If localroom.name = "archive" Then localroom.tooltip.tooltipimage = 0
					If localroom.name = "office" Then localroom.tooltip.tooltipimage = 1
					If (localroom.name.Find("studio",0)+1) =1 Then localroom.tooltip.tooltipimage = 5
					If localroom.owner >= 1 Then localroom.tooltip.TitleBGtype = localroom.owner + 10
					foundtooltip = 1
				EndIf
			EndIf
		Next
    End Function

	Function DrawDoorsOnBackground:Int()
	  If Not DoorsDrawnToBackground
	    Local gfx_building_elevator_border:TImage = Assets.GetSprite("gfx_building_Fahrstuhl_Rahmen").GetImage()
	    Local Pix:TPixmap = LockImage(Assets.GetSprite("gfx_building").parent.image)

		'fahrstuhlrahmen
	  	For Local i:Int = 0 To 13
			DrawOnPixmap(gfx_building_elevator_border, 0, Pix, 230, 67 - ImageHeight(gfx_building_elevator_border) + 73 * i)
	  	Next

	    For Local localroom:TRooms = EachIn RoomList
          If localroom <> Null
            If localroom.doortype >= 0 And localroom.Pos.x > 0
              If localroom.doortype > 5 Then localroom.doortype=5
              If localroom.name <> "roomboard" And localroom.name <> "credits" And localroom.name <> "porter"
				DrawOnPixmap(Assets.GetSprite("gfx_building_Tueren").GetFrameImage(localroom.doortype), 0, Pix, localroom.Pos.x - Building.pos.x - 127, Building.GetFloorY(localroom.Pos.y) - Assets.GetSprite("gfx_building_Tueren").h)
				If localroom.owner < 5 And localroom.owner >=0
					DrawOnPixmap(Assets.GetSprite("gfx_building_sign"+localroom.owner).parent.image , 0, Pix, localroom.Pos.x - Building.pos.x - 127 + 2 + Assets.GetSprite("gfx_building_Tueren").framew, Building.GetFloorY(localroom.Pos.y) - Assets.GetSprite("gfx_building_Tueren").h)
				EndIf
           EndIf
            EndIf
          EndIf
        Next
		UnlockImage(Assets.GetSprite("gfx_building").parent.image)
'		gfx_building_skyscraper.CreateFromPixmap(Pix)
		DoorsDrawnToBackground = True
      EndIf

	End Function

	Function DrawDoors:Int()
		If RoomList = Null Then Print "RoomList missing"
		For Local room:TRooms = EachIn RoomList
			If room <> Null
				If room.doortype >= 0 And room.name <> "" And room.Pos.x > 0
					If room.getDoorType() >= 5 And room.name <> "roomboard" And room.name <> "credits" And room.name <> "porter"
						If room.getDoorType() = 5 AND room.DoorOpenTimer + 500 < MilliSecs() Then room.CloseDoor()
						'valign = 1 -> subtract sprite height
						Assets.GetSprite("gfx_building_Tueren").Draw(room.Pos.x, Building.pos.y + Building.GetFloorY(room.Pos.y), room.getDoorType(), VALIGN_TOP)
					EndIf
				EndIf
			EndIf
		Next
		'if game.debugmode Print "GAME: finished TRooms.drawDoors"
    End Function

    'draw Room
    'Raum zeichnen
    Method Draw()
		SetBlend SOLIDBLEND
		If background = Null
			Print "ERROR: room.draw() - background missing"
		Else
			If ActiveBackground = Null OR ActiveBackgroundID <> Self.uniqueID
				ActiveBackground = Self.background
				ActiveBackgroundID = Self.uniqueID
			EndIf
			ActiveBackground.Draw(20,10)
		EndIf
		SetBlend ALPHABLEND
		ActiveRoom = Self
	End Method

	'leave with Open/close-animation (black)
	Method LeaveAnimated:Int(dontleave:Int)
        If Self.name = "roomboard" Then If TRoomSigns.AdditionallyDragged > 0 Then dontleave = True
        If Self.name = "adagency"    Then TContractBlock.ContractsToPlayer(Game.playerID)
        If Self.name = "movieagency" Then TMovieAgencyBlocks.ProgrammeToPlayer(Game.playerID)
        If Self.name = "archive" Then TArchiveProgrammeBlock.ProgrammeToSuitcase(Game.playerID)
        If Not dontleave Then
			If GetDoorType() >= 0
				Fader.Enable() 'room fading
				OpenDoor()
				FadeAnimationActive = True
			Else
				CloseDoor()
 			    Players[Game.playerID].Figure.LeaveRoom()
			EndIf
		EndIf
		Return dontleave
	End Method

    'process special functions of this room. Is there something to click on?
    'animated gimmicks? draw within this function.
    'spezielle Funktionen des Raumes abarbeiten/zeichnen. Kann man darin
    'was anklicken? Animierte Gimmicks? Hier zeichnen.
    Method Update:Int(draw:Byte=0)
	  TRooms.doadraw = Draw
	  If Fader.fadeenabled And FadeAnimationActive
  			If Fader.fadecount >= 20 And Fader.fadeout = False
				Fader.EnableFadeout()
				CloseDoor()
				FadeAnimationActive = False
 			    Players[Game.playerID].Figure.LeaveRoom()
				Return 0
			EndIf
	  End If
      If MOUSEMANAGER.IsDown(2)
		Local dontleave:Int = Self.LeaveAnimated(0)
        If Not dontleave Then MOUSEMANAGER.resetKey(2)
      EndIf
	  Select Self.name
	     Case "betty" Room_Betty_Compute(Self) ;Return 0
	     Case "office" Room_Office_Compute(Self) ;Return 0
	     Case "archive" Room_Archive_Compute(Self) ;Return 0
	     Case "safe" Room_Safe_Compute(Self) ;Return 0
	     Case "elevator" Room_Elevator_Compute(Self) ;Return 0
	     Case "roomboard" Room_RoomBoard_Compute(Self) ;Return 0
	     Case "movieagency" Room_MovieAgency_Compute(Self) ;Return 0
	     Case "movieauction" Room_MovieAuction_Compute(Self) ;Return 0
	     Case "adagency" Room_AdAgency_Compute(Self) ;Return 0
	     Case "financials" Room_Financials_Compute(Self) ;Return 0
	     Case "image" Room_Image_Compute(Self) ;Return 0
	     Case "chief" Room_Chief_Compute(Self) ;Return 0
	     Case "stationmap" Room_StationMap_Compute(Self) ;Return 0
	     Case "newsplanner" Room_NewsPlanner_Compute(Self) ;Return 0
	     Case "programmeplanner" Room_ProgrammePlanner_Compute(Self) ;Return 0
	     Case "news" Room_News_Compute(Self) ;Return 0
	  End Select
	 Players[game.playerID].figure.fromroom = Null
    End Method

    'draw actual room
    'aktuellen Raum zeichnen
    Method DrawActiveOne()
      If ActiveRoom <> Null
        If not RoomList Print "ERROR: no RoomList";Return       'aufhoeren wenn keine Liste vorhanden
    '    For Local room:TRooms= EachIn RoomList
    '      If ActiveRoom = room.name
            If ActiveRoom.background = Null
				Print "ERROR: missing ActiveRoom.background"
            Else
				activeRoom.background.Draw(20, 10)
			EndIf
			'DrawImage(ActiveRoom.background, 20,10,0)
            ActiveRoom.Update()
        '  EndIf
        'Next
      EndIf
    End Method

    'create room and use preloaded image
    'Raum erstellen und bereits geladenes Bild nutzen
    'x = 1-4
    'y = floor
	Function Create:TRooms(background:TGW_Sprites, name:String = "unknown", desc:String = "unknown", descTwo:String = "", x:Int = 0, y:Int = 0, doortype:Int = -1, owner:Int = -1, createATooltip:Int = 0)
		Local obj:TRooms	= New TRooms
		obj.background 	= background
		obj.name		= name
		obj.desc		= desc
		obj.descTwo		= descTwo
		obj.owner		= owner
		obj.doorwidth	= Assets.GetSprite("gfx_building_Tueren").framew
		obj.uniqueID	= TRooms.LastID + 1
		obj.LastID:+1
		obj.xpos		= x
		obj.Pos			= TPosition.Create()
		If x <=4
			If x = 0 Then obj.Pos.x = -10
			If x = 1 Then obj.Pos.x = 206
			If x = 2 Then obj.Pos.x = 293
			If x = 3 Then obj.Pos.x = 469
			If x = 4 Then obj.Pos.x = 557
		EndIf
		obj.RoomBoardX = x
		obj.Pos.y = y
		obj.doortype = doortype

		If not RoomList Then RoomList = CreateList()
		RoomList.AddLast(obj)
		SortList RoomList

		If createATooltip
			obj.CreateTooltip(x)
		EndIf
		Return obj
	End Function

	Method CreateTooltip(myx:Int = 0)
		If doortype >= 0
	       	Local signx:Int = Self.RoomBoardX
	       	Local signy:Int = 0
	       	If signx <= 4 Then
	       	  If signx = 1 Then signx = 26
	  	      If signx = 2 Then signx = 208
		      If signx = 3 Then signx = 417
		      If signx = 4 Then signx = 599
	        EndIf
	        signy = 41 + (13 - Pos.y) * 23
	        RoomSign = TRoomSigns.Create(desc, signx, signy, owner)
		EndIf
	End Method

    'create room and use preloaded image
    'Raum erstellen und bereits geladenes Bild nutzen
	Function CreateWithPos:TRooms(background:TGW_Sprites, name:String = "unknown", desc:String = "unknown", x:Int = 0, xpos:Int = 0, width:Int = 0, y:Int = 0, doortype:Int = -1, owner:Int = -1, createATooltip:Int = 0)
	  Local tmproom:TRooms=New TRooms
	  tmproom.background = background
	  tmproom.name       = name
	  tmproom.desc       = desc
	  tmproom.owner      = owner
	  tmproom.doorwidth  = width
	  TRooms.LastID:+1
	  tmproom.uniqueID = TRooms.LastID
	  tmproom.xpos = xpos
	  tmproom.Pos = TPosition.Create()
	  tmproom.Pos.SetXY(x, y)

	  tmproom.doortype = doortype

	  If not RoomList Then RoomList = CreateList()
	  RoomList.AddLast(tmproom)
	  SortList RoomList
	  tmproom.RoomBoardX = tmproom.xpos

	  If CreateAToolTip
	  	tmproom.CreateToolTip(xpos)
	  EndIf

	  Return tmproom
	End Function

    Function GetTargetRoom:TRooms(x:int, y:int)
		For Local room:TRooms = EachIn TRooms.RoomList
			If room.doortype >= 0
				If room.name = "roomboard" Then room.doorwidth = 59
				If functions.IsIn(x, y, room.Pos.x, Building.pos.y + Building.GetFloorY(room.pos.y) - Assets.GetSprite("gfx_building_Tueren").h, room.doorwidth, 54)
					Return room
				EndIf
			EndIf
			If room.name = "elevator" AND functions.IsIn(x, y, Building.pos.x + Building.Elevator.pos.x, Building.pos.y + Building.GetFloorY(room.Pos.y) - 58, Building.Elevator.spriteDoor.sprite.framew, 58)
				room.Pos.x = Building.Elevator.GetDoorCenter()
				Return room
			EndIf
		Next
		Return Null
    End Function

	Function GetRoom:TRooms(ID:Int)
		For Local room:TRooms = EachIn TRooms.RoomList
			If room.uniqueID = id Then Return room
		Next
		Return Null
	End Function

	Function GetRandomReachableRoom:TRooms()
		Local room:TRooms = Null
		Repeat
			room = TRooms(TRooms.RoomList.ValueAtIndex(Rand(TRooms.RoomList.Count() - 1)))
			If room.doortype >0 Then Return room
		Forever
		Return Null
	End Function

	Function GetRoomFromXY:TRooms(x:Int, y:Int)
      if x > 0 and y > 0
        For Local room:TRooms= EachIn TRooms.RoomList
          If room.Pos.x = x And room.Pos.y = y Then Return room
        Next
      EndIf
      Return Null
	End Function

	Function GetRoomFromMapPos:TRooms(x:Int, y:Int)
      if x > 0 and y >= 0
        For Local room:TRooms= EachIn TRooms.RoomList
	      If room.Pos.y = y And room.xpos = x Then Return room
        Next
      EndIf
      Return Null
	End Function

	Function GetRoomByDetails:TRooms(desc:String, owner:Int, strictOwner:int = 1)
		For Local room:TRooms= EachIn TRooms.RoomList
			If room.name = desc and (room.owner = owner OR (strictOwner = 0 AND owner <=0 AND room.owner <=0)) Then Return room
		Next
		Return Null
	End Function
End Type

'Buereau: special functions, gimmicks, ...
'Buero: Spezialfunktionen, Gimmicks, ...
global PlannerToolTip:TTooltip
Function Room_News_Compute(_room:TRooms)

	if not TRooms.doadraw 'draw it
		Players[game.playerid].figure.fromroom =Null
		TNewsbuttons.UpdateAll(App.timer.getDeltaTime())
		Game.cursorstate = 0
		If PlannerToolTip <> Null  Then PlannerToolTip.Update(App.Timer.getDeltaTime())
		If functions.IsIn(MouseX(), MouseY(), 167,60,240,160)
			If PlannerToolTip = Null Then PlannerToolTip = TTooltip.Create("Newsplaner", "Hinzufügen und entfernen", 180, 100, 0, 0)
			PlannerToolTip.enabled = 1
			PlannerToolTip.Hover()
			Game.cursorstate = 1
			If MOUSEMANAGER.IsHit(1) Then MOUSEMANAGER.resetKey(1);Game.cursorstate = 0;players[game.playerID].figure.inRoom = TRooms.GetRoomByDetails("newsplanner", _room.owner)
		endif
	else
		If PlannerToolTip <> Null  Then PlannerToolTip.Draw(App.Timer.getDeltaTime())
		TNewsbuttons.DrawAll(App.timer.getTween())
    EndIf
End Function

'Buereau: special functions, gimmicks, ...
'Buero: Spezialfunktionen, Gimmicks, ...
Function Room_Office_Compute(_room:TRooms)
  Global PlannerToolTip:TTooltip
  Global StationsToolTip:TTooltip
  If TRooms.doadraw 'draw it
    If _room.owner = Game.playerID
      If StationsToolTip <> Null Then StationsToolTip.Draw()
    EndIf
    If PlannerToolTip <> Null  Then PlannerToolTip.Draw()
  Else
	Players[game.playerid].figure.fromroom =Null
    If MouseManager.IsHit(1)
      If functions.IsIn(MouseX(),MouseY(),25,40,150,295)
		Players[Game.playerID].Figure.LeaveRoom()
        MOUSEMANAGER.resetKey(1)
	  EndIf
      If functions.IsIn(MouseX(),MouseY(),164,54,67,110) And _room.owner = game.playerID
        MOUSEMANAGER.resetKey(1);
		Game.cursorstate = 0;
		Players[game.playerID].figure.inRoom = TRooms.GetRoomByDetails("safe", -1)
        Players[Game.playerID].Figure.fromRoom = TRooms.GetRoomByDetails("office", _room.owner)
     EndIf
	EndIf

	Game.cursorstate = 0
    If functions.IsIn(MouseX(), MouseY(), 600,140,128,210)
      If PlannerToolTip = Null Then PlannerToolTip = TTooltip.Create("Programmplaner", "und Statistiken", 580, 140, 0, 0)
      PlannerToolTip.enabled = 1
      PlannerToolTip.Hover()
      Game.cursorstate = 1
      If MOUSEMANAGER.IsHit(1) Then MOUSEMANAGER.resetKey(1);Game.cursorstate = 0;players[game.playerID].figure.inRoom = TRooms.GetRoomByDetails("programmeplanner", _room.owner)
    EndIf
    If _room.owner = Game.playerID
   	  If functions.IsIn(MouseX(), MouseY(), 732,45,160,170)
	    If StationsToolTip = Null Then StationsToolTip = TTooltip.Create("Senderkarte", "Kauf und Verkauf", 650, 80, 0, 0)
	    StationsToolTip.enabled = 1
	    StationsToolTip.Hover()
	    Game.cursorstate = 1
	    If MOUSEMANAGER.IsHit(1) Then MOUSEMANAGER.resetKey(1);Game.cursorstate = 0;players[game.playerID].figure.inRoom = TRooms.GetRoomByDetails("stationmap", _room.owner)
	  EndIf
      If StationsToolTip <> Null Then StationsToolTip.Update(App.timer.getDeltaTime())
    EndIf
    If PlannerToolTip <> Null  Then PlannerToolTip.Update(App.timer.getDeltaTime())
  endif
End Function


Function Room_Safe_Compute(_room:TRooms)
  If TRooms.doadraw 'draw it
  Else
    Players[Game.playerID].Figure.fromRoom = TRooms.GetRoomByDetails("office", game.playerID)
    Game.cursorstate = 0
  EndIf
End Function


Function Room_Financials_Compute(_room:TRooms)
	If TRooms.doadraw 'draw it
		Local showday:Int = Game.getWeekday()
		Players[Game.playerID].Figure.fromRoom = TRooms.GetRoomByDetails("programmeplanner", _room.owner)
		Game.cursorstate = 0
		local font13:TBitmapFont = Assets.GetFont("Default", 14, BOLDFONT)
		local font12:TBitmapFont = Assets.GetFont("Default", 11)

		local finances:TFinancials = Players[_room.owner].finances[showday]
		local line:int = 14
		font13.drawBlock(Localization.GetString("FINANCES_OVERVIEW") 	,55, 236,330,20, 0,50,50,50)
		font13.drawBlock(Localization.GetString("FINANCES_COSTS")       ,55,  30,330,20, 0,50,50,50)
		font13.drawBlock(Localization.GetString("FINANCES_INCOME")      ,415, 30,330,20, 0,50,50,50)
		font13.drawBlock(Localization.GetString("FINANCES_MONEY_BEFORE"),415,130,330,20, 0,50,50,50)
		font13.drawBlock(Localization.GetString("FINANCES_MONEY_AFTER") ,415,194,330,20, 0,50,50,50)

		font12.drawBlock(Localization.GetString("FINANCES_SOLD_MOVIES") ,415, 49+line*0,330,20,0, 50, 50, 50)
		font12.drawBlock(Localization.GetString("FINANCES_AD_INCOME")   ,415, 49+line*1,330,20,0,120,120,120)
		font12.drawBlock(Localization.GetString("FINANCES_MISC_INCOME") ,415, 49+line*2,330,20,0, 50, 50, 50)
		font12.drawBlock(finances.sold_movies							,640, 49+line*0, 95,20,2, 50, 50, 50)
		font12.drawBlock(finances.sold_ads       						,640, 49+line*1, 95,20,2,120,120,120)
		font12.drawBlock(finances.sold_misc 							,640, 49+line*2, 95,20,2, 50, 50, 50)
		font12.drawBlock(finances.callerRevenue							,640, 49+line*3, 95,20,2, 50, 50, 50)
		font13.drawBlock(finances.sold_total							,640, 96, 92,20,2, 30, 30, 30)

		font13.drawBlock(finances.revenue_before 						,640,130,92,20,2,30,30,30)
		font12.drawBlock(" + "+Localization.GetString("FINANCES_INCOME"),415,148+line*0,93,20,0,50,50,50)
		font12.drawBlock(" - "+Localization.GetString("FINANCES_COSTS")	,415,148+line*1,93,20,0,120,120,120)
		font12.drawBlock(" - "+Localization.GetString("FINANCES_INTEREST"),415,148+line*2,93,20,0,50,50,50)
		font12.drawBlock(finances.sold_total							,640,148+line*0,93,20,2,50,50,50)
		font12.drawBlock(finances.paid_total							,640,148+line*1,93,20,2,120,120,120)
		font12.drawBlock(finances.revenue_interest						,640,148+line*2,93,20,2,50,50,50)
		font13.drawBlock(finances.money									,640,194,92,20,2,30,30,30)

		font12.drawBlock(Localization.GetString("FINANCES_BOUGHT_MOVIES")   ,55, 49+line*0,330,20,0,50,50,50)
		font12.drawBlock(Localization.GetString("FINANCES_BOUGHT_STATIONS") ,55, 49+line*1,330,20,0,120,120,120)
		font12.drawBlock(Localization.GetString("FINANCES_SCRIPTS")         ,55, 49+line*2,330,20,0,50,50,50)
		font12.drawBlock(Localization.GetString("FINANCES_ACTORS_STAGES")   ,55, 49+line*3,330,20,0,120,120,120)
		font12.drawBlock(Localization.GetString("FINANCES_PENALTIES")       ,55, 49+line*4,330,20,0,50,50,50)
		font12.drawBlock(Localization.GetString("FINANCES_STUDIO_RENT")     ,55, 49+line*5,330,20,0,120,120,120)
		font12.drawBlock(Localization.GetString("FINANCES_NEWS")            ,55, 49+line*6,330,20,0,50,50,50)
		font12.drawBlock(Localization.GetString("FINANCES_NEWSAGENCIES")    ,55, 49+line*7,330,20,0,120,120,120)
		font12.drawBlock(Localization.GetString("FINANCES_STATION_COSTS")   ,55, 49+line*8,330,20,0,50,50,50)
		font12.drawBlock(Localization.GetString("FINANCES_MISC_COSTS")     	,55, 49+line*9,330,20,0,120,120,120)
		font12.drawBlock(Players[_room.owner].finances[showday].paid_movies          ,280, 49+line*0,93,20,2,50,50,50)
		font12.drawBlock(Players[_room.owner].finances[showday].paid_stations        ,280, 49+line*1,93,20,2,120,120,120)
		font12.drawBlock(Players[_room.owner].finances[showday].paid_scripts         ,280, 49+line*2,93,20,2,50,50,50)
		font12.drawBlock(Players[_room.owner].finances[showday].paid_productionstuff ,280, 49+line*3,93,20,2,120,120,120)
		font12.drawBlock(Players[_room.owner].finances[showday].paid_penalty         ,280, 49+line*4,93,20,2,50,50,50)
		font12.drawBlock(Players[_room.owner].finances[showday].paid_rent            ,280, 49+line*5,93,20,2,120,120,120)
		font12.drawBlock(Players[_room.owner].finances[showday].paid_news            ,280, 49+line*6,93,20,2,50,50,50)
		font12.drawBlock(Players[_room.owner].finances[showday].paid_newsagencies    ,280, 49+line*7,93,20,2,120,120,120)
		font12.drawBlock(Players[_room.owner].finances[showday].paid_stationfees     ,280, 49+line*8,93,20,2,50,50,50)
		font12.drawBlock(Players[_room.owner].finances[showday].paid_misc            ,280, 49+line*9,93,20,2,120,120,120)
		font13.drawBlock(Players[_room.owner].finances[showday].paid_total           ,280,194,92,20,2,30,30,30)


		Local maxvalue:float=0.0
		Local barrenheight:Float=0
		For local day:Int = 0 To 6
			For Local locObject:TPlayer = EachIn TPlayer.List
				maxValue = max(maxValue, locObject.finances[6 - day].money)
			Next
		Next
		SetColor 200, 200, 200
		DrawLine(53,265,578,265)
		DrawLine(53,315,578,315)
		SetColor 255, 255, 255
		TPlayer.List.Sort(False)
		For local day:Int = 0 To 6
			For Local locObject:TPlayer = EachIn TPlayer.List
				barrenheight = 0 + (maxvalue > 0) * Floor((Float(locobject.finances[day].money) / maxvalue) * 100)
				Assets.getSprite("gfx_financials_barren"+locObject.playerID).drawClipped(450 - 65 * (day) + (locObject.playerID) * 9, 365 - barrenheight, 450 - + 65 * (day) + (locObject.playerID) * 9, 265, 21, 100)
			Next
		Next
		'coord descriptor
		font12.drawBlock(functions.convertValue(maxvalue,2,0)       ,478 , 265,100,20,2,180,180,180)
		font12.drawBlock(functions.convertValue(Int(maxvalue/2),2,0),478 , 315,100,20,2,180,180,180)
	endif
End Function

Function Room_Image_Compute(_room:TRooms)
	If TRooms.doadraw 'draw it
		Game.cursorstate = 0
		Assets.GetFont("Default",13).drawBlock(Localization.GetString("IMAGE_REACH") , 55, 233, 330, 20, 0, 50, 50, 50)

		Assets.GetFont("Default",12).drawBlock(Localization.GetString("IMAGE_SHARETOTAL") , 55, 45, 330, 20, 0, 50, 50, 50)
		Assets.GetFont("Default",12).drawBlock(functions.convertPercent(100.0 * Players[_room.owner].maxaudience / StationMap.einwohner, 2) + "%", 280, 45, 93, 20, 2, 50, 50, 50)
	Else
		Players[Game.playerID].Figure.fromRoom = TRooms.GetRoomByDetails("programmeplanner", _room.owner)
	EndIf

End Function


Function Room_Elevator_Compute(_room:TRooms)
	local playerFigure:TFigures = Players[Game.playerID].figure
	If TRooms.doadraw 'draw it
		TRoomSigns.DrawAll()
		Assets.fonts.baseFont.Draw("Rausschmiss in "+(Building.Elevator.waitAtFloorTimer - MilliSecs()), 600, 20)
	Else
		local mouseHit:int = MouseManager.IsHit(1)

		Game.cursorstate = 0
		playerFigure.fromroom =Null
		If playerFigure.inRoom.name = "elevator"
			if Building.Elevator.waitAtFloorTimer <= MilliSecs()
				Print "Schmeisse Figur " +  playerFigure.Name + " aus dem Fahrstuhl (" + (MilliSecs() - Building.Elevator.waitAtFloorTimer) + ")"
				'waitatfloortimer synchronisieren, wenn spieler fahrstuhlplan betritt
				playerFigure.inElevator		= False
				playerFigure.calledElevator	= False
				playerFigure.inRoom			= Null
				playerFigure.clickedToRoom	= Null
				Building.Elevator.blockedByFigureID = -1
				building.elevator.waitAtFloorTimer = MilliSecs()
			else if mouseHit
				building.Elevator.waitAtFloorTimer = 0
				building.Elevator.blockedByFigureID	= playerFigure.id
				local clickedRoom:TRooms = TRoomSigns.GetRoomFromXY(MouseX(),MouseY())
				if clickedRoom then playerFigure.ChangeTarget(clickedroom.Pos.x, Building.pos.y + Building.GetFloorY(clickedroom.Pos.y))
			endif
		EndIf
		TRoomSigns.UpdateAll(False)
		if mouseHit then MouseManager.ResetKey(1)
	EndIf
End Function

Function Room_RoomBoard_Compute(_room:TRooms)
	if TRooms.doadraw 'draw it
		Players[game.playerid].figure.fromroom =Null
		TRoomSigns.DrawAll()
		Assets.fonts.baseFont.draw("owner:"+_room.owner, 20,20)
		Assets.fonts.baseFont.draw(building.Elevator.waitAtFloorTimer - MilliSecs(), 20,40)
	Else
		' MouseManager.changeStatus()
		Game.cursorstate = 0
		Players[game.playerid].figure.fromroom =Null
		TRoomSigns.UpdateAll(True)
		If MouseManager.IsDown(1) Then MouseManager.resetKey(1)
	EndIf
End Function

Function Room_AdAgency_Compute(_room:TRooms)
	if TRooms.doadraw 'draw it
		Assets.GetSprite("gfx_suitcase").Draw(530, 55)
		' Local locContractX:Int =550
		TContractBlock.DrawAll(True)
        For Local LocObject:TContractBlock= EachIn TContractBlock.List
      	  If locobject.owner <=0 Or locobject.owner=Game.playerID And..
      	     functions.IsIn(MouseX(), MouseY(), LocObject.Pos.x, locobject.Pos.y, locobject.width, locobject.height)
            If LocObject.contract <> Null
			  If LocObject.contract.owner <> 0 Then
			    Local block:TAdBlock = TAdblock.GetBlockByContract(LocObject.contract)
				If block <> Null Then block.ShowSheet(480,185);Exit
				If block =  Null Then LocObject.contract.ShowSheet(480,185);Exit
			  Else
			    If LocObject.dragged Then Game.cursorstate = 2 Else Game.cursorstate = 1
                LocObject.contract.ShowSheet(480,185);Exit
			  EndIf
            EndIf
          EndIf
        Next
	Else
		Players[ game.playerid ].figure.fromroom = Null
		Game.cursorstate = 0
		TContractBlock.UpdateAll(True)
	EndIf
End Function

Global Room_MovieAgency_GimmickTimer:Int = 0

Function Room_MovieAgency_Compute(_room:TRooms)
	Global AuctionToolTip:TTooltip
  If TRooms.doadraw 'draw it
    If functions.IsIn(MouseX(), MouseY(), 210,220,140,60)
		Assets.GetSprite("gfx_hint_rooms_movieagency").Draw(20,60)
	endif

	If Room_MovieAgency_GimmickTimer > MilliSecs()
	  Assets.GetSprite("gfx_gimmick_rooms_movieagency").Draw(10,60)
	EndIf

	local glow:string = ""
	For Local LocObject:TMovieAgencyBlocks= EachIn TMovieAgencyBlocks.List
		If locobject.owner <=0 and locobject.dragged then glow = "_glow"; exit
	Next
	Assets.GetSprite("gfx_suitcase"+glow).Draw(530, 240)

    SetAlpha 0.5
    Assets.GetFont("Default",12).drawBlock("Filme", 640, 28, 110,25, 1, 50,50,50)
    Assets.GetFont("Default",12).drawBlock("Serien", 640, 139, 110,25, 1, 50,50,50)
    SetAlpha 1.0
	TMovieAgencyBlocks.DrawAll(True)

    If AuctionToolTip <> Null Then AuctionToolTip.Draw()

	ReverseList(TMovieAgencyBlocks.List)
        For Local LocObject:TMovieAgencyBlocks= EachIn TMovieAgencyBlocks.List
      	  If locobject.owner <=0 Or locobject.owner=Game.playerID And..
      	     (functions.IsIn(MouseX(), MouseY(), LocObject.Pos.x, locobject.Pos.y, locobject.width, locobject.height) Or..
			  locobject.dragged = 1)
            If LocObject.Programme <> Null
			  If LocObject.dragged Then game.cursorstate = 2 Else Game.cursorstate = 1
			  SetColor 0,0,0
			  SetAlpha 0.2
			  Local x:Float = 120 + Assets.GetSprite("gfx_datasheets_movie").w - 20
			  Local tri:Float[]=[x,45.0,x,90.0,locobject.Pos.x+locobject.width/2.0+3,locobject.Pos.y+locobject.height/2.0]
			  DrawPoly(tri)
			  SetColor 255,255,255
			  SetAlpha 1.0
              LocObject.Programme.ShowSheet(120,30)
              Exit
            EndIf
          EndIf
        Next
    ReverseList(TMovieAgencyBlocks.List)
  Else
    Players[game.playerid].figure.fromroom =Null
    Game.cursorstate = 0
    If functions.IsIn(MouseX(), MouseY(), 210,220,140,60)
      If AuctionToolTip = Null Then AuctionToolTip = TTooltip.Create("Auktion", "Film- und Serienauktion", 200, 180, 0, 0)
      AuctionToolTip.enabled = 1
      AuctionToolTip.Hover()
      Game.cursorstate = 1
      If MOUSEMANAGER.IsHit(1) Then MOUSEMANAGER.resetKey(1);Game.cursorstate = 0;players[game.playerID].figure.inRoom = TRooms.GetRoomByDetails("movieauction", _room.owner)
    EndIf

	If MilliSecs() > Room_MovieAgency_GimmickTimer + 6000 Then Room_MovieAgency_GimmickTimer = MilliSecs() + 250
    TMovieAgencyBlocks.UpdateAll(True)
	If AuctionToolTip <> Null Then AuctionToolTip.Update(App.timer.getDeltaTime())
  EndIf
End Function


Function Room_MovieAuction_Compute(_room:TRooms)
	Global AuctionRect:TImage
  If TRooms.doadraw 'draw it
	Assets.GetSprite("gfx_suitcase").Draw(530, 240)
    SetAlpha 0.5
    Assets.GetFont("Default",12).drawBlock("Filme", 640, 28, 110,25, 1, 50,50,50)
    Assets.GetFont("Default",12).drawBlock("Serien", 640, 139, 110,25, 1, 50,50,50)
    SetAlpha 1.0
	TMovieAgencyBlocks.DrawAll(True)
	SetAlpha 0.5;SetColor 0,0,0
	DrawRect(20,10,760,373)
	SetAlpha 1.0;SetColor 255,255,255
	DrawGFXRect(Assets.GetSpritePack("gfx_gui_rect"), 120, 60, 555, 290)
	Assets.GetFont("Default",12).draw("Zum Bieten auf Film oder Serie klicken",145,315)
	TAuctionProgrammeBlocks.DrawAll(0)
  Else
    Players[Game.playerID].Figure.fromRoom = TRooms.GetRoomByDetails("movieagency", 0)
    Game.cursorstate = 0
	TAuctionProgrammeBlocks.UpdateAll(0)
  EndIf
End Function

Function Room_Betty_Compute(_room:TRooms)
  If TRooms.doadraw 'draw it
    Players[Game.playerid].figure.fromroom = Null
	For Local i:Int = 1 To 4
		local sprite:TGW_Sprites = Assets.GetSprite("gfx_room_betty_picture1")
		Local picY:Int = 240
		Local picX:Int = 410 + i * (sprite.w + 5)
		sprite.Draw( picX, picY )
		SetAlpha 0.4
		Players[i].color.SetRGB()
		DrawRect(picX + 2, picY + 8, 26, 28)
		SetColor 255, 255, 255
		SetAlpha 1.0
		local x:float = picX + Int(sprite.w / 2) - Int(Players[i].Figure.Sprite.framew / 2)
		local y:float = picY + sprite.h - 30
		Players[i].Figure.Sprite.DrawClipped(x, y, x, y, sprite.w, sprite.h-16,0,0,8)
	Next
	Local DlgText:String = "Na Du?" + Chr(13) + "Du könntest ruhig mal öfters bei mir vorbeischauen."
	DrawDialog(Assets.GetSpritePack("gfx_dialog"), 430, 120, 280, 90, "StartLeftDown", 0, DlgText, Assets.GetFont("Default",14))
  EndIf

End Function

Function Room_Chief_Compute(_room:TRooms)
	If TRooms.doadraw 'draw it
		Players[game.playerid].figure.fromroom =Null
		For Local i:Int = 1 To plength-1
			part_array[i].Draw()
		Next
		For Local dialog:TDialogue = EachIn _room.Dialogues
			dialog.Draw()
		Next
  Else

	If _room.Dialogues.Count() <= 0
		Local ChefDialoge:TDialogueTexts[5]
		ChefDialoge[0] = TDialogueTexts.Create("Was ist " + Players[Game.playerID].name + "?!" + Chr(13) + "Haben Sie nichts besseres zu tun als meine Zeit zu verschwenden?" + Chr(13) + " " + Chr(13) + "Ab an die Arbeit oder jemand anderes erledigt Ihren Job...!")
		ChefDialoge[0].AddAnswer(TDialogueAnswer.Create("Ja, ist ja schon gut Chef ich störe nicht weiter!", - 2, Null))
		ChefDialoge[0].AddAnswer(TDialogueAnswer.Create("Ich wollte wegen *ähm* einem Kredit nachfragen.", 1, Null))
		If Players[Game.playerID].GetCreditCurrent() > 0 Then ChefDialoge[0].AddAnswer(TDialogueAnswer.Create("Ich will etwas von meinem Kredit abbezahlen..", 3, Null))
		If Players[Game.playerID].GetCreditAvailable() > 0
			ChefDialoge[1] = TDialogueTexts.Create("Schon wieder neue Kohle?" + Chr(13) + "Naja, Sie machen Ihren Job ja besser als andere Praktikanten. Allerdings sind nicht mehr als " + Players[Game.playerID].GetCreditAvailable() + "€ drin, verstanden!?")
			ChefDialoge[1].AddAnswer(TDialogueAnswer.Create("Ja, den Kredit nehme ich dann wohl.", 2, TPlayer.extSetCredit, Players[Game.playerID].GetCreditAvailable()))
			ChefDialoge[1].AddAnswer(TDialogueAnswer.Create("Ach, nein Danke Boss, hab's mir anders überlegt", - 2))
		Else
			ChefDialoge[1] = TDialogueTexts.Create("Wollen Sie nicht erstmal den alten Kredit zurückzahlen?" + Chr(13) + "Sie schulden mir noch " + Players[Game.playerID].GetCreditCurrent() + "€ - zahlen Sie die ersteinmal ab!" + Chr(13) + "Und nun raus bevor ich mich vergesse")
			ChefDialoge[1].AddAnswer(TDialogueAnswer.Create("Ja, dann zahl ich halt etwas zurück.", 3))
			ChefDialoge[1].AddAnswer(TDialogueAnswer.Create("Öhm, ich schau dann wohl später nochmal vorbei.", - 2))
		EndIf
		ChefDialoge[1].AddAnswer(TDialogueAnswer.Create("Können wir nicht über etwas anderes reden?", 0))

		ChefDialoge[2] = TDialogueTexts.Create("So und nun an die Arbeit " + Players[Game.playerID].name + "!")
		ChefDialoge[2].AddAnswer(TDialogueAnswer.Create("Ok, bin ja schon weg.", - 2))

		ChefDialoge[3] = TDialogueTexts.Create("Soso, wenigstens eine gute Nachricht für den heutigen Tag." + Chr(13) + " " + Chr(13) + "Wieviel wollen Sie denn zurückzahlen?")
		If Players[Game.playerID].GetCreditCurrent() >= 100000 And Players[Game.playerID].GetMoney() >= 100000
			ChefDialoge[3].AddAnswer(TDialogueAnswer.Create("Naja 100000€ könnte ich zurückzahlen.", - 2, TPlayer.extSetCredit, - 1 * 100000))
		EndIf
		If Players[Game.playerID].GetCreditCurrent() < Players[Game.playerID].GetMoney()
			ChefDialoge[3].AddAnswer(TDialogueAnswer.Create("Eigentlich gleich den kompletten Kredit.", - 2, TPlayer.extSetCredit, - 1 * Players[Game.playerID].GetCreditCurrent()))
		EndIf
		ChefDialoge[3].AddAnswer(TDialogueAnswer.Create("Hab's mir doch anders überlegt, bis später Chef.", - 2))
		ChefDialoge[3].AddAnswer(TDialogueAnswer.Create("Können wir nicht über etwas anderes reden?", 0))
		Local ChefDialog:TDialogue = TDialogue.Create(350, 60, 450, 200)
		ChefDialog.AddText(Chefdialoge[0])
		ChefDialog.AddText(Chefdialoge[1])
		ChefDialog.AddText(Chefdialoge[2])
		ChefDialog.AddText(Chefdialoge[3])
		_room.Dialogues.AddLast(ChefDialog)
	EndIf

	spawn_delay:-1
	If spawn_delay<0
		spawn_delay=5
		For local pp:int = 1 To 64
			For local i:int = 1 To plength-1
				If part_array[i].is_alive = False
					part_array[i].Spawn(69,335,Rnd (5.0,35.0),Rnd (0.30,2.75),Rnd (0.2,1.4),Rnd(176, 184),2,2)
					Exit
				EndIf
			Next
		Next
	EndIf
	For local i:int = 1 To plength-1
		part_array[i].Update(App.timer.getDeltaTime())
	Next
	For Local dialog:TDialogue = EachIn _room.Dialogues
		If dialog.Update(MOUSEMANAGER.IsHit(1)) = 0 Then _room.LeaveAnimated(0) ; _room.Dialogues.Remove(dialog)
	Next
  EndIf
rem
  Local ChefText:String
  ChefText = "Was ist?!" + Chr(13) + "Haben Sie nichts besseres zu tun als meine Zeit zu verschwenden?" + Chr(13) + " " + Chr(13) + "Ab an die Arbeit oder jemand anderes erledigt Ihren Job...!"
  If Betty.LastAwardWinner <> Game.playerID And Betty.LastAwardWinner <> 0
  	If Betty.GetAwardTypeString() <> "NONE" Then ChefText = "In " + (Betty.GetAwardEnding() - Game.day) + " Tagen wird der Preis für " + Betty.GetAwardTypeString() + " verliehen. Holen Sie den Preis oder Ihr Job ist nicht mehr sicher."
  	If Betty.LastAwardType <> 0
	  	ChefText = "Was fällt Ihnen ein den Award für " + Betty.GetAwardTypeString(Betty.LastAwardType) + " nicht zu holen?!" + Chr(13) + " " + Chr(13) + "Naja ich hoffe mal Sie schnappen sich den Preis für " + Betty.GetAwardTypeString() + "."
	EndIf
  EndIf
  functions.DrawDialog(Assets.GetSpritePack("gfx_dialog"), 350, 60, 450, 120, "StartLeftDown", 0, ChefText, Font14)
endrem
End Function

Function OnClick_StationMapSell(triggerEvent:TEventBase)
	Local evt:TEventSimple = TEventSimple(triggerEvent)
	If evt<>Null
		Local button:TGUIButton = TGUIButton(evt._sender)
		If button <> Null
			if StationMap.action <> 3
				button.value = "Wirklich verkaufen"
				StationMap.action = 3 'selling of stations
			else
				 button.value = "Verkaufen"
				 StationMap.action = 4 'finished selling
			endif
		endif
     EndIf
End Function

Function OnClick_StationMapBuy(triggerEvent:TEventBase)
	Local evt:TEventSimple = TEventSimple(triggerEvent)
	If evt<>Null
		Local button:TGUIButton = TGUIButton(evt._sender)
		If button <> Null
			if StationMap.action <> 1
				button.value		= "Kaufen"
				StationMap.action	= 1			'enables buying of stations
			else
				button.value		= "Neue Station"
				StationMap.action 	= 2			'tries to buy
			endif
		EndIf
	endif
End Function

Function OnUpdate_StationMapBuy(triggerEvent:TEventBase)
	Local evt:TEventSimple = TEventSimple(triggerEvent)
	If evt<>Null
		Local obj:TGUIButton = TGUIButton(evt._sender)

		If MOUSEMANAGER.IsHit(1) And StationMap.action = 1 And MouseX() < 570
			local ClickPos:TPosition = TPosition.Create( MouseX() - 20, MouseY() - 10 )
			If StationMap.LastStation.pos.isSame( ClickPos )
				EventManager.registerEvent( TEventSimple.Create( "guiobject.OnClick", null, obj ) )
			Else
				StationMap.LastStation.pos.setPos(clickPos)
			EndIf
			MouseManager.resetKey(1)
			If StationMap.action > 1
				EventManager.registerEvent( TEventSimple.Create( "guiobject.OnClick", null, obj ) )
			endif
		EndIf
	EndIf
End Function

Function OnUpdate_StationMapSell(triggerEvent:TEventBase)
	Local evt:TEventSimple = TEventSimple(triggerEvent)
	If evt<>Null
		Local obj:TGUIButton = TGUIButton(evt._sender)
		If obj <> Null
			If StationMap.sellStation[Game.playerID] <> Null Then obj.enable() Else obj.disable()
		EndIf
	EndIf
End Function

Function OnUpdate_StationMapList(triggerEvent:TEventBase)
	Local evt:TEventSimple = TEventSimple(triggerEvent)
	If evt<>Null
		Local obj:TGUIList = TGUIList(evt._sender)
		If obj <> Null
			'first fill of stationlist
			obj.ClearEntries()
			Local counter:Int = 0
			For Local station:TStation = EachIn StationMap.StationList
				If Game.playerID = station.owner
					obj.AddEntry("", "Station (" + functions.convertValue(station.reach, 2, 0) + ")", 0, 0, 0, MilliSecs())
					If obj.ListPosClicked = counter
						StationMap.sellStation[Game.playerID] = station
					EndIf
					counter:+1
				EndIf
			Next
		EndIf
	Endif
End Function

Function OnUpdate_StationMapFilters(triggerEvent:TEventBase)
	Local evt:TEventSimple = TEventSimple(triggerEvent)
	If evt<>Null
		Local obj:TGUIOkbutton = TGUIOkbutton(evt._sender)
		If obj <> Null then StationMap.filter_ShowStations[Int(obj.value)] = obj.crossed
	EndIf
End Function

'StationMap-GUIcomponents
Local button:TGUIButton
button = new TGUIButton.Create(TPosition.Create(610, 110), 155,,, , "Neue Station", "STATIONMAP")
button.SetTextalign("CENTER")
EventManager.registerListenerFunction( "guiobject.onClick",	OnClick_StationMapBuy, button )
EventManager.registerListenerFunction( "guiobject.onUpdate", OnUpdate_StationMapBuy, button )

button = new TGUIButton.Create(TPosition.Create(610, 345), 155,,, , "Station verkaufen", "STATIONMAP")
button.disable()
button.SetTextalign("CENTER")
EventManager.registerListenerFunction( "guiobject.onClick",	OnClick_StationMapSell, button )
EventManager.registerListenerFunction( "guiobject.onUpdate", OnUpdate_StationMapSell, button )

Local stationlist:TGUIList = new TGUIList.Create(588, 233, 190, 100,, 40, "STATIONMAP")
stationlist.SetControlState(1)
EventManager.registerListenerFunction( "guiobject.onUpdate", OnUpdate_StationMapList, stationlist )
For Local i:Int = 0 To 3
	local button:TGUIOkbutton = new TGUIOkButton.Create(535, 30 + i * Assets.GetSprite("gfx_gui_ok_off").h*GUIManager.globalScale, 1, 1, String(i + 1), "STATIONMAP", Assets.GetFont("Default", 11, BOLDFONT))
	EventManager.registerListenerFunction( "guiobject.onUpdate", OnUpdate_StationMapFilters, button )
Next


Function Room_StationMap_Compute(_room:TRooms)
  If TRooms.doadraw 'draw it
	Players[Game.playerID].Figure.fromRoom = TRooms.GetRoomByDetails("office", _room.owner)
    StationMap.Draw()
	GUIManager.Draw("STATIONMAP")
	Assets.fonts.baseFont.drawBlock("zeige Spieler:", 480, 15, 100, 20, 2)
	For Local i:Int = 0 To 3
		SetColor 100, 100, 100
		DrawRect(564, 32 + i * Assets.GetSprite("gfx_gui_ok_off").h*GUIManager.globalScale, 15, 18)
		Players[i + 1].color.SetRGB()
		DrawRect(565, 33 + i * Assets.GetSprite("gfx_gui_ok_off").h*GUIManager.globalScale, 13, 16)
	Next
	SetColor 255, 255, 255
  Else
	Players[Game.playerID].Figure.fromRoom = TRooms.GetRoomByDetails("office", _room.owner)
    StationMap.Update()
	GUIManager.Update("STATIONMAP")
  EndIf
End Function


'Newsplanner: placing, deleting of news ...
Function Room_NewsPlanner_Compute(_room:TRooms)
  If TRooms.doadraw 'draw it
    SetColor 255,255,255  'normal
    SetColor 255,255,255
    If game.networkgame Then If network.isServer Then DrawText ( (Game.timeSinceBegin - NewsAgency.NextEventTime), 50,12)
	GUIManager.Draw("Newsplanner")
    Players[_room.owner].ProgrammePlan.DrawAllNewsBlocks()
  Else
    Players[Game.playerID].Figure.fromRoom = TRooms.GetRoomByDetails("news", _room.owner)
    Game.cursorstate = 0
    If Btn_newsplanner_up.GetClicks() >= 1 Then TNewsBlock.DecLeftListPosition()
    If Btn_newsplanner_down.GetClicks() >= 1 Then TNewsBlock.IncLeftListPosition()
    If TNewsBlock.AdditionallyDragged > 0 Then Game.cursorstate=2
	GUIManager.Update("Newsplanner")
    Players[_room.owner].ProgrammePlan.UpdateAllNewsBlocks()
  endif
End Function

'Buereau: programmeplanner, ...
'Buero: Programmplaner, ...
Global DrawnOnProgrammePlannerBG:Byte= 0 'bg-items already drawn?
Function Room_ProgrammePlanner_Compute(_room:TRooms)
	Local State:Int=0
	Local othertime:Int = 0
	If TRooms.doadraw 'draw it

		If Not DrawnOnProgrammePlannerBG
			local pixImage:Timage = Assets.GetSprite("rooms_pplanning").parent.image
			Local Pix:TPixmap = LockImage(pixImage)
			'SetImageFont(font11)

			For Local i:Int = 0 To 11
				'left side
				Assets.fonts.baseFont.drawOnPixmap( (i + 12) + ":00", 356, 25 + i * 30, 255,255,255, Pix, True )
				'right side
				local text:string = i + ":00"
				If i < 10 then text = "0" + text
				Assets.fonts.baseFont.drawOnPixmap(text, 29, 25 + i * 30, 255,255,255, Pix, True)
			Next
			_room.background = Assets.GetSprite("rooms_pplanning")
			TRooms.ActiveBackground = Assets.GetSprite("rooms_pplanning")
			DrawnOnProgrammePlannerBG = True
			UnlockImage(pixImage)
		EndIf

		TProfiler.Enter("ProgrammePlanner:DRAW")
		'draw blocks (backgrounds)
		For Local i : Byte = 0 To 23
			local rightSide:int = floor(i / 11) '0-11 = 0,12-23 = 1
			local slotPos:int = i
			if rightSide then slotPos :- 12

			'for programmeblocks
			If Game.day > Game.daytoplan Then State = 4 Else State = 0 'else = game.day < game.daytoplan
			If Game.day = Game.daytoplan
				If i > othertime
					State = 0  'normal
				Else If i = othertime
					State = 2  'running
				Else If i < (Int(Floor((Game.minutesOfDayGone+5) / 60)))
					State = 1  'runned
				EndIf
			EndIf
 			If State <> 0 And State <> 4 '0=normal, 4=old day
				If State = 1
					SetColor 195, 105, 105  'runned - red, if a programme is set, the programme will overlay it
				Else If State = 2
					SetColor 180, 160, 50  'running
				EndIf
				SetAlpha 0.5
				Assets.GetSprite("pp_programmeblock1").Draw(67 + rightSide*327, 17 + slotPos * 30)
			EndIf

			'for adblocks
			If Game.day > Game.daytoplan Then State = 4 Else State = 0 'else = game.day < game.daytoplan
			If Game.day = Game.daytoplan
				othertime = Int(Floor((Game.minutesOfDayGone - 55) / 60))
				If i > othertime
					State = 0  'normal
				Else If i = othertime
					State = 2  'running
				Else If i < (Int(Floor((Game.minutesOfDayGone) / 60)))
					State = 1  'runned
				EndIf
			EndIf

			If State <> 0 And State <> 4 '0=normal, 4=old day
				If State = 1
					SetColor 195, 105, 105  'runned - red, if a programme is set, the programme will overlay it
				Else If State = 2
					SetColor 180, 160, 50  'running
				EndIf
				SetAlpha 0.5
				Assets.GetSprite("pp_adblock1").Draw(67 + rightSide*327 + Assets.GetSprite("pp_programmeblock1").w, 17 + slotPos * 30)
			EndIf
		Next
		SetAlpha 1.0
		SetColor 255, 255, 255  'normal

		TPPbuttons.DrawAll()


		If Players[_room.owner].ProgrammePlan.AdditionallyDraggedProgrammeBlocks > 0
			TAdBlock.DrawAll(_room.owner)
			SetColor 255,255,255  'normal
			Players[_room.owner].ProgrammePlan.DrawAllProgrammeBlocks()
		Else
			Players[_room.owner].ProgrammePlan.DrawAllProgrammeBlocks()
			SetColor 255,255,255  'normal
			TAdBlock.DrawAll(_room.owner)
		EndIf


		'overlay old days
		If Game.day > Game.daytoplan
			SetColor 100,100,100
			SetAlpha 0.5
			DrawRect(27,17,637,360)
			SetColor 255,255,255
			SetAlpha 1.0
		EndIf

		If Game.daytoplan = Game.day Then SetColor 0,100,0
		If Game.daytoplan < Game.day Then SetColor 100,100,0
		If Game.daytoplan > Game.day Then SetColor 0,0,0
		Assets.GetFont("Default", 10).drawBlock(Game.GetFormattedDay(Game.daytoplan), 691, 17, 100, 15, 0)

		SetColor 255,255,255
		If _room.owner = Game.playerID
			If PPprogrammeList.GetOpen() > 0 Then PPprogrammeList.Draw(1)
			If PPcontractList.GetOpen()  > 0 Then PPcontractList.Draw()
			If PPprogrammeList.GetOpen() = 0 And PPcontractList.GetOpen() = 0
				For Local ProgrammeBlock:TProgrammeBlock = EachIn Players[_room.owner].ProgrammePlan.ProgrammeBlocks
					If ProgrammeBlock.sendHour >= Game.daytoplan*24 AND ProgrammeBlock.sendHour <= Game.daytoplan*24+24 And..
					   functions.IsIn(MouseX(),MouseY(), ProgrammeBlock.StartPos.x, ProgrammeBlock.StartPos.y, ProgrammeBlock.width, ProgrammeBlock.height*ProgrammeBlock.programme.blocks)
						If Programmeblock.sendHour > game.getDay()*24 + game.GetHour()
							Game.cursorstate = 1
						EndIf
						local showOnRightSide:int = 0
						if MouseX() < 390 then showOnrightSide = 1
						ProgrammeBlock.Programme.ShowSheet(30+328*showOnRightside,20,-1, ProgrammeBlock.programme.parent)
						Exit
					EndIf
				Next
				For Local AdBlock:TAdBlock = EachIn TAdBlock.List
					If _room.owner = AdBlock.owner And..
					   AdBlock.senddate = Game.daytoplan And..
					   functions.IsIn(MouseX(),MouseY(), AdBlock.StartPos.x, AdBlock.StartPos.y, AdBlock.width, AdBlock.Height)
						Game.cursorstate = 1
						If MouseX() <= 400 then AdBlock.ShowSheet(358,20);Exit else AdBlock.ShowSheet(30,20);Exit
					EndIf
				Next
			EndIf 'if no programmeList is open
		EndIf
		SetColor 255,255,255
		TProfiler.Leave("ProgrammePlanner:DRAW")
	Else
		TProfiler.Enter("ProgrammePlanner:UPDATE")
		Game.cursorstate = 0
		Players[Game.playerID].Figure.fromRoom = TRooms.GetRoomByDetails("office", _room.owner)
		If functions.IsIn(MouseX(), MouseY(), 759,17,14,15)
			Game.cursorstate = 1
			If MOUSEMANAGER.IsHit(1)
				MOUSEMANAGER.resetKey(1)
				Game.cursorstate = 0
				Game.daytoplan :+ 1
			endif
		EndIf
		If functions.IsIn(MouseX(), MouseY(), 670,17,14,15)
			Game.cursorstate = 1
			If MOUSEMANAGER.IsHit(1)
				MOUSEMANAGER.resetKey(1)
				Game.cursorstate = 0
				Game.daytoplan :- 1
			endif
			If Game.daytoplan <= 1 Then Game.daytoplan = 1
		EndIf
		TPPbuttons.UpdateAll()

		TAdBlock.UpdateAll(_room.owner)
		Players[_room.owner].ProgrammePlan.UpdateAllProgrammeBlocks()

		If _room.owner = Game.playerID
			If TProgrammeBlock.AdditionallyDragged > 0 OR TADblock.AdditionallyDragged > 0 Then Game.cursorstate=2
			PPprogrammeList.Update()
			PPcontractList.Update()
		EndIf
		TProfiler.Leave("ProgrammePlanner:DRAW")
	EndIf
End Function

'Archive: handling of players programmearchive - for selling it later, ...
Function Room_Archive_Compute(_room:TRooms)
  If TRooms.doadraw 'draw it
	Assets.GetSprite("gfx_suitcase").Draw(40, 270)
    If _room.owner = Game.playerID
      TArchiveProgrammeBlock.DrawAll(_room.owner)
      ArchiveprogrammeList.Draw(False)
    EndIf
    For Local LocObject:TArchiveProgrammeBlock= EachIn TArchiveProgrammeBlock.List
      If locobject.owner <=0 Or locobject.owner=Game.playerID And..
         functions.IsIn(MouseX(), MouseY(), LocObject.Pos.x, locobject.Pos.y, locobject.width, locobject.height)
        If LocObject.Programme <> Null
          If locobject.dragged = 0
		    LocObject.Programme.ShowSheet(30,20)
		    game.cursorstate = 1
		  Else
  	        game.cursorstate = 2
	  	  EndIf
          Exit
        EndIf
      EndIf
    Next
    SetColor 255,255,255
  Else
    Game.cursorstate = 0
    Players[Game.playerID].Figure.fromRoom = Null

    If (functions.IsIn(MouseX(), MouseY(), 605,65,120,90) Or functions.IsIn(MouseX(), MouseY(), 525,155,240,225)) And..
      ArchiveProgrammeList.GetOpen() = 0
      Game.cursorstate = 1
      If MOUSEMANAGER.IsHit(1) Then MOUSEMANAGER.resetKey(1);Game.cursorstate = 0;ArchiveProgrammeList.SetOpen(1)
    EndIf

    If _room.owner = Game.playerID
      TArchiveProgrammeBlock.UpdateAll(_room.owner)
      ArchiveprogrammeList.Update(False)
    EndIf
  EndIf
End Function



'signs used in elevator-plan /room-plan
Type TRoomSigns Extends TBlock
  Field title:String
  Field image:TGW_Sprites
  Field imageWithText:TGW_Sprites
  Field image_dragged:TGW_Sprites
  Global DragAndDropList:TList
  Global List:TList = CreateList()
  Global AdditionallyDragged:Int =0
  Global DebugMode:Byte = 1


  Function Create:TRoomSigns(text:String="unknown", x:Int=0, y:Int=0, owner:Int=0)
	  Local LocObject:TRoomSigns=New TRoomSigns
	  LocObject.Pos 	= TPosition.Create(x, y)
	  LocObject.OrigPos	= TPosition.Create(x, y)
	  LocObject.StartPos= TPosition.Create(x, y)

 	  LocObject.dragable = 1
	  LocObject.owner = owner
	  If owner <0 Then owner = 0

 	  Locobject.image			= Assets.GetSprite("gfx_elevator_sign"+owner)
 	  Locobject.image_dragged	= Assets.GetSprite("gfx_elevator_sign_dragged"+owner)
 	  LocObject.width			= LocObject.image.w
 	  LocObject.Height			= LocObject.image.h - 1
 	  LocObject.title			= text
 	  If not List Then List = CreateList()
 	  List.AddLast(LocObject)
 	  SortList List
        Local DragAndDrop:TDragAndDrop = New TDragAndDrop
 	    DragAndDrop.slot = CountList(List) - 1
 	    DragAndDrop.pos.setXY(x,y)
 	    DragAndDrop.w = LocObject.image.w
 	    DragAndDrop.h = LocObject.image.h-1
   	    If Not TRoomSigns.DragAndDropList Then TRoomSigns.DragAndDropList = CreateList()
        TRoomSigns.DragAndDropList.AddLast(DragAndDrop)
 	    SortList TRoomSigns.DragAndDropList

 	  Return LocObject
	End Function

	Method SetDragable(_dragable:Int = 1)
		dragable = _dragable
	End Method


    Method Compare:Int(otherObject:Object)
       Local s:TRoomSigns = TRoomSigns(otherObject)
       If Not s Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
       Return (dragged * 100)-(s.dragged * 100)
    End Method

    Method GetSlotOfBlock:Int()
    	If Pos.x = 589 then Return 12+(Int(Floor(StartPos.y - 17) / 30))
    	If Pos.x = 262 then Return 1*(Int(Floor(StartPos.y - 17) / 30))
    	Return -1
    End Method

	'draw the Block inclusive text
    'zeichnet den Block inklusive Text
    Method Draw()
		SetColor 255,255,255;dragable=1  'normal

		If dragged = 1
			If TRoomSigns.AdditionallyDragged > 0 Then SetAlpha 1- 1/TRoomSigns.AdditionallyDragged * 0.25
			if image_dragged <> null
				image_dragged.Draw(Pos.x,Pos.y)
				If imagewithtext <> Null then imagewithtext.Draw(Pos.x,Pos.y)
			endif
		Else
			If imagewithtext <> Null
				imagewithtext.Draw(Pos.x,Pos.y)
			Else
				if image <> null
					image.Draw(Pos.x,Pos.y)
					Local colr:Int = 255
					Local colg:Int = 255
					Local colb:Int = 255
					If colr > 255 Then colr = 255
					If colg > 255 Then colg = 255
					If colb > 255 Then colb = 255
					SetAlpha 1.0;Assets.GetFont("Default",10).drawBlock(title, Pos.x+23,Pos.y+4,150,20,0,0,0,0,1)
					SetAlpha 1.0;Assets.GetFont("Default",10).drawBlock(title, Pos.x+22,Pos.y+3,150,20,0,0,0,0,1)
					Local TxtWidth:Int = Min(TextWidth(title)+4, image.w-23-5)
					Local pixmap:TPixmap = GrabPixmap(Pos.x+23-2,Pos.y+4-2,TxtWidth,TextHeight(title)+3)
					pixmap = ConvertPixmap(pixmap, PF_RGB888)
					blurPixmap(pixmap, 0.5)
					pixmap = ConvertPixmap(pixmap, PF_RGB888)
					DrawImage(LoadImage(pixmap), Pos.x+21,Pos.y+2)

					If owner > 0 And owner <=4
						SetAlpha 1.0;Assets.GetFont("Default",10).drawBlock(title, Pos.x+22,Pos.y+3,150,20,0,colr,colg,colb,1)
					Else
						SetAlpha 1.0;Assets.GetFont("Default",10).drawBlock(title, Pos.x+22,Pos.y+3,150,20,0,250,250,250,1)
					EndIf
				endif
			EndIf
			If imagewithtext = Null AND image <> null
				local newimgwithtext:Timage = TImage.Create(image.w, image.h -1,1,0,255,0,255)
				newimgwithtext.pixmaps[0].format = PF_RGB888
				newimgwithtext.pixmaps[0] = GrabPixmap(Pos.x,Pos.y,image.w,image.h-1)
				newimgwithtext.pixmaps[0] = ConvertPixmap(newimgwithtext.pixmaps[0], PF_RGB888)
				imagewithtext = Assets.ConvertImageToSprite(newimgwithtext, "imagewithtext")
			EndIf
		EndIf
		SetAlpha 1
    End Method


	Function UpdateAll(DraggingAllowed:Byte)
		'Local localslot:Int = 0 								'slot in suitcase

		TRoomSigns.AdditionallyDragged = 0				'reset additional dragged objects
		SortList TRoomSigns.List						'sort blocklist
		ReverseList TRoomSigns.list 					'reorder: first are dragged obj then not dragged

		For Local locObj:TRoomSigns = EachIn TRoomSigns.List
			If locObj <> Null
				If locObj.dragged
					If locObj.StartPosBackup.y = 0 Then
						LocObj.StartPosBackup.SetPos(LocObj.StartPos)
					EndIf
				EndIf
				'block is dragable
				If DraggingAllowed And locObj.dragable
					'if right mbutton clicked and block dragged: reset coord of block
					If MOUSEMANAGER.IsHit(2) And locObj.dragged
						locObj.SetCoords(locObj.StartPos.x, locObj.StartPos.y, 1000, 1000)
						locObj.dragged = False
						MOUSEMANAGER.resetKey(2)
					EndIf

					'if left mbutton clicked: drop, replace with underlaying block...
					If MouseManager.IsHit(1)
						'search for underlaying block (we have a block dragged already)
						If locObj.dragged
							'obj over old position - drop ?
							If functions.IsIn(MouseX(),MouseY(),LocObj.StartPosBackup.x,locobj.StartPosBackup.y,locobj.width,locobj.height)
								locObj.dragged = False
							EndIf

							'want to drop in origin-position
							If locObj.ContainingCoord(MouseX(), MouseY())
								locObj.dragged = False
								MouseManager.resetKey(1)
								If Self.DebugMode=1 Then Print "roomboard: dropped to original position"
							'not dropping on origin: search for other underlaying obj
							Else
								For Local OtherLocObj:TRoomSigns = EachIn TRoomSigns.List
									If OtherLocObj <> Null
										If OtherLocObj.ContainingCoord(MouseX(), MouseY()) And OtherLocObj <> locObj And OtherLocObj.dragged = False And OtherLocObj.dragable
'											If game.networkgame Then
'												Network.SendMovieAgencyChange(Network.NET_SWITCH, game.playerID, OtherlocObj.Programme.id, -1, locObj.Programme)
'			  								End If
											locObj.SwitchBlock(otherLocObj)
											If Self.DebugMode=1 Then Print "roomboard: switched - other obj found"
											MouseManager.resetKey(1)
											Exit	'exit enclosing for-loop (stop searching for other underlaying blocks)
										EndIf
									End If
								Next
							EndIf		'end: drop in origin or search for other obj underlaying
						Else			'end: an obj is dragged
							If LocObj.ContainingCoord(MouseX(), MouseY())
								locObj.dragged = 1
								MouseManager.resetKey(1)
							EndIf
						EndIf
					EndIf 				'end: left mbutton clicked
				EndIf					'end: dragable block and player or movieagency is owner
			EndIf 						'end: obj <> NULL

			'if obj dragged then coords to mousecursor+displacement, else to startcoords
			If locObj.dragged = 1
				TRoomSigns.AdditionallyDragged :+1
				Local displacement:Int = TRoomSigns.AdditionallyDragged *5
				locObj.setCoords(MouseX() - locObj.width/2 - displacement, 11+ MouseY() - locObj.height/2 - displacement)
			Else
				locObj.SetCoords(locObj.StartPos.x, locObj.StartPos.y,1000,1000)
			EndIf
		Next
		ReverseList TRoomSigns.list 'reorder: first are not dragged obj
  End Function

	Function DrawAll()
		SortList TRoomSigns.List
		For Local locObject:TRoomSigns = EachIn TRoomSigns.List
			Assets.GetSprite("gfx_elevator_sign_bg").Draw(locObject.OrigPos.x + 20, locObject.OrigPos.y + 6)
		Next
		For Local locObject:TRoomSigns = EachIn TRoomSigns.List
			locObject.Draw()
		Next
  End Function

    Function GetRoomFromXY:TRooms(_x:Int, _y:Int)
		Local _width:Int = Assets.GetSprite("gfx_elevator_sign_bg").w
		Local _height:Int = Assets.GetSprite("gfx_elevator_sign_bg").h

		For Local room:TRoomSigns = EachIn TRoomSigns.List
			If room.Pos.x >= 0
				Local signfloor:Int = (13 - Ceil((MouseY() -41) / 23))
				Local xpos:Int = 0
				If room.Pos.x = 26 Then xpos = 1
				If room.Pos.x = 208 Then xpos = 2
				If room.Pos.x = 417 Then xpos = 3
				If room.Pos.x = 599 Then xpos = 4
				If functions.IsIn(_x, _y, room.Pos.x, room.Pos.y, _width, _height)
					Local clickedroom:TRooms = TRooms.GetRoomFromMapPos(xpos, signfloor)
					print "GetRoomFromXY : "+clickedroom.name
					return clickedroom
				EndIf
			EndIf
		Next
		Print "GetRoomFromXY : no room found"
		return null
    End Function

End Type


Global part_array:TGW_SpritesParticle[100]
Global spawn_delay:Int = 15
Global pcount:Int
Global part_counter:Int
Global plength:Int = Len part_array

For Local i:Int = 1 To plength-1
	part_array[i] = New TGW_SpritesParticle
	part_array[i].image = Assets.GetSprite("gfx_tex_smoke")
	part_array[i].life = Rnd(0.100,1.5)
	part_array[i].scale = 1.1
	part_array[i].is_alive =False
	part_array[i].alpha = 1
Next

Function Init_CreateAllRooms()

	If Not DrawnOnProgrammePlannerBG
		local roomImg:TImage = Assets.GetSprite("rooms_pplanning").parent.image
		Local Pix:TPixmap = LockImage(roomImg)
		Local gfx_ProgrammeBlock1:TImage = Assets.GetSprite("pp_programmeblock1").GetImage()
		Local gfx_AdBlock1:TImage = Assets.GetSprite("pp_adblock1").GetImage()

		For Local j:Int = 0 To 11
			DrawOnPixmap(gfx_Programmeblock1, 0, Pix, 67 - 20, 17 - 10 + j * 30, 0.3, 0.8)
			DrawOnPixmap(gfx_Programmeblock1, 0, Pix, 394 - 20, 17 - 10 + j * 30, 0.3, 0.8)
			DrawOnPixmap(gfx_Adblock1, 0, Pix, 67 + ImageWidth(gfx_Programmeblock1) - 20, 17 - 10 + j * 30, 0.3, 0.8)
			DrawOnPixmap(gfx_Adblock1, 0, Pix, 394 + ImageWidth(gfx_Programmeblock1) - 20, 17 - 10 + j * 30, 0.3, 0.8)
		Next
'		Assets.Add("rooms_pplanning", TAsset.CreateBaseAsset(TBigImage.Create(Pix), "BIGIMAGE"))
		DrawnOnProgrammePlannerBG = False 'True
		UnlockImage(roomImg)
		PrintDebug("  Init_CreateAllRooms()", "created programmeplannergfx", DEBUG_START)
	End If

	For Local i:Int = 1 To 4
		TRooms.Create(Assets.GetSprite("rooms_pplanning") , "programmeplanner", Localization.GetString("ROOM_PROGRAMMEPLANNER") , "", 0, 0, - 1, i)
		TRooms.Create(Assets.GetSprite("rooms_stationmap") , "stationmap", Localization.GetString("ROOM_STATIONMAP") , "", 0, 0, - 1, i)
		TRooms.Create(Assets.GetSprite("rooms_newsplanning") , "newsplanner", Localization.GetString("ROOM_NEWSPLANNER") , "", 0, 0, - 1, i)
		TRooms.Create(Assets.GetSprite("rooms_financials") , "financials", Localization.GetString("ROOM_FINANCES") , "", 0, 0, - 1, i)
		TRooms.Create(Assets.GetSprite("rooms_image") , "image", Localization.GetString("ROOM_IMAGE_AND_QUOTES") , "", 0, 0, - 1, i)
	Next

	'elevator doors, to make them clickable
	For Local i:Int =0 To 13
	  TRooms.Create(Assets.GetSprite("rooms_elevator"), "elevator", Localization.GetString("ROOM_ROOMMAP") , "", 0, i, - 1, 0)
	Next

	TRooms.Create(Assets.GetSprite("rooms_movieagency"), "movieauction", Localization.GetString("ROOM_MOVIEAGENCY"), Localization.GetString("ROOM_MOVIEAGENCY_OWNER"), 0, 0, - 1, 0)
	TRooms.Create(Assets.GetSprite("rooms_movieagency"), "movieagency", Localization.GetString("ROOM_MOVIEAGENCY"), Localization.GetString("ROOM_MOVIEAGENCY_OWNER"), 1, 3, 3, 0)
	TRooms.Create(Assets.GetSprite("rooms_adagency"), "adagency", Localization.GetString("ROOM_ADAGENCY") , Localization.GetString("ROOM_ADAGENCY_OWNER"), 1, 10, 3, 0)
	TRooms.CreateWithPos(Assets.GetSprite("rooms_elevator"), "roomboard", Localization.GetString("ROOM_ROOMBOARD"), 527, 4, 59, 0, 1, - 1)
	TRooms.CreateWithPos(Assets.GetSprite("rooms_credits"), "credits", Localization.GetString("ROOM_CREDITS"), 559, 4, 52, 13, 1, - 1)
	TRooms.CreateWithPos(Assets.GetSprite("rooms_credits"), "porter", Localization.GetString("ROOM_PORTER"), 186, 1, 66, 0, 1, - 1)

	TRooms.Create(Assets.GetSprite("rooms_safe"), "safe", Localization.GetString("ROOM_SAFE"), "", 0, 0, - 1, - 1)
	TRooms.Create(Assets.GetSprite("rooms_betty"), "betty", Localization.GetString("ROOM_BETTY"), "", 1, 13, 1, 0)
	TRooms.Create(Assets.GetSprite("rooms_supermarket"), "supermarket", Localization.GetString("ROOM_SUPERMARKET"), Localization.GetString("ROOM_SUPERMARKET_SUB"), 3, 1, 3, 0)
	'empty rooms

	PrintDebug("  Init_CreateAllRooms()", "created Rooms", DEBUG_START)

	Local roomMap:TMap = Assets.GetMap("rooms")
	For Local asset:TAsset = EachIn roomMap.Values()
		local room:TMap = TMap(asset._object)
		TRooms.Create(Assets.GetSprite(String(room.ValueForKey("image"))),  ..
					  String(room.ValueForKey("roomname")),  ..
					  Localization.GetString(String(room.ValueForKey("tooltip"))),  ..
					  Localization.GetString(String(room.ValueForKey("tooltip2"))),  ..
					  Int(String(room.ValueForKey("x"))),  ..
					  Int(String(room.ValueForKey("y"))),  ..
					  Int(String(room.ValueForKey("doortype"))),  ..
					  Int(String(room.ValueForKey("owner"))))
	Next

End Function

'Global room:TRooms[1]
'room[0] = TRooms.Create(gfx_rooms_archive, "empty", "leerer Raum", 0, 0, - 1, 0)
Function Init_SetRoomNames()
	For Local i:Int = 1 To 4
		TRooms.GetRoomByDetails("studiosize1", i).desc:+" " + Players[i].channelname
		TRooms.GetRoomByDetails("office", i).desc:+" " + Players[i].name
		TRooms.GetRoomByDetails("chief", i).desc:+" " + Players[i].channelname
		TRooms.GetRoomByDetails("news", i).desc:+" " + Players[i].channelname
		TRooms.GetRoomByDetails("archive", i).desc:+" " + Players[i].channelname
	Next
End Function

Function Init_CreateRoomTooltips()
	For Local Room:TRooms = EachIn TRooms.RoomList
		Room.CreateTooltip()
	Next
End Function