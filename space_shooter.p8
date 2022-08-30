pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
--[[
ideas:
- docking stations: enemies
	can maybe damage these
	
- map: player can only use map
	if they dock with a map station
	-- player should start at a map
				station
- upgrades: player collects
	"things" that follow them.
	when docking with an upgrade
	ship, they can spend them on
	upgrades
	
- paralax bk: procedural gen was
	unreliable - just use pre-made
	constilations
]]--

cam={x=0,y=0,sx=0,sy=0,s_tm=0}
pp={
	x=0,y=0,dx=0,dy=-1
}
mode=0//0=map,1=game
blts={}
strs={}
dust0={}
dust1={}
str_dst=2
map_r=1000

function rand(n,m)
	return flr(rnd((m+1)-n))+n
end

function dist(x1,y1,x2,y2)
	local dx,dy=x1-x2,y1-y2
	return sqrt(dx*dx + dy*dy)
end

function _init()
	printh("=====start=====")
	init_level()
end

function init_level()
	init_dust()
	init_strs()
end

function _draw()
	cls()
	
	if(mode==0)draw_mode_map()
	if(mode==1)draw_mode_game()
end

function draw_mode_map()
	camera(0,0)
	draw_map()
end

function draw_mode_game()
	camera(cam.x+cam.sx,
		cam.y+cam.sy)
	
	draw_strs()
	draw_dust()
	draw_player()
	
	print("x: "..pp.x,cam.x,cam.y+116,7)
	print("y: "..pp.y,cam.x,cam.y+122,7)
end

function _update()
	if mode==0 then
		update_mode_map()
	elseif mode==1 then
		update_mode_game()
	end
end

function update_mode_map()
	if(btnp(❎))mode=1
end

function update_mode_game()
	if btnp(❎) then
		mode=0
		return
	end
	update_player()
	update_blts()
	update_dust()
	update_cam()
end

function update_cam()
	cam.x=pp.x-64
	cam.y=pp.y-64
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
	
	if btnp(🅾️) then
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
		b.x+=b.dx*5
		b.y+=b.dy*5
		if b.x<cam.x or b.x>cam.x+128 or
		b.y<cam.y or b.y>cam.y+128 then
			del(blts,b)
		end
	end
end

function init_dust()
	for i=0,100 do
		add(dust,{
			x=rand(0,127),y=rand(0,127)
		})
	end
end

function draw_dust()
	for d in all(dust0) do
		pset(d.x,d.y,5)
	end
	for d in all(dust1) do
		pset(d.x,d.y,1)
	end
end

function update_dust()
	for d in all(dust0) do
		d.x-=pp.dx
		d.y-=pp.dy
		if d.x<cam.x-1 or 
		d.x>cam.x+128 or
		d.y<cam.y-1 or 
		d.y>cam.y+128 then
			del(dust0,d)
		end
	end
	
	for d in all(dust1) do
		d.x-=pp.dx*0.5
		d.y-=pp.dy*0.5
		if d.x<cam.x-1 or 
		d.x>cam.x+128 or
		d.y<cam.y-1 or 
		d.y>cam.y+128 then
			del(dust1,d)
		end
	end
	
	if pp.dx!=0 and rand(0,10)==0 then
		add(dust0,{
			x=pp.x+64*pp.dx,
			y=rand(cam.y,cam.y+127)
		})
	end
	if pp.dy!=0 and rand(0,10)==0 then
		add(dust0,{
			x=rand(cam.x,cam.x+127),
			y=pp.y+64*pp.dy,
		})
	end
	
	if pp.dx!=0 and rand(0,10)==0 then
		add(dust1,{
			x=pp.x+64*pp.dx,
			y=rand(cam.y,cam.y+127)
		})
	end
	if pp.dy!=0 and rand(0,10)==0 then
		add(dust1,{
			x=rand(cam.x,cam.x+127),
			y=pp.y+64*pp.dy,
		})
	end
end

function init_strs()
	for i=0,20 do
		local s={}
		local x=rand(-map_r,map_r)
		local y=rand(-map_r,map_r)
		local n=rand(2,5)
		printh("cnst "..x..","..y)
		for j=0,n do
			local rx=rand(x-100,x+100)
			local ry=rand(y-100,y+100)
			add(s,{x=rx,y=ry,n={}})
			//printh("\tadd "..rx..","..ry)
		end
		for s0 in all(s) do
			printh("\tchk "..s0.x..","..s0.y)
			local m=10000
			local fnd={}
			for s1 in all(s) do
				local d=dist(s0.x,s0.y,s1.x,s1.y)
				printh("\t\tdst "..d)
				if d>0 and d<m then
					m=d
					add(fnd,s1)
					printh("\t\t\tadd "..s1.x..","..s1.y)
				end
			end
			local n_fnd=min(rand(1,3),count(fnd))
			for i=0,n_fnd do
				local ii=count(fnd)-i
				add(s0.n,fnd[ii])
			end
		end
		
		add(strs,s)		
	end
end

function nrm_pos(x)
	return ((x- -map_r)/(2*map_r))*128
end

function draw_map()
	for ss in all(strs) do
	for s in all(ss) do
		local x=nrm_pos(s.x)
		local y=nrm_pos(s.y)
		
		for ns in all(s.n) do
			local nx=nrm_pos(ns.x)
			local ny=nrm_pos(ns.y)
			line(x,y,nx,ny,1)
		end
		
	end
	for s in all(ss) do
		local x=nrm_pos(s.x)
		local y=nrm_pos(s.y)
		pset(x,y,6)
	end
	end
	
	local x=nrm_pos(pp.x)
	local y=nrm_pos(pp.y)
	pset(x,y,8)
end

function draw_strs()
	for ss in all(strs) do
	for s in all(ss) do
		local sx=pp.x+(s.x-pp.x)/str_dst
		local sy=pp.y+(s.y-pp.y)/str_dst
		pset(sx,sy,6)
	end end
end

function update_strs()
	for s in all(strs) do
		//s.x
	end
end
__gfx__
00000000000770008777800000800077900000090000000008000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770000666000007706777090000900000000088800000000000000000000000000000000000000000000000000000000000000000000000000000
00700700006776000566660077667770009009000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000806776080057777786677760000000000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000766776670057777705577600000000000007700000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700766556670566660000056678009009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000765005670666000000056770090000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000800000088777800000008700900000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
