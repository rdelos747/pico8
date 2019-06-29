pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--[[
jumper
- generate blob within 16x16
		map
- no scrolling (or maybe just
		a little above and below
		blob)
- when player jumps off blob and
		hits bottom of section,
			destroy current blob, and
			scroll player to top of
			screen.
		- then, generate new blob 
				below and drop player down.
		
]]--
