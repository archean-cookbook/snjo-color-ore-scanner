; COLOR ORE SCANNER by Snjo, based on batcholi and Drya'd BMD's blueprints

; OPTION SECTION, EDIT VALUES TO TASTE ----------------
; If there are ores missing in the config menu, add them in the init section at the bottom of the file

; REST MODE. Set this to 0 if there's no speed sensor and angular velocity senor attached
const $allowRestMode = 1

; STARTING ORE SELECTION, can be changed in the on-screen config menu
const $ore1Default = "Fe"
const $ore2Default = "land"
const $ore3Default = "sea"
var $resetStoredValue = 0 ; override to reset stored values, set to 1 to fix any bugged values

; Artificially boost the visibility of any ores, if you want to see trace amounts
; for examble, set Uranium's oreboost to 0.5, and a very low value will still be very visible
const $oreboost1 = 0 ; use values between 0-1
const $oreboost2 = 0 ; use values between 0-1
const $oreboost3 = 0 ; use values between 0-1

; Limit the brighness of an ore, for example dampen iron output since it's often overwhelming other ores
; 1 is normal, 0.1 is very faint.
; Values above 1 makes the color brighter, but it's better to use oreboost.
const $orenerf1 = 1 ; use values between 0-1
const $orenerf2 = 1 ; use values between 0-1
const $orenerf3 = 1 ; use values between 0-1

; CUSTOMIZE SCAN RANGE
const $shortRange = 250
const $mediumRange = 1000
const $longRange = 5000

; SCAN STEPS (AND TROUBLESHOOTING)
; Use this to limit power usage and server impact, but decrease the line density on screen.
; Max allowed is scan steps is 100, lower resolution screens use fewer lines.
; If you see circular stripes in the output near the center, reduce the $maxScanSteps value 
; or check that the scanner is connected directly to a battery. If power is routed through a junction,
; the scanner may run out of power before all scan steps are done per tick, and will output bad data.
const $maxScanSteps = 40
var $scanArc = 360 ; 1-360. change between full circle scan or narrow beam, which is faster to update the section you care about
const $rotSpeed = 0.10 ;how fast the scanner spins
var $scanDuration = 25 * 20; the amount of time in ticks (25*20 is 20s) to scan before going to sleep if there's no movement of the vehicle

; ATTACHED DEVICES, update if needed, You can replace port numbers with device names. (i.e. set $scanner_io to "ore_scanner")

var $screen = screen(0,0) ; COMPUTER PORT 0: monitor
const $scanner_io = 1	 ; COMPUTER PORT 1: ore scanner
const $pivot_io = 2	   ; COMPUTER PORT 2: robotic pivot
const $speed_io = 3	   ; COMPUTER PORT 3: speed sensor
const $angle_io = 4	   ; COMPUTER PORT 4: angular velocity sensor
const $terrain_io = 5

var $scan = 1 ; 1 means the scanner is ON, change this to 0 if you always want to startin OFF mode after rebooting

const $ButtonHeight = 25 ; reduce this if the menus don't fit on screen. Bigger buttons are easier to hit.

; END OF OPTION SECTION ----------------
; VARIABLES ----------------

var $scanDurationCount = $scanDuration
array $oreNames:text
var $max_distance = $mediumRange ; gets changed by UI buttons

var $lastScan = 0 ; timestamp of last completed scan

var $resting = 0 ; gets set to 1 when the vehicle isn't moving or rotating, overriden by $allowRestMode
var $angle = 0 ;current pivot angle
;var $oldAngle = 0 ; used by rest mode check
;var $extraScanRotation = 0 ;perform an extra full revolution after a change
var $showOreMenu = 0

; STORED VALUES ----------

storage var $ore1:text	;Red channel
storage var $ore2:text	;Green channel
storage var $ore3:text	;Blue channel

function @loadStoredValue($value:text,$default:text):text
	if $value == "" || $resetStoredValue
		print ("stored value is empty, setting in to ",$default)
		return $default
	else
		print ("stored value loaded",$value)
		return $value
		
function @loadStoredValues()
	$ore1 = @loadStoredValue($ore1,$ore1Default)
	$ore2 = @loadStoredValue($ore2,$ore2Default)
	$ore3 = @loadStoredValue($ore3,$ore3Default)

