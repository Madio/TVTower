SuperStrict
'Author: Ronny Otto
Import "basefunctions.bmx"
Import "basefunctions_sprites.bmx"
Import "basefunctions_keymanager.bmx"
Import "basefunctions_localization.bmx"
Import "basefunctions_resourcemanager.bmx"
''''''GUIzeugs'

Global gfx_GuiPack:TGW_SpritePack = TGW_SpritePack.Create(LoadImage("grafiken/GUI/guipack.png"), "guipack_pack")
'gfx_GuiPack.AddSprite("Arrows", 0, 0, 64, 16, 4)
gfx_GuiPack.AddAnimSpriteMultiCol("Input", 290, 30, 204, 27, 34, 27, 6)
'gfx_GuiPack.AddSprite("RadioButton", 64, 0, 30, 15, 2)
gfx_GuiPack.AddAnimSpriteMultiCol("ListControl", 96, 0, 56, 28, 14, 14, 8)
'gfx_GuiPack.AddAnimSpriteMultiCol("Button", 290, 0, 126, 28, 14, 14, 18)
gfx_GuiPack.AddAnimSpriteMultiCol("DropDown", 160, 0, 126, 42, 14, 14, 21)
gfx_GuiPack.AddSprite("Slider", 0, 30, 112, 14, 8)
'gfx_GuiPack.AddSprite("Overlay_player", 420, 0, 22, 27)
'gfx_GuiPack.AddSprite("Overlay_tvchannel", 443, 0, 22, 27)
'gfx_GuiPack.AddSprite("Overlay_disk", 466, 0, 22, 27)
gfx_GuiPack.AddSprite("Chat_IngameOverlay", 0, 60, 504, 20)
gfx_GuiPack.AddSprite("Chat_Top", 0, 80, 445, 20)
gfx_GuiPack.AddSprite("Chat_Middle", 0, 100, 445, 50)
gfx_GuiPack.AddSprite("Chat_Bottom", 0, 142, 445, 35)
gfx_GuiPack.AddSprite("Chat_Input", 0, 186, 445, 35)


Global GetViewPortX:Int
Global GetViewPortY:Int
Global GetViewPortWidth:Int
Global GetViewPortHeight:Int

Local i:Int
For local i:int = 0 To 255
  KEYWRAPPER.allowKey(i,KEYWRAP_ALLOW_BOTH,600,200)
Next

Type TGUIManager
	Field Defaultfont:TImageFont
	Field GUIobjectactive:Int
	Field LastGuiID:Int = 0
	Field globalScale:float = 1.0
	Field oldfont:TImageFont

	Field MouseIsHit:int = 0
	Field List:TList = CreateList()

	Function Create:TGUIManager()
		local obj:TGUIManager = new TGUIManager
		return obj
	End Function

	Method Add(GUIobject:TGUIobject)
		self.List.AddLast(GUIobject)
		self.list.sort(true, self.SortObjects)
  	    'SortListArray(List)
	End Method

	Function SortObjects:int(ob1:object, ob2:object)
		Local objA:TGUIobject = TGUIobject(ob1)
		Local objB:TGUIobject = TGUIobject(ob2)

		If Not objB Then Return 1                  ' Objekt nicht gefunden, an das Ende der Liste setzen
		If GUIManager.getActive() = objB.uid Return - 1 Else Return 1
		If objB._visible = 0
			If objB.Zindex <= objA.ZIndex
				Return 0
			Else
				Return -1
			EndIf
		EndIf
		If objB.ZIndex <= objA.ZIndex then	Return 1 Else Return 0
	End Function

	Method getActive:int()
		return self.GUIobjectactive
	End Method


	Method setActive(uid:int)
		self.GUIobjectactive = uid
	End Method

	Method Remove(guiobject:TGUIObject)
		ListRemove List,(guiobject)
	End Method


	Method Update(State:String = "", updatelanguage:Int = 0, fromZ:int=-1000, toZ:int=-1000)
		If Not List Return                           'aufhoeren wenn keine Liste vorhanden
		List.Sort()
		If MOUSEMANAGER.IsHit(1) Then MouseIsHit = 1 Else MouseIsHit = 0
		For Local GUIobject:TGUIobject = EachIn self.List 'Liste hier global
			if (toZ = -1000 OR guiobject.zIndex <= toZ) AND (fromZ = -1000 OR guiobject.zIndex >= fromZ)
				If guiobject._visible = 1 AND (State = guiobject.forstateonly Or State = "")
					If guiobject.clickable
						If State <> guiobject.forstateonly Or Not functions.isIn( MouseX(), MouseY(), guiobject.pos.x, guiobject.pos.y, guiobject.width, guiobject.Height )
							guiobject.MouseIsDown = 0
							guiobject.MouseIsDownPos.SetXY(-1,-1)
							guiobject.Clicked = 0
							guiobject.clickedPos.SetXY(-1,-1)
							guiobject.mouseover = 0
							guiobject.setState("")
							If MouseIsHit And self.getActive() = guiobject.uid Then self.setActive(0)
					   EndIf
					   If guiobject.typ <> "background" And functions.isIn(MouseX(), MouseY(), guiobject.pos.x, guiobject.pos.y, guiobject.width, guiobject.Height)
							If MOUSEMANAGER.IsDown(1) and guiobject._enabled
								self.setActive(guiobject.uid)
								guiobject.MouseIsDown = 1
								guiobject.MouseIsDownPos.SetXY( MouseX(), MouseY() )
							EndIf
							guiobject.mouseover = 1

							If guiobject.clickable and guiobject._enabled
								if MOUSEMANAGER.isDown(1) OR guiobject.MouseIsDown = 1 then guiobject.setState("active") else guiobject.setState("hover")

								If MOUSEMANAGER.isUp(1) And guiobject.MouseIsDown = 1
									guiobject.Clicked = 1
									guiobject.clickedPos.SetXY( MouseX(), MouseY() )
									'fire onClickEvent
									If guiobject._enabled Then If guiobject._onClickFunc <> Null Then guiobject._onClickFunc(guiobject)
									guiobject.MouseIsDown = 0 'added for imagebutton and arrowbutton not being reset when mouse standing still
								EndIf
							endif
						EndIf
					EndIf
					If guiobject.value = "" Then guiobject.value = "  "
					If guiobject.backupvalue = "x" Then guiobject.backupvalue = guiobject.value
					If updatelanguage Or Chr(guiobject.value[0] ) = "_" Then If Chr(guiobject.backupvalue[0] ) = "_" Then guiobject.value = Localization.GetString(Right(guiobject.backupvalue, Len(guiobject.backupvalue) - 1))
					If guiobject._onUpdateFunc <> Null Then guiobject._onUpdateFunc(guiobject)
					guiobject.Update()
				EndIf 'forstateonly
			endif
		Next
	End Method

	Method DisplaceGUIobjects(State:String = "", x:Int = 0, y:Int = 0)
    	If Not List Return                           'aufhoeren wenn keine Liste vorhanden
		For Local GUIobject:TGUIobject = EachIn self.List 'Liste hier global
			If State = guiobject.forstateonly
				guiobject.pos.x:+x
				guiobject.pos.y:+y
			EndIf 'forstateonly
		Next
	End Method

	Method Draw(State:String = "", updatelanguage:Int = 0, fromZ:int=-1000, toZ:int=-1000)
		If Not List Return                           'aufhoeren wenn keine Liste vorhanden
		GetViewport(GetViewPortX, GetViewPortY, GetViewPortWidth, GetViewPortHeight)
		Self.oldfont = GetImageFont()
		Local myoldfont:TImageFont = Self.oldfont

		For Local GUIobject:TGUIobject = EachIn self.List 'Liste hier global
			if (toZ = -1000 OR guiobject.zIndex <= toZ) AND (fromZ = -1000 OR guiobject.zIndex >= fromZ)
				If State = guiobject.forstateonly
					'If guiobject.enabled = 0 Return
					If guiobject._visible = 1
						If GuiObject.UseFont <> Null Then SetImageFont guiobject.UseFont Else SetImageFont self.Defaultfont
						If guiobject.value = "" Then guiobject.value = "  "
						If guiobject.backupvalue = "x" Then guiobject.backupvalue = guiobject.value
						If updatelanguage Or Chr(guiobject.value[0] ) = "_" Then If Chr(guiobject.backupvalue[0] ) = "_" Then guiobject.value = Localization.GetString(Right(guiobject.backupvalue, Len(guiobject.backupvalue) - 1))
						GUIobject.Draw()
					EndIf
				EndIf 'forstateonly
			endif
		Next
		SetImageFont myoldfont
		SetViewport(GetViewPortX, GetViewPortY, GetViewPortWidth, GetViewPortHeight)
	End Method

End Type

Global GUIManager:TGUIManager = TGUIManager.Create()


