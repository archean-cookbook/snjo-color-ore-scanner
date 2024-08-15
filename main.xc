include "ColorOreScanner.main.xc"
init
	print("Boot BIOS, load Ore scanner.")
	@oreinit()
	@SetOreScreen(screen(0,0)) ; optional. If you don't use this the scanner uses screen(0,0)