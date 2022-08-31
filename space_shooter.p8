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
	x=0,y=0,dx=0,dy=-1,w=8,h=8
}
mode=0//0=map,1=game
blts={}
strs={}
dust0={}
dust1={}
str_dst=2
map_r=1000
shps={} --enemy ships

function rand(n,m)
	return flr(rnd((m+1)-n))+n
end

function round(x)
	return flr(x+0.5)
end

function dist(x1,y1,x2,y2)
	local dx,dy=x1-x2,y1-y2
	return sqrt(dx*dx + dy*dy)
end

function ang_lerp(a1,a2,t)
	a1=a1%1
	a2=a2%1
	if abs(a1-a2)>0.5 then
		if a1>a2 then
			a2+=1
		else
			a1+=1
		end
	end
	return ((1-t)*a1+t*a2)%1
end

function col_bb(a,b)
	local ax=a.x-a.w/2
	local ay=a.y-a.h/2
	local bx=b.x-b.w/2
	local by=b.y-b.h/2
	return ax<=bx+b.w and
		ax+a.w>=bx and ay<=by+b.h and
		ay+a.h>=by
end

function _init()
	printh("=====start=====")
	init_level()
end

function init_level()
	init_dust()
	init_strs()
	pp.x=rand(-map_r,map_r)
	pp.y=rand(-map_r,map_r)
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
	draw_shps()
	draw_blts()
	
	print("ns: "..count(shps),cam.x,cam.y+108,7)
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
	update_shps()
	update_dust()
	update_cam()
end

function update_cam()
	cam.x=pp.x-64
	cam.y=pp.y-64
end

function draw_player()
	local px=pp.x-pp.w/2
	local py=pp.y-pp.h/2
	if pp.dx==0 then
		spr(1,px,py,1,1,0,pp.dy==1)
	elseif pp.dy==0 then
		spr(2,px,py,1,1,pp.dx==-1,0)
	else
		spr(3,px,py,1,1,pp.dx==-1,pp.dy==1)
	end
end

function update_player()
	-- input
	local dx=0
	local dy=0
	if(btn(⬆️))dy=-1
	if(btn(⬇️))dy=1
	if(btn(⬅️))dx=-1
	if(btn(➡️))dx=1
	
	-- dir / movement
	if dx!=0 or dy!=0 then
		pp.dx=dx
		pp.dy=dy
	end
	pp.x+=pp.dx
	pp.y+=pp.dy
	
	-- wrap
	if pp.x<-map_r and pp.dx==-1 then
		pp.x=map_r
	elseif pp.x>map_r and pp.dx==1 then
		pp.x=-map_r
	end
	if pp.y<-map_r and pp.dy==-1 then
		pp.y=map_r
	elseif pp.y>map_r and pp.dy==1 then
		pp.y=-map_r
	end
	
	-- shoot
	if btnp(🅾️) then
		add(blts,{
			x=pp.x+4*pp.dx,
			y=pp.y+4*pp.dy,
			dx=pp.dx,
			dy=pp.dy,
			w=2,h=2
		})
	end
end

function draw_blts()
	for b in all(blts) do
		spr(5,(b.x-b.w/2)-3,(b.y-b.h/2)-3)
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
		
		for e in all(shps) do
			if col_bb(b,e) then
				del(shps,e)
				del(blts,b)
			end 
		end
	end
end

function draw_shps()
	for e in all(shps) do
		local ex=e.x-e.w/2
		local ey=e.y-e.h/2
		local dx=round(cos(e.a))
		local dy=round(sin(e.a))
		if dx==0 then
			spr(17,ex,ey,1,1,0,dy==1)
		elseif dy==0 then
			spr(18,ex,ey,1,1,dx==-1,0)
		else
			spr(19,ex,ey,1,1,dx==-1,dy==1)
		end
	end
end

spn_t=0
spn_t_m=100 --spawn time
shp_s=0.01 --ship speed
function update_shps()
	for e in all(shps) do
		local ang=atan2(pp.x-e.x,pp.y-e.y)
		e.a=ang_lerp(e.a,ang,0.05)
		e.x+=1*cos(e.a)
		e.y+=1*sin(e.a)
	end
	
	if spn_t==0 then
		spn_t=spn_t_m
		local ra=rnd(1)
		local rx=64*cos(ra)
		local ry=64*sin(ra)
		add(shps,{
			x=pp.x-rx,
			y=pp.y-ry,
			w=8,h=8,
			a=0
		})
	else
		spn_t-=1
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
			rx=mid(-map_r+1,rx,map_r-1)
			ry=mid(-map_r+1,ry,map_r-1)
			local rc=6
			local rcn=rand(0,100)
			if(rcn>70)rc=13
			if(rcn>80)rc=14
			if(rcn>90)rc=15
			add(s,{x=rx,y=ry,c=rc,n={}})
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
		pset(x,y,s.c)
	end
	end
	
-- dont show player
--	local x=nrm_pos(pp.x)
--	local y=nrm_pos(pp.y)
--	pset(x,y,8)
end

function draw_strs()
	for ss in all(strs) do
	for s in all(ss) do
		local sx=pp.x+(s.x-pp.x)/str_dst
		local sy=pp.y+(s.y-pp.y)/str_dst
		pset(sx,sy,s.c)
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
00000000080000800999990000098800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000090000908889999809999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000995005990055550099950008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000995885990008800098588098000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000995885990008800080088599000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000985005890055550000005990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000980000898889999800008990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000080000800999990000089900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000050000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000550000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000550000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555885550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555885550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000550000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000550000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000050000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
