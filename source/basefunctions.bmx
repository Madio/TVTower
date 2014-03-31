﻿SuperStrict
Import brl.pngloader
Import "basefunctions_zip.bmx"
Import "basefunctions_localization.bmx"
'Import "basefunctions_text.bmx"
Import "basefunctions_keymanager.bmx"	'holds pressed Keys and Mousebuttons for one mainloop instead of resetting it like MouseHit()
Import brl.reflection
?Threaded
Import Brl.threads
?
'Import bah.libxml
Import "external/libxml/libxml.bmx"
Import "external/persistence.mod/persistence.bmx"


'Mersenne: Random numbers
'reproduceable random numbers for network
Import "basefunctions_mersenne.c"

Extern "c"
  Function SeedRand(seed:int)
  Function Rand32:Int()
  Function RandMax:Int(hi:int)
  Function RandRange:Int(lo:int,hi:int)
End Extern
'------------------------

Type TApplicationSettings
	field fullscreen:int	= 0
	field directx:int		= 0
	field colordepth:int	= 16
	field realWidth:int		= 800
	field realHeight:int	= 600
	field designedWidth:int	= 800
	field designedHeight:int= 600
	field hertz:int			= 60
	field flag:Int			= 0 'GRAPHICS_BACKBUFFER | GRAPHICS_ALPHABUFFER '& GRAPHICS_ACCUMBUFFER & GRAPHICS_DEPTHBUFFER

	Function Create:TApplicationSettings()
		local obj:TApplicationSettings = new TApplicationSettings
		return obj
	End Function

	Method GetHeight:int()
		return self.designedHeight
	End Method

	Method GetWidth:int()
		return self.designedWidth
	End Method

End Type







' -----------------------------------------------------------------------------
' USAGE: Note that the order is important!
' -----------------------------------------------------------------------------

' 1) Call InitVirtualGraphics before anything else;
' 2) Call Graphics as normal to create display;
' 3) Call SetVirtualGraphics to set virtual display size.

' The optional 'monitor_stretch' parameter of SetVirtualGraphics is there
' because some monitors have the option to stretch non-native ratios to native
' ratios, and you cannot detect this programmatically.

' For instance, my monitor's native resolution is 1920 x 1080, and if I set the
' Graphics mode to 1024, 768, it defaults to stretching that to fill the screen,
' meaning the image is stretched horizontally, so a square will appear non-
' square; however, it also provides an option to scale to the correct aspect
' ratio. Since this is set on the monitor, there's no way to detect or correct
' it other than by offering the option to the user. Leave it off if unsure...

Type TVirtualGfx
	Global instance:TVirtualGfx

	Global DTInitComplete:Int = False
	Global DTW:Int
	Global DTH:Int

	Field vwidth:Int
	Field vheight:Int

	Field vxoff:Float
	Field vyoff:Float

	Field vscale:Float

	Method Create:TVirtualGfx (width:Int, height:Int)
		self.instance = self
		self.vwidth = width
		self.vheight = height

		return self
	End Method

	Function getInstance:TVirtualGfx()
		if not TVirtualGfx.instance then new TVirtualGfx.Create(800, 600)

		return TVirtualGfx.instance
	End Function

	Method Init()
		' There must be a smarter way to check if Graphics has been called...
		If GraphicsWidth () > 0 Or GraphicsHeight () > 0 Then EndGraphics; Notify "Programmer error! Call InitVirtualGraphics BEFORE Graphics!", True; End
		self.DTW = DesktopWidth ()
		self.DTH = DesktopHeight ()
		' This only checks once... best to call InitVirtualGraphics again before any further Graphics calls (if you call EndGraphics at all)...
		self.DTInitComplete = True
	End Method

	Function SetVirtualGraphics (vwidth:Int, vheight:Int, monitor_stretch:Int = False)
		' InitVirtualGraphics has been called...
		If getInstance().DTInitComplete
			' Graphics has been called...
			If GraphicsWidth () = 0 Or GraphicsHeight () = 0
				Notify "Programmer error! Must call Graphics before SetVirtualGraphics", True; End
			EndIf
		Else
			EndGraphics; Notify "Programmer error! Call InitVirtualGraphics before Graphics!", True; End
		EndIf

		' Reset of display needed when re-calculating virtual graphics stuff/clearing borders...
		SetVirtualResolution( GraphicsWidth(), GraphicsHeight() )
		SetViewport( 0, 0, GraphicsWidth(), GraphicsHeight() )
		SetOrigin( 0, 0 )

		' Store current Cls colours...
		Local clsr:Int, clsg:Int, clsb:Int
		GetClsColor clsr, clsg, clsb

		' Set to black...
		SetClsColor 0, 0, 0

		' Got to clear both front AND back buffers or it flickers if new display area is smaller...
		Cls;Flip
		Cls;Flip
		Cls;Flip

		SetClsColor clsr, clsg, clsb

		' Create new (global) virtual display object...
		local instance:TVirtualGfx = new TVirtualGfx.Create( vwidth, vheight )

		' Real Graphics width/height...
		Local gwidth:Int = GraphicsWidth()
		Local gheight:Int = GraphicsHeight()

		' If monitor is correcting aspect ratio IN FULL-SCREEN MODE, use desktop size, otherwise use
		' specified Graphics size. NB. This assumes user's desktop is using native monitor resolution,
		' as most laptops would be by default...
		If monitor_stretch And GraphicsDepth()
			' Pretend real Graphics mode is desktop width/height...
			gwidth = DTW
			gheight = DTH
		EndIf

		' Width/height ratios...
		Local graphicsratio:Float = Float(gwidth) / Float(gheight)
		Local virtualratio:Float = Float(instance.vwidth) / Float(instance.vheight)

		' Ratio-to-ratio. Don't even know what you'd call this, but hours of trial and error
		' provided the right numbers in the end...
		Local gtovratio:Float = graphicsratio / virtualratio
		Local vtogratio:Float = virtualratio / graphicsratio

		' Compare ratios...
		If graphicsratio => virtualratio
			' Graphics ratio wider than (or same as) virtual graphics ratio...
			instance.vscale = Float(gheight) / Float(instance.vheight)

			' Now go crazy with trial-and-error... ooh, it works! This tiny bit of code took FOREVER.
			Local pixels:Float = Float (instance.vwidth) / (1.0 / instance.vscale) ' Width after scaling
			Local half_scale:Float = (1.0 / instance.vscale) / 2.0

			SetVirtualResolution( instance.vwidth * gtovratio, instance.vheight )

			' Offset into 'real' display area...

			instance.vxoff = (gwidth - pixels) * half_scale
			instance.vyoff = 0

		Else
			' Graphics ratio narrower...
			instance.vscale = Float (gwidth) / Float (instance.vwidth)

			Local pixels:Float = Float (instance.vheight) / (1.0 / instance.vscale) ' Height after scaling
			Local half_scale:Float = (1.0 / instance.vscale) / 2.0

			SetVirtualResolution instance.vwidth, instance.vheight * vtogratio

			instance.vxoff = 0
			instance.vyoff = (gheight - pixels) * half_scale
		EndIf

		' Set up virtual graphics area...
		SetViewport( instance.vxoff, instance.vyoff, instance.vwidth, instance.vheight )
		SetOrigin( instance.vxoff, instance.vyoff )
	End Function

	Method VMouseX:Float ()
		Local mx:Float = VirtualMouseX () - vxoff
		If mx < 0 Then mx = 0 Else If mx > vwidth - 1 Then mx = vwidth - 1
		Return mx
	End Method

	Method VMouseY:Float ()
		Local my:Float = VirtualMouseY () - vyoff
		If my < 0 Then my = 0 Else If my > vheight - 1 Then my = vheight - 1
		Return my
	End Method

	Method VirtualWidth:Int ()
		Return vwidth
	End Method

	Method VirtualHeight:Int ()
		Return vheight
	End Method

	Method VirtualGrabPixmap:TPixmap(x:int,y:int,w:int,h:int)
		local scaleX:float = float(GraphicsWidth()) / float(self.vwidth)
		local scaleY:float = float(GraphicsHeight()) / float(self.vheight)
		return _max2dDriver.GrabPixmap(float(X)*scaleX + self.vxoff, float(Y)*scaleY + self.vyoff, float(w)*scaleX, float(h)*scaleY)
	End Method

End Type

' -----------------------------------------------------------------------------
' ... and these helper functions (required)...
' -----------------------------------------------------------------------------
Function InitVirtualGraphics ()
	TVirtualGfx.getInstance().Init()
End Function

Function SetVirtualGraphics (vwidth:Int, vheight:Int, monitor_stretch:Int = False)
	TVirtualGfx.SetVirtualGraphics (vwidth, vheight, monitor_stretch)
