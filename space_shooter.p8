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

cam={x=0,y=0,sx=0,sy=0,s=0}
pp={
	x=0,y=0,dx=0,dy=-1,w=8,h=8,
	ergy=90,ergy_m=100
}
mode=0//0=map,1=game
blts={}
strs={}
dust0={}
dust1={}
str_dst=2
map_r=1000
ergy={} --energy pellets
shps={} --enemy ships
stns={} --enemy stations
roks={} --rocks
spkl={} --sprinkles


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

//functoin lerp

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

-- u/thehansinator255
function apr_pos(x,y,ox,oy)
	local xa=x
	if xa-ox>map_r then
		xa-=map_r*2
	elseif ox-xa>map_r then
		xa+=map_r*2
	end
	
	local ya=y
	if ya-oy>map_r then
		ya-=map_r*2
	elseif oy-ya>map_r then
		ya+=map_r*2
	end
	
	return xa,ya
end

function wrap_pos(x,y)
	local ex,ey=x,y
	if(ex<-map_r)ex=map_r
	if(ex>map_r)ex=-map_r
	if(ey<-map_r)ey=map_r
	if(ey>map_r)ey=-map_r
	return ex,ey
end

function _init()
	printh("=====start=====")
	init_level()
end

function init_level()
	init_dust()
	init_strs()
	
	init_roks()
	pp.x=rand(-map_r,map_r)
	pp.y=rand(-map_r,map_r)
	--temp here
	init_stns()
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
	draw_stns()
	draw_blts()
	draw_ergy()
	draw_roks()
	draw_spkl()
	
	draw_hud()
	
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
	update_player()
	update_blts()
	update_shps()
	update_stns()
	update_ergy()
	update_roks()
	update_dust()
	update_spkl()
	update_cam()
end

function update_cam()
	if cam.s>0.05 then
		cam.sx=rand(-2,2)*cam.s
		cam.sy=rand(-2,2)*cam.s
		cam.s*=0.8
	else
		cam.s=0
		cam.sx=0
		cam.sy=0
	end
	cam.x=(pp.x-64)+cam.sx
	cam.y=(pp.y-64)+cam.sy
end

function shake()
	cam.s=1
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
	
	pp.x,pp.y=wrap_pos(pp.x,pp.y)
	
	-- shoot
	if btnp(🅾️) then
		// i dont like the +6 offset
		add_blt(
			pp.x+6*pp.dx,pp.y+6*pp.dy,
			pp.dx,pp.dy,5)
	end
	
	-- getting shot
	for b in all(blts) do
		if col_bb(b,pp) then
			pp.ergy-=5
			del(blts,b)
			shake()
		end
	end
	
	-- getting hit
	for e in all(shps) do
		if col_bb(pp,e) then
			pp.ergy-=10
			del(shps,e)
			shake()
			add_spkl(e.x,e.y)
		end
	end
	
	for r in all(roks) do
		if col_bb(pp,r) then
			if(r.hp==2)pp.ergy-=10
			if(r.hp==1)pp.ergy-=5
			kill_rok(r)
			shake()
		end
	end
	
	if btnp(❎) then
		if pp.ergy>=10 then
			pp.ergy-=10
			mode=0
			return
		end
	end
end

function draw_hud()
	print("e:",cam.x,cam.y,7)
	rectfill(cam.x+7,cam.y+1,
		cam.x+7+pp.ergy,cam.y+3,12)
	rect(cam.x+7,cam.y,
		cam.x+7+pp.ergy_m+1,cam.y+4,7)
	for i=0,9 do
		pset(cam.x+7+i*10,cam.y+1,7)
	end
end

function draw_blts()
	for b in all(blts) do
		local drx,dry=apr_pos(
			b.x,b.y,pp.x,pp.y
		)
		spr(5,(drx-b.w/2)-3,(dry-b.h/2)-3)
	end
end

function update_blts()
	for b in all(blts) do
		b.x+=b.dx*b.s
		b.y+=b.dy*b.s
		local px,py=apr_pos(
			pp.x,pp.y,b.x,b.y
		)
		if abs(b.x-px)>64 or
					abs(b.y-py)>64 then
			del(blts,b)
		end
	end
end

function add_blt(x,y,dx,dy,s)
	add(blts,{
		x=x,y=y,
		dx=dx,dy=dy,
		w=2,h=2,
		s=s
	})
end

function draw_shps()
	for e in all(shps) do
		local drx,dry=apr_pos(
			e.x,e.y,pp.x,pp.y
		)
		local ex=drx-e.w/2
		local ey=dry-e.h/2
		
		if e.dx==0 then
			spr(17,ex,ey,1,1,0,e.dy==1)
		elseif e.dy==0 then
			spr(18,ex,ey,1,1,e.dx==-1,0)
		else
			spr(19,ex,ey,1,1,e.dx==-1,e.dy==1)
		end
	end
