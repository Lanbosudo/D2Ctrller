; Using a Joystick as a Mouse
; http://www.autohotkey.com
; This script converts a joystick into a three-button mouse.  It allows each
; button to drag just like a mouse button and it uses virtually no CPU time.
; Also, it will move the cursor faster depending on how far you push the joystick
; from center. You can personalize various settings at the top of the script.

; Increase the following value to make the mouse cursor move faster:
JoyMultiplier = 45

; Decrease the following value to require less joystick displacement-from-center
; to start moving the mouse.  However, you may need to calibrate your joystick
; -- ensuring it's properly centered -- to avoid cursor drift. A perfectly tight
; and centered joystick could use a value of 1:
JoyThreshold = 3

; Change the following to true to invert the Y-axis, which causes the mouse to
; move vertically in the direction opposite the stick:
InvertYAxis := false

; Change these values to use joystick button numbers other than 1, 2, and 3 for
; the left, right mouse buttons.  Available numbers are 1 through 32.
; Use the Joystick Test Script to find out your joystick's numbers more easily.
ButtonLeft = 6
ButtonRight = 8

; If your joystick has a POV control, you can use it as a mouse wheel.  The
; following value is the number of milliseconds between turns of the wheel.
; Decrease it to have the wheel turn faster:
WheelDelay = 250

; If your system has more than one joystick, increase this value to use a joystick
; other than the first:
JoystickNumber = 1

; Control Shift
ButtonControl = 1Joy7
ButtonShift = 1Joy5

AltFlag = 0

; END OF CONFIG SECTION -- Don't change anything below this point unless you want
; to alter the basic nature of the script.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


#SingleInstance


JoystickPrefix = %JoystickNumber%Joy
Hotkey, %JoystickPrefix%%ButtonLeft%, ButtonLeft
Hotkey, %JoystickPrefix%%ButtonRight%, ButtonRight

Hotkey, %ButtonControl%, ButtonControl
Hotkey, %ButtonShift%, ButtonShift

; Calculate the axis displacements that are needed to start moving the cursor:
JoyThresholdUpper := 50 + JoyThreshold
JoyThresholdLower := 50 - JoyThreshold
if InvertYAxis
	YAxisMultiplier = -1
else
	YAxisMultiplier = 1

SetTimer, WatchJoystick, 10  ; Monitor the movement of the joystick.

GetKeyState, JoyInfo, %JoystickNumber%JoyInfo
IfInString, JoyInfo, P  ; Joystick has POV control, so use it as a mouse wheel.
	SetTimer, MouseWheel, %WheelDelay%

SetTimer, WatchLeftJoystick, 10 ; Monitor left wheel

return  ; End of auto-execute section.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; The subroutines below do not use KeyWait because that would sometimes trap the
; WatchJoystick quasi-thread beneath the wait-for-button-up thread, which would
; effectively prevent mouse-dragging with the joystick.

ButtonLeft:

;WinGetTitle, title, A
;if (title = "Steam")
;Return

SetMouseDelay, -1  ; Makes movement smoother.
MouseClick, left,,, 1, 0, D  ; Hold down the left mouse button.
SetTimer, WaitForLeftButtonUp, 10
return

ButtonRight:

;WinGetTitle, title, A
;if (title = "Steam")
;Return

SetMouseDelay, -1  ; Makes movement smoother.
MouseClick, right,,, 1, 0, D  ; Hold down the right mouse button.
SetTimer, WaitForRightButtonUp, 10
return

WaitForLeftButtonUp:
if GetKeyState(JoystickPrefix . ButtonLeft)
	return  ; The button is still, down, so keep waiting.
; Otherwise, the button has been released.
SetTimer, WaitForLeftButtonUp, off
SetMouseDelay, -1  ; Makes movement smoother.
MouseClick, left,,, 1, 0, U  ; Release the mouse button.
return

WaitForRightButtonUp:
if GetKeyState(JoystickPrefix . ButtonRight)
	return  ; The button is still, down, so keep waiting.
; Otherwise, the button has been released.
SetTimer, WaitForRightButtonUp, off
MouseClick, right,,, 1, 0, U  ; Release the mouse button.
return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ButtonControl:

WinGetTitle, title, A
if (title = "Steam")
Return

Send {Control Down}
SetTimer, WaitForControlUp, 10
return

WaitForControlUp:
  if GetKeyState(ButtonControl)
    Return  ; The button is still, down, so keep waiting.
; Otherwise, the button has been released.
  SetTimer, WaitForControlUp, off
  Send {Control Up}
return

ButtonShift:

WinGetTitle, title, A
if (title = "Steam")
Return

  Send {Shift Down}
  SetTimer, WaitForShiftUp, 10
  Return