End Function

Function VMouseX:Float ()
	Return TVirtualGfx.getInstance().VMouseX ()
End Function

Function VMouseY:Float ()
	Return TVirtualGfx.getInstance().VMouseY ()
End Function

' Don't need VirtualMouseXSpeed/YSpeed replacements!

Function VirtualWidth:Int ()
	Return TVirtualGfx.getInstance().VirtualWidth ()
End Function

Function VirtualHeight:Int ()
	Return TVirtualGfx.getInstance().VirtualHeight ()
End Function

'Grab an image from the back buffer with Virtual support
Function VirtualGrabPixmap:TPixmap(X:Int, Y:Int, W:int, H:int, Frame:Int = 0)
	Return TVirtualGfx.getInstance().VirtualGrabPixmap(x,y,w,h)
End Function


Global CURRENT_TWEEN_FACTOR:float = 0.0
Function GetTweenResult:float(currentValue:float, oldValue:float, avoidShaking:int=TRUE)
	local result:float = currentValue * CURRENT_TWEEN_FACTOR + oldValue * (1.0 - CURRENT_TWEEN_FACTOR)
	if avoidShaking and Abs(result - currentValue) < 0.1 then return currentValue
	return result
End Function


Function GetTweenPoint:TPoint(currentPoint:TPoint, oldPoint:TPoint, avoidShaking:int=TRUE)
	return TPoint.Create(..
	         GetTweenResult(currentPoint.x, oldPoint.x, avoidShaking),..
	         GetTweenResult(currentPoint.y, oldPoint.y, avoidShaking)..
	       )
End Function




Type TXmlHelper
	field filename:string =""
	field file:TxmlDoc
	field root:TxmlNode


	Function Create:TXmlHelper(filename:string)
		local obj:TXmlHelper = new TXmlHelper
		obj.filename	= filename
		obj.file		= TxmlDoc.parseFile(filename)
		obj.root		= obj.file.getRootElement()
		return obj
	End Function


	Method FindNode:TxmlNode(startNode:TXmlNode, nodeName:string)
		nodeName = nodeName.ToLower()
		if not startNode then startNode = root

		local children:TList = startNode.getChildren()
		if not children then return null
		For local child:TxmlNode = eachin children
			if child.getName().ToLower() = nodeName then return child
			For local subStartNode:TxmlNode = eachin child.getChildren()
				local subChild:TXmlNode = FindNode(subStartNode, nodeName)
				if subChild then return subChild
			Next
		Next
		return null
	End Method


	Method FindRootChild:TxmlNode(nodeName:string)
		return FindChild(root, nodeName)
	End Method


	Method findAttribute:string(node:TxmlNode, attributeName:string, defaultValue:string)
		if node.hasAttribute(attributeName) <> null then return node.getAttribute(attributeName) else return defaultValue
	End Method


	Method FindChild:TxmlNode(node:TxmlNode, nodeName:string)
		nodeName = nodeName.ToLower()
		local children:TList = node.getChildren()
		if not children then return null
		For local child:TxmlNode = eachin children
			if child.getName().ToLower() = nodeName then return child
		Next
		return null
	End Method


	'loads values of a node into a tdata object
	Function LoadValuesToData:int(node:TXmlNode, data:TData var, fieldNames:string[])
		For local fieldName:String = eachin fieldNames
			if not TXmlHelper.HasValue(node, fieldName) then continue
			'use the first fieldname ("frames|f" -> add as "frames")
			local names:string[] = fieldName.ToLower().Split("|")

			data.Add(names[0], FindValue(node, fieldName, ""))
		Next
	End Function


	Function HasValue:int(node:TXmlNode, fieldName:string)
		local fieldNames:string[] = fieldName.ToLower().Split("|")
		For local name:String = eachin fieldNames
			If node.hasAttribute(name) then Return True

			For local subNode:TxmlNode = EachIn node
				if subNode.getType() = XML_TEXT_NODE then continue
				If subNode.getName().ToLower() = name then return TRUE
				If subNode.getName().ToLower() = "data" and subNode.hasAttribute(name) then Return TRUE
			Next
		Next
		return FALSE
	End Function


	Function FindValue:string(node:TxmlNode, fieldName:string, defaultValue:string, logString:string="")
		'loop through all potential fieldnames ("frames|f" -> "frames", "f")
		local fieldNames:string[] = fieldName.ToLower().Split("|")

		For local name:String = eachin fieldNames
			'given node has attribute (<episode number="1">)
			If node.hasAttribute(name) then Return node.getAttribute(name)

			For local subNode:TxmlNode = EachIn node
				if subNode.getType() = XML_TEXT_NODE then continue
				if subNode <> null
					If subNode.getName().ToLower() = name then return subNode.getContent()
					If subNode.getName().ToLower() = "data" and subNode.hasAttribute(name) then Return subNode.getAttribute(name)
				endif
			Next
		Next
		if logString <> "" then print logString
		return defaultValue
	End Function


	Method FindValueInt:int(node:TxmlNode, fieldName:string, defaultValue:int, logString:string="")
		local result:string = self.FindValue(node, fieldName, string(defaultValue), logString)
		if result = null then return defaultValue
		return int( result )
	End Method


	Method FindValueFloat:float(node:TxmlNode, fieldName:string, defaultValue:int, logString:string="")
		local result:string = self.FindValue(node, fieldName, string(defaultValue), logString)
		if result = null then return defaultValue
		return float( result )
	End Method


	Method FindValueBool:float(node:TxmlNode, fieldName:string, defaultValue:int, logString:string="")
		local result:string = FindValue(node, fieldName, string(defaultValue), logString)
		Select result.toLower()
			case "0", "false"	return false
			case "1", "true"	return true
		End Select
		return defaultValue
	End Method
End Type




Type TData
	field data:TMap = CreateMap()

	Method Init:TData(data:TMap=null)
		if data then self.data = data

		return self
	End Method


	Method ToString:String()
		local res:string = "TData content [~n"
		For local key:String = eachin data.Keys()
			res :+ key+" = " + string(data.ValueForKey(key)) + "~n"
		Next
		res :+ "]~n"
		return res
	End Method


	'add keys->values from other data object (and overwrite own if also existing)
	Method Merge:int(otherData:TData)
		if not otherData then return FALSE

		For local key:string = eachin otherData.data.Keys()
			key = key.ToLower()
			Add(key, otherData.data.ValueForKey(key))
		Next
		return TRUE
	End Method


	Method Add:TData(key:string, data:object)
		self.data.insert(key.ToLower(), data)
		return self
	End Method


	Method AddString:TData(key:string, data:string)
		self.Add( key, object(data) )
		return self
	End Method


	Method AddNumber:TData(key:string, data:float)
		self.Add( key, object( string(data) ) )
		return self
	End Method


	Method AddObject:TData(key:string, data:object)
		self.Add( key, object( data ) )
		return self
	End Method


	Method Get:object(key:string, defaultValue:object=null)
		local result:object = data.ValueForKey(key.ToLower())
		if result then return result
		return defaultValue
	End Method


	Method GetString:string(key:string, defaultValue:string=null)
		local result:object = self.Get(key)
		if result then return String( result )
		return defaultValue
	End Method


	Method GetBool:int(key:string, defaultValue:int=FALSE)
		local result:object = self.Get(key)
		if not result then return defaultValue
		Select String(result).toLower()
			case "1", "true", "yes"
				return True
			default
				return False
		End Select
	End Method


	Method GetFloat:float(key:string, defaultValue:float = 0.0)
		local result:object = self.Get(key)
		if result then return float( String( result ) )
		return defaultValue
	End Method


	Method GetInt:int(key:string, defaultValue:int = null)
		local result:object = self.Get(key)
		if result then return Int( float( String( result ) ) )
		return defaultValue
	End Method
End Type



Function CurrentDateTime:String(_what:String="%d %B %Y")
	Local	time:Byte[256],buff:Byte[256]
	time_(time)
	strftime_(buff,256,_what,localtime_( time ))
	Return String.FromCString(buff)
End Function




Const LOG_ERROR:int		= 1
Const LOG_WARNING:int	= 2
Const LOG_INFO:int		= 4
Const LOG_DEBUG:int		= 8
Const LOG_DEV:int		= 16
Const LOG_TESTING:int	= 32
Const LOG_LOADING:int	= 64
Const LOG_GAME:int		= 128
Const LOG_AI:int		= 256
Const LOG_XML:int		= 512
Const LOG_NETWORK:int	= 1024
Const LOG_SAVELOAD:int	= 2048
'all but debug/dev/testing/ai
Const LOG_ALL_NORMAL:int	= 1|2|4| 0 | 0 | 0 |64|128| 0 |512|1024|2048
Const LOG_ALL:int			= 1|2|4| 8 |16 |32 |64|128|256|512|1024|2048


