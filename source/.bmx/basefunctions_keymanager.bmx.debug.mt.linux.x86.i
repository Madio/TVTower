import brl.blitz
import brl.system
import brl.polledinput
import brl.glmax2d
KEY_STATE_NORMAL%=0
KEY_STATE_HIT%=1
KEY_STATE_DOWN%=2
KEY_STATE_UP%=3
TMouseManager^brl.blitz.Object{
.LastMouseX%&
.LastMouseY%&
.MousePosChanged@&
.errorboxes%&
._iKeyStatus%&[]&
-New%()="_bb_TMouseManager_New"
-isNormal%(iKey%)="_bb_TMouseManager_isNormal"
-IsHit%(iKey%)="_bb_TMouseManager_IsHit"
-IsDown%(iKey%)="_bb_TMouseManager_IsDown"
-isUp%(iKey%)="_bb_TMouseManager_isUp"
-SetDown%(iKey%)="_bb_TMouseManager_SetDown"
-changeStatus%(_errorboxes%=0)="_bb_TMouseManager_changeStatus"
-resetKey%(iKey%)="_bb_TMouseManager_resetKey"
-getStatus%(iKey%)="_bb_TMouseManager_getStatus"
}="bb_TMouseManager"
TKeyManager^brl.blitz.Object{
._iKeyStatus%&[]&
-New%()="_bb_TKeyManager_New"
-isNormal%(iKey%)="_bb_TKeyManager_isNormal"
-IsHit%(iKey%)="_bb_TKeyManager_IsHit"
-IsDown%(iKey%)="_bb_TKeyManager_IsDown"
-isUp%(iKey%)="_bb_TKeyManager_isUp"
-changeStatus%()="_bb_TKeyManager_changeStatus"
-getStatus%(iKey%)="_bb_TKeyManager_getStatus"
-resetKey%(iKey%)="_bb_TKeyManager_resetKey"
}="bb_TKeyManager"
KEYWRAP_ALLOW_HIT%=1
KEYWRAP_ALLOW_HOLD%=2
KEYWRAP_ALLOW_BOTH%=3
TKeyWrapper^brl.blitz.Object{
._iKeySet%&[,]&
-New%()="_bb_TKeyWrapper_New"
-allowKey%(iKey%,iRule%=3,iHitTime%=600,iHoldtime%=100)="_bb_TKeyWrapper_allowKey"
-pressedKey%(iKey%)="_bb_TKeyWrapper_pressedKey"
-hitKey%(iKey%)="_bb_TKeyWrapper_hitKey"
-holdKey%(iKey%)="_bb_TKeyWrapper_holdKey"
-resetKey%(iKey%)="_bb_TKeyWrapper_resetKey"
}="bb_TKeyWrapper"
MOUSEMANAGER:TMouseManager&=mem:p("bb_MOUSEMANAGER")
KEYMANAGER:TKeyManager&=mem:p("bb_KEYMANAGER")
KEYWRAPPER:TKeyWrapper&=mem:p("bb_KEYWRAPPER")