WaitForShiftUp:
  if GetKeyState(ButtonShift)
    Return  ; The button is still, down, so keep waiting.
; Otherwise, the button has been released.
  SetTimer, WaitForShiftUp, Off
  Send {Shift Up}
  Return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

WatchJoystick:
MouseNeedsToBeMoved := false  ; Set default.

;Set MouseMoveSpeed a y=x^n function

SetFormat, float, 0.20
GetKeyState, joyx, %JoystickNumber%JoyZ
GetKeyState, joyy, %JoystickNumber%JoyR
if joyx > %JoyThresholdUpper%
{
	MouseNeedsToBeMoved := true
	DeltaX := 1/6 + 5/6*((joyx-JoyThresholdUpper)/(100-JoyThresholdUpper))**9
}
else if joyx < %JoyThresholdLower%
{
	MouseNeedsToBeMoved := true
	DeltaX := -1/6 + 5/6*((joyx-JoyThresholdLower)/(JoyThresholdLower))**9
}
else
	DeltaX = 0
if joyy > %JoyThresholdUpper%
{
	MouseNeedsToBeMoved := true
	DeltaY := 1/6 + 5/6*((joyy-JoyThresholdUpper)/(100-JoyThresholdUpper))**9
}
else if joyy < %JoyThresholdLower%
{
	MouseNeedsToBeMoved := true
	DeltaY := -1/6 + 5/6*((joyy-JoyThresholdLower)/(JoyThresholdLower))**9
}
else
	DeltaY = 0
if MouseNeedsToBeMoved
{
	SetMouseDelay, -1  ; Makes movement smoother.
	MouseMove, DeltaX * JoyMultiplier, DeltaY * YAxisMultiplier * JoyMultiplier, 0, R
}
return

MouseWheel:
GetKeyState, JoyPOV, %JoystickNumber%JoyPOV
if JoyPOV = -1  ; No angle.
	return
if (JoyPOV > 31500 or JoyPOV < 4500)  ; Forward
	Send {WheelUp}
else if JoyPOV between 13500 and 22500  ; Back
	Send {WheelDown}
else if JoyPOV between 4501 and 13500 ; Right
{
    Send {T}{Click right}
    WinGetPos,,, total_width, total_height, A
    x_axis := round(total_width*0.48)
    y_axis := round(total_height*0.44)
    Click down %x_axis% %y_axis%  ; move cursor on the portal
    Click up
    Sleep, 1000
    Click
    }
else ; Left
    Send {I}
return

; WASD movement with left wheel


; monitor function
WatchLeftJoystick:
  
  WinGetTitle, title, A
  if not (title = "Diablo II")
  Return

  WinGetPos,,, total_width, total_height, A ; In case of running a Window, or in a resolution not matching the Desktop's.

  x_axis_centre := round(total_width//2)
  y_axis_centre := round(total_height*0.5) ; This is corrected for true horizontal movement.

  unit_x := round(total_width*0.045)
  unit_y := round(total_height*0.06)



  SetFormat, float, 03
  GetKeyState, joyx, %JoystickNumber%JoyX
  GetKeyState, joyy, %JoystickNumber%JoyY

  if joyx > %JoyThresholdUpper%
    DeltaX := 1
  else if joyx < %JoyThresholdLower%
    DeltaX := -1
  Else
    DeltaX = 0

  if joyy > %JoyThresholdUpper%
    DeltaY := 1
  else if joyy < %JoyThresholdLower%
    DeltaY := -1
  Else
    DeltaY = 0
  if not (DeltaX = 0 and DeltaY = 0)
  {
    x_axis := x_axis_centre + DeltaX*unit_x
    y_axis := y_axis_centre + DeltaY*unit_y
    Click down %x_axis% %y_axis%
    Click up
  }

  Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; potion
1Joy1::
WinGetTitle, title, A
if (title = "Steam")
Return
Send {1}
Return

1Joy2::
WinGetTitle, title, A
if (title = "Steam")
Return
Send {2}
Return

1Joy3::
WinGetTitle, title, A
if (title = "Steam")
Return
Send {3}
Return

1Joy4::
WinGetTitle, title, A
if (title = "Steam")
Return
Send {4}
Return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; function keys

1Joy10::
WinGetTitle, title, A
if (title = "Steam")
Return
Send {Esc}
Return

1Joy9::

  WinGetTitle, title, A
  if (title = "Steam")
    Return

  if (AltFlag = 0) {
    Send {Alt down}
    AltFlag := 1
    }
  else {
    Send {Alt up}
    AltFlag := 0
    }

  Return

1Joy11::
WinGetTitle, title, A
if (title = "Steam")
Return
Send {Tab}
Return
