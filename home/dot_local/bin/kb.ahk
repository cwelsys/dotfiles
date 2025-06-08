#NoEnv ; recommended for performance and compatibility with future autohotkey releases.
#UseHook
#InstallKeybdHook
#SingleInstance force

SendMode Input

;; deactivate capslock completely
SetCapslockState, AlwaysOff

;; remap capslock to hyper
;; if capslock is toggled, remap it to esc
~Capslock::
    ;; must use downtemp to emulate hyper key, you cannot use down in this case
    ;; according to https://autohotkey.com/docs/commands/Send.htm, downtemp is as same as down except for ctrl/alt/shift/win keys
    ;; in those cases, downtemp tells subsequent sends that the key is not permanently down, and may be
    ;; released whenever a keystroke calls for it.
    ;; for example, Send {Ctrl Downtemp} followed later by Send {Left} would produce a normal {Left}
    ;; keystroke, not a Ctrl{Left} keystroke
    Send {Ctrl DownTemp}{Shift DownTemp}{Alt DownTemp}{LWin DownTemp}
    KeyWait, Capslock
    Send {Ctrl Up}{Shift Up}{Alt Up}{LWin Up}
    if (A_PriorKey = "Capslock") {
        Send {Esc}
    }
return

;; Toggle hidden files with Alt+Shift+.
!+.::GoSub,CheckActiveWindow

CheckActiveWindow:
  ID := WinExist("A")
  WinGetClass,Class, ahk_id %ID%
  WClasses := "CabinetWClass ExploreWClass"
  IfInString, WClasses, %Class%
    GoSub, Toggle_HiddenFiles_Display
Return

Toggle_HiddenFiles_Display:
  RootKey = HKEY_CURRENT_USER
  SubKey  = Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced

  RegRead, HiddenFiles_Status, % RootKey, % SubKey, Hidden

  if HiddenFiles_Status = 2
      RegWrite, REG_DWORD, % RootKey, % SubKey, Hidden, 1
  else
      RegWrite, REG_DWORD, % RootKey, % SubKey, Hidden, 2
  PostMessage, 0x111, 41504,,, ahk_id %ID% ; or Send {AppsKey}e
Return