'by default EVERYTHING is logged
TDevHelper.setLogMode(LOG_ALL)
TDevHelper.setPrintMode(LOG_ALL)

Type TDevHelper
	global printMode:int = 0 'print nothing
	global logMode:int = 0 'log nothing
	global lastLoggedMode:int =0
	global lastPrintMode:int =0
	global lastLoggedFunction:string=""
	global lastPrintFunction:string=""
	const MODE_LENGTH:int = 8

	'replace print mode flags
	Function setPrintMode(flag:int=0)
		printMode = flag
	End Function

	'replace logfile mode flags
	Function setLogMode(flag:int=0)
		logMode = flag
	End Function

	'change an existing print mode (add or remove flag)
	Function changePrintMode(flag:int=0, enable:int=TRUE)
		if enable
			printMode :| flag
		else
			printMode :& ~flag
		endif
	End Function

	'change an existing logfile mode (add or remove flag)
	Function changeLogMode(flag:int=0, enable:int=TRUE)
		if enable
			logMode :| flag
		else
			logMode :& ~flag
		endif
	End Function


	'outputs a string to stdout and/or logfile
	'exactTypeRequired: requires the mode to exactly contain the debugType
	'                   so a LOG_AI|LOG_DEBUG will only get logged if BOTH are enabled
	Function log(functiontext:String = "", message:String, debugType:int=LOG_DEBUG, exactTypeRequired:int=FALSE)
		Local debugtext:String = ""
		If debugType & LOG_ERROR Then debugtext :+ "ERROR "
		If debugType & LOG_WARNING Then debugtext :+ "WARNING "
		If debugType & LOG_INFO Then debugtext :+ "INFO "
		If debugType & LOG_DEV Then debugtext :+ "DEV "
		If debugType & LOG_DEBUG Then debugtext :+ "DEBUG "
		If debugType & LOG_LOADING Then debugtext :+ "LOAD "
		If debugType & LOG_GAME Then debugtext :+ "GAME "
		If debugType & LOG_AI Then debugtext :+ "AI "
		If debugType & LOG_XML Then debugtext :+ "XML "
		If debugType & LOG_NETWORK Then debugtext :+ "NET "
		If debugType & LOG_SAVELOAD Then debugtext :+  "SAVELOAD "
		if len(debugText < MODE_LENGTH)
			debugtext = LSet(debugtext, MODE_LENGTH) + " | "
		else
			debugtext = debugtext + " | "
		endif

		local showFunctionText:string = ""
		local doLog:int = FALSE
		local doPrint:int = FALSE
		'means ALL GIVEN TYPES have to fit
		if exactTypeRequired
			doLog = ((logMode & debugType) = debugType)
			doPrint = ((printMode & debugType) = debugType)
		'only one of the given types has to fit
		else
			doLog = (logMode & debugType)
			doPrint = (printMode & debugType)
		endif

		if doLog
			if debugType = lastLoggedMode and functiontext = lastLoggedFunction
				showFunctionText = LSet("", len(lastLoggedFunction))
			else
				lastLoggedFunction = functiontext
				lastLoggedMode = debugType
				showFunctionText = functiontext
			endif

			AppLog.AddLog("[" + CurrentTime() + "] " + debugtext + Upper(showFunctionText) + ": " + message)
		endif

		if doPrint
			if debugType = lastPrintMode and functiontext = lastPrintFunction
				showFunctionText = LSet("", len(lastPrintFunction))
			else
				lastPrintFunction = functiontext
				lastPrintMode = debugType
				showFunctionText = functiontext
			endif

			print "[" + CurrentTime() + "] " + debugtext + Upper(showFunctionText) + ": " + message
		endif
	End Function
End Type


Function SortListArray(List:TList Var)
	Local Arr:Object[] = List.ToArray()
	Arr.Sort()
	List = List.FromArray(arr)
End Function

Type TNumberCurveValue
	Field _value:Int

	Function Create:TNumberCurveValue(number:Int = 0)
		Local obj:TNumberCurveValue = New TNumberCurveValue
		obj._value = number
		Return obj
	End Function
End Type

Type TNumberCurve
	Field _values:TList[]
	Field _ratio:Float[]
	Field _amount:Int = 100

	Function Create:TNumberCurve(curves:Int = 1, amount:Int = 0)
		Local obj:TNumberCurve = New TNumberCurve
		obj._values = obj._values[..Curves + 1]
		obj._ratio = obj._ratio[..Curves + 1]
		For Local i:Int = 1 To Curves
			obj._values[i] = CreateList()
		Next
		Return obj
	End Function

	Method SetCurveRatio(curve:Int = 1, ratio:Float = 1.0)
		Self._ratio[curve] = ratio
	End Method

	Method AddNumber(curve:Int = 1, number:Int = 0)
		If Self._values.Length <= curve
			Self._values[curve].AddLast(TNumberCurveValue.Create(number))
			'remove first if over _amount
			For Local i:Int = 0 To (Self._values[curve].Count() - _amount)
				Self._values[curve].RemoveFirst()
			Next
		EndIf
	End Method

	Method Draw(x:Float, y:Float, w:Float, h:Float)
		SetAlpha 0.5
		SetColor 255, 255, 255
		DrawRect(x, y, w, h)
		SetAlpha 1.0

		'find out max value
		Local curvescount:Int = Self._values.Length
		Local maxvalue:Int[curvescount]
		For Local i:Int = 0 To curvescount - 1
			maxvalue[i] = 0
			For Local number:TNumberCurveValue = EachIn Self._values[i]
				If number._value > maxvalue[i] Then maxvalue[i] = number._value
			Next
			'Set each ratio
			If maxvalue[i] > 0
				Self._ratio[i] = h / maxvalue[i]
			Else
				Self._ratio[i] = 1.0
			EndIf
			Self._ratio[i] = Self._ratio[i] * 0.75 'don't be at the top each time, 3/4 of height is enough
		Next

		Local base:Float = y + h

		'draw
		For Local i:Int = 0 To curvescount - 1
			Local dx:Float = 0.0
			Local lastdx:Float = -1
			Local lastpoint:Float = Null
			If i = 0 Then SetColor 0, 255, 0
			If i = 1 Then SetColor 255, 0, 0
			If i = 2 Then SetColor 0, 0, 255

			For Local number:TNumberCurveValue = EachIn Self._values[i]
				Local point:Float = base - number._value * Self._ratio[i]
				If lastpoint = Null Then lastpoint = point
				DrawLine(x + Max(lastdx, 0), base - lastpoint, x + dx, base - point, True)
				lastdx = + 1
				dx = + 1
			Next
		Next

	End Method
End Type


'for things happening every X moments
Type TIntervalTimer
	field interval:int		= 0		'happens every ...
	field intervalToUse:int	= 0		'happens every ...
	field actionTime:int	= 0		'plus duration
	field randomness:int	= 0		'value the interval can "change" on GetIntervall() to BOTH sides - minus and plus
	field timer:int			= 0		'time when event last happened

	Function Create:TIntervalTimer(interval:int, actionTime:int = 0, randomness:int = 0)
		local obj:TIntervalTimer = new TIntervalTimer
		obj.interval	= interval
		obj.actionTime	= actionTime
		obj.randomness	= randomness
		'set timer
		obj.reset()
		return obj
	End Function

	Method GetInterval:int()
		return self.intervalToUse
	End Method

	Method SetInterval(value:int, resetTimer:int=false)
		self.interval = value
		if resetTimer then self.Reset()
	End Method

	Method SetActionTime(value:int, resetTimer:int=false)
		self.actionTime = value
		if resetTimer then self.Reset()
	End Method

	'returns TRUE if interval is gone (ignores action time)
	'action time could be eg. "show text for actiontime-seconds EVERY interval-seconds"
	Method doAction:int()
		local timeLeft:int = Millisecs() - (self.timer + self.GetInterval() )
		return ( timeLeft > 0 AND timeLeft < self.actionTime )
	End Method

	'returns TRUE if interval and duration is gone (ignores duration)
	Method isExpired:int()
		return ( self.timer + self.GetInterval() + self.actionTime <= Millisecs() )
	End Method

	Method getTimeGoneInPercents:float()
		local restTime:int = Max(0, getTimeUntilExpire())
		if restTime = 0 then return 1.0
		return 1.0 - (restTime / float(self.GetInterval()))
	End Method

	Method getTimeUntilExpire:int()
		return self.timer + self.GetInterval() + self.actionTime - Millisecs()
	End Method

	Method reachedHalftime:int()
		return ( self.timer + 0.5*(self.GetInterval() + self.actionTime) <= Millisecs() )
	End Method

	Method expire()
		self.timer = -self.GetInterval()
	End Method

	Method reset()
		self.intervalToUse = self.interval + rand(-self.randomness, self.randomness)

		self.timer = Millisecs()
	End Method

