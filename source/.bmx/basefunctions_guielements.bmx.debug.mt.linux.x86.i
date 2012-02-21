import brl.blitz
import "basefunctions.bmx"
import "basefunctions_sprites.bmx"
import "basefunctions_resourcemanager.bmx"
TGUIManager^brl.blitz.Object{
.Defaultfont:brl.max2d.TImageFont&
.GUIobjectactive%&
.LastGuiID%&
.globalScale#&
.oldfont:brl.max2d.TImageFont&
.MouseIsHit%&
.List:brl.linkedlist.TList&
-New%()="_bb_TGUIManager_New"
+Create:TGUIManager()="_bb_TGUIManager_Create"
-Add%(GUIobject:TGUIobject)="_bb_TGUIManager_Add"
+SortObjects%(ob1:Object,ob2:Object)="_bb_TGUIManager_SortObjects"
-getActive%()="_bb_TGUIManager_getActive"
-setActive%(uid%)="_bb_TGUIManager_setActive"
-Remove%(guiobject:TGUIObject)="_bb_TGUIManager_Remove"
-Update%(State$=$"",updatelanguage%=0,fromZ%=-1000,toZ%=-1000)="_bb_TGUIManager_Update"
-DisplaceGUIobjects%(State$=$"",x%=0,y%=0)="_bb_TGUIManager_DisplaceGUIobjects"
-Draw%(State$=$"",updatelanguage%=0,fromZ%=-1000,toZ%=-1000)="_bb_TGUIManager_Draw"
}="bb_TGUIManager"
TGUIobject^brl.blitz.Object{
.pos:TPosition&
.width%&
.height%&
.scale#&
.align%&
.state$&
.value$&
.backupvalue$&
.Clicked%&
.clickedPos:TPosition&
.MouseIsDown%&
.MouseIsDownPos:TPosition&
.mousePos:TPosition&
.ParentID%&
.ParentGUIObject:TGUIobject&
.ZIndex%&
.EnterPressed%&
.uid%&
.on%&
.typ$&
._enabled%&
._visible%&
.clickable%&
.mouseover%&
.forstateonly$&
.UseFont:brl.max2d.TImageFont&
._onClickFunc%(sender:Object)&
._onDoubleClickFunc%(sender:Object)&
._onUpdateFunc%(sender:Object)&
.grayedout%&
.oldfont:brl.max2d.TImageFont&
-New%()="_bb_TGUIobject_New"
+GetNewID%()="_bb_TGUIobject_GetNewID"
-SetImgFont%(font:brl.max2d.TImageFont)="_bb_TGUIobject_SetImgFont"
-RestoreImgFont%()="_bb_TGUIobject_RestoreImgFont"
-SetClickFunc%(onFunc%(sender:Object))="_bb_TGUIobject_SetClickFunc"
-SetDoubleClickFunc%(onFunc%(sender:Object))="_bb_TGUIobject_SetDoubleClickFunc"
-SetUpdateFunc%(onFunc%(sender:Object))="_bb_TGUIobject_SetUpdateFunc"
-Draw%()A="brl_blitz_NullMethodError"
-Show%()="_bb_TGUIobject_Show"
-Hide%()="_bb_TGUIobject_Hide"
-enable%()="_bb_TGUIobject_enable"
-disable%()="_bb_TGUIobject_disable"
-Update%()A="brl_blitz_NullMethodError"
-SetZIndex%(zindex%)="_bb_TGUIobject_SetZIndex"
-SetState%(state$=$"")="_bb_TGUIobject_SetState"
-Input2Value$(value$)="_bb_TGUIobject_Input2Value"
}A="bb_TGUIobject"
TGUIButton^TGUIobject{
.textalign%&
.manualState%&
-New%()="_bb_TGUIButton_New"
+Create:TGUIButton(x%,y%,width%=-1,on@=0,enabled@=1,textalign%=0,value$,State$=$"",UseFont:brl.max2d.TImageFont="bbNullObject")="_bb_TGUIButton_Create"
-GetClicks%()="_bb_TGUIButton_GetClicks"
-SetTextalign%(aligntype$=$"LEFT")="_bb_TGUIButton_SetTextalign"
-Update%()="_bb_TGUIButton_Update"
-Draw%()="_bb_TGUIButton_Draw"
}="bb_TGUIButton"
TGUIImageButton^TGUIobject{
.grayedout%&
.startframe%&
.image:brl.max2d.TImage&
-New%()="_bb_TGUIImageButton_New"
+Create:TGUIImageButton(x%,y%,width%,Height%,image:brl.max2d.TImage,on@=0,enabled@=1,grayedout%=0,State$=$"",startframe%=0)="_bb_TGUIImageButton_Create"
-Update%()="_bb_TGUIImageButton_Update"
-GetClicks%()="_bb_TGUIImageButton_GetClicks"
-Draw%()="_bb_TGUIImageButton_Draw"
}="bb_TGUIImageButton"
TGUIBackgroundBox^TGUIobject{
.textalign%&
.manualState%&
-New%()="_bb_TGUIBackgroundBox_New"
+Create:TGUIBackgroundBox(x%,y%,width%=100,height%=100,textalign%=0,value$,State$=$"",UseFont:brl.max2d.TImageFont="bbNullObject")="_bb_TGUIBackgroundBox_Create"
-SetTextalign%(aligntype$=$"LEFT")="_bb_TGUIBackgroundBox_SetTextalign"
-Update%()="_bb_TGUIBackgroundBox_Update"
-Draw%()="_bb_TGUIBackgroundBox_Draw"
}="bb_TGUIBackgroundBox"
TGUIArrowButton^TGUIobject{
.direction$&
.grayedout%&
-New%()="_bb_TGUIArrowButton_New"
+Create:TGUIArrowButton(x%,y%,direction%=0,on@=0,enabled@=1,grayedout%=0,State$=$"",align%=0)="_bb_TGUIArrowButton_Create"
-setAlign%(align%=0)="_bb_TGUIArrowButton_setAlign"
-Update%()="_bb_TGUIArrowButton_Update"
-GetClicks%()="_bb_TGUIArrowButton_GetClicks"
-Draw%()="_bb_TGUIArrowButton_Draw"
}="bb_TGUIArrowButton"
TGUISlider^TGUIobject{
.minvalue%&
.maxvalue%&
.actvalue%&
.addvalue%&
.drawvalue%&
-New%()="_bb_TGUISlider_New"
+Create:TGUISlider(x%,y%,width%,minvalue%,maxvalue%,enabled@=1,value$,State$=$"")="_bb_TGUISlider_Create"
-Update%()="_bb_TGUISlider_Update"
-EnableDrawValue%()="_bb_TGUISlider_EnableDrawValue"
-DisableDrawValue%()="_bb_TGUISlider_DisableDrawValue"
-EnableAddValue%(add%)="_bb_TGUISlider_EnableAddValue"
-DisableAddValue%()="_bb_TGUISlider_DisableAddValue"
-GetValue%()="_bb_TGUISlider_GetValue"
-Draw%()="_bb_TGUISlider_Draw"
}="bb_TGUISlider"
TGUIinput^TGUIobject{
.maxlength%&
.maxTextWidth%&
.nobackground%&
.colR@&
.colG@&
.ColB@&
.OverlayImage:TGW_Sprites&
.InputImage:TGW_Sprites&
.OverlayRect%&
.OverlayColR%&
.OverlayColG%&
.OverlayColB%&
.OverlayColA#&
.grayedout%&
.TextDisplaceY%&
.TextDisplaceX%&
-New%()="_bb_TGUIinput_New"
+Create:TGUIinput(x%,y%,width%,enabled@=1,value$,maxlength%=128,State$=$"",useFont:brl.max2d.TImageFont="bbNullObject")="_bb_TGUIinput_Create"
-SetCol%(colR%,colG%,colB%)="_bb_TGUIinput_SetCol"
-Update%()="_bb_TGUIinput_Update"
-SetOverlayImage:TGUIInput(_sprite:TGW_Sprites)="_bb_TGUIinput_SetOverlayImage"
-Draw%()="_bb_TGUIinput_Draw"
}="bb_TGUIinput"
TGUIDropDownEntries^brl.blitz.Object{
List:brl.linkedlist.TList&=mem:p("_bb_TGUIDropDownEntries_List")
.value$&
.entryid%&
.pid%&
-New%()="_bb_TGUIDropDownEntries_New"
+Create:TGUIDropDownEntries(value$,id%)="_bb_TGUIDropDownEntries_Create"
}="bb_TGUIDropDownEntries"
TGUIDropDown^TGUIobject{
.grayedout%&
.Values$&[]&
.Entries:TGUIDropDownEntries&
.EntryList:brl.linkedlist.TList&
.PosChangeTimer%&
.ListPosClicked%&
.ListPosEntryID%&
.buttonheight%&
.textalign%&
.OnChange_%(listpos%)&
-New%()="_bb_TGUIDropDown_New"
+Create:TGUIDropDown(x%,y%,width%=-1,on@=0,enabled@=1,grayedout%=0,value$,State$=$"")="_bb_TGUIDropDown_Create"
+DoNothing%(listpos%)="_bb_TGUIDropDown_DoNothing"
-SetActiveEntry%(id%)="_bb_TGUIDropDown_SetActiveEntry"
-Update%()="_bb_TGUIDropDown_Update"
-AddEntry%(value$,id%)="_bb_TGUIDropDown_AddEntry"
-GetClicks%()="_bb_TGUIDropDown_GetClicks"
-Draw%()="_bb_TGUIDropDown_Draw"
}="bb_TGUIDropDown"
TGUIOkButton^TGUIobject{
.crossed@&
.onoffstate$&
.assetWidth#&
-New%()="_bb_TGUIOkButton_New"
+Create:TGUIOkButton(x%,y%,on@=0,enabled@=1,value$,State$=$"")="_bb_TGUIOkButton_Create"
-Update%()="_bb_TGUIOkButton_Update"
-IsCrossed%()="_bb_TGUIOkButton_IsCrossed"
-Draw%()="_bb_TGUIOkButton_Draw"
}="bb_TGUIOkButton"
TGUIbackground^TGUIobject{
.guigfx%&
-New%()="_bb_TGUIbackground_New"
+Create:TGUIbackground(x%,y%,width%,height%,Own%=0,State$=$"")="_bb_TGUIbackground_Create"
-Update%()="_bb_TGUIbackground_Update"
-Draw%()="_bb_TGUIbackground_Draw"
}="bb_TGUIbackground"
TGUIListEntries^brl.blitz.Object{
List:brl.linkedlist.TList&=mem:p("_bb_TGUIListEntries_List")
.value$&
.title$&
.pid%&
.team$&
.ip$&
.port$&
.time%&
-New%()="_bb_TGUIListEntries_New"
+Create:TGUIListEntries(title$,value$,team$,pid%,ip$=$"",port$=$"",time%=0)="_bb_TGUIListEntries_Create"
}="bb_TGUIListEntries"
TGUIList^TGUIobject{
.maxlength%&
.filter$&
.buttonclicked%&
.ListStartsAtPos%&
.PosChangeTimer%&
.ListPosClicked%&
.GUIbackground:TGUIbackground&
.EntryList:brl.linkedlist.TList&
.ControlEnabled%&
.lastMouseClickTime%&
.LastMouseClickPos%&
.nobackground%&
-New%()="_bb_TGUIList_New"
+Create:TGUIList(x%,y%,width%,height%=50,enabled@=1,maxlength%=128,State$=$"")="_bb_TGUIList_Create"
-Update%()="_bb_TGUIList_Update"
-DisableBackground%()="_bb_TGUIList_DisableBackground"
-SetControlState%(on%=1)="_bb_TGUIList_SetControlState"
-SetFilter%(usefilter$=$"")="_bb_TGUIList_SetFilter"
-RemoveOldEntries%(uid%=0,timeout%=500)="_bb_TGUIList_RemoveOldEntries"
-AddUniqueEntry%(title$,value$,team$,ip$,port$,time%,usefilter$=$"")="_bb_TGUIList_AddUniqueEntry"
-GetEntryCount%()="_bb_TGUIList_GetEntryCount"
-GetEntryPort$()="_bb_TGUIList_GetEntryPort"
-GetEntryTime%()="_bb_TGUIList_GetEntryTime"
-GetEntryValue$()="_bb_TGUIList_GetEntryValue"
-GetEntryTitle$()="_bb_TGUIList_GetEntryTitle"
-GetEntryIP$()="_bb_TGUIList_GetEntryIP"
-ClearEntries%()="_bb_TGUIList_ClearEntries"
-AddEntry%(title$,value$,team$,ip$,port$,time%)="_bb_TGUIList_AddEntry"
-Draw%()="_bb_TGUIList_Draw"
}="bb_TGUIList"
TGUIChat^TGUIList{
.AutoScroll%&
.turndirection%&
.fadeout%&
.GUIInput:TGUIinput&
.guichatgfx%&
.colR%&
.colG%&
.ColB%&
.EnterPressed%&
._UpdateFunc_%()&
.TeamNames$&[]&
.TeamColors:TPlayerColor&[]&
.Font:brl.max2d.TImageFont&
-New%()="_bb_TGUIChat_New"
+Create:TGUIChat(x%,y%,width%,height%=50,enabled@=1,maxlength%=128,State$=$"")="_bb_TGUIChat_Create"
-Update%()="_bb_TGUIChat_Update"
-Draw%()="_bb_TGUIChat_Draw"
}="bb_TGUIChat"
gfx_GuiPack:TGW_SpritePack&=mem:p("bb_gfx_GuiPack")
GetViewPortX%&=mem("bb_GetViewPortX")
GetViewPortY%&=mem("bb_GetViewPortY")
GetViewPortWidth%&=mem("bb_GetViewPortWidth")
GetViewPortHeight%&=mem("bb_GetViewPortHeight")
GUIManager:TGUIManager&=mem:p("bb_GUIManager")
