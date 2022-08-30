pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
--[[
ideas:
- docking stations: enemies
	can maybe damage these
	
- map: player can only use map
	if they dock with a map station

- upgrades: player collects
	"things" that follow them.
	when docking with an upgrade
	ship, they can spend them on
	upgrades
	
- paralax bk: should be procedurally
	generated, player can use to
	navagate
]]--

cam={x=0,y=0,sx=0,sy=0,s_tm=0}
pp={
	x=0,y=0,dx=0,dy=-1
}
blts={}

function rand(n,m)
	return flr(rnd((m+1)-n))+n
end

function _init()
	printh("=====start=====")
	init_level()
end

test={}
function init_level()
	add(test,{x=0,y=0})
	for i=0,20 do
		add(test,{
			x=rand(0,500),
			y=rand(0,500)
		})
	end
end

function _draw()
	cls()
	
	camera(cam.x+cam.sx,
		cam.y+cam.sy)
		
	draw_player()
	draw_test()
end

function draw_player()
	if pp.dx==0 then
		spr(1,pp.x,pp.y,1,1,0,pp.dy==1)
	elseif pp.dy==0 then
		spr(2,pp.x,pp.y,1,1,pp.dx==-1,0)
	else
		spr(
		3,pp.x,pp.y,1,1,pp.dx==-1,pp.dy==1
		)
	end
	
	for b in all(blts) do
		spr(5,b.x,b.y)
	end
end

function draw_test()
	for i in all(test) do
		spr(4,i.x,i.y)
	end
end

function _update()
	update_player()
	update_blts()
	update_cam()
end

function update_cam()
	cam.x=pp.x-64
	cam.y=pp.y-64
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
	pp.x+=pp.dx
	pp.y+=pp.dy
	
	if btnp(❎) then
		add(blts,{
			x=pp.x+4*pp.dx,
			y=pp.y+4*pp.dy,
			dx=pp.dx,
			dy=pp.dy
		})
	end
end

function update_blts()
	for b in all(blts) do
		b.x+=b.dx*2
		b.y+=b.dy*2
		if b.x<cam.x or b.x>cam.x+128 or
		b.y<cam.y or b.y>cam.y+128 then
			del(blts,b)
		end
	end
end
__gfx__
00000000000770008777800000800077900000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770000666000007700777090000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700006776000566660077667770009009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000806776080057777786677700000000000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000766776670057777705577600000000000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700766556670566660000556678009009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000765005670666000000056770090000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000800000088777800000008700900000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