Type TGUIobject
	Field pos:TPosition = TPosition.Create(-1,-1)
	Field width:Int
	Field height:Int
	Field scale:float=1.0
	Field align:int = 0 'alignment od object
	Field state:string = ""
	Field value:String = ""
	Field backupvalue:String = "x"
	Field Clicked:Int
	Field clickedPos:TPosition = TPosition.Create(-1,-1)
	Field MouseIsDown:Int
	Field MouseIsDownPos:TPosition = TPosition.Create(-1,-1)
	Field mousePos:TPosition = TPosition.Create(-1,-1)
	Field ParentID:Int
	Field ParentGUIObject:TGUIobject = Null
	Field ZIndex:Int
	Field EnterPressed:Int=0
	Field uid:Int
	Field on:Int
	Field typ:String
	Field _enabled:Int = 1
	Field _visible:Int = 1
	Field clickable:Int=1
	Field mouseover:Int = 0
	Field forstateonly:String = "" 'fuer welchen gamestate anzeigen
	Field UseFont:TImageFont' = SmallImageFont
	Field _onClickFunc(sender:Object)
	Field _onDoubleClickFunc(sender:Object)
	Field _onUpdateFunc(sender:Object)
	Field grayedout:Int = 0
	Field oldfont:TImageFont

	Function GetNewID:Int()
		GUIManager.LastGuiID:+1
		Return GUIManager.LastGuiID
	End Function

	Method SetImgFont(font:TImageFont)
		oldfont = GetImageFont()
		SetImageFont(font)
	End Method

   Method RestoreImgFont()
     SetImageFont(oldfont)
   End Method

   Method SetClickFunc(onFunc(sender:Object))
   	Self._onClickFunc = onFunc
   End Method

   Method SetDoubleClickFunc(onFunc(sender:Object))
   	Self._onDoubleClickFunc = onFunc
   End Method

   Method SetUpdateFunc(onFunc(sender:Object))
   	Self._onUpdateFunc = onFunc
   End Method

   Method Draw() abstract

	Method Show()
		Self._visible = 1
	End Method

	Method Hide()
		Self._visible = 0
	End Method

   Method enable()
   	 _enabled = 1
   	 GUIManager.list.sort()
	 'SortListArray(GUIManager.list)
   End Method

   Method disable()
   	 _enabled = 0
   	 GUIManager.list.sort()
	 'SortListArray(GUIManager.list)
   End Method

	Method Update() Abstract

	Method SetZIndex(zindex:int)
		self.ZIndex = zindex
		GUIManager.list.sort()
		'SortListArray(GUIManager.list)
	End Method

	Method SetState(state:string="")
		if state <> "" then state = "."+state
		self.state = state
	End Method

   Method Input2Value:String(value$)
   	   Local i:Int
   	   For i = 65 To 90
'         If i <> 81 And i <> 69
           If KEYWRAPPER.pressedKey(i)
'		     Keywrapper.resetKey(i)
'			 Keywrapper.allowKey(i, KEYWRAP_ALLOW_BOTH, 500,600)
'           If KEYWRAPPER.pressedKey(i)
If i = 69
		If KEYWRAPPER.pressedKey(69) Then
		  If (KEYMANAGER.IsDown(160) Or KEYMANAGER.IsDown(161)) Then value :+ "E"
          Else If (KEYMANAGER.IsDown(164) Or KEYMANAGER.IsDown(165)) Then value :+ "€"
 		  Else If KEYMANAGER.IsDown(160) Or KEYMANAGER.IsDown(161) Then value :+ Chr(i) Else value :+ Chr(i+32)
        EndIf
Else If i = 81
		If KEYWRAPPER.pressedKey(81) Then
		  If (KEYMANAGER.IsDown(160) Or KEYMANAGER.IsDown(161)) Then value :+ "Q"
          Else If (KEYMANAGER.IsDown(164) Or KEYMANAGER.IsDown(165)) Then value :+ "@"
 		  Else If KEYMANAGER.IsDown(160) Or KEYMANAGER.IsDown(161) Then value :+ Chr(i) Else value :+ Chr(i+32)
        EndIf
Else

			 If KEYMANAGER.IsDown(160) Or KEYMANAGER.IsDown(161) Then value :+ Chr(i) Else value :+ Chr(i+32)
EndIf
		   EndIf
 '        EndIf
       Next

        If KEYWRAPPER.pressedKey(192) If KEYMANAGER.IsDown(160) Or KEYMANAGER.IsDown(161) Then value:+ "Ö" Else value :+ "ö"
        If KEYWRAPPER.pressedKey(222) If KEYMANAGER.IsDown(160) or KEYMANAGER.IsDown(161) Then value:+ "Ä" Else value :+ "ä"
        If KEYWRAPPER.pressedKey(186) If KEYMANAGER.IsDown(160) Or KEYMANAGER.IsDown(161) Then value:+ "Ü" Else value :+ "ü"

        If KEYWRAPPER.pressedKey(48)  If KEYMANAGER.IsDown(160) or KEYMANAGER.IsDown(161) Then value :+ "=" Else value :+ "0"
        If KEYWRAPPER.pressedKey(49)  If KEYMANAGER.IsDown(160) Or KEYMANAGER.IsDown(161) Then value :+ "!" Else value :+ "1"
        If KEYWRAPPER.pressedKey(50)  If KEYMANAGER.IsDown(160) or KEYMANAGER.IsDown(161) Then value :+ Chr(34) Else value :+ "2"
        If KEYWRAPPER.pressedKey(51)  If KEYMANAGER.IsDown(160) or KEYMANAGER.IsDown(161) Then value :+ "§" Else value :+ "3"
        If KEYWRAPPER.pressedKey(52)  If KEYMANAGER.IsDown(160) or KEYMANAGER.IsDown(161) Then value :+ "$" Else value :+ "4"
        If KEYWRAPPER.pressedKey(53)  If KEYMANAGER.IsDown(160) or KEYMANAGER.IsDown(161) Then value :+ "%" Else value :+ "5"
        If KEYWRAPPER.pressedKey(54)  If KEYMANAGER.IsDown(160) or KEYMANAGER.IsDown(161) Then value :+ "&" Else value :+ "6"
        If KEYWRAPPER.pressedKey(55)  If KEYMANAGER.IsDown(160) or KEYMANAGER.IsDown(161) Then value :+ "/" Else value :+ "7"
        If KEYWRAPPER.pressedKey(56)  If KEYMANAGER.IsDown(160) or KEYMANAGER.IsDown(161) Then value :+ "(" Else value :+ "8"
        If KEYWRAPPER.pressedKey(57)  If KEYMANAGER.IsDown(160) or KEYMANAGER.IsDown(161) Then value :+ ")" Else value :+ "9"
        If KEYWRAPPER.pressedKey(219) and (KEYMANAGER.IsDown(160) or KEYMANAGER.IsDown(161)) Then value :+ "?"
        If KEYWRAPPER.pressedKey(219) and (KEYMANAGER.IsDown(164) or KEYMANAGER.IsDown(165)) Then value :+ "\"
        If KEYWRAPPER.pressedKey(219) and (not KEYMANAGER.IsDown(164) and not KEYMANAGER.IsDown(165)) and (not KEYMANAGER.IsDown(160) and not KEYMANAGER.IsDown(161)) value :+ "ß"

        If KEYWRAPPER.pressedKey(221) If KEYMANAGER.IsDown(160) or KEYMANAGER.IsDown(161) Then value :+ "`" Else value :+ "´"
	    If KEYWRAPPER.pressedKey(188) If KEYMANAGER.IsDown(160) or KEYMANAGER.IsDown(161) Then value :+ ";" Else value :+ ","
	    If KEYWRAPPER.pressedKey(189) If KEYMANAGER.IsDown(160) or KEYMANAGER.IsDown(161) Then value :+ "_" Else value :+ "-"
	    If KEYWRAPPER.pressedKey(190) If KEYMANAGER.IsDown(160) or KEYMANAGER.IsDown(161) Then value :+ ":" Else value :+ "."
        If KEYWRAPPER.pressedKey(226) If KEYMANAGER.IsDown(160) or KEYMANAGER.IsDown(161) Then value :+ ">" Else value :+ "<"
        If KEYWRAPPER.pressedKey(KEY_BACKSPACE) value = value[..value.length -1]
	    If KEYWRAPPER.pressedKey(106) value :+ "*"
	    If KEYWRAPPER.pressedKey(111) value :+ "/"
	    If KEYWRAPPER.pressedKey(109) value :+ "-"
	    If KEYWRAPPER.pressedKey(109) value :+ "-"
	    If KEYWRAPPER.pressedKey(110) value :+ ","
	    If KEYWRAPPER.pressedKey(96)  value :+ "0"
	    If KEYWRAPPER.pressedKey(97)  value :+ "1"
	    If KEYWRAPPER.pressedKey(98)  value :+ "2"
	    If KEYWRAPPER.pressedKey(99)  value :+ "3"
	    If KEYWRAPPER.pressedKey(100) value :+ "4"
	    If KEYWRAPPER.pressedKey(101) value :+ "5"
	    If KEYWRAPPER.pressedKey(102) value :+ "6"
	    If KEYWRAPPER.pressedKey(103) value :+ "7"
	    If KEYWRAPPER.pressedKey(104) value :+ "8"
	    If KEYWRAPPER.pressedKey(105) value :+ "9"
	    If KEYWRAPPER.pressedKey(32) value :+ " "

	    If KEYWRAPPER.pressedKey(13) EnterPressed = 1  'EnterTaste abfragbar...
	'    for i = 0 to 255
	'	if Keywrapper.pressedKey(i) debuglog (i)
	'    next
   	    Return value$
   End Method
End Type

Type TGUIButton  Extends TGUIobject
   ' Global List:Tlist
	Field textalign:Int = 0
	Field manualState:Int = 0

	Function Create:TGUIButton(x:Int, y:Int, width:Int = -1, on:Byte = 0, enabled:Byte = 1, textalign:Int = 0, value:String, State:String = "", UseFont:TImageFont = Null)
		Local obj:TGUIButton=New TGUIButton
		obj.pos.setXY( x,y )
		obj.on			= on
		obj._enabled	= enabled
		obj.textalign	= textalign
		If width < 0 Then width = TextWidth(value) + 8
		obj.uid			= TGUIObject.GetNewID()
		obj.scale		= GUIManager.globalScale
		obj.width		= width
		obj.Height		= Assets.GetSprite("gfx_gui_button.L").h * obj.scale
		obj.zindex		= 10
		obj.value		= value
		obj.typ			= "button"
		obj.forstateonly= State
		If UseFont = Null then obj.UseFont = GUIManager.defaultFont Else obj.UseFont = UseFont

    	GUIManager.Add( obj )
		Return obj
	End Function

	Method GetClicks:Int()
		If self.grayedout Then self.Clicked = 0
	    Local varGetClicks:Int = self.clicked
 	    self.Clicked = 0
		Return varGetClicks
	End Method

	Method SetTextalign(aligntype:String = "LEFT")
		textalign = 0 'left
		If aligntype.ToUpper() = "CENTER" Then textalign = 1
		If aligntype.ToUpper() = "RIGHT" Then textalign = 2
	End Method

	Method Update()
		If Not manualState
	        If MouseIsDown = 1 And Not grayedout Then on = 1 Else on = 0
			If Not MouseOver Then on = 0 'no mouse within button-regions, so button not clicked
		EndIf
		If Self._enabled = False Then on = 2; Clicked = 0
	End Method

	Method Draw()
		SetColor 255, 255, 255

		OldFont = GetImageFont()
		SetImageFont(self.UseFont)

		if self.scale <> 1.0 then SetScale self.scale, self.scale
		Assets.GetSprite("gfx_gui_button"+self.state+".L").Draw(self.pos.x,self.pos.y)
		Assets.GetSprite("gfx_gui_button"+self.state+".M").TileDrawHorizontal(self.pos.x + Assets.GetSprite("gfx_gui_button"+self.state+".L").w*self.scale, self.pos.y, width - ( Assets.GetSprite("gfx_gui_button"+self.state+".L").w + Assets.GetSprite("gfx_gui_button"+self.state+".R").w)*scale, self.scale)
		Assets.GetSprite("gfx_gui_button"+self.state+".R").Draw(self.pos.x + width - Assets.GetSprite("gfx_gui_button"+self.state+".R").w*self.scale, self.pos.y)
		if self.scale <> 1.0 then SetScale 1.0,1.0

		Local TextX:Float = ceil(self.pos.x + 10)
		Local TextY:Float = ceil(self.pos.y - (TextHeight("abcd") - height) / 2)

		If textalign = 1 Then TextX = ceil(self.pos.x + (self.width - TextWidth(value)) / 2)
		SetAlpha 0.50
		SetColor 250, 250, 250
		DrawText(value, TextX+1, TextY + 1)
		SetAlpha 0.35
		SetColor 150, 150, 150
		DrawText(value, TextX-1, TextY - 1)
		SetAlpha 1.0
		If self.mouseover Then SetColor 50, 50, 50 Else SetColor 100, 100, 100
		DrawText(value, TextX, TextY)

		SetColor 255,255,255
		SetImageFont(OldFont)
	End Method

