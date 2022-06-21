pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
pp={
	x=0,y=0,dx=0,dy=-1
}

function _init()
end

function _draw()
	cls()
	draw_player()
end

function draw_player()
	if pp.dx==0 then
		spr(1,20,20)
	else if pp.dy==0 then
		spr(2,20,20)
	else
	
	end
end

function _update()
	update_player()
end

function update_player()
	local dx=0
	local dy=0
	if(btn(⬆️))dy=-1
	if(btn(⬇️))dy=1
	if(btn(⬅️))dx=-1
	if(btn(➡️))dx=1
	if dx!=0 or dy!=0 then
		pp.dx=dx
		pp.dy=dy
	end
end
__gfx__
00000000000770000080007787778000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770000770077706660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700006776007766777005666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000806776088667770000577777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000766776670557760000577777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700766556670055667805666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000765005670005677006660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000800000080000870087778000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