End Type




Type TRectangle {_exposeToLua="selected"}
	Field position:TPoint {_exposeToLua saveload="normal"}
	Field dimension:TPoint {_exposeToLua saveload="normal"}


	Function Create:TRectangle(x:Float=0.0,y:Float=0.0, w:float=0.0, h:float=0.0)
		local obj:TRectangle = new TRectangle
		obj.position	= TPoint.Create(x,y)
		obj.dimension	= TPoint.Create(w,h)
		return obj
	End Function


	Method Copy:TRectangle()
		return TRectangle.Create(self.position.x, self.position.y, self.dimension.x, self.dimension.y)
	End Method


	'does the rects overlap?
	Method Intersects:int(rect:TRectangle) {_exposeToLua}
		return (   self.containsXY( rect.GetX(), rect.GetY() ) ..
		        OR self.containsXY( rect.GetX() + rect.GetW(),  rect.GetY() + rect.GetH() ) ..
		       )
	End Method


	'global helper variables should be faster than allocating locals each time (in huge amount)
	global ix:float,iy:float,iw:float,ih:float
	'get intersecting rectangle
	Method IntersectRect:TRectangle(rectB:TRectangle) {_exposeToLua}
		ix = max(self.GetX(), rectB.GetX())
		iy = max(self.GetY(), rectB.GetY())
		iw = min(self.GetX()+self.dimension.GetX(), rectB.position.GetX()+rectB.dimension.GetX() ) -ix
		ih = min(self.GetY()+self.dimension.GetY(), rectB.position.GetY()+rectB.dimension.GetY() ) -iy

		local intersect:TRectangle = TRectangle.Create(ix,iy,iw,ih)

		if iw > 0 AND ih > 0 then
			return intersect
		else
			return Null
		endif
	End Method


	'does the point overlap?
	Method containsPoint:int(point:TPoint) {_exposeToLua}
		return self.containsXY( point.GetX(), point.GetY() )
	End Method


	Method containsX:int(x:float) {_exposeToLua}
		return (    x >= self.position.GetX()..
		        And x < self.position.GetX() + self.dimension.GetX() )
	End Method


	Method containsY:int(y:float) {_exposeToLua}
		return (    y >= self.position.GetY()..
		        And y < self.position.GetY() + self.dimension.GetY() )
	End Method


	'does the rect overlap with the coordinates?
	Method containsXY:int(x:float, y:float) {_exposeToLua}
		return (    x >= self.position.GetX()..
		        And x < self.position.GetX() + self.dimension.GetX() ..
		        And y >= self.position.GetY()..
		        And y < self.position.GetY() + self.dimension.GetY() )
	End Method


	Method MoveXY:int(x:float,y:float)
		self.position.MoveXY(x,y)
	End Method


	'rectangle names
	Method setXYWH(x:float,y:float,w:float,h:float)
		self.position.setXY(x,y)
		self.dimension.setXY(w,h)
	End Method


	Method GetX:float()
		return self.position.GetX()
	End Method


	Method GetY:float()
		return self.position.GetY()
	End Method


	Method GetW:float()
		return self.dimension.GetX()
	End Method


	Method GetH:float()
		return self.dimension.GetY()
	End Method


	'four sided TFunctions
	Method setTLBR(top:float,left:float,bottom:float,right:float)
		self.position.setXY(top,left)
		self.dimension.setXY(bottom,right)
	End Method


	Method SetTop:int(value:float)
		return self.position.SetX(value)
	End Method


	Method SetLeft:int(value:float)
		return self.position.SetY(value)
	End Method


	Method SetBottom:int(value:float)
		return self.dimension.SetX(value)
	End Method


	Method SetRight:int(value:float)
		return self.dimension.SetY(value)
	End Method


	Method GetTop:float()
		return self.position.GetX()
	End Method


	Method GetLeft:float()
		return self.position.GetY()
	End Method


	Method GetBottom:float()
		return self.dimension.GetX()
	End Method


	Method GetRight:float()
		return self.dimension.GetY()
	End Method


	Method GetX2:float()
		return self.position.GetX() + self.dimension.GetX()
	End Method


	Method GetY2:float()
		return self.position.GetY() + self.dimension.GetY()
	End Method


	Method GetAbsoluteCenterPoint:TPoint()
		return TPoint.Create(Self.GetX() + Self.GetW()/2, Self.GetY() + Self.GetH()/2)
	End Method


	Method Compare:Int(o:Object)
		Local rect:TRectangle = TRectangle(o)
		If rect.dimension.y*rect.dimension.x < dimension.y*dimension.x then Return -1
		If rect.dimension.y*rect.dimension.x > dimension.y*dimension.x then Return 1
		Return 0
	End Method


	Method Draw:int()
		DrawRect(GetX(), GetY(), GetW(), GetH())
	End Method
End Type


Type TPoint {_exposeToLua="selected"}
	Field x:Float
	Field y:Float
	Field z:Float 'Tiefe des Raumes (für Audio) Minus-Werte = Hintergrund; Plus-Werte = Vordergrund

	Function Create:TPoint(_x:Float=0.0,_y:Float=0.0,_z:Float=0.0)
		Local tmpObj:TPoint = New TPoint
		tmpObj.SetX(_x)
		tmpObj.SetY(_y)
		tmpObj.SetZ(_z)
		Return tmpObj
	End Function

	Method Copy:TPoint()
		return TPoint.Create(x,y)
	end Method

	Method GetIntX:int() {_exposeToLua}
		return floor(self.x)
	End Method

	Method GetIntY:int() {_exposeToLua}
		return floor(self.y)
	End Method

	Method GetIntZ:int() {_exposeToLua}
		return floor(self.z)
	End Method


	Method GetX:float() {_exposeToLua}
		return self.x
	End Method

	Method GetY:float() {_exposeToLua}
		return self.y
	End Method

	Method GetZ:float() {_exposeToLua}
		return self.z
	End Method

	Method SetX(_x:Float)
		Self.x = _x
	End Method

	Method SetY(_y:Float)
		Self.y = _y
	End Method

	Method SetZ(_z:Float)
		Self.z = _z
	End Method

	Method SetXY(_x:Float, _y:Float)
		Self.SetX(_x)
		Self.SetY(_y)
	End Method

	Method SetXYZ(_x:Float, _y:Float, _z:Float)
		Self.SetX(_x)
		Self.SetY(_y)
		Self.SetZ(_z)
	End Method

	Method SetPos(otherPos:TPoint)
		Self.SetX(otherPos.x)
		Self.SetY(otherPos.y)
		Self.SetZ(otherPos.z)
	End Method


	Method MoveX(_x:float)
		Self.x:+ _x
	End Method


	Method MoveY(_y:float)
		Self.y:+ _y
	End Method


	Method MoveXY( _x:float, _y:float )
		Self.x:+ _x
		Self.y:+ _y
	End Method

	Method isSame:int(otherPos:TPoint, round:int=0) {_exposeToLua}
		if round
			return abs(self.x -otherPos.x)<1.0 AND abs(self.y -otherPos.y) < 1.0
		else
			return self.x = otherPos.x AND self.y = otherPos.y
		endif
	End Method

	Method isInRect:int(rect:TRectangle)
		return rect.containsPoint(self)
	End Method

	Method DistanceTo:float(otherPoint:TPoint, withZ:int = true)
		local distanceX:float = DistanceOfValues(x, otherPoint.x)
		local distanceY:float = DistanceOfValues(y, otherPoint.y)
		local distanceZ:float = DistanceOfValues(z, otherPoint.z)

		local distanceXY:float = Sqr(distanceX * distanceX + distanceY * distanceY) 'Wurzel(a² + b²) = Hypotenuse von X und Y

		If withZ and distanceZ <> 0
			Return Sqr(distanceXY * distanceXY + distanceZ * distanceZ) 'Wurzel(a² + b²) = Hypotenuse von XY und Z
		Else
			Return distanceXY
		Endif
	End Method

	Function DistanceOfValues:int(value1:int, value2:int)
		return abs(value1-value2)
	rem
		If (value1 > value2) Then
			Return value1 - value2
		Else
			Return value2 - value1
		EndIf
	endrem
	End Function

	Function SwitchPos(Pos:TPoint Var, otherPos:TPoint Var)
		Local oldx:Float, oldy:Float, oldz:Float
		oldx = Pos.x
		oldy = Pos.y
		oldz = Pos.z
		Pos.x = otherpos.x
		Pos.y = otherpos.y
		Pos.z = otherpos.z
		otherpos.x = oldx
		otherpos.y = oldy
		otherpos.z = oldz
	End Function

 	Method Save()
		print "implement"
	End Method

	Function Load:TPoint(pnode:TxmlNode)
		print "implement load position"
	End Function