; BUTTONS  ---------------
const $textSize = 1
var $charHeight = 7
var $charWidth = 7
const $ButtonWidth = 52
;const $ButtonHeight = 25 ;change this to fit your screen ;moved to higher up in the user option section
const $ButtonPadding = 3 ; free space around the button
var $ButtonTextPadding = ($ButtonHeight-$textSize )/2 ; (horizontal) text distance from edge of button
const $ButtonExtWidth = $ButtonWidth + $ButtonPadding
const $ButtonExtHeight = $ButtonHeight + $ButtonPadding

function @refreshScreen()
	;$extraScanRotation = 1
	$scanDurationCount = $scanDuration
	$screen.blank()
	;Transparent screen:
	;$screen.blank(color(10,10,10,0)
	;$screen.draw_circle($screen.width/2,$screen.width/2,($screen.width/2)+1,black,black)

;UI BUTTONS etc --------------------

function @colorOn($value:number,$oncolor:number,$offcolor:number):number
	if $value
		return $oncolor
	return $offcolor

function @drawRangeButton($index:number, $range:number)
	var $top = $index*($ButtonHeight+$ButtonPadding)
	var $left = $screen.width-$ButtonWidth-$ButtonPadding
	var $right = $screen.width-$ButtonPadding
	var $bottom = $top + $ButtonHeight
	if $max_distance == $range
		$screen.draw_rect($left,$top,$right, $bottom, white, blue)
	else
		$screen.draw_rect($left,$top,$right, $bottom, white, black)
	$screen.write($left+4,$top+$ButtonTextPadding,white,$range:text)
	if $screen.button_rect($left, $top, $right, $bottom, 0)
		$max_distance = $range
		@refreshScreen()
		$resting = 0
		
function @drawFunctionButton($index:number, $function:text, $extrawidth:number)
	;ON/OFF and CONFIG buttons
	var $top = $index*($ButtonHeight+$ButtonPadding)
	var $left = $ButtonPadding
	var $right = $ButtonWidth+$ButtonPadding+$extrawidth
	var $bottom = $top + $ButtonHeight
	;$screen.draw_rect($left,$top,$right, $bottom, white, black)
	if $screen.button_rect($left, $top, $right, $bottom, white, black)
		if $function == "TURN OFF"
			$scan = 0
			@refreshScreen()
		if $function == "TURN ON"
			$scan = 1
			@refreshScreen()
			$resting = 0
		if $function == "CONFIG"
			$showOreMenu = 1
	$screen.write($left+4,$top+$ButtonTextPadding,white,$function)

function @drawArcButton($top:number,$col:number,$value:number)
	var $bw = $buttonHeight*1.25
	;var $top = $line*($ButtonHeight+$ButtonPadding)
	var $left = $col*($bw+$ButtonPadding)+$ButtonPadding
	var $right = $left + $bw
	var $bottom = $top + $ButtonHeight
	if $screen.button_rect($left, $top, $right, $bottom, white,@colorOn($value == $scanarc,blue,black))
		$scanArc = $value
		$scanDurationCount = $scanDuration
		$screen.blank(black)
	$screen.write($left+4,$top+$ButtonTextPadding,white,$value:text & "°")
	
function @drawPowerButtons()
	;on/off buttons
	var $bwidth = 5
	if $scan
		@drawFunctionButton(1,"TURN OFF", $bwidth)
	else
		@drawFunctionButton(1,"TURN ON", $bwidth)
	
function @drawRangeButtons()
	;range buttons
	var $top = 5
	var $left = $screen.width-64
	$screen.write($left,$top,white,"SCAN RANGE")
	@drawRangeButton(1,$shortrange)
	@drawRangeButton(2,$mediumrange)
	@drawRangeButton(3,$longrange)

;REST MODE, stop scanning when the vehicle is stationary ------------------

function @updateRestMode()
	;if $scanDurationCount <= 0 || $resting

	var $speed = input_number($speed_io,0)
	var $rot0 = abs(input_number($angle_io,0))
	var $rot1 = abs(input_number($angle_io,1))
	var $rot2 = abs(input_number($angle_io,2))
	var $rotating = $rot0 > 0.02 || $rot1 > 0.02 || $rot2 > 0.02
	var $standingStill = $speed < 0.1 && $rotating == 0
	if $standingStill && $allowRestMode && $scanDurationCount <= 0.1; enable rest mode when the vehicle is still
		$resting = 1
	elseif !$standingStill && $resting ; wake up when moved
		$resting = 0
		$scanDurationCount = $scanDuration
	else
		$resting = 0
	$scanDurationCount = max($scanDurationCount - 1, 0)

;TERRAIN AND ORE SCAN RETURN VALUES ---------------
var $terrain = 0
var $composite = ""
var $terrainScale = 0.0005 ; higher values go bright faster, less sensitive
var $seaScale = 0.0003 ; higher values goes to black quicker as the water is deeper, more sensitive
function @terrainSelected() : number
	return $ore1 == "land" || $ore2 == "land"  || $ore3 == "land" || $ore1 == "sea" || $ore2 == "sea" || $ore3 == "sea"
	
function @oreSelected() : number
	foreach $oreNames ($i,$o)
		if ($o == $ore1 || $o == $ore2 || $o == $ore3) && ($o != "off" && $o != "land" && $o != "sea")
			return 1
	return 0
	
function @getChannelStrength($channel:number,$resource:text,$nerf:number):number
	if $resource == "land"
		if $terrain > 0
			return clamp(($terrain*$terrainScale),0,1)
		else
			return 0
	if $resource == "sea"
		if $terrain < 0
			return clamp(1+($terrain*$seaScale*2),0,1)
		else
			return 0
	else
		return $composite.$resource

;TERRAIN AND ORE SCANNING  ---------------

var $rot = $rotSpeed
function @updatePivotAngle()
	var $chunk = 2pi / 360
	var $scanArcReal = $scanArc / 2
	if $scanArcReal < 360
		if $angle > $chunk*$scanArcReal  && $angle < $chunk * 180
			$rot = -$rotSpeed
			;print("go -",$scanArc,$angle,">",$chunk*$scanArc)
		elseif $angle < $chunk * (360-$scanArcReal) && $angle > $chunk * 180
			$rot = $rotSpeed
			;print("go +", (12-$scanArc),$angle,"<",$chunk * (360-$scanArc))
		else
			;$rot = $rotSpeed
			;print("huh?")
	else
		$rot = $rotSpeed
		;print("default rot")
	output_number($pivot_io,0,$rot)

var $offsetY = 0
var $scanZoom = 1
function @performScan()
	@updatePivotAngle()
	;output_number($pivot_io,0,$rotSpeed)
		
	;fade out to black, only works if above 0.5???
	$screen.draw(0,0,color(0,0,0,0.4),$screen.width,$screen.height)	
		
	var $half_width = $screen.width/2
	var $half_height = $screen.height/2
	if $scanArc > 180
		$offsetY = 0
		$scanZoom = 1
	else
		$offsetY = $half_height * 0.7
		$scanZoom = 1.3
		;print($offsetY)
	; var $steps = min(min($half_height, $maxScanSteps),100) ;steps above 100 will return bad values
	var $steps = min(min($half_height+$offsetY, $maxScanSteps),100) ;steps above 100 will return bad values

	var $x = sin($angle)
	var $y = cos($angle)
	repeat $steps ($i)
		if @oreSelected()
			$composite=input_text($scanner_io,$i)
		if @terrainSelected()
			$terrain=input_number($terrain_io,$i)
			
		;boost ore numbers
		if $composite.$ore1 > 0 && $composite.$ore1 < $oreboost1
			$composite.$ore1 = min($oreboost1,1)
		if $composite.$ore2 > 0 && $composite.$ore2 < $oreboost2
			$composite.$ore2 = min($oreboost2,1)
		if $composite.$ore3 > 0 && $composite.$ore3 < $oreboost3
			$composite.$ore3 = min($oreboost3,1)
						
		var $step= ($i+1)/$steps * $scanZoom
		var $distance = $step*$max_distance
		if @oreSelected()
			output_number($scanner_io,$i,$distance)
			;print("feed ore scanner")
		if @terrainSelected()
			output_number($terrain_io,$i,$distance)
			;print("feed terrain scanner")

		var $R = clamp(@getChannelStrength(1,$ore1,$orenerf1)*255*$orenerf1,0,255);min($composite.$ore1*255*$orenerf1,255)
		var $G = clamp(@getChannelStrength(2,$ore2,$orenerf2)*255*$orenerf2,0,255)
		var $B = clamp(@getChannelStrength(3,$ore3,$orenerf3)*255*$orenerf3,0,255)
		;var $G = min($composite.$ore2*255*$orenerf2,255)
		;var $B = min($composite.$ore3*255*$orenerf3,255)
		var $color=color($R,$G,$B,255)
		var $xx=(1-$x*$step)*$half_width
		var $yy=(1-$y*$step)*$half_height + $offsetY
		$screen.draw_circle($xx,$yy,2,0,$color) ; paint the ore dot
		
function @stopPivot()
	output_number($pivot_io,0,0)
	
function @drawRangeCircles()
	; draw the range circles and distance labels		
	var $cx = $screen.width/2 ;center screen
	var $cy = $screen.height/2 + $offsetY
	var $circleIncrements = 100
	if $max_distance > 5000
		$circleIncrements = 1000
	elseif $max_distance > 1000
		$circleIncrements = 500
	elseif $max_distance < 500
		$circleIncrements = 50
	repeat 11 ($i)
		if $i > 0
			var $radius = ($circleIncrements*$i / $max_distance) * ($screen.height/2)
			$screen.draw_circle($cx,$cy,$radius*$scanZoom,gray,0)
			var $labelDist = ($i*$circleIncrements):text & "m")
			var $labelWidth = size($labelDist)*$screen.char_w
			var $labelHeight = $screen.char_w
			var $labelX = $cx-$labelWidth/2
			var $labelY = $cy+$radius-$labelHeight/2-1
			$screen.draw_rect($labelX, $labelY,$labelX+$labelWidth,$labelY+$labelHeight+1,0,color(0,0,0,128))
			$screen.write($labelX, $cy+$radius*$scanZoom-4, white, ($i*$circleIncrements):text & "m")
	$screen.draw_circle($cx,$cy,2,white,0)
	