end

spn_t=0 --spawn time
spn_t_m=100
shp_s=1 --ship speed
shp_t=0.03 --ship turn lerp
function update_shps()
	for e in all(shps) do
		-- apparent pos
		local px,py=apr_pos(
			pp.x,pp.y,e.x,e.y
		)
		--angle
		local ang=atan2(px-e.x,py-e.y)
		e.a=ang_lerp(e.a,ang,shp_t)
		e.x+=shp_s*cos(e.a)
		e.y+=shp_s*sin(e.a)
		
		e.x,e.y=wrap_pos(e.x,e.y)
		
		e.dx=round(cos(e.a))
		e.dy=round(sin(e.a))
		
		--shooting
		if abs((ang-e.a%1))<0.15 and
					rand(0,100)>95 then
			add_blt(
				e.x+6*e.dx,e.y+6*e.dy,
				e.dx,e.dy,3)
		end
		
		-- getting shot
		for b in all(blts) do
			if col_bb(e,b) then
				local ner=rand(1,5)
				for i=0,ner do
					add_ergy(e.x,e.y)
				end
				del(blts,b)
				del(shps,e)
				add_spkl(e.x,e.y)
			end 
		end
	end
	
	--spawning
	if spn_t==0 then
		spn_t=spn_t_m
		local ra=rnd(1)
		local rx=64*cos(ra)
		local ry=64*sin(ra)
		add(shps,{
			x=pp.x-rx,
			y=pp.y-ry,
			dx=0,dy=0,
			w=8,h=8,
			a=0
		})
	else
		spn_t-=1
	end
end

function init_stns()
	-- temp
	local x=pp.x+50
	local y=pp.y+50
	
	local pods={}
	local np=8
	for i=1,np do
		local a=i/np
		add(pods,{
			x=x-cos(a)*24,
			y=y-sin(a)*24,
			w=8,h=8,a=a
		})
	end
	
	add(stns,{
		x=x,y=y,
		w=24,h=24,
		pods=pods
	})
end

function draw_stns()
	for s in all(stns) do
		local drx,dry=apr_pos(
			s.x,s.y,pp.x,pp.y
		)
		spr(13,drx-12,dry-12)
		spr(14,drx-4, dry-12)
		spr(15,drx+4, dry-12)
		spr(29,drx-12,dry-4)
		spr(30,drx-4, dry-4)
		spr(31,drx+4, dry-4)
		spr(45,drx-12,dry+4)
		spr(46,drx-4, dry+4)
		spr(47,drx+4, dry+4)
		
		pset(drx,dry,8)
		
		for p in all(s.pods) do
			local ddrx,ddry=apr_pos(
				p.x,p.y,pp.x,pp.y
			)
			spr(12,ddrx-4,ddry-4)
		end
		
		--[[
		spr(12,drx-4,dry-4)
		spr(13,drx+4,dry-4)
		spr(28,drx-4,dry+4)
		spr(29,drx+4,dry+4)
		]]--
	end
end

function update_stns()
	for s in all(stns) do
		for p in all(s.pods) do
			p.a=(p.a+0.005)%1
			p.x=s.x-cos(p.a)*24
			p.y=s.y-sin(p.a)*24
			
			for b in all(blts) do
				if col_bb(b,p) then
					del(blts,b)
				end
			end
			
			// consider col rocks here
		end
		
		for b in all(blts) do
			if col_bb(s,b) then
				del(blts,b)
			end
		end
	end
end

function draw_ergy()
	for e in all(ergy) do
		local drx,dry=apr_pos(
			e.x,e.y,pp.x,pp.y
		)
		pal(7,(e.t%8)+8)
		if e.t<25 or e.t%2==0 then
			spr(6,(drx-e.w/2)-1,(dry-e.h/2)-1)
		end
		pal()
	end
end

function update_ergy()
	for e in all(ergy) do
		e.x+=cos(e.a)*e.s
		e.y+=sin(e.a)*e.s
		e.s*=e.sf
		
		e.x,e.y=wrap_pos(e.x,e.y)
		e.t+=0.5
		if col_bb(e,pp) then
			del(ergy,e)
			if(pp.ergy<pp.ergy_m)pp.ergy+=1
		end
		if(e.t>40)del(ergy,e)
	end
end

function add_ergy(x,y)
	add(ergy,{
		x=x,y=y,
		a=rnd(1),s=1,
		sf=rand(90,99)/100,
		w=6,h=6,
		t=rand(1,8)
	})
end

n_roks=100
function init_roks()
	for i=0,n_roks do
		local rx=rand(-map_r,map_r)	
		local ry=rand(-map_r,map_r)
		add_rok(rx,ry,2,0)
	end
end