End Type


'--- color
'Type TColorFunctions

Function ARGB_Alpha:Int(ARGB:Int)
	Return (argb Shr 24) & $ff
EndFunction

Function ARGB_Red:Int(ARGB:Int)
	Return (argb Shr 16) & $ff
EndFunction

Function ARGB_Green:Int(ARGB:Int)
	Return (argb Shr 8) & $ff
EndFunction

Function ARGB_Blue:Int(ARGB:Int)
	Return (argb & $ff)
EndFunction

Function ARGB_Color:Int(alpha:Int,red:Int,green:Int,blue:Int)
	Return (Int(alpha * $1000000) + Int(red * $10000) + Int(green * $100) + Int(blue))
EndFunction

Function RGBA_Color:Int(alpha:int,red:int,green:int,blue:int)
'	Return (Int(alpha * $1000000) + Int(blue * $10000) + Int(green * $100) + Int(red))
'	is the same :
	local argb:int = 0
	local pointer:Byte Ptr = Varptr(argb)
	pointer[0] = red
	pointer[1] = green
	pointer[2] = blue
	pointer[3] = alpha

	return argb
EndFunction


'returns true if the given pixel is monochrome (grey)
Function isMonochrome:int(argb:Int)
	If ARGB_Red(argb) = ARGB_Green(argb) And ARGB_Red(argb) = ARGB_Blue(argb) And ARGB_Alpha(argb) <> 0 then Return ARGB_Red(argb)
	'old with "white filter < 250"
	'filter should be done outside of that function
	'If (red = green) And (red = blue) And(alpha <> 0) And(red < 250) Then Return green
	Return 0
End Function


Function MergeLists:TList(a:TList,b:TList)
	local list:TList = a.copy()
	for local obj:object = eachin b
		list.addLast(obj)
	next
	return list
End Function


Type TStringHelper
   Function FirstPart:String(txt:String,trenn:Byte=32)
      Local i:Short
      For i=0 To txt.length-1
         If txt[i]=trenn Then
           Return txt[..i]+":"
         End If
      Next
      Return ""
   End Function

   Function LastPart:String(txt:String,trenn:Byte=32)
      Local i:Short
      For i = 0 To txt.length - 1
         If txt[i]=trenn Then
          Return txt[(i+1)..]
         End If
      Next
      Return txt
   End Function

	Function gparam:String(txt:String, Count:Int, trenn:Byte = 32)
		Local x:Int = 0
		Local lastpos:Int = 0
		For local i:int = 0 To txt.length-1
			If txt[i]=trenn
				x:+1
				If x=count Then Return txt[lastpos..i]
				lastpos=i+1
			EndIf
		Next
		If x < Count - 1 Then Return Null
		Return txt[lastpos..x]
	End Function
End Type

'Gibt Eingabewert zurueck, wenn innerhalb Grenzen, ansonsten passende Grenze
Function Clamp:Float(value:Float, minvalue:Float = 0.0, maxvalue:Float = 1.0)
	value=Max(value,minvalue)
	value=Min(value,maxvalue)
	Return value
End Function

Global LastSeekPos:Int =0
Function Stream_SeekString:Int(str:String, stream:TStream)
  If stream <> Null
    stream.Seek(LastSeekPos)
	Local lastchar:Int=0
	For Local i:Int = LastSeekPos To stream.Size()-1
	  stream.Seek(i)
	  If stream.ReadByte() = str[lastchar] Then lastchar:+1 Else lastchar = 0
	  If lastchar = Len(str) Then LastSeekPos=i;Return i
	Next
	If LastSeekPos > 0 Then Return Stream_SeekString(str,stream)
	Return -1
  EndIf
End Function

Function SortListFast(list:TList)
TProfiler.Enter("SortFast")
		Local Arr:Object[] = ListToArray(list)
		Arr.Sort()
		list = ListFromArray(Arr)
  TPRofiler.Leave("SortFast")
End Function



Function RequestFromUrl:String(myurl:String)
	Local myip:TStream    = ReadStream(myurl$)	'Now we gonna open the requested URL to read
	Local ipstring:String	= ""				'var to store the string returned by the php script
	'Successfully opened the requested URL?
	If Not myip 								'If not then we let the user know
	  ipstring$ = "Error"
	Else 										'If yes then we read all that our script has for us
	  While Not Eof(myip)
		ipstring$ :+ ReadLine(myip) 			'And store the output line by line
	  Wend
	EndIf
	CloseStream myip							'Don't forget to close the opened stream in the end!
	Return ipstring$							'Just return what we've got
End Function


Type TCall
	Field depth:int = 0
	Field parent:TCall = null
	Field name:String
	Field start:Int
	Field Times:TList
	Field calls:Int
	Method New()
		times = CreateList()
	End Method

End Type

Type TLogFile
	field Strings:TList		= CreateList()
	field title:string		= ""
	field filename:string	= ""
	global logs:TList		= CreateList()

	Function Create:TLogFile(title:string, filename:string)
		local obj:TLogFile = new TLogFile
		obj.title = title
		obj.filename = filename
		TLogfile.logs.addLast(obj)

		return obj
	End Function

	Function DumpLog(doPrint:Int = 1)
		For local logfile:TLogFile = eachin TLogFile.logs
			Local fi:TStream = WriteFile( logfile.filename )
			WriteLine fi, logfile.title
			For Local line:String = EachIn logfile.Strings
				If doPrint = 1 then Print line
				WriteLine fi, line
			Next
			CloseFile fi
		Next
	End Function

	Method AddLog:int(text:String, addDateTime:int=FALSE)
		if addDateTime then text = "[" + CurrentTime() + "] " + text
		Strings.AddLast(text)
		return TRUE
	End Method
End Type
Global AppLog:TLogFile = TLogFile.Create("TVT Log v1.0", "log.app.txt")

Type TProfiler
	Global activated:Byte = 1
	Global calls:TMap = CreateMap()
	Global lastCall:TCall = null
	?Threaded
	Global accessMutex:TMutex = CreateMutex()
	?

	Function DumpLog( file:String )

		Local fi:TStream = WriteFile( file )

			WriteLine fi,".-----------------------------------------------------------------------------."
			WriteLine fi,"| AppProfiler |                                                               |"
			WriteLine fi,"|-----------------------------------------------------------------------------|"
			For Local c:TCall = EachIn calls.Values()
				Local totTime:int=0
				For Local time:string = EachIn c.times
					totTime:+int(time)
				Next
				local funcName:string = C.Name
				local depth:int = 0
				while Instr(funcName, "-") > 0
					funcName = Mid(funcName, Instr(funcName, "-")+1)
					depth:+1
				Wend
				c.depth = max(c.depth, depth)

				if c.depth > 0
					funcName = "'-"+funcName
					if c.depth >=2
						for local i:int = 0 to c.depth-2
							funcName = "  "+funcName
						Next
					endif
				endif
				local AvgTime:string = String( floor(int(1000.0*(Float(TotTime) / Float(c.calls)))) / 1000.0 )
				WriteLine fi, "| " + LSet(funcName, 24) + "  Calls: " + RSet(c.calls, 8) + "  Total: " + LSet(String(Float(tottime) / Float(1000)),8)+"s" + "  Avg:" + LSet(AvgTime,8)+"ms"+ " |"
			Next
			WriteLine fi,"'-----------------------------------------------------------------------------'"
		CloseFile fi

	End Function

	Function Enter:int(func:String)
		If TProfiler.activated
			?Threaded
				return TRUE
				'wait for the mutex to get access to child variables
				LockMutex(accessMutex)
			?

			Local call:tcall = null
			call = TCall(calls.ValueForKey(func))
			if call <> null
				call.start	= MilliSecs()
				call.calls	:+1
				Return true
			EndIf

			call = New TCall

			if TProfiler.LastCall <> null then call.depth = TProfiler.LastCall.depth +1
			'Print "Profiler: added new call:"+func + " depth:"+ call.depth
			call.parent	= TProfiler.LastCall
			call.calls	= 1
			call.name	= func
			call.start	= MilliSecs()
			calls.insert(func, call)
			TProfiler.LastCall = call
			?Threaded
				'wait for the mutex to get access to child variables
				UnLockMutex(accessMutex)
			?
		EndIf
	End Function

	Function Leave:int( func:String )
		If TProfiler.activated
			?Threaded
				return TRUE
				'wait for the mutex to get access to child variables
				LockMutex(accessMutex)
			?
			Local call:TCall = TCall(calls.ValueForKey(func))
			If call <> null
				Local l:int = MilliSecs()-call.start
				call.times.addlast( string(l) )
				if call.parent <> null
					TProfiler.LastCall = call.parent
				endif
				?Threaded
					'wait for the mutex to get access to child variables
					UnLockMutex(accessMutex)
				?
				Return true
			EndIf
			?Threaded
				'wait for the mutex to get access to child variables
				UnLockMutex(accessMutex)
			?
		EndIf
		return false
	End Function
