'Author: Ronny Otto

SuperStrict
Import brl.font
Import brl.basic

Type TGW_FontManager
	Field DefaultFont:TGW_Font
	Field List:TList = CreateList()

	Function Create:TGW_FontManager()
		Local tmpObj:TGW_FontManager = New TGW_FontManager
		tmpObj.List = CreateList()
		Return tmpObj
	End Function

	Method GW_GetFont:TImageFont(_FName:String, _FSize:Int = -1, _FStyle:Int = -1)
		if _FName = "Default" and _FSize = -1 and _FStyle = -1 then return DefaultFont.FFont
		If _FSize = -1 Then _FSize = DefaultFont.FSize
		If _FStyle = -1 Then _FStyle = DefaultFont.FStyle else _FStyle :+ SMOOTHFONT

		local defaultFontFile:string = DefaultFont.FFile
		For local Font:TGW_Font = EachIn Self.List
			If Font.FName = _FName AND Font.FStyle = _FStyle then defaultFontFile = Font.FFile
			If Font.FName = _FName And Font.FSize = _FSize AND Font.FStyle = _FStyle then return Font.FFont
		Next
		Return AddFont(_FName, defaultFontFile, _FSize, _FStyle).FFont
	End Method

	Method AddFont:TGW_Font(_FName:String, _FFile:String, _FSize:Int, _FStyle:int)
		If _FSize = -1 Then _FSize = DefaultFont.FSize
		If _FStyle = -1 Then _FStyle = DefaultFont.FStyle
		If _FFile = "" Then _FFile = DefaultFont.FFile

		Local Font:TGW_Font = TGW_Font.Create(_FName, _FFile, _FSize, _FStyle)
		Self.List.AddLast(Font)
		Return Font
	End Method
End Type

Type TGW_Font
	Field FName:String
	Field FFile:String
	Field FSize:Int
	Field FStyle:Int
	Field FFont:TImageFont

	Function Create:TGW_Font(_FName:String, _FFile:String, _FSize:Int, _FStyle:Int)
		Local tmpObj:TGW_Font = New TGW_Font
		tmpObj.FName = _FName
		tmpObj.FFile = _FFile
		tmpObj.FSize = _FSize
		tmpObj.FStyle = _FStyle
		tmpObj.FFont = LoadImageFont(_FFile, _FSize, SMOOTHFONT + _FStyle)
		Return tmpObj
	End Function
End Type