End Type

Type TGUIImageButton Extends TGUIobject
    Field grayedout:Int
	Field startframe:Int = 0
    Field image:TImage = Null

	Function Create:TGUIImageButton(x:Int, y:Int, width:Int, Height:Int, image:TImage, on:Byte = 0, enabled:Byte = 1, grayedout:Int = 0, State:String = "", startframe:Int = 0)
		Local obj:TGUIImageButton = New TGUIImageButton
		obj.pos.setXY( x,y )
		obj.on      = on
		obj.grayedout=grayedout
		obj._enabled = enabled
		obj.image = image
		obj.startframe = startframe
		obj.width   = ImageWidth(image)
		obj.uid      = TGUIObject.GetNewID()
		obj.height  = ImageHeight(image)
		obj.value$  = ""
		obj.typ$    = "button"
		obj.forstateonly = State$

		GUIManager.Add( obj )
		Return obj
	End Function

	Method Update()
		'
	End Method

	Method GetClicks:Int()
	    Local varGetClicks:Int = Clicked
 	    Clicked = 0
		Return varGetClicks
	End Method

	Method Draw()
        If MouseIsDown = 1 Then on = 1 Else on = 0
        If grayedout=1 then on = 2
        If grayedout=1 then Clicked = 0
		SetColor 255,255,255
        SetViewport(GetViewPortX,GetViewPortY,GetViewPortWidth,GetViewPortHeight)
 		If on < 2 Then DrawImage(image, self.pos.x, self.pos.y, on + startframe)
	End Method

End Type