End Type


'collection of useful functions
Type TFunctions
	Global roundToBeautifulEnabled:int = TRUE

	'check whether a checkedObject equals to a limitObject
	'1) is the same object
	'2) is of the same type
	'3) is extended from same type
	function ObjectsAreEqual:int(checkedObject:object, limit:object)
		'one of both is empty
		if not checkedObject then return FALSE
		if not limit then return FALSE
		'same object
		if checkedObject = limit then return TRUE
		'check if classname / type is the same (type-name given as limit )
		if string(limit)<>null
			local typeId:TTypeId = TTypeId.ForName(string(limit))
			'if we haven't got a valid classname
			if not typeId then return FALSE
			'if checked object is same type or does extend from that type
			if TTypeId.ForObject(checkedObject).ExtendsType(typeId) then return TRUE
		endif

		return FALSE
	End Function


	Function CreateEmptyImage:TImage(width:int, height:int, flags:int=DYNAMICIMAGE | FILTEREDIMAGE)
		local image:TImage = CreateImage(width, height, flags)
		local pixmap:TPixmap = LockImage(image)
		pixmap.clearPixels(0)
		return image
	End Function

	Function MouseIn:int(x:float,y:float,w:float,h:float)
		return TFunctions.IsIn(MouseManager.x, MouseManager.y, x,y,w,h)
	End Function

	Function MouseInRect:int(rect:TRectangle)
		return TFunctions.IsIn(MouseManager.x, MouseManager.y, rect.position.x,rect.position.y,rect.dimension.x, rect.dimension.y)
	End Function


	Function DoMeet:int(startA:float, endA:float, startB:float, endB:float)
		'DoMeet - 4 possibilities - but only 2 for not meeting
		' |--A--| .--B--.    or   .--B--. |--A--|
		return  not (Max(startA,endA) < Min(startB,endB) or Min(startA,endA) > Max(startB, endB) )
	End function


	Function IsIn:Int(x:Float, y:Float, rectx:Float, recty:Float, rectw:Float, recth:Float)
		If x >= rectx And x<=rectx+rectw And..
		   y >= recty And y<=recty+recth
			Return 1
		Else
			Return 0
		End If
	End Function


	Function ListDir:String(dir:String, onlyExtension:String = "", out:String = "")
		Local separator:String = "/"
		Local csd:Int = ReadDir(dir:String)
		If Not csd Then Return ""

		Repeat
		Local file:String = NextFile(csd)
		If file:String = "" Then Exit
		If FileType(dir + separator + file) = 1
			If onlyExtension = "" Or ExtractExt(dir + separator + file) = onlyExtension
				out = out + dir + separator + file + Chr:String(13) + Chr:String(10)
			EndIf
		EndIf

		If FileType(dir + separator + file) = 2 And file <> ".." And file <> "."
			out:String = out:String + ListDir:String(dir:String + separator + file:String, onlyExtension)
		EndIf
		Forever
		Return out$
	End Function


	Function RoundToBeautifulValue:int(value:int)
		'dev
		if not roundToBeautifulEnabled then return value

		if value = 0 then return 0
		if value <= 25 then return 25
		if value <= 50 then return 50
		if value <= 75 then return 75
		if value <= 100 then return 100
		'102 /50 = 2 mod 2 = 0 -> un/gerade
		If value <= 1000 then return ceil(value / 100.0)*100 'bisher 250
		If value <= 5000 then return ceil(value / 250.0)*250 'bisher 500
		If value <= 10000 then return ceil(value / 500.0)*500 'bisher 1.000
		If value <= 50000 then return ceil(value / 1000.0)*1000 'bisher 2.500
		If value <= 100000 then return ceil(value / 5000.0)*5000 'bisher 10.000
		If value <= 500000 then return ceil(value / 10000.0)*10000 'bisher 25.000
		If value <= 1000000 then return ceil(value / 25000.0)*25000 'bisher 250.000
		If value <= 2500000 then return ceil(value / 100000.0)*100000 'bisher --
		If value <= 5000000 then return ceil(value / 250000.0)*250000 'bisher --
		'>5.000.0000 in steps of 1 million
		return ceil(value / 1000000.0)*1000000
	End Function


	'formats a value: 1000400 = 1,0 Mio
	Function convertValue:String(value:float, digitsAfterDecimalPoint:int=2, typ:Int=0, delimeter:string=",")
      ' typ 1: 250000 = 250Tsd
      ' typ 2: 250000 = 0,25Mio
      ' typ 3: 250000 = 0,0Mrd
      ' typ 0: 250000 = 0,25Mio (automatically)

		'find out amount of digits before decimal point
		local intValue:int = int(value)
		local length:int = string(intValue).length
		'do not count negative signs.
		if intValue < 0 then length:-1

		'automatically
		if typ=0
			If length < 10 and length >= 7 Then typ=2
			If length >= 10 Then typ=3
		endif
		'250000 = 250Tsd -> divide by 1000
		if typ=1 then return shortenFloat(value/1000.0, 0)+" Tsd"
		'250000 = 0,25Mio -> divide by 1000000
		if typ=2 then return shortenFloat(value/1000000.0, 2)+" Mio"
		'250000 = 0,0Mrd -> divide by 1000000000
		if typ=3 then return shortenFloat(value/1000000000.0, 2)+" Mrd"
		'add thousands-delimiter: 10000 = 10.000
		if length <= 7 and length > 3
			return int(floor(int(value) / 1000))+"."+Left( abs(int((int(value) - int(floor(int(value) / 1000)*1000)))) +"000",3)
		else
			return int(value)
		endif
		'Return convertValue
    End Function

	'deprecated
	Function shortenFloat:string(value:float, digitsAfterDecimalPoint:int=2)
		return FloatToString(value, digitsAfterDecimalPoint)
	End Function


	'convert a float to a string
	'float is rounded to the requested amount of digits after comma
	Function floatToString:String(value:Float, digitsAfterDecimalPoint:int = 2)
		Local s:String = RoundNumber(value, digitsAfterDecimalPoint + 1)

		'calculate amount of digits before "."
		'instead of just string(int(s))).length we use the "Abs"-value
		'and compare the original value if it is negative
		'- this is needed because "-0.1" would be "0" as int (one char less)
		local lengthBeforeDecimalPoint:int = string(abs(int(s))).length
		if value < 0 then lengthBeforeDecimalPoint:+1 'minus sign
		'remove unneeded digits (length = BEFORE + . + AFTER)
		s = Left(s, lengthBeforeDecimalPoint + 1 + digitsAfterDecimalPoint)

		'add at as much zeros as requested by digitsAfterDecimalPoint
		If s.EndsWith(".")
			for local i:int = 0 until digitsAfterDecimalPoint
				s :+ "0"
			Next
		endif

		Return s
	End Function


	'round a number using weighted non-trucate rounding.
	Function roundNumber:Double(number:Double, digitsAfterDecimalPoint:Byte = 2)
		Local t:Long = 10 ^ digitsAfterDecimalPoint
		Return Long(number * t + 0.5:double * Sgn(number)) / Double(t)
	End Function


rem
	'Ronny: Manuels Methode lieferte falsche Ergebnisse
			aus 0.167339996 wurde 1.67
	Function shortenFloat:string(value:float, digitsAfterDecimalPoint:int=2)
		'mv: Die alte Methode hat nicht funktioniert, deswegen hab ich sie umgebaut. Wenn man z.B. 19.0575913 runden wollte, kam 19.57 raus. Richtig wäre aber 19,06!
		If value = 0 then return "0"
		Local values:String[] = string(value).split(".")
		local length:int = string(values[0]).length
		local potenz:int = 10^digitsAfterDecimalPoint
		local temp:string = Left(String(int(value * potenz + .5)) + "00000000000", digitsAfterDecimalPoint + length) 'Thema runden: http://www.blitzbasic.com/Community/posts.php?topic=51753
		local result:string = Left(temp, length) + "." + Mid(temp, length+1)
		Return result
	End Function
endrem
End Type