function draw_roks()
	for r in all(roks) do
		local drx,dry=apr_pos(
			r.x,r.y,pp.x,pp.y
		)
		if abs(drx-pp.x)<128 and
					abs(dry-pp.y)<128 then
			if r.hp==2 then
				spr(7,(drx-r.w/2),(dry-r.h/2))
			else
				spr(8,(drx-r.w/2)-2,(dry-r.h/2)-2)
			end
		end
	end
end

function update_roks()
	for r in all(roks) do
		for b in all(blts) do
			if col_bb(r,b) then
				kill_rok(r)
				del(blts,b)
			end
		end
		
		if r.hp==1 then
			r.x+=cos(r.a)*0.5
			r.y+=sin(r.a)*0.5
			
			local px,py=apr_pos(
				pp.x,pp.y,r.x,r.y
			)
			if abs(r.x-px)>128 or
					abs(r.y-py)>128 then
			del(blts,r)
			end
		end
	end
end

function kill_rok(r)
	if r.hp==2 then
		local nr=rand(4,10)
		for i=0,nr do
			add_rok(r.x,r.y,1,rnd(1))
		end
	end
	del(roks,r)
	add_spkl(r.x,r.y,4)
end

function add_rok(x,y,hp,a)
	if hp==2 then
		add(roks,{
			x=x,y=y,hp=hp,a=a,w=8,h=8
		})
	else
		add(roks,{
			x=x,y=y,hp=hp,a=a,w=4,h=4
		})
	end
end

function draw_spkl()
	for s in all(spkl) do
		local drx,dry=apr_pos(
			s.x,s.y,pp.x,pp.y
		)
		if s.c==7 then
			pal(7,(s.t%8)+8)
			pset(drx,dry,7)
			pal()
		else
			pset(drx,dry,s.c+(s.t%2))
		end
	end
end

function update_spkl()
	for s in all(spkl) do
		s.x+=cos(s.a)*1
		s.y+=sin(s.a)*1
		
		s.x,s.y=wrap_pos(s.x,s.y)
		s.t+=0.5
		if(s.t>10)del(spkl,s)
	end
end

function add_spkl(x,y,c)
	c=c or 7
	local rn=rand(20,30)
	for i=0,rn do
		add(spkl,{
			x=x,y=y,
			a=rnd(1),
			t=rand(1,8),
			c=c
		})
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
		local drx,dry=apr_pos(
			s.x,s.y,pp.x,pp.y
		)
		local sx=pp.x+(drx-pp.x)/str_dst
		local sy=pp.y+(dry-pp.y)/str_dst
		pset(sx,sy,s.c)
	end end
end

function update_strs()
	for s in all(strs) do
		//s.x
	end
end
__gfx__
00000000000770008777800000800077900000090000000000000000000440000000000000000000000000000000000000bbb300000000003300003300000000
0000000000077000066600000770677709000090000000000007700000444400000000000000000000000000000000000b333330000000333300003333000000
007007000067760005666600776677700090090000000000007007000455444000004000000000000000000000000000b0300303000003bbb300003333300000
000770008067760800577777866777600000000000077000070700700445440000054400000000000000000000000000b339933300003bbb3300003303030000
000770007667766700577777055776000000000000077000070000704444544000405000000000000000000000000000333993310003bb333300003333313000
00700700766556670566660000056678009009000000000000700700154455440001010000000000000000000000000030300301003bb3333330033303011300
0000000076500567066600000005677009000090000000000007700015501555000000000000000000000000000000000133331003bb33333330033333331130
0000000080000008877780000000870090000009000000000000000001100150000000000000000000000000000000000011110003bb33333330033333331130
0000000008000080099999000009880000000000000000000000000000000000000000000000000000000000000000000000000003b333333338833333331130
00000000090000908889999809999000000000000000000000000000000000000000000000000000000000000000000000000000333333333308803333333333
00000000995005990055550099950008000000000000000000000000000000000000000000000000000000000000000000000000000003333088880333300000
00000000995885990008800098588098000000000000000000000000000000000000000000000000000000000000000000000000000000008887788800000000
00000000995885990008800080088599000000000000000000000000000000000000000000000000000000000000000000000000000000008887788800000000
00000000985005890055550000005990000000000000000000000000000000000000000000000000000000000000000000000000000003333088880333300000
00000000980000898889999800008990000000000000000000000000000000000000000000000000000000000000000000000000333333333308803333333333
00000000080000800999990000089900000000000000000000000000000000000000000000000000000000000000000000000000033333333338833333311130
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033333333330033333311130
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033333333330033333111130
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003331333330033331111300
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000333113300003111113000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000033311300003111130000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003331300003111300000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000333300003333000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000300003000000000
00000000050000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000550000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000550000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555885550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555885550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000550000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000550000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000050000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