'''''TProgressBar -> Ladebildschirm

Type TGUIBackgroundBox  Extends TGUIobject
   ' Global List:Tlist
	Field textalign:Int = 0
	Field manualState:Int = 0

	Function Create:TGUIBackgroundBox(x:Int, y:Int, width:Int = 100, height:int= 100, textalign:Int = 0, value:String, State:String = "", UseFont:TImageFont = Null)
		Local obj:TGUIBackgroundBox=New TGUIBackgroundBox
		obj.pos.setXY( x,y )
		obj.textalign	= textalign
		obj.uid			= TGUIObject.GetNewID()
		obj.width		= width
		obj.height		= height
		obj.value		= value
		obj.typ			= "backgroundbox"
		obj.zindex		= 0
		obj.forstateonly = State
		obj.scale		= GUIManager.globalScale
		If UseFont = Null then obj.UseFont = GUIManager.defaultFont Else obj.UseFont = UseFont
		GUIManager.Add(obj)
		Return obj
	End Function

	Method SetTextalign(aligntype:String = "LEFT")
		textalign = 0 'left
		If aligntype.ToUpper() = "CENTER" Then textalign = 1
		If aligntype.ToUpper() = "RIGHT" Then textalign = 2
	End Method

	Method Update()
		'
	End Method

	Method Draw()
		SetColor 255, 255, 255

		OldFont = GetImageFont()
		SetImageFont(UseFont)

		if self.scale <> 1.0 then SetScale self.scale, self.scale
		local addY:float = 0
		Assets.GetSprite("gfx_gui_box_context.TL").Draw(self.pos.x,self.pos.y)
		Assets.GetSprite("gfx_gui_box_context.TM").TileDrawHorizontal(self.pos.x + Assets.GetSprite("gfx_gui_box_context.TL").w*self.scale, self.pos.y, width - Assets.GetSprite("gfx_gui_box_context.TL").w*self.scale - Assets.GetSprite("gfx_gui_box_context.TR").w*self.scale, self.scale)
		Assets.GetSprite("gfx_gui_box_context.TR").Draw(self.pos.x + width - Assets.GetSprite("gfx_gui_box_context.TR").w*self.scale, self.pos.y) 'align left
		addY = Assets.GetSprite("gfx_gui_box_context.TM").h * scale

		Assets.GetSprite("gfx_gui_box_context.ML").TileDrawVertical(self.pos.x,self.pos.y + addY, height- addY - (Assets.GetSprite("gfx_gui_box_context.BL").h*self.scale), self.scale )
		Assets.GetSprite("gfx_gui_box_context.MM").TileDraw(self.pos.x + Assets.GetSprite("gfx_gui_box_context.ML").w*self.scale, self.pos.y + addY, width - Assets.GetSprite("gfx_gui_box_context.BL").w*scale - Assets.GetSprite("gfx_gui_box_context.BR").w*scale,  height- addY - (Assets.GetSprite("gfx_gui_box_context.BL").h*self.scale), -1, self.scale )
		Assets.GetSprite("gfx_gui_box_context.MR").TileDrawVertical(self.pos.x + width - Assets.GetSprite("gfx_gui_box_context.MR").w*self.scale,self.pos.y + addY, height- addY - (Assets.GetSprite("gfx_gui_box_context.BR").h*self.scale), self.scale )


		addY = height - Assets.GetSprite("gfx_gui_box_context.BM").h * scale

		'buggy "line" zwischen bottom und tiled bg
		addY :-1

'		drawRect(self.pos.x-5, self.pos.y + addY, 200, 50)
		Assets.GetSprite("gfx_gui_box_context.BL").Draw(self.pos.x,self.pos.y + addY)
		Assets.GetSprite("gfx_gui_box_context.BM").TileDrawHorizontal(self.pos.x + Assets.GetSprite("gfx_gui_box_context.BL").w*self.scale, self.pos.y + addY, width - Assets.GetSprite("gfx_gui_box_context.TL").w*self.scale - Assets.GetSprite("gfx_gui_box_context.BR").w*self.scale, self.scale)
		Assets.GetSprite("gfx_gui_box_context.BR").Draw(self.pos.x + width - Assets.GetSprite("gfx_gui_box_context.BR").w*self.scale, self.pos.y +  addY) 'align left

		if self.scale <> 1.0 then SetScale 1.0,1.0

		Local TextX:Float = ceil(self.pos.x + 10)
		Local TextY:Float = ceil(self.pos.y - (TextHeight(value) - Assets.GetSprite("gfx_gui_box_context.TL").h * self.scale) / 2)

		If textalign = 1 Then TextX = ceil(self.pos.x + (width - TextWidth(value)) / 2)
		SetAlpha 0.50
		SetColor 75, 75, 75
		DrawText(value, TextX+1, TextY + 1)
		SetAlpha 0.35
		SetColor 0, 0, 0
		DrawText(value, TextX-1, TextY - 1)
		SetAlpha 1.0
		SetColor 200, 200, 200
		DrawText(value, TextX, TextY)

		SetColor 255,255,255
		SetImageFont(OldFont)
	End Method

End Type


Type TGUIArrowButton  Extends TGUIobject
   ' Global List:Tlist
    Field direction:string
    Field grayedout:Int

	Function Create:TGUIArrowButton(x:Int,y:Int, direction:Int=0, on:Byte = 0, enabled:Byte = 1, grayedout:Int =0, State:String="", align:int = 0)
		Local obj:TGUIArrowButton=New TGUIArrowButton
		obj.pos.setXY( x,y)
		obj.on      	= on
		obj.grayedout	= grayedout
		obj._enabled 	= enabled
		obj.direction = "left"
		if direction = 0 then obj.direction = "left"
		if direction = 1 then obj.direction = "up"
		if direction = 2 then obj.direction = "right"
		if direction = 3 then obj.direction = "down"
		obj.zindex		= 40

		obj.scale		= GUIManager.globalScale
		obj.width		= Assets.GetSprite("gfx_gui_arrow_"+obj.direction).w * obj.scale
		obj.height		= Assets.GetSprite("gfx_gui_arrow_"+obj.direction).h * obj.scale
		obj.uid			= obj.GetNewID()
		obj.value		= ""
		obj.typ			= "button"
		obj.forstateonly= State
		obj.setAlign(align)

		GUIManager.Add( obj )
		Return obj
	End Function

	Method setAlign(align:int=0)
		if self.align <> align
			if self.align = 0 and align = 1
				self.pos.setX( self.pos.x - self.width )
			endif
			if self.align = 1 and align = 0
				self.pos.setX( self.pos.x + self.width )
			endif
		endif
	End Method

	Method Update()
        If MouseIsDown = 1 and not grayedout Then on = 1 Else on = 0
        If grayedout=1  Clicked = 0
	End Method

	Method GetClicks:Int()
	    Local varGetClicks:Int
		varGetClicks = Clicked
 	    Clicked = 0
		Return varGetClicks
	End Method

	Method Draw()
		SetColor 255,255,255
		if self.scale <> 1.0 then setScale self.scale, self.scale
 		If on < 2 Then Assets.GetSprite("gfx_gui_arrow_"+self.direction+self.state).Draw(self.pos.x, self.pos.y)
		if self.scale <> 1.0 then setScale 1.0, 1.0
	    If grayedout=1  on = 2
	End Method

End Type

Type TGUISlider  Extends TGUIobject
    Field minvalue:Int
    Field maxvalue:Int
    Field actvalue:Int = 50
    Field addvalue:Int = 0
    Field drawvalue:Int = 0

	Function Create:TGUISlider(x:Int, y:Int, width:Int, minvalue:Int, maxvalue:Int, enabled:Byte = 1, value:String, State:String = "")
		Local GUISlider:TGUISlider = New TGUISlider
		GUISlider.pos.setXY( x,y )
		GUISlider.on = 0
		GUISlider._enabled = enabled
		If width < 0 Then width = TextWidth(value) + 8
		guislider.uid = Rand(1, 10000)
		GUISlider.width = width
		GUISlider.Height = gfx_GuiPack.GetSprite("Button").frameh
		GUISlider.value = value
		GUISlider.minvalue = minvalue
		GUISlider.maxvalue = maxvalue
		GUISlider.actvalue = minvalue
		GUISlider.typ = "slider"
		GUISlider.forstateonly = State
		GUIMAnager.Add( GUISlider )
		Return GUISlider
	End Function

	Method Update()
	'
	End Method

    Method EnableDrawValue:Int()
		drawvalue = 1
	End Method

    Method DisableDrawValue:Int()
		drawvalue = 0
	End Method

    Method EnableAddValue:Int(add:Int)
 		addvalue = add
	End Method

    Method DisableAddValue:Int()
 		addvalue = 0
	End Method


	Method GetValue:Int()
		Return actvalue + addvalue
	End Method

	Method Draw()
		Local gfx_gui_slider:TImage = gfx_GuiPack.GetSpriteImage("Slider")
	    Local SliderImgWidth:Int = ImageWidth(gfx_gui_slider)
	    Local SliderImgHeight:Int = ImageHeight(gfx_gui_slider)
		Local PixelPerValue:Float = width / (maxvalue - 1 - minvalue)
	    Local actvalueX:Float = actvalue * PixelPerValue
	    Local maxvalueX:Float = (maxvalue) * PixelPerValue
		Local i:Int = 0
		If MouseIsDown = 1 Then on = 1 Else on = 0
		Local difference:Int = actvalueX '+ PixelPerValue / 2

		If on
			difference = MouseX() - self.pos.x + PixelPerValue / 2
			actvalue = Float(difference) / PixelPerValue
			If actvalue > maxvalue Then actvalue = maxvalue
			If actvalue < minvalue Then actvalue = minvalue
			actvalueX = difference'actvalue * PixelPerValue
			If actvalueX >= maxValueX - SliderImgWidth Then actvalueX = maxValueX - SliderImgWidth
		EndIf

  		If Ceil(actvalueX) < SliderImgWidth
			ClipImageToViewport(gfx_gui_slider, self.pos.x, self.pos.y, self.pos.x, self.pos.y, Ceil(actvalueX) + 5, SliderImgHeight, 0, 0, 4)       								'links an
  		    ClipImageToViewport(gfx_gui_slider, self.pos.x, self.pos.y, self.pos.x + Ceil(actvalueX) + 5, self.pos.y, SliderImgWidth, SliderImgHeight, 0, 0, 0)       'links aus
		Else
			DrawImage(gfx_gui_slider, self.pos.x, self.pos.y, 4)
		EndIf
  		If Ceil(actvalueX) > width - SliderImgWidth
			ClipImageToViewport(gfx_gui_slider, self.pos.x + width - SliderImgWidth, self.pos.y, self.pos.x + width - SliderImgWidth, self.pos.y, Ceil(actvalueX) - (width - SliderImgWidth) + 5, SliderImgHeight, 0, 0, 6)                        								'links an
  		    ClipImageToViewport(gfx_gui_slider, self.pos.x + width - SliderImgWidth, self.pos.y, self.pos.x + actvalueX + 5, self.pos.y, SliderImgWidth, SliderImgHeight, 0, 0, 2)                    'links aus
		Else
			DrawImage(gfx_gui_slider, self.pos.x + width - SliderImgWidth, self.pos.y, 2)
		EndIf

		For i = 1 To Ceil(actvalueX) / SliderImgWidth
			If i * SliderImgWidth < width - SliderImgWidth
				Local mywidth:Int = SliderImgWidth
				If i * SliderImgWidth + SliderImgWidth > actvalueX Then mywidth = actvalueX - i * SliderImgWidth
				If i * SliderImgWidth + SliderImgWidth > width - SliderImgWidth Then mywidth = width - SliderImgWidth - (i * SliderImgWidth)
				If i * SliderImgWidth + mywidth > actvalueX Then mywidth = actvalueX - i * SliderImgWidth
		    	ClipImageToViewport(gfx_gui_slider, self.pos.x + i * SliderImgWidth, self.pos.y, self.pos.x + i * SliderImgWidth, self.pos.y, mywidth, SliderImgHeight, 0, 0, 1 + 4)
			EndIf
		Next 'gefaerbter Balken

		For i = Ceil(actvalueX) / SliderImgWidth To Ceil(maxvalueX) / SliderImgWidth - 1
				Local minX:Int = self.pos.x + i * SliderImgWidth
				local mywidth:float = SliderImgWidth
				If minx <= Max(self.pos.x + SliderImgWidth, self.pos.x + actvalueX) Then minx = Max(self.pos.x + SliderImgWidth, self.pos.x + actvalueX)
				If i * sliderImgWidth + SliderImgWidth >= width - SliderImgWidth Then mywidth = (width - SliderImgWidth) - (minx - self.pos.x)
				If mywidth < 0 Then mywidth = 0
		    	ClipImageToViewport(gfx_gui_slider, self.pos.x + i * SliderImgWidth, self.pos.y, minx, self.pos.y, mywidth, SliderImgHeight, 0, 0, 1)
		Next 'ungefaerbte Balken

		DrawImage(gfx_gui_slider, self.pos.x + Ceil(actvalueX - 5), self.pos.y, 3 + on * 4)    '5 = Mitte des Draggers
		SetColor 255, 255, 255
		If drawvalue = 0
  	 	  If value$ <> "" DrawText(value$, self.pos.x+width+7, self.pos.y- (TextHeight(value$) - height) / 2 - 1)
		Else
		  If value$ <> "" DrawText((actvalue + addvalue) + " "+value$, self.pos.x+width+7, self.pos.y- (TextHeight(value$) - height) / 2 - 1)
		EndIf
	End Method

End Type

Type TGUIinput  Extends TGUIobject
    Field maxlength:Int
    Field maxTextWidth:Int
    Field nobackground:Int
    Field colR:Byte, colG:Byte, ColB:Byte
    Field OverlayImage:TGW_Sprites
    Field InputImage:TGW_Sprites	  'own Image for Inputarea
    Field OverlayRect:Int = 0 		'no image? just a rectangle
    Field OverlayColR:Int = 200
    Field OverlayColG:Int = 200
    Field OverlayColB:Int = 200
    Field OverlayColA:Float = 0.5
    Field grayedout:Int = 0
	Field TextDisplaceY:Int = 5
	Field TextDisplaceX:Int = 5

    Function Create:TGUIinput(x:Int, y:Int, width:Int, enabled:Byte = 1, value:String, maxlength:Int = 128, State:String = "", useFont:TImageFont = Null)
		Local obj:TGUIinput = New TGUIinput
		obj.pos.setXY( x,y )
		obj._enabled	= enabled
		obj.scale		= GUIManager.globalScale
		obj.zindex		= 20
		obj.width		= Max(width, 40)
		obj.maxTextWidth= obj.width - 15
		obj.height		= Assets.GetSprite("gfx_gui_input.L").h *  obj.scale
		obj.value		= value
		obj.uid			= obj.GetNewID()
		obj.maxlength	= maxlength
		obj.forstateonly = State
		obj.EnterPressed = 0
		obj.nobackground = 0
		obj.SetCol(100,100,100)
		If UseFont = Null then obj.UseFont = GUIManager.defaultFont Else obj.UseFont = UseFont

		GUIMAnager.Add( obj )
	  	Return obj
	End Function

	Method SetCol(colR:Int, colG:Int, colB:Int)
		Self.colR = colR
		Self.colG = colG
		self.ColB = colB
	End Method

	Method Update()
		If Not grayedout
			If EnterPressed = 1 Then EnterPressed = 0; GUIManager.setActive(0)
			If GUIManager.getActive() = uid Then value = Input2Value(value)
		EndIf
		If GUIManager.getActive() = uid Then on = 1 Else on = 0
		If GUIManager.getActive() = uid Then Self.setState("active")

        If value.length > maxlength Then value = value[..maxlength]

	End Method

    Method SetOverlayImage:TGUIInput(_sprite:TGW_Sprites)
		If _sprite <> Null Then If _sprite.w > 0 Then OverlayImage = _sprite
		return self
	End Method

	Method Draw()
		Local useTextDisplaceX:Int = Self.TextDisplaceX
	    Local i:Int =0
		Local printvalue:String = value
		If grayedout Then on = 0;SetColor 225, 255, 150

		if self.scale <> 1.0 then SetScale self.scale, self.scale
		If nobackground = 0
			Assets.GetSprite("gfx_gui_input"+self.state+".L").Draw(self.pos.x,self.pos.y)
			Assets.GetSprite("gfx_gui_input"+self.state+".M").TileDrawHorizontal(self.pos.x + Assets.GetSprite("gfx_gui_input"+self.state+".L").w*self.scale, self.pos.y, width - ( Assets.GetSprite("gfx_gui_input"+self.state+".L").w + Assets.GetSprite("gfx_gui_input"+self.state+".R").w)*scale, self.scale)
			Assets.GetSprite("gfx_gui_input"+self.state+".R").Draw(self.pos.x + width - Assets.GetSprite("gfx_gui_input"+self.state+".R").w*self.scale, self.pos.y)

			'center overlay over left frame
			local left:float = ( ( Assets.GetSprite("gfx_gui_input"+self.state+".L").w - OverlayImage.w ) / 2 ) * self.scale
			local top:float = ( ( Assets.GetSprite("gfx_gui_input"+self.state+".L").h - OverlayImage.h ) / 2 ) * self.scale
			If OverlayImage <> Null then OverlayImage.Draw( self.pos.x + left, self.pos.y + top )
			'If OverlayImage <> Null then OverlayImage.Draw( self.pos.x, self.pos.y )
		Else
			If GUIManager.getActive() = uid
				'SetVirtualViewPort(x, y, width, Height)
				If OverlayRect Then
					SetAlpha OverlayColA
					SetColor OverlayColR, OverlayColG, OverlayColB
					DrawRect self.pos.x, self.pos.y + 4, width, Height
					SetAlpha 1
					SetColor 255, 255, 255
				Else
					If InputImage <> Null Then InputImage.Draw(self.pos.x, self.pos.y)
				EndIf
			EndIf
			i = (width / 34) - 1
		EndIf
		if self.scale <> 1.0 then SetScale 1.0,1.0

		local useMaxTextWidth:int = self.maxTextWidth

		OldFont = GetImageFont()
		SetImageFont(self.UseFont)


		self.textDisplaceY = (self.height) / 2 - TextHeight("abcd")/2

        If OverlayImage <> Null
			useTextDisplaceX :+ OverlayImage.framew * self.scale
			useMaxTextWidth :-  OverlayImage.framew * self.scale
		endif
		If on = 1
			SetColor colR - 100, colG - 100, ColB - 100
			While TextWidth(printValue + "_") > useMaxTextWidth
				printvalue = printValue[1..]
			Wend
			DrawText(printValue, self.pos.x + usetextDisplaceX + 2, self.pos.y + textDisplaceY)

			SetAlpha Ceil(Sin(MilliSecs() / 2))
			DrawText("_", self.pos.x + usetextdisplaceX + 2 + TextWidth(printValue), self.pos.y + textDisplaceY)
			SetAlpha 1
	    Else
			'useMaxTextWidth :-  Assets.GetSprite("gfx_gui_input"+self.state+".R").w * self.scale
			SetColor ColR, ColG, ColB
			While TextWidth(printValue) > useMaxTextWidth AND printvalue.length > 0
				printvalue = printValue[..printvalue.length - 1]
			Wend

			SetAlpha 0.50
			SetColor 250, 250, 250
			DrawText(printValue, self.pos.x + usetextdisplaceX + 2 + 1, self.pos.y + textDisplaceY +1)
			SetAlpha 0.35
			SetColor 150, 150, 150
			DrawText(printValue, self.pos.x + usetextdisplaceX + 2 - 1, self.pos.y + textDisplaceY -1)
			SetAlpha 1.0
			If self.mouseover Then SetColor colR-50, colG-50, colB-50 Else SetColor colR, colG, colB
			DrawText(printValue, self.pos.x + usetextdisplaceX + 2, self.pos.y + textDisplaceY)
		EndIf
		SetImageFont(Oldfont)

		SetColor 255, 255, 255
	End Method

End Type

Type TGUIDropDownEntries   'Listeneintraege der GUIListe
  Global List:TList
  Field value:String
  Field entryid:Int
  Field pid:Int

  Function Create:TGUIDropDownEntries(value:String, id:Int)
    Local GUIDropDownEntries:TGUIDropDownEntries = New TGUIDropDownEntries
    'DebugLog("entry created")
	GUIDropDownEntries.value$ = value$
	GUIDropDownEntries.pid    = 0'pid
	GUIDropDownEntries.entryid= id

    Return GUIDropDownEntries
  End Function
End Type

Type TGUIDropDown  Extends TGUIobject
   ' Global List:Tlist
    Field grayedout:Int
    Field Values : String[]
	Field Entries:TGUIDropDownEntries = New TGUIDropDownEntries
	Field EntryList: TList
    Field PosChangeTimer: Int
	Field ListPosClicked:Int=-1
	Field ListPosEntryID:Int=-1
	Field buttonheight:Int
	Field textalign:Int = 0
	Field OnChange_(listpos:Int) = TGUIDropDown.DoNothing

	Function Create:TGUIDropDown(x:Int, y:Int, width:Int = -1, on:Byte = 0, enabled:Byte = 1, grayedout:Int = 0, value:String, State:String = "")
		Local GUIDropDown:TGUIDropDown=New TGUIDropDown
		GUIDropDown.pos.setXY( x,y )
		GUIDropDown.on = on
		guiDropDown.grayedout = grayedout
		GUIDropDown._enabled = enabled
		If width < 0 Then width = TextWidth(value:String) + 8
		guiDropDown.uid = Rand(1, 10000)
		GUIDropDown.width = width
		GUIDropDown.buttonheight = gfx_GuiPack.GetSprite("DropDown").frameh * 2
		GUIDropDown.Height = GUIDropDown.buttonheight
		GUIDropDown.value = value
		GUIDropDown.typ = "dropdown"
		GUIDropDown.forstateonly = State
		If Not guiDropDown.EntryList Then guiDropDown.EntryList = CreateList()

		GUIManager.Add( GUIDropDown )
		Return GUIDropDown
	End Function

	Function DoNothing(listpos:Int)
		'
	End Function

	Method SetActiveEntry(id:Int)
		Self.ListPosClicked = id
		Self.value = TGUIDropDownEntries(Self.EntryList.ValueAtIndex(id)).value
	End Method

	Method Update()
	    Local printheight:Int = 0, i:Int = 0
        If GUIManager.getActive() = uid Then on = 1 Else on = 0
		If MOUSEMANAGER.IsHit(1) And on
			For local Entries:TGUIDropDownEntries = EachIn EntryList 'Liste hier global
				If functions.isin( MouseX(),MouseY(), self.pos.x + 5, self.pos.y + 5 + printheight + 30, width - 10, 5 + printheight + 30 + TextHeight(Entries.value) )
					ListPosClicked	= i
					value			= Entries.value
		        	EnterPressed	= 0
					ListPosEntryID	= Entries.entryid
					on				= 0
					GUIManager.setActive(0)
					OnChange_(Entries.entryid)
					Exit
		        EndIf
	          	printheight :+ TextHeight(Entries.value)
			  	i:+1
			Next
        	on = 0
			GUIManager.setActive(0)
			MOUSEMANAGER.resetKey(1)
		End If
	End Method

	Method AddEntry(value:String, id:Int)
		EntryList.AddLast(Entries.Create(value, id))
		If Self.value = "" then Self.value = value
		If Self.ListPosEntryID = -1 then Self.ListPosEntryID = id
	End Method

	Method GetClicks:Int()
		If grayedout Then clicked = 0
	    Local varGetClicks:Int = Clicked
 	    Clicked = 0
		Return varGetClicks
	End Method

	Method Draw()
		Local GuiSprite:TGW_Sprites	= gfx_GuiPack.GetSprite("DropDown")
		Local ImgWidth:Int			= GuiSprite.framew
		Local ImgHeight:Int			= GuiSprite.frameh
	    Local i:Int					= 0
	    Local j:Int					= 0
	    Local useheight:Int			= 0
	    Local printheight:Int		= 0
        If grayedout = 1 then on = 2;Clicked = 0

		If on = 1 And Not grayedout 'ausgeklappt zeichnen
			useheight = 0
			For local Entries:TGUIDropDownEntries = EachIn EntryList 'Liste hier global
				useheight = useheight + TextHeight(Entries.value)
			Next
			useheight = useheight + 15
			Local lineheight:Int = 19

			SetAlpha 0.8
			'SetViewport(0, 0, 800, 600)
			For i = 1 To useheight / ImgHeight + 1
				Local minY:Int = i * lineheight
				If minY + lineheight > useheight + buttonheight - ImgHeight
					minY = useheight + buttonheight - ImgHeight - lineheight
				EndIf
				GuiSprite.DrawClipped(self.pos.x + 5, self.pos.y + i * lineheight, self.pos.x + 5, self.pos.y + minY, width - 10 - imgwidth, lineheight,,, 18)
	  		    For j = 1 To (width - 10) / ImgWidth - 1
					GuiSprite.DrawClipped(self.pos.x + j * ImgWidth, self.pos.y + i * lineheight, self.pos.x + 5, self.pos.y + miny, width - 10 - ImgWidth, lineheight, 0, 0, 19)
	            Next
				GuiSprite.DrawClipped(self.pos.x - 5 + width - ImgWidth, self.pos.y + i * lineheight, self.pos.x - 5 + width - ImgWidth, self.pos.y + minY, imgWidth, lineheight,,, 20)
			Next

			'unten "liste"
			For i = 1 To (width / ImgWidth) - 1
				GuiSprite.DrawClipped(self.pos.x + 5 + i * ImgWidth, self.pos.y + useheight + imgheight, self.pos.x + 5, self.pos.y + useheight + imgHeight, width - 10 - ImgWidth, imgHeight, 0, 0, 22)
			Next
	  		SetViewport(self.pos.x + 5, self.pos.y + useheight + buttonheight - ImgHeight, width - 10, lineheight)
			GuiSprite.Draw(self.pos.x + 5, self.pos.y + useheight + buttonheight - ImgHeight, 21)
			GuiSprite.Draw(self.pos.x - 5 + width - ImgWidth, self.pos.y + useheight + buttonheight - ImgHeight, 23)
			SetAlpha 1.0

			'Zeileninhalte
			SetViewport(0, 0, 800, 600)
			'SetViewport(0, 0, Game.GameGraphics.screenw, Game.GameGraphics.screenh)
			i = 0
			For local Entries:TGUIDropDownEntries = EachIn EntryList 'Liste hier global
				If i = ListPosClicked
					SetAlpha 0.2
					SetColor 95, 80, 30
					DrawRect(self.pos.x + 13, self.pos.y + 5 + printheight + 30, width - 27, TextHeight(Entries.value))
					SetAlpha 1.0
					SetColor 255, 255, 255
				EndIf
				If ListPosClicked = i Then SetColor(244, 206, 74)
				If MouseX() > self.pos.x + 5 And MouseX() < self.pos.x + width - 10 And MouseY() > self.pos.y + 5 + printheight + 30 And MouseY() < self.pos.y + 5 + printheight + 30 + TextHeight(Entries.value)
		        	SetAlpha 0.2
		        	DrawRect(self.pos.x + 13, self.pos.y + 5 + printheight + 30, width - 27, TextHeight(Entries.value))
		        	SetAlpha 1.0
				EndIf
				If textalign = 1 Then DrawText(Entries.value, self.pos.x + (width - TextWidth(Entries.value)) / 2, self.pos.y + 5 + printheight + 30)
				If textalign = 0 Then DrawText(Entries.value, self.pos.x + 15, self.pos.y + 5 + printheight + 30)
				If ListPosClicked = i Then SetColor 255, 255, 255
				printheight:+TextHeight(Entries.value)
				i:+1
			Next

			GuiSprite.Draw(self.pos.x, self.pos.y, 0 + 3 * on)
			GuiSprite.Draw(self.pos.x, self.pos.y + buttonheight - ImgHeight, 9 + 3 * on)

			For i = 1 To (width / ImgWidth) - 1
				GuiSprite.DrawClipped(self.pos.x + i * ImgWidth, self.pos.y, self.pos.x, self.pos.y, width - ImgWidth, Height, 0, 0, 1 + 3 * on)
				GuiSprite.DrawClipped(self.pos.x + i * ImgWidth, self.pos.y + ImgHeight, self.pos.x, self.pos.y, width - ImgWidth, Height, 0, 0, 10 + 3 * on)
			Next
			SetViewport(GetViewPortX, GetViewPortY, GetViewPortWidth, GetViewPortHeight)
			GuiSprite.Draw(self.pos.x + width - ImgWidth, self.pos.y, 2 + 3 * on)
			GuiSprite.Draw(self.pos.x + width - ImgWidth, self.pos.y + ImgHeight, 11 + 3 * on)
		End If
		If on = 0 Or grayedout
			GuiSprite.Draw(self.pos.x, self.pos.y, 0 + 3 * on)
			GuiSprite.Draw(self.pos.x, self.pos.y + buttonheight - ImgHeight, 9 + 3 * on)

			For i = 1 To (width / ImgWidth) - 1
				GuiSprite.DrawClipped(self.pos.x + i * ImgWidth, self.pos.y, self.pos.x, self.pos.y, width - ImgWidth, Height, 0, 0, 1 + 3 * on)
				GuiSprite.DrawClipped(self.pos.x + i * ImgWidth, self.pos.y + ImgHeight, self.pos.x, self.pos.y, width - ImgWidth, Height, 0, 0, 10 + 3 * on)
			Next
			SetViewport(GetViewPortX, GetViewPortY, GetViewPortWidth, GetViewPortHeight)
			GuiSprite.Draw(self.pos.x + width - ImgWidth, self.pos.y, 2 + 3 * on)
			GuiSprite.Draw(self.pos.x + width - ImgWidth, self.pos.y + ImgHeight, 11 + 3 * on)
		EndIf
		If on Or grayedout
			If grayedout Then SetAlpha 0.7
			DrawText(value, self.pos.x + (width - TextWidth(value)) / 2 - 4, self.pos.y - (TextHeight(value) - buttonheight) / 2 - 2)
			If grayedout Then SetAlpha 1.0
	    Else
			SetColor 230, 230, 230
			DrawText(value, self.pos.x + (width - TextWidth(value)) / 2 - 4 + 1, self.pos.y - (TextHeight(value) - buttonheight) / 2 - 1)
			SetColor 255, 255, 255
		EndIf
        If grayedout = 1 Then on = 2
		'debuglog ("GUIradiobutton zeichnen")
	End Method
End Type



Type TGUIOkButton  Extends TGUIobject
	Field crossed:Byte = 0
	field onoffstate:string = "off"
	field assetWidth:float = 1.0

	Function Create:TGUIOkButton(x:Int,y:Int,on:Byte = 0, enabled:Byte = 1, value:String, State:String="")
		Local obj:TGUIOkButton=New TGUIOkButton
		obj.pos.setXY( x,y )
		obj.on			= on
		obj._enabled 	= enabled
		obj.scale		= GUIManager.globalScale
		obj.width 		= Assets.GetSprite("gfx_gui_ok_off").w * obj.scale
		obj.height	 	= Assets.GetSprite("gfx_gui_ok_off").h * obj.scale
		obj.assetWidth	= Assets.GetSprite("gfx_gui_ok_off").w
		obj.value		= value
		obj.forstateonly= State
		obj.zindex		= 50
		obj.crossed		= on
		obj.typ			= "okbutton"
		obj.uid			= obj.GetNewID()
		GUIManager.Add( obj )
		Return obj
	End Function

	Method Update()
		If clicked Then crossed = 1-crossed; clicked = 0
		If crossed Then on = 1 Else on = 0
		if crossed then self.onoffstate = "on" else self.onoffstate = "off"
		'disable "active state"
		if self.state = ".active" then self.state = ".hover"
	End Method

	Method IsCrossed:Int()
		return crossed & 1
		'If crossed = 1 Then Return 1 Else Return 0
	End Method

	Method Draw()
		if self.scale <> 1.0 then SetScale self.scale, self.scale
		Assets.GetSprite("gfx_gui_ok_"+self.onoffstate+self.state).Draw(self.pos.x, self.pos.y)
		if self.scale <> 1.0 then SetScale 1.0,1.0

		local textDisplaceX:int = 5
		SetColor 50,50,100
		DrawText(value, self.pos.x+self.assetWidth*self.scale + textDisplaceX, self.pos.y - (TextHeight(value) - height) / 2 - 1)
		width = self.assetWidth*self.scale + textDisplaceX + TextWidth(value)
		SetColor 255,255,255
	End Method

End Type

Type TGUIbackground Extends TGUIobject
    Field guigfx:Int =0
    Function Create:TGUIbackground(x:Int,y:Int,width:Int, height:Int, Own:Int=0, State:String="")
    print "OLD OWN-Param : TGUIbackground"
		Local GUIbackground:TGUIbackground = New TGUIbackground
			GUIbackground.pos.setXY( x,y )
		 GUIbackground._enabled = 1
		 If width < 0 Then width = 40
		 GUIbackground.width    = width
		 GUIbackground.height   = height
		 GUIbackground.value$   = ""
		 GUIbackground.typ$     = "background"
		 GUIbackground.forstateonly = State$

		GUIManager.Add( GUIbackground )

		Return GUIbackground
	End Function

	Method Update()

	End Method

	Method Draw()
'		If guigfx = 0 DrawImage(gfx_nw_option, x, y)
   	        SetViewport(GetViewPortX, GetViewPortY, GetViewPortWidth, GetViewPortHeight)
       End Method
End Type

Type TGUIListEntries   'Listeneintraege der GUIListe
  Global List:TList
  Field value:String
  Field title:String
  Field pid: Int
  Field team:String
  Field ip:String
  Field port:String
  Field time:Int

  Function Create:TGUIListEntries(title:String, value:String, team:String,pid:Int, ip:String="", port:String="", time:Int=0)
    Local GUIListEntries:TGUIListEntries = New TGUIListEntries
    'DebugLog("entry created")
	GUIListEntries.title$ = title$
	GUIListEntries.value$ = value$
	GUIListEntries.team$ = team$
	GUIListEntries.pid    = pid
	GUIListEntries.port$   = port$
	GUIListEntries.ip$     = ip$
	GUIListEntries.time    = time

    Return GUIListEntries
  End Function
End Type

Type TGUIList  Extends TGUIobject
    Field maxlength:Int
    Field filter:String
	Field buttonclicked: Int
	Field ListStartsAtPos :Int
	Field PosChangeTimer: Int
	Field ListPosClicked:Int
	Field GUIbackground: TGUIbackground
'	Field Entries:TGUIListEntries = New TGUIListEntries
	Field EntryList: TList
	Field ControlEnabled:Int = 0
	Field lastMouseClickTime:Int = 0
	Field LastMouseClickPos:Int = 0
    Field nobackground:Int

    Function Create:TGUIList(x:Int, y:Int, width:Int, height:Int = 50, enabled:Byte = 1, maxlength:Int = 128, State:String = "")
		Local GUIList:TGUIList=New TGUIList
			GUIList.pos.setXY( x,y )
		 GUIList._enabled = enabled
		 If width < 40 Then width = 40
		 GUIList.width    = width
		 GUIList.height   = height
		 GUIList.uid      = Rand(1,10000)
		 GUIList.maxlength= maxlength
		 guilist.typ      = "list"
		 guilist.PosChangeTimer  = MilliSecs()
		 guilist.ListStartsAtPos = 0
		 guilist.ListPosClicked = -1
		 guilist.GUIbackground:TGUIbackground = New TGUIbackground
		 guilist.GUIbackground.pos.setXY( x,y )
		 guilist.GUIbackground.width = width
		 guilist.GUIbackground.height = height
		 guilist.GUIbackground.typ$     = "background"

		 GUIList.forstateonly = State$


	     If not guilist.EntryList Then guilist.EntryList = CreateList()

		GUIManager.Add( GUIList )
	  	 Return GUIList
	End Function

	Method Update()
		'
	End Method

	Method DisableBackground()
		Self.nobackground = True
	End Method

	Method SetControlState(on:Int = 1)
		Self.ControlEnabled = on
	End Method

	Method SetFilter:Int(usefilter:String = "")
	  filter$ = usefilter$
	End Method

 	Method RemoveOldEntries:Int(uid:Int=0, timeout:Int=500)
	  Local i:Int = 0
	  Local RemoveTime:Int = MilliSecs()
	  For local Entries:TGUIListEntries = EachIn self.EntryList
        If Entries.pid = uid
		  if Entries.time = 0 then Entries.time = Millisecs()
          If Entries.time +timeout < RemoveTime
		    Print (entries.time + timeout)+"<"+RemoveTime
	        ListRemove EntryList,(Entries)
	      EndIf
	    EndIf
  	    i = i + 1
 	  Next
 	  Return i
	End Method


	Method AddUniqueEntry:Int(title$, value$, team$, ip$, port$, time:Int, usefilter:String = "")
      If filter$ = "" Or filter$ = usefilter$
	    For local Entries:TGUIListEntries = EachIn self.EntryList 'Liste hier global
          If Entries.pid = uid
            If Entries.ip$ = ip$ And Entries.port$ = port$
  		      Entries.time = time
			  If time = 0 Then Entries.time = MilliSecs()
		      Entries.team$ = team$
		      Entries.value = value
		      Return 0
	        EndIf
	      EndIf
 	    Next
		EntryList.AddLast( TGUIListEntries.Create(title, value, team, uid, ip, port, time) )
      EndIf
	End Method

 	Method GetEntryCount:Int()
	    Return EntryList.count()
	End Method

 	Method GetEntryPort:String()
	    Local i:Int = 0
	    For local Entries:TGUIListEntries = EachIn self.EntryList 'Liste hier lokal
	      If i = ListPosClicked
	          Return Entries.port$
	      EndIf
  	      i = i + 1
	    Next
	End Method

	Method GetEntryTime:Int()
	    Local i:Int = 0
  	    For local Entries:TGUIListEntries = EachIn EntryList 'Liste hier lokal
   	        If i = ListPosClicked
	          Return Entries.time
	        EndIf
  	      i = i + 1
	    Next
	End Method

	Method GetEntryValue:String()
	    Local i:Int = 0
  	    For local Entries:TGUIListEntries = EachIn EntryList 'Liste hier lokal
   	        If i = ListPosClicked
	          Return Entries.value$
	      EndIf
  	      i = i + 1
	    Next
	End Method

	Method GetEntryTitle:String()
	    Local i:Int = 0
  	    For local Entries:TGUIListEntries = EachIn EntryList 'Liste hier lokal
			If i = ListPosClicked Then Return Entries.title:String
  	      	i:+1
	    Next
	End Method

	Method GetEntryIP:String()
	    Local i:Int = 0
  	    For local Entries:TGUIListEntries = EachIn EntryList
 	        If i = ListPosClicked Then Return Entries.ip:String
  	      	i:+1
	    Next
	End Method

	Method ClearEntries()
		EntryList.Clear()
	End Method

	Method AddEntry(title$, value$, team$, ip$, port$, time:Int)
	  If time = 0 Then time = MilliSecs()
	  EntryList.AddLast(TGUIListEntries.Create(title$, value$,team$,uid, ip$, port$, time))
	End Method

	Method Draw()
		Local i:Int = 0
		Local spaceavaiable:Int =0
		Local Zeit : Int
		Local printvalue:String
		Zeit = MilliSecs()
        If GUIManager.getActive() = uid Then on = 1 Else on = 0
		If Not Self.nobackground
		    If GUIbackground <> Null
			 GUIbackground.pos.setPos(self.pos)
			 GUIbackground.width = width
			 GUIbackground.height = height
	        Else
				gfx_GuiPack.GetSprite("Chat_Top").Draw(self.pos.x, self.pos.y)
				gfx_GuiPack.GetSprite("Chat_Middle").TileDraw(self.pos.x, self.pos.y + gfx_GuiPack.GetSprite("Chat_Top").h, gfx_GuiPack.GetSprite("Chat_Middle").w, Self.height - gfx_GuiPack.GetSprite("Chat_Top").h - gfx_GuiPack.GetSprite("Chat_Bottom").h)
				gfx_GuiPack.GetSprite("Chat_Bottom").Draw(self.pos.x, self.pos.y + Self.height, 0, 1)
	        EndIf
		EndIf
		SetViewport(self.pos.x, self.pos.y, width - 12, height)
	    i = 0
		SpaceAvaiable = height 'Hoehe der Liste
		Local controlWidth:Float = ControlEnabled * gfx_GuiPack.GetSprite("ListControl").framew
	    For local Entries:TGUIListEntries = EachIn EntryList 'Liste hier global
		  If i > ListStartsAtPos-1 Then
	  	    If TextHeight(Entries.value$) < SpaceAvaiable
			  If Int(Entries.team$) > 0
			    printValue$ = "[Team "+Entries.team$ + "]: "+Entries.value$
			  Else
			    printValue$ = Entries.value$
			  EndIf
			  While TextWidth(printValue$+"...") > width-4-18
		    	printvalue$= printValue$[..printvalue$.length-1]
	      	  Wend
	          If Int(Entries.team$) > 0
	            If printvalue$ <> "[Team "+Entries.team$ + "]: "+Entries.value$   printvalue$ = printvalue$+"..."
	          Else
	            If printvalue$ <> Entries.value$   printvalue$ = printvalue$+"..."
	          EndIf
		      If i = ListPosClicked
			    SetAlpha(0.5)
		        SetColor(250,180,20)
		        DrawRect(self.pos.x+8,self.pos.y+8+height-SpaceAvaiable ,width-12, TextHeight(printvalue$))
		        SetAlpha(1)
		        SetColor(255,255,255)
 			  EndIf
              If ListPosClicked = i SetColor(250, 180, 20)
			  If MouseX() > self.pos.x + 5 And MouseX() < self.pos.x + width - 6 - ControlWidth And MouseY() > self.pos.y + 5 + height - Spaceavaiable And MouseY() < self.pos.y + 5 + height - Spaceavaiable + TextHeight(printvalue)
		        SetAlpha(0.5)
		        DrawRect(self.pos.x+8,self.pos.y+8+height-SpaceAvaiable ,width-12, TextHeight(printvalue$))
		        SetAlpha(1)
		        If MouseIsDown=1
				  ListPosClicked = i
				  If LastMouseClickPos = i
				    If LastMouseClickTime + 50 < MilliSecs() And LastMouseClicktime +700 > MilliSecs()
				      If Self._onDoubleClickFunc <> Null Then Print "doubleclickfunc";Self._onDoubleClickFunc(Self)
				    EndIf
				  EndIf
				  LastMouseClickTime = MilliSecs()
				  LastMouseClickPos = i
				EndIf
 		      EndIf
	            If Entries.team$ = "0" SetColor(255,0,200)
	            If Entries.team$ = "1" SetColor(255,0,0)
	            If Entries.team$ = "2" SetColor(0,0,255)
	            If Entries.team$ = "3" SetColor(255,255,0)
	            If Entries.team$ = "4" SetColor(0,255,0)
	            If Entries.team$ = "5" SetColor(0,255,255)
	            If Entries.team$ = "6" SetColor(120,0,255)
	            SetColor(55,55,55)
  	            DrawText(TStringHelper.gparam(printvalue$,1,Asc(":")), self.pos.x+13, self.pos.y+8+height-SpaceAvaiable)
	            SetColor(55,55,55)
  	            DrawText(TStringHelper.gparam(printvalue$,2,Asc(":")), self.pos.x+13+TextWidth(TStringHelper.gparam(printvalue$,1,Asc(":"))), self.pos.y+8+height-SpaceAvaiable)
	            SetColor(255,255,255)
                SpaceAvaiable:-TextHeight(printvalue)
            EndIf
          EndIf
          i= i+1
  		Next
		     SetViewport(GetViewPortX, GetViewPortY, GetViewPortWidth, GetViewPortHeight)
rem 01.05.09
          If GUIbackground <> Null
		  	'DrawImage(gfx_gamelobby_playerlist,x,y)
			gfx_GuiPack.GetSprite("Chat_Top").Draw(x, y)
			gfx_GuiPack.GetSprite("Chat_Middle").TileDraw(x, self.pos.y + gfx_GuiPack.GetSprite("Chat_Top").h, gfx_GuiPack.GetSprite("Chat_Middle").w, Self.height - gfx_GuiPack.GetSprite("Chat_Top").h - gfx_GuiPack.GetSprite("Chat_Bottom").h)
			gfx_GuiPack.GetSprite("Chat_Bottom").Draw(x, self.pos.y + Self.height, 0, 1)
		  EndIf
endrem
    If ControlEnabled = 1
		Local guiListControl:TGW_Sprites = gfx_GuiPack.GetSprite("ListControl")
		For i = 0 To Ceil(Height / guiListControl.frameh) - 1
  		  guiListControl.Draw(self.pos.x + width - guiListControl.framew, self.pos.y + i * guiListControl.frameh, 7)
		Next
        If GUIManager.getActive() = uid and MouseIsDown=1 and self.clickedPos.x >= self.pos.x+width-14 and self.clickedPos.y <= self.pos.y+14
          guiListControl.Draw(self.pos.x + width - 14, self.pos.y, 1)
          If PosChangeTimer + 250 < Zeit and ListStartsAtPos > 0
            ListStartsAtPos = ListStartsAtPos -1
            PosChangeTimer = Zeit
          EndIf
	    Else
	      guiListControl.Draw(self.pos.x + width - 14, self.pos.y, 0)
        EndIf

        If GUIManager.getActive() = uid and MouseIsDown=1 and self.clickedPos.x >= self.pos.x+width-14 and self.clickedPos.y >= self.pos.y+height-14
          guiListControl.Draw(self.pos.x + width - 14, self.pos.y + Height - 14, 5)
          If PosChangeTimer + 250 < Zeit And ListStartsAtPos < Int(EntryList.Count() - 2)
            ListStartsAtPos = ListStartsAtPos + 1
            PosChangeTimer = Zeit
          EndIf
        Else
          guiListControl.Draw(self.pos.x + width - 14, self.pos.y + Height - 14, 4)
		EndIf
    EndIf 'ControlEnabled

		SetColor 255,255,255
	End Method

End Type

Type TGUIChat  Extends TGUIList
    Field AutoScroll:Int
    Field turndirection:Int = 0
    Field fadeout:Int = 0
    Field GUIInput: TGUIinput
    Field guichatgfx:Int=1
    Field colR:Int =110
    Field colG:Int =110
    Field ColB:Int =110
	Field EnterPressed:Int = 0
	Field _UpdateFunc_()
	Field TeamNames:String[5]
	Field TeamColors:TPlayerColor[5]
	Field Font:TImageFont

    Function Create:TGUIChat(x:Int, y:Int, width:Int, height:Int = 50, enabled:Byte = 1, maxlength:Int = 128, State:String = "")
		Local GUIChat:TGUIChat=New TGUIChat
			GUIChat.pos.setXY( x,y )
		 GUIChat._enabled = enabled
		 If width < 40 Then width = 40
		 GUIChat.width    = width
		 GUIChat.height   = height
		 GUIChat.uid      = Rand(1,10000)
		 GUIChat.maxlength= maxlength
		 GUIChat.typ      = "list"
		 GUIChat.PosChangeTimer  = MilliSecs()
		 GUIChat.ListStartsAtPos = 0
		 GUIChat.ListPosClicked = -1
		 GUIChat.GUIInput:TGUIinput = New TGUIinput
		 GUIChat.ParentGUIObject = GUIChat
		 GUIChat.GUIInput.pos.setXY( x+8, y+height-26 -3)
		 GUIChat.GUIInput.width = width-30
		 GUIChat.GUIInput.uid = GUIchat.uid
		 GUIChat.GUIInput.maxlength = 100
		 GUIChat.GUIInput.height = 20
		 GUIChat.GUIInput.typ$     = "input"
		 GUIchat.GUIInput.colR = 50
		 GUIchat.GUIInput.colG = 50
		 GUIchat.GUIInput.ColB = 50

		 GUIchat.GUIInput.nobackground = 1
'		 guichat.guichatgfx = 1
		 GUIchat.nobackground = 1


		 GUIChat.GUIbackground:TGUIbackground = New TGUIbackground
		 GUIChat.GUIbackground.pos.setXY( x,y )
		 GUIChat.GUIbackground.width = width
		 GUIChat.GUIbackground.height = height
		 GUIChat.GUIbackground.typ$     = "background"
		 GUIchat.AutoScroll  = 1

		 GUIChat.forstateonly = State$


	     If not guichat.EntryList Then guichat.EntryList = CreateList()

		GUIManager.Add( GUIChat )
	  	 Return GUIChat
	End Function

   	Method Update()
		Self.EnterPressed = Self.GUIInput.EnterPressed
		Self.GUIInput.Update()
		If Self.EnterPressed = 1 Then GUIManager.setActive(Self.uid)
		_UpdateFunc_()
       If GUIManager.getActive() = uid Then on = 1 Else on = 0
	End Method


	Method Draw()
		Local OldFont:TImageFont = Null
		If Self.Font <> Null Then OldFont = GetImageFont() ;SetImageFont(Self.Font)
	  Local SpaceAvaiable:Int = 0
  	  Local i:Int =0
	   Local chatinputheight:Int
	   Local Zeit : Int = MilliSecs()
	   Local printvalue:String
	   Local charcount:Int
	   Local charpos:Int
	   Local lineprintvalue:String=""
	   If nobackground = 0
			GUIbackground.pos.setPos(self.pos)
		 GUIbackground.width = width
		 GUIbackground.height = height

                 GUIbackground.Draw()
                 chatinputheight = 0
	   Else
	    If guichatgfx > 0
			gfx_GuiPack.GetSprite("Chat_Top").Draw(self.pos.x, self.pos.y)
			gfx_GuiPack.GetSprite("Chat_Middle").TileDraw(self.pos.x, self.pos.y + gfx_GuiPack.GetSprite("Chat_Top").h, gfx_GuiPack.GetSprite("Chat_Middle").w, Self.height - gfx_GuiPack.GetSprite("Chat_Top").h - gfx_GuiPack.GetSprite("Chat_Input").h)
			gfx_GuiPack.GetSprite("Chat_Input").Draw(self.pos.x, self.pos.y + Self.height, 0, 1)
	    EndIf
	    chatinputheight = 35
  	   EndIf
		SetViewport(self.pos.x,self.pos.y,width-18, height)
		SpaceAvaiable = height 'Hoehe der Liste
	    i = 0

	    For local Entries:TGUIListEntries = EachIn EntryList 'Liste hier global
          if fadeout Then SetAlpha (7 - Float(MilliSecs() - Entries.time)/1000)
		  If i > ListStartsAtPos-1 Then
	  	    If AutoScroll=1 and TextHeight(Entries.value$) > SpaceAvaiable-chatinputheight   ListStartsAtPos = ListStartsAtPos +1
	  	    If TextHeight(Entries.value$) < SpaceAvaiable-chatinputheight
			  printValue$		= Entries.value$
		      lineprintvalue$	= printvalue$
              Local playerID:Int = Int(Entries.team)
              Local linenumber:Int =1
		      Repeat
			    Local playername:String = ""
				If PlayerID > 0 Then playername = Self.TeamNames[PlayerID]
				If PlayerID <=0 Then playername = "System:"
                If linenumber = 1
                 If Not turndirection
	      	      If PlayerID > 0 Then
				    SetAlpha 0.5
					SetColor(50, 50, 50)
					functions.DrawTextWithBG(playername + ": ", self.pos.x + 12, self.pos.y + 10 + Height - SpaceAvaiable, 0.5, 255)
				    SetAlpha 1.0
	      	        SetColor(TeamColors[PlayerID].colR,TeamColors[PlayerID].colG,TeamColors[PlayerID].ColB)
	  	          EndIf
				  If PlayerID <=0 Then SetColor 150,150,150
				  functions.DrawTextWithBg(playername + ": ", self.pos.x + 11, self.pos.y + 9 + Height - SpaceAvaiable, 0.5, 255)
	  	         Else
	      	      If PlayerID > 0 Then
				    SetAlpha 0.5
				    SetColor(50,50,50)
	  	            functions.DrawTextWithBG(playername + ": ", self.pos.x + 12, self.pos.y + 10 + SpaceAvaiable, 0.5, 255)
				    SetAlpha 1.0
	      	        SetColor(TeamColors[PlayerID].colR,TeamColors[PlayerID].colG,TeamColors[PlayerID].ColB)
	  	          EndIf
				  If PlayerID <=0 Then SetColor 100,100,100
	  	          functions.DrawTextWithBG(playername + ": ", self.pos.x + 11, self.pos.y + 9 + SpaceAvaiable, 0.5, 255)
 	  	         EndIf
                EndIf
			    charcount = 0
			    While TextWidth(playername + ": " + lineprintValue) > width - 4 - 25
					If lineprintvalue.Length > 1
			       	    For charpos = 0 To lineprintvalue.length - 1
			       	     If lineprintvalue[charpos] = Asc(" ")    charcount = charpos
			       	     If lineprintvalue[charpos] = Asc("-")    charcount = charpos-1
			       	    Next
			       	    lineprintValue = lineprintValue[..CharCount]
					EndIf
	      	    Wend
		        SetColor(50,50,50)
				If PlayerID > 0
  			      SetAlpha 0.5
                  If Not turndirection
  	  	            functions.DrawTextWithBG(lineprintvalue, self.pos.x + 13 + TextWidth(Playername + ": "), self.pos.y + 10 + Height - SpaceAvaiable)
		          Else
  	  	            functions.DrawTextWithBG(lineprintvalue, self.pos.x + 14 + TextWidth(Playername + ": "), self.pos.y + 10 + SpaceAvaiable)
		          EndIf
				  SetAlpha 1.0
		        EndIf
				SetColor(colR,colG,ColB)
                If Not turndirection
  	  	          functions.DrawTextWithBG(lineprintvalue, self.pos.x + 13 + TextWidth(Playername + ": "), self.pos.y + 9 + Height - SpaceAvaiable)
		        Else
  	  	          functions.DrawTextWithBG(lineprintvalue, self.pos.x + 13 + TextWidth(Playername + ": "), self.pos.y + 9 + SpaceAvaiable)
		        EndIf
		        SpaceAvaiable = SpaceAvaiable - TextHeight(lineprintvalue$)
                lineprintvalue$ = printvalue$[charcount+1..]
                linenumber:+1
      	      Until charcount=0
	      '    If printvalue$ <> Entries.value$   printvalue$ = printvalue$+"..."
            EndIf
          EndIf
          i= i+1
          If fadeout Then SetAlpha (1)
          If fadeout And (7 - Float(MilliSecs() - Entries.time)/1000) <=0 Then EntryList.Remove(Entries)
  		Next
		     SetViewport(GetViewPortX,GetViewPortY,GetViewPortWidth,GetViewPortHeight)

           GUIInput.Draw()

		Local guiListControl:TGW_Sprites = gfx_GuiPack.GetSprite("ListControl")
	   If nobackground = 0
		For i = 0 To Ceil(Height / guiListControl.frameh) - 1
  		  guiListControl.Draw(self.pos.x + width - guiListControl.framew, self.pos.y + i * guiListControl.frameh, 7)
		Next
        If GUIManager.getActive() = uid And MouseIsDown=1 And self.clickedPos.x >= self.pos.x+width-14 And self.clickedPos.y <= self.pos.y+14
          guiListControl.Draw(self.pos.x + width - 14, self.pos.y, 1)
          If PosChangeTimer + 250 < Zeit And ListStartsAtPos > 0
            ListStartsAtPos = ListStartsAtPos -1
            PosChangeTimer = Zeit
          EndIf
	    Else
	      guiListControl.Draw(self.pos.x + width - 14, self.pos.y, 0)
        EndIf

        If GUIManager.getActive() = uid and MouseIsDown=1 and self.clickedPos.x >= self.pos.x+width-14 and self.clickedPos.y >= self.pos.y+height-14
          guiListControl.Draw(self.pos.x + width - 14, self.pos.y + Height - 14, 5)
          If PosChangeTimer + 250 < Zeit And ListStartsAtPos < Int(EntryList.Count() - 2)
            ListStartsAtPos = ListStartsAtPos + 1
            PosChangeTimer = Zeit
          EndIf
        Else
          guiListControl.Draw(self.pos.x + width - 14, self.pos.y + Height - 14, 4)
		EndIf
		If Self.Font <> Null Then SetImageFont(OldFont)

	EndIf 'nobackground

		SetColor 255,255,255
	  '  debuglog ("GUIList zeichnen")
	End Method

End Type