Type TDragAndDrop
	field pos:TPoint = TPoint.Create(0,0)
  Field w:Int = 0
  Field h:Int = 0
  Field typ:String = ""
  Field slot:Int = 0
  Global List:TList = CreateList()

 	Function FindDragAndDropObject:TDragAndDrop(List:TList, _pos:TPoint)
 	  For Local P:TDragAndDrop = EachIn List
		If P.pos.isSame(_pos) Then Return P
	  Next
	  Return Null
 	End Function


	Function Create:TDragAndDrop(x:Int, y:Int, w:Int, h:Int, _typ:String="")
		Local DragAndDrop:TDragAndDrop=New TDragAndDrop
		DragAndDrop.pos.SetXY(x,y)
		DragAndDrop.w = w
		DragAndDrop.h = h
		DragAndDrop.typ = _typ
		List.AddLast(DragAndDrop)
		SortList List
		Return DragAndDrop
	EndFunction

    Method IsIn:Int(x:Int, y:Int)
		return (x >= pos.x And x <= pos.x + w And y >= pos.y And y <= pos.y + h)
    End Method

    Method CanDrop:Int(x:Int, y:Int, _Typ:String="")
		return (IsIn(x,y) = 1 And typ=_Typ)
    End Method
End Type



Type TColor
	Field r:int			= 0
	Field g:int			= 0
	Field b:int			= 0
	Field a:float		= 1.0
	Field ownerID:int	= 0				'store if a player/object... uses that color

	global list:TList	= CreateList()	'storage for colors (allows handle referencing)
	'some const
	global clBlack:TColor = TColor.CreateGrey(0)
	global clWhite:TColor = TColor.CreateGrey(255)
	global clRed:TColor = TColor.Create(255,0,0)
	global clGreen:TColor = TColor.Create(0,255,0)
	global clBlue:TColor = TColor.Create(0,0,255)

	Function Create:TColor(r:int=0,g:int=0,b:int=0,a:float=1.0)
		local obj:TColor = new TColor
		obj.r = r
		obj.g = g
		obj.b = b
		obj.a = a
		return obj
	End Function


	Function CreateGrey:TColor(grey:int=0,a:float=1.0)
		local obj:TColor = new TColor
		obj.r = grey
		obj.g = grey
		obj.b = grey
		obj.a = a
		return obj
	End Function


	Function FromName:TColor(name:String, alpha:float=1.0)
		Select name.ToLower()
				Case "red"
						Return clRed.copy().AdjustAlpha(alpha)
				Case "green"
						Return clGreen.copy().AdjustAlpha(alpha)
				Case "blue"
						Return clBlue.copy().AdjustAlpha(alpha)
				Case "black"
						Return clBlack.copy().AdjustAlpha(alpha)
				Case "white"
						Return clWhite.copy().AdjustAlpha(alpha)
		End Select
		Return clWhite.copy()
	End Function


	Method Copy:TColor()
		return TColor.Create(r,g,b,a)
	end Method


	Method SetOwner:TColor(ownerID:int)
		self.ownerID = ownerID
		return self
	End Method


	Method AddToList:TColor(remove:int=0)
		'if in list - remove first as wished
		if remove then self.list.remove(self)

		self.list.AddLast(self)
		return self
	End Method


	Function getFromListObj:TColor(col:TColor)
		return TColor.getFromList(col.r,col.g,col.b,col.a)
	End Function


	Function getFromList:TColor(r:Int, g:Int, b:Int, a:float=1.0)
		For local obj:TColor = EachIn TColor.List
			If obj.r = r And obj.g = g And obj.b = b And obj.a = a Then Return obj
		Next
		Return Null
	End Function


	Function getByOwner:TColor(ownerID:int=0)
		For local obj:TColor = EachIn TColor.List
			if obj.ownerID = ownerID then return obj
		Next
		return Null
	End Function


	Method AdjustRelative:TColor(percentage:float=1.0)
		self.r = Max(0, self.r * (1.0+percentage))
		self.g = Max(0, self.g * (1.0+percentage))
		self.b = Max(0, self.b * (1.0+percentage))
		return self
	End Method


	Method AdjustFactor:TColor(factor:int=100)
		self.r = Max(0, self.r + factor)
		self.g = Max(0, self.g + factor)
		self.b = Max(0, self.b + factor)
		return self
	End Method


	Method AdjustAlpha:TColor(a:float)
		self.a = a
		return self
	End Method


	Method AdjustRGB:TColor(r:int=-1,g:int=-1,b:int=-1, overwrite:int=0)
		if overwrite
			self.r = r
			self.g = g
			self.b = b
		else
			self.r :+r
			self.g :+g
			self.b :+b
		endif
		return self
	End Method


	Method FromInt:TColor(color:int)
		self.r = ARGB_Red(color)
		self.g = ARGB_Green(color)
		self.b = ARGB_Blue(color)
		self.a = float(ARGB_Alpha(color))/255.0
		return self
	End Method


	Method ToInt:int()
		return ARGB_Color(ceil(self.a*255), self.r, self.g, self.b )
	End Method


	'same as set()
	Method setRGB:TColor()
		SetColor(self.r, self.g, self.b)
		return self
	End Method


	Method setRGBA:TColor()
		SetColor(self.r, self.g, self.b)
		SetAlpha(self.a)
		return self
	End Method


	Method get:TColor()
		GetColor(self.r, self.g, self.b)
		self.a = GetAlpha()
		return self
	End Method
End Type