; ORE SELECT DISPLAY/MENU  --------------------------------

function @drawOreNames()
	; display the selected ores at the top of the screen in their colors
	$screen.draw_rect($ButtonPadding,$ButtonPadding,30+$ButtonPadding,18,0,color(100,0,0))
	$screen.write($ButtonPadding+3, 7, white ,$ore1)

	$screen.draw_rect($ButtonPadding+31,$ButtonPadding,60+$ButtonPadding,18,0,color(0,50,0))
	$screen.write($ButtonPadding+33, 7, white ,$ore2)

	$screen.draw_rect($ButtonPadding+61,$ButtonPadding,90+$ButtonPadding,18,0,color(20,20,255))
	$screen.write($ButtonPadding+63, 7, white ,$ore3)

var $selectedConfigOre = 1
function @drawConfigOreButton($X:number, $Y:number, $oreNumber:number)
	var	$left = $X+$ButtonPadding
	var $top = $Y+(($ButtonPadding+$ButtonHeight)*$oreNumber) + $ButtonPadding
	var $right = $left+$ButtonWidth
	var $bottom = $top+$ButtonHeight
	var $bg = black
	if $oreNumber+1 == $selectedConfigOre
		$bg = blue
	if $screen.button_rect($left, $top, $right, $bottom, white, $bg)
		$selectedConfigOre = $oreNumber+1
		;print("selected ore " & ($selectedConfigOre):text)
	$screen.write($left+4, $top+$ButtonTextPadding, white, "ORE " & ($oreNumber+1):text)

