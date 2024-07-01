# Color ore scanner

Scan for three different ores at once using a three-color scheme.

UI button to select:
- Ores to scan for
- Scanning range
- Stop or start scanning to save power

There's a section at the top of the code to specify ores to scan for, scanning speed, range and detail.

You can also artificially boost the return value of ores, so that if there's a trace amount of an ore, it will still output in a strong color.

## Computer Ports
0. Screen
1. Ore scanner
2. Pivot (make sure to turn off servo mode with V)
3. Speed sensor (can be dropped if $allowRestMode is 0)
4. Angular speed sensor (can be dropped if $allowRestMode is 0)
5. Terrain scanner (optional)

## Optional terrain scanner
If you attach a terrain scanner on port 5, you can select "land" and "sea" on the green and blue channel to show the terrain on screen.

## Power saving features
When the vehicle isn't moving, the scanner stops turning and scanning to save power. This can be disabled by setting $allowRestMode to 0.
If you don't select either land or sea, the terrain scanner doesn't draw any power.
If no ores are selected, the ore scanner doesn't draw any power.


## Values you might want to tweak

        ; REST MODE. Set this to 0 if there's no speed sensor and angular velocity senor attached
        const $allowRestMode = 1

        ; STARTING ORE SELECTION, can be changed in the on-screen config menu
        ; After the first start, these values are stored and reloaded after rebooting or editing code
        var $ore1Default="Fe"   ;Iron, Red channel
        var $ore2Default="Cu"   ;Copper, Green channel
        var $ore3Default="Al"    ;Aluminium, Blue channel
        var $resetStoredValue = 0 ; override to reset stored values, set to 1 to fix any bugged ore values

        ; BOOST ORE VISIBILITY
        const $oreboost1=0       ; normal display
        const $oreboost2=0.5    ; any amount of ore will be displayed as at least 50%
        const $oreboost3=0.1    ; any amount of ore will be displayed as at least 10%

        ; CUSTOMIZE SCAN RANGES ON BUTTONS
        const $shortRange = 250
        const $mediumRange = 500
        const $longRange = 1000

        ; ADJUST SCANNER ROTATION SPEED
        const $rotSpeed = 0.1

        ; Change button sizes
        const $ButtonHeight = 25

        ; Use this to limit power usage and server impact, but decrease the line density on screen.
        ; Max allowed is scan steps is 100, lower resolution screens use fewer lines.
        const $maxScanSteps = 40


## Troubleshooting
If you see circular stripes in the output near the center, reduce the $maxScanSteps value or check that the scanner is connected directly to a battery. If power is routed through a junction, the scanner may run out of power before all scan steps are done per tick, and will output bad data.

## Source code
The code is based on *batcholi* and *Drya'd BMD's* blueprints, but with extra bells and whistles.

If you want to load the code into a computer without spawning the blueprint, you can find the code here:

https://github.com/archean-cookbook/snjo-color-ore-scanner