Type TCatmullRomSpline
	Field points:TList			= CreateList()	'list of the control points (TPoint)
	Field cache:TPoint[]						'array of cached points
	Field cacheGenerated:int	= FALSE
	Field totalDistance:float	= 0				'how long is the spline?
	const resolution:float		= 100.0

	Method New()
		'
	End Method

	Method addXY:TCatmullRomSpline(x:float,y:float)
		self.points.addLast( TPoint.Create( x, y ) )
		self.cacheGenerated = FALSE
		return self
	End MEthod

	'Call this to add a point to the end of the list
	Method addPoint:TCatmullRomSpline(p:TPoint)
		self.points.addlast(p)
		self.cacheGenerated = FALSE
		return self
	End Method

	Method addPoints:TCatmullRomSpline(p:TPoint[])
		For local i:int = 0 to p.length-1
			self.points.addLast(p[i])
		Next
		self.cacheGenerated = FALSE
		return self
	End Method

	'draw the spline!
	Method draw:int()
		'Draw a rectangle at each control point so we can see
		'them (not relevant to the algorithm)
		For local p:TPoint = EachIn self.points
			DrawRect(p.x-3 , p.y-3 , 7 , 7)
		Next

		'Check there are enough points to draw a spline
	'	If self.points.count()<4 Then Return FALSE

		'Get the first three  TLinks in the list of points. This algorithm
		'is going to work by working out the first three points, then
		'getting the last point at the start of the while loop. After the
		'curve section has been drawn, every point is moved along one,
		'and the TLink is moved to the next one so we can see if it's
		'null, and then get the next p3 from it if not.

		local pl:TLink	= Null
		local p0:TPoint = Null
		local p1:TPoint = Null
		local p2:TPoint = Null
		local p3:TPoint = Null

		'assign first 2 points
		'point 3 is assigned in the while loop
		pl = points.firstlink()
		p0 = TPoint( pl.value() )
		pl = pl.nextlink()
		p1 = TPoint( pl.value() )
		pl = pl.nextlink()
		p2 = TPoint( pl.value() )
		pl = pl.nextlink()

		'pl3 will be null when we've reached the end of the list
		While pl <> Null
			'get the point objects from the TLinks
			p3 = TPoint( pl.value() )

			local oldX:float = p1.x
			local oldY:float = p1.y
			local x:float = 0.0
			local y:float = 0.0
			'THE MEAT And BONES! Oddly, there isn't much to explain here, just copy the code.
			For local t:float = 0 To 1 Step .01
				x = .5 * ( (2 * p1.x) + (p2.x - p0.x) * t + (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t * t + (3 * p1.x - p0.x - 3 * p2.x + p3.x) * t * t * t)
				y = .5 * ( (2 * p1.y) + (p2.y - p0.y) * t + (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t * t + (3 * p1.y - p0.y - 3 * p2.y + p3.y) * t * t * t)
				DrawLine oldX , oldY , x , y

				oldX = x
				oldY = y
			Next

			'Move one place along the list
			p0 = p1
			p1 = p2
			p2 = p3
			pl=pl.nextlink()
		Wend
	End Method

	Method GetTotalDistance:float()
		if not self.cacheGenerated then self.GenerateCache()

		return self.totalDistance
	End Method

	Method GenerateCache:float()
		If self.points.count()<4 Then Return 0

		local pl:TLink	= Null
		local p0:TPoint, p1:TPoint, p2:TPoint, p3:TPoint = Null

		'assign first 2 points
		'point 3 is assigned in the while loop
		pl = points.firstlink()
		p0 = TPoint( pl.value() )
		pl = pl.nextlink()
		p1 = TPoint( pl.value() )
		pl = pl.nextlink()
		p2 = TPoint( pl.value() )
		pl = pl.nextlink()

		local oldPoint:TPoint = TPoint.Create(0,0,0)
		local cachedPoints:int = 0

		'pl3 will be null when we've reached the end of the list
		While pl <> Null
			'get the point objects from the TLinks
			p3 = Tpoint( pl.value() )

			oldPoint.SetPos(p1)

			'THE MEAT And BONES! Oddly, there isn't much to explain here, just copy the code.
			For local t:float = 0 To 1 Step 1.0/self.resolution
				local point:TPoint = TPoint.Create(0,0,0)
				point.x = .5 * ( (2 * p1.x) + (p2.x - p0.x) * t + (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t * t + (3 * p1.x - p0.x - 3 * p2.x + p3.x) * t * t * t)
				point.y = .5 * ( (2 * p1.y) + (p2.y - p0.y) * t + (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t * t + (3 * p1.y - p0.y - 3 * p2.y + p3.y) * t * t * t)

				'set distance
				self.totalDistance :+ point.DistanceTo(oldPoint, false)
				'distance is stored in the current points Z coordinate
				point.z = self.totalDistance
				oldPoint.setPos(point)

				'add to cache
				self.cache = self.cache[.. cachedPoints+1]
				self.cache[cachedPoints] = point
				cachedPoints:+1
			Next

			'Move one place along the list
			p0 = p1
			p1 = p2
			p2 = p3
			pl=pl.nextlink()

		Wend

		self.cacheGenerated = TRUE

		return self.totalDistance
	End Method

	'returns the coordinate of a given distance
	'the spot is ranging from 0.0 (0%) to 1.0 (100%) of the distance
	Method GetPoint:TPoint(distance:float, relativeValue:int=FALSE)
		if not self.cacheGenerated then self.generateCache()
		if relativeValue then distance = distance*self.totalDistance

		For local t:float = 0 To self.cache.length-1
			'if the searched distance is reached - return it
			if self.cache[t].z > distance
				return self.cache[Max(t-1, 0)]
			endif
		Next
		return Null
	End Method

	'returns the coordinate of a given distance
	'the spot is ranging from 0.0 (0%) to 1.0 (100%) of the distance
	Method GetTweenPoint:TPoint(distance:float, relativeValue:int=FALSE)
		if not cacheGenerated then generateCache()
		if relativeValue then distance = distance * totalDistance

		local pointA:TPoint = Null
		local pointB:TPoint = Null

		For local t:float = 0 To cache.length-1
			'if the searched distance is reached
			if cache[t].z > distance
				if not pointA
					pointA = cache[Max(t-1, 0)]
				elseif not pointB
					pointB = cache[Max(t-1, 0)]
					exit
				endif
			endif
		Next

		'if no point was good enough - use the last possible one
		if not pointA then pointA = cache[cache.length-1]
		'if pointA is already the last one we have, the second point
		'could be the same
		if not pointB then pointB = pointA.Copy()

		if pointA and pointB
			'local distanceAB:float = abs(pointB.z - pointA.z)
			'local distanceAX:float = abs(distance - pointA.z)
			'local distanceBX:float = abs(distance - pointB.z)
			'local weightAX:float   = 1- distanceAX/distanceAB
			local weightAX:float   = 1- abs(distance - pointA.z)/abs(pointB.z - pointA.z)

			return TPoint.Create(..
				pointA.x*weightAX + pointB.x*(1-weightAX), ..
				pointA.y*weightAX + pointB.y*(1-weightAX) ..
			)
		else
			return Null
		endif
	End Method

End Type



'=======================================================================
Type appKubSpline
	Field dataX:Float[]
	Field dataY:Float[]
	Field dataCount:Int =0
	Field koeffB:Float[]
	Field koeffC:Float[]
	Field koeffD:Float[]
  '---------------------------------------------------------------------
  ' gets data as FLOAT and calculates the cubic splines
  ' if x-, y-arrays size is different, only the smaller count is taken
  ' data must be sorted uprising for x
  Method GetData(x:Float[], y:Float[])
    Local i:Int =0

    Local count:Int =Min(x.length, y.length)
    dataX =x[..]
    dataX =x[..count]
    dataY =y[..]
    dataY =y[..count]
    koeffB =koeffB[..count]
    koeffC =koeffC[..count]
    koeffD =koeffD[..count]

    Local m:Int =count -2
    Local s:Float = 0.0
    Local r:Float = 0.0
    For i =0 To m
      koeffD[i] =dataX[i +1] -dataX[i]
      r =(dataY[i +1] -dataY[i]) /koeffD[i]
      koeffC[i] =r -s
      s =r
    Next
    s =0
    r =0
    koeffC[0] =0
    koeffC[count -1] =0
    For i =1 To m
      koeffC[i] =koeffC[i] +r *koeffC[i -1]
      koeffB[i] =(dataX[i -1] -dataX[i +1]) *2 -r *s
      s =koeffD[i]
      r =s /koeffB[i]
    Next
    For i =m To 1 Step -1
      koeffC[i] =(koeffD[i] *koeffC[i +1] -koeffC[i]) /koeffB[i]
    Next
    For i =0 To m
      s =koeffD[i]
      r =koeffC[i +1] -koeffC[i]
      koeffD[i] =r /s
      koeffC[i] =koeffC[i] *3
      koeffB[i] =(dataY[i +1] -dataY[i]) /s -(koeffC[i] +r) *s
    Next

    dataCount =count

  End Method
  '------------------------------------------------------------------------------------------------------------
  ' gets data as INT and calculates the cubic splines
  ' if x-, y-arrays size is different, only the smaller count is taken
  ' data must be sorted uprising for x
  Method GetDataInt(x:Int[], y:Int[])
    Local z:Int=0
    Local i:Int=0
    Local count:Int =Min(x.length, y.length)

    dataX =dataX[..count]
    For z =1 To count
      dataX[z -1] =Float(x[z -1])
    Next
    dataY =dataY[..count]
    For z =1 To count
      dataY[z -1] =Float(y[z -1])
    Next
    koeffB =koeffB[..count]
    koeffC =koeffC[..count]
    koeffD =koeffD[..count]

    Local m:Int =count -2
    Local s:Float
    Local r:Float
    For i =0 To m
      koeffD[i] =dataX[i +1] -dataX[i]
      r =(dataY[i +1] -dataY[i]) /koeffD[i]
      koeffC[i] =r -s
      s =r
    Next
    s =0
    r =0
    koeffC[0] =0
    koeffC[count -1] =0
    For i =1 To m
      koeffC[i] =koeffC[i] +r *koeffC[i -1]
      koeffB[i] =(dataX[i -1] -dataX[i +1]) *2 -r *s
      s =koeffD[i]
      r =s /koeffB[i]
    Next
    For i =m To 1 Step -1
      koeffC[i] =(koeffD[i] *koeffC[i +1] -koeffC[i]) /koeffB[i]
    Next
    For i =0 To m
      s =koeffD[i]
      r =koeffC[i +1] -koeffC[i]
      koeffD[i] =r /s
      koeffC[i] =koeffC[i] *3
      koeffB[i] =(dataY[i +1] -dataY[i]) /s -(koeffC[i] +r) *s
    Next

    dataCount =count

  End Method
  '------------------------------------------------------------------------------------------------------------
  ' returns kubic splines value as FLOAT at given x -position
   'or always 0 if currently no data is loaded
  Method value:Float(x:Float)

    If dataCount =0 Then Return 0

    If x <dataX[0] Then
      Repeat
        x :+dataX[dataCount -1] -dataX[0]
      Until x =>dataX[0]
    ElseIf x >dataX[dataCount -1] Then
      Repeat
        x :-dataX[dataCount -1] -dataX[0]
      Until x <=dataX[dataCount -1]
    End If

    Local q:Float =Sgn(dataX[dataCount -1] -dataX[0])
    Local k:Int =-1
    Local i:Int
    Repeat
      i =k
      k :+1
    Until (q *x <q *dataX[k]) Or k =dataCount -1

    q =x - dataX[i]
    Return ((koeffD[i] *q +koeffC[i]) *q +koeffB[i]) *q +dataY[i]

  End Method
  '---------------------------------------------------------------------
  ' returns kubic splines value as rounded INT at given x -position
   'or always 0 if currently no data is loaded
  Method ValueInt:Int(x:Float)
	local tmpResult:Float = self.Value(x)

    If tmpResult -Floor(tmpResult) <=.5 Then
      Return Floor(tmpResult)
    Else
      Return Floor(tmpResult) +1
    End If

  End Method
  '---------------------------------------------------------------------

End Type
'-----------------------------------------------------------------------