function @setOre($selecteConfigOre:number, $oreName:text)
	if $selectedConfigOre == 1
		$ore1 = $oreName
	elseif $selectedConfigOre == 2
		$ore2 = $oreName
	else
		$ore3 = $oreName
	$resting = 0

function @getSelectedOre($selecteConfigOre:number) : text
	if $selectedConfigOre == 1
		return $ore1
	elseif $selectedConfigOre == 2
		return $ore2
	else
		return $ore3

function @drawOreButton($X:number, $Y:number, $oreNumber:number, $oreName:text)
	var $Ybuttons = 6
	var $buttonRowNum = $oreNumber % $Ybuttons
	var $buttonColNum = floor($oreNumber/$Ybuttons
	
	var	$left = $X+ ($buttonColNum*$ButtonExtWidth)
	var $top = $Y + $buttonPadding + ($ButtonExtHeight*$buttonRowNum)
	var $right = $left+$ButtonWidth
	var $bottom = $top+$ButtonHeight
	
	var $bg = black
	if $oreName == @getSelectedOre($oreNumber)
		$bg = gray
	if $screen.button_rect($left, $top, $right, $bottom, white, $bg)
		print("selected ore: " & $oreName)
		@setOre($selectedConfigOre, $oreName)
		@refreshScreen()
	$screen.write($left+4, $top+$ButtonTextPadding, white, $oreName)

function @drawOreSelect()
	var $left = $buttonPadding
	var $top = (($ButtonExtHeight) * 2)
	var $width = ($ButtonExtWidth*4) + ($ButtonPadding)
	var $height = ($ButtonExtHeight * 7) + 5
	var $right = $left + $width
	var $bottom = $top + $height
	if $showOreMenu
		$screen.draw_rect($left,$top,$right,$bottom,white,black)
		@drawConfigOreButton($left, $top, 0)
		@drawConfigOreButton($left, $top, 1)
		@drawConfigOreButton($left, $top, 2)
		foreach $oreNames ($i, $oreN)
			@drawOreButton($left+$buttonWidth+($buttonPadding*2), $top, $i, $oreN)
;		if $screen.button_rect($right-$ButtonExtWidth-$ButtonPadding-1, $bottom-$ButtonExtHeight, $right-$ButtonPadding, $bottom-$ButtonPadding, white, green)
		var $OKleft = $left+$ButtonPadding+($ButtonExtWidth*1)
		var $OKwidth = $ButtonExtWidth*3
		if $screen.button_rect($OKleft, $bottom-$ButtonExtHeight-$ButtonPadding, $OKleft+$OKwidth-$ButtonPadding, $bottom-$ButtonPadding, white, green)
			$showOreMenu = 0
			@refreshScreen()
			$resting = 0
		$screen.write($OKleft+($OKwidth/2)-($charwidth/2), $bottom-$ButtonExtHeight+$ButtonTextPadding, black, "OK")
	else
		@drawFunctionButton(2,"CONFIG")
		;if $screen.button_rect($left,$top,$left+$ButtonWidth+5,$top+$ButtonHeight,white,black)
		;	$showOreMenu = 1
		;$screen.write($left+4, $top+$ButtonTextPadding, white, "CONFIG")
		

; EXECUTION --------------------------------

init 
	@loadStoredValues()
	@refreshScreen()
	print("Booting ore scanner")
	print("Screen dimensions: " & $screen.width:text & "x" & $screen.height:text)
	print("Scanning for ores: " & $ore1 & ", " & $ore2 & ", " &  $ore3)
	; All known ores. Add to this if more are added in game
	$oreNames.append("Ag")
	$oreNames.append("Al")
	$oreNames.append("Au")
	$oreNames.append("C")
	$oreNames.append("Cu")
	$oreNames.append("Cr")
	$oreNames.append("Fe")
	$oreNames.append("Ni")
	$oreNames.append("Pb")
	$oreNames.append("Si")
	$oreNames.append("Sn")
	$oreNames.append("Ti")
	$oreNames.append("U")
	$oreNames.append("W")
	$oreNames.append("land")
	$oreNames.append("sea")
	$oreNames.append("off")

update	
	$screen.text_size($textSize)
	$charHeight = $screen.char_h
	$charWidth = $screen.char_w
	var $screenCenterX = $screen.width / 2
	var $screenCenterY = $screen.height / 2
	$ButtonTextPadding = ($ButtonHeight-$charHeight)/2 
	$angle = input_number($pivot_io, 0) * 2pi ; check the current pivot angle
	
	;if $angle < $oldAngle || $resting
	@updateRestMode()
	;$oldAngle = $angle

	if $scan == 0 ; user has turned the scanner off via UI button
		@drawRangeCircles()
		$screen.text_size(2)
		$screen.draw_rect($screenCenterX-(8*$screen.char_w), $screenCenterY-(1*$screen.char_h), $screenCenterX+(8*$screen.char_w), $screenCenterY+(1*$screen.char_h),red,black)
		$screen.write($screenCenterX - (7*$screen.char_w), $screenCenterY-($screen.char_h/2), red ,"Scanner is OFF")
		$screen.text_size(1)
		@stopPivot()
	elseif $resting
		@stopPivot()
	else
		@performScan()
		@drawRangeCircles()
		
	@drawPowerButtons()
	@drawRangeButtons()
	@drawOreNames()
	@drawOreSelect()
	var $arcY = $screen.height-$buttonHeight-$buttonpadding
	@drawArcButton($arcY,0,360)
	@drawArcButton($arcY,1,180)
	@drawArcButton($arcY,2,90)
;end of file
