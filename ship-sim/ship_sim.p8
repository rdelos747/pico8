pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- ship sim
version="0.0.1"

ship_pts={
	{5,0},
	{-5,-3},
	//{-2,0},
	{-5,3}
}


function _init()
	printh("====== start ======")
	poke(0x5f5d,1)
	
	comps={
		new_engine("eng1"),
		new_engine("eng2"),
		new_battery(),
		new_radar(),
		new_shield(),
		--todo swap with real comp
		new_engine("gun1"),
		new_engine("gun2")
	}
	
	--test
	comps[3].pwr=100
	
	--local ss=rand(0,10000)
	--printh("seed: "..ss)
	srand(4733)
	stars={}
	for i=1,100 do
		local rx,ry=rand(-10000,10000),rand(-10000,10000)
		add(stars,{
			x=rx,y=ry,
			scr_x=get_on_screen(rx),
			scr_y=get_on_screen(ry),
			c=rand(0,10)==10 and 8 or rand(9,12)
		})
	end
	
	--ui
	idx,last_idx=0,0
	cam_y,cam_targ=0,0
	ui_tm=0
	
	--map
	map_srch=false
	map_conf_targ=nil
	map_x=50
	map_y=50
	zoom=1
	
	--ship
	pp_x=0
	pp_y=0
	pp_a=0.2
	pp_spd=0
	pp_flip=false
	pp_auto=false
	pp_targ=nil
	cycle_t=0
	cycle=0
	
	-- reactor
	fuel_max=10000
	fuel_cur=10000
	rtr_on=true
	
	-- coolant
	cool_max=0
	cool_cur=0
	rad_size=50
	rad_max=4
	rad_cur=2
end

function _draw()
	cls()
	--rect(0,cam_y,127,cam_y+128,15)
	
	draw_trip()
	draw_comps(128)
	draw_stat(256)
end

function get_on_screen(v)
	return flr(((v+10000)/20000)*98)+1
end

function _update()
	ui_tm+=0.1
		
	if cam_y!=cam_targ then
		cam_y+=sgn(cam_targ-cam_y)*16
	end
	camera(0,cam_y)
	
	if map_srch then
		if map_conf_targ==nil then
			if(btnp(⬆️))map_y,ui_tm=max(1,map_y-1),0
			if(btnp(⬇️))map_y,ui_tm=min(98,map_y+1),0
			if(btnp(⬅️))map_x,ui_tm=max(1,map_x-1),0
			if(btnp(➡️))map_x,ui_tm=min(98,map_x+1),0
		end
		
		if btnp2(🅾️) then
			if map_conf_targ!=nil then
				map_conf_targ=nil
			else
				map_srch,idx=false,1
			end
		end
	
		if btnp2(❎) then
			if map_conf_targ!=nil then
				pp_targ=map_conf_targ
				map_conf_targ=nil
				map_srch,idx=false,1
				pp_a=atan2(
					pp_x-pp_targ.x,
					pp_y-pp_targ.y)+0.5
				printh("dist")
				printh(dist(pp_x,pp_y,pp_targ.x,pp_targ.y))
			else
				map_conf_targ=nil
				for s in all(stars)do
					if s.scr_x==map_x and s.scr_y==map_y then
						map_conf_targ=s
					end
				end
			end
		end
	else
		if(btnp2(⬆️))idx=max(idx-1,0)
		if(btnp2(⬇️))idx=min(idx+1,#comps+7)
	end
	
	if (idx==3 and last_idx==2) or
				(idx==#comps+6 and last_idx==#comps+7) then
		cam_targ=128
	elseif idx==2 and last_idx==3 then
		cam_targ=0
	elseif idx==#comps+7 and last_idx==#comps+6 then
		cam_targ=256
	end
	
	last_idx=idx
	
	if idx==0 and 
				not map_srch and 
				btnp2(❎) then
		map_srch=true
		zoom=1
	elseif idx==1 then
	elseif idx==2 then
		if btnp(⬅️) then
			zoom=max(1,zoom-1)
		elseif btnp(➡️) then
			zoom=min(8,zoom+1)
		end
	elseif idx==3 then
		if btnp(⬅️) then
			pp_auto=false
		elseif btnp(➡️) then
			pp_auto=true
		end
	elseif idx==4 then
		if btnp(⬅️) then
			pp_flip=false
		elseif btnp(➡️) then
			pp_flip=true
		end
	elseif idx==5 then
		if btnp(⬅️) then
			rtr_on=false
		elseif btnp(➡️) then
			rtr_on=true
		end
	elseif idx>5 and idx<#comps+6 then
		comps[idx-5]:update()
	elseif idx==#comps+6 then
		if btnp(⬅️) then
			rad_cur=max(0,rad_cur-1)
		elseif btnp(➡️) then
			rad_cur=min(rad_max,rad_cur+1)
		end
	end
	
	if cycle_t>0 then
		cycle_t-=1
	else
		cycle_t=30
		run_cycle()
	end
end

function run_cycle()
	cycle+=1
	
	--rtr_load=0
	cool_cur=0
	cool_max=rad_cur*rad_size
	
	if pp_auto then
		//pp_flip=
		// for each comp calc
	end
	
	local r={}
	for i=1,#comps do
		add(r,i)
	end
	shuffle(r)
	for c in all(r)do
		comps[c]:run()
		comps[c]:cool()
	end
	
	for i=1,2 do
		pp_spd+=comps[i].pwr*0.01*(pp_flip and -1 or 1)
	end
	pp_x+=pp_spd*cos(pp_a)
	pp_y+=pp_spd*sin(pp_a)
end

function cool_comp(c)
	--[[
	might need to impliment some
	kind of flow rate here. 
	]]--
	local d=max(0,c.temp-c.t_min)
	d=min(d,cool_max-cool_cur)
	cool_cur+=d
	c.temp-=d
end

function format(v,b)
	local s=tostr(flr(v))
	local ss=""
	for i=0,b-#s-1 do
		ss=ss.."0"
	end
	return ss..s
end


function shuffle(t)
 -- fisher-yates shuffle
 for i=#t,1,-1 do
  local j=flr(rnd(i))+1
  t[i],t[j]=t[j],t[i]
 end
end

function rand(bot,top)
	return flr(rnd((top+1)-bot))+bot
end

function dist(x1,y1,x2,y2)
 local a0,b0=abs(x1-x2),abs(y1-y2)
 return max(a0,b0)*0.9609+min(a0,b0)*0.3984
end

-- btnp 2
-- sam hocevar
do
  local _ub,_b2,_b1 = _update_buttons,0,btn()
  function _update_buttons()
    _ub() _b2,_b1 = _b1,btn()
  end
  function btnp2(i)
    local b = band(btnp(),bnot(_b2))
    return not i and b or band(b,shl(1, i)) != 0
  end
end

-->8
-- draws

function draw_trip()	
	if pp_targ!=nil and zoom==1 then
		spr(1,pp_targ.scr_x-2,pp_targ.scr_y-4)
	end
	
	if map_srch and flr(ui_tm)%2==0 then
		line(map_x-1,map_y-1,map_x+1,map_y+1,9)
		line(map_x-1,map_y+1,map_x+1,map_y-1,9)
	end
	
	rect(0,0,100,100,map_srch and 9 or 7)
	
	local z=2^(8-zoom)
	
	for s in all(stars)do
		if zoom>1 then
			local sx=(s.x-pp_x)/(z)+49
			local sy=(s.y-pp_y)/(z)+49
			if sx>0 and sx<100 and
						sy>0 and sy<100 then
				circ(sx,sy,100/z,s.c)
			end
		else
			pset(s.scr_x,s.scr_y,s.c)
		end
	end
	
	for i=1,10 do
		local x=(50+i*100)/z+49
		pset(x,50,15)
	end
	
	if zoom>1 then
		draw_ship(50,50,
			pp_a+(pp_flip and 0.5 or 0),
			z)
	elseif flr(ui_tm)%2==0 then
		pset(
			get_on_screen(pp_x),
			get_on_screen(pp_y),
			15)
	end
	
	print("spd",102,0,7)
	print(flr(pp_spd),102,6,7)
	
	--zoom testing
	print("z",102,20,7)
	print(z,102,26,7)
	print("a:"..flr(20000/z),102,32,7)
	
	if idx==0	then
		if not map_srch then
			rectfill(14,46,86,52,0)
			print("press ❎ to search",15,47,9)
		elseif map_conf_targ!=nil then
			print("set target?",2,94,7)
		end
	elseif idx==1 then
		rectfill(0,116,30,120,9)
		--print("<   >",32,y,7)
	elseif idx==2 then
		rectfill(0,123,30,127,9)
		--print("< >",50,y+120,7)
	end
	
	print("view",0,116,7)
	print("zoom",0,123,7)
	print(zoom,30,123,7)
	
	if pp_targ!=nil and pp_spd!=0 then
		local d=dist(pp_x,pp_y,pp_targ.x,pp_targ.y)
		pp_steps=flr(d/abs(pp_spd))
	end
	print("step  "..pp_steps,50,102)
	
	pp_pwr_cur=0
	//local pp_steps0
	for i=1,2 do
		pp_pwr_cur+=comps[i].pwr*0.01
	end
	
	if pp_pwr_cur==0 then
		print("step0 ---",50,108)
	else
		print("step0 "..flr(pp_spd/pp_pwr_cur),50,108)
		print("pc "..pp_pwr_cur,50,114)
	end
end
pp_steps=0
pp_pwr_cur=0

function draw_comps(y)
	
	if idx==3 then
		rectfill(4,y,30,y+4,9)
		print("<   >",32,y,7)
	elseif idx==4 then
		rectfill(4,y+6,30,y+10,9)
		print("<   >",32,y+6,7)
	elseif idx==5 then
		rectfill(4,y+16,30,y+20,9)
		print("<   >",32,y+16,7)
	elseif idx==#comps+6 then
		rectfill(4,y+120,30,y+124,9)
		print("< >",50,y+120,7)
	end
	
	-- auto
	print("auto",4,y,7)
	print(
		pp_auto and "on" or "off",
		36,y,
		pp_auto and 7 or 1)
	
	-- flip
	print("flip",4,y+6,7)
	print(
		pp_flip and "on" or "off",
		36,y+6,
		pp_flip and 7 or 1)
	
	-- reactor
	print("reactor",4,y+16,7)
	print(
		rtr_on and "on" or "off",
		36,y+16,
		rtr_on and 7 or 1)
	print(format(fuel_cur,5)
		,52,y+16,7)
	print("/",72,y+16,7)
	print(fuel_max,76,y+16,7)
		
	local r_pwr=false
	local b_pwr=false
	
	-- components from battery
	for i=#comps,4,-1 do
		local dy=i*6+y+28
		local c=comps[i]
		c:draw(dy,idx-5==i)
		
		local cr1=1
		if c.pwr>0 then
			if comps[3].can_send then
				b_pwr,cr1=true,11
			else
				r_pwr,cr1=true,7
			end
		end
		
		local cr2=1
		if b_pwr then
			cr2=11
		elseif r_pwr then
			cr2=7
		end
		line(0,dy+2,2,dy+2,cr1)
		line(0,dy+2,0,dy-3,cr2)
	end
	
	-- battery
	comps[3]:draw(y+42,idx==8)
	if comps[3].charging then
		r_pwr=true
	end
	line(0,y+44,2,y+44,comps[3].charging and 7 or 1)
	line(0,y+44,0,y+35,r_pwr and 7 or 1)
	
	-- components from reactor
	for i=2,1,-1 do
		local dy=i*6+y+20
		local c=comps[i]
		c:draw(dy,idx-5==i)
		if(c.pwr>0)r_pwr=true
		line(0,dy+2,2,dy+2,c.pwr>0 and 7 or 1)
		line(0,dy+2,0,dy-3,r_pwr and 7 or 1)
	end
	
	-- reactor lines
	line(0,y+18,0,y+22,r_pwr and 7 or 1)
	line(0,y+18,2,y+18,r_pwr and 7 or 1)
	
	-- cooling system
	print("cooling",4,y+120,7)
	print("rads",34,y+120,13)
	print(rad_cur,54,y+120,7)
	print(format(cool_cur,5),70,y+120,7)
	print("/",90,y+120,7)
	print(format(cool_max,5),94,y+120,7)
	
	--print("cycle:"..cycle,0,123+y,7)
end

function draw_stat(y)
	print("ship stat",0,y,7)
	
	draw_ship(64,y+64,0.25,0.1)
	
	--version
	print("ver "..version,0,y+122,1)
end

-- general

function rot_pt(p,a)
	return p[1]*cos(a)-p[2]*sin(a),p[1]*sin(a)+p[2]*cos(a)
end

function draw_ship(x,y,a,z)
	for i=1,#ship_pts do
		local p1x,p1y=rot_pt(ship_pts[i],a)
		local p2x,p2y=rot_pt(ship_pts[(i%#ship_pts)+1],a)
		line(
			x+p1x/z,
			y+p1y/z,
			x+p2x/z,
			y+p2y/z,
			7)
	end
end
-->8
-- components

-- general
function new_comp(draw,run,update)
	return {
		cool=cool_comp,
		draw=draw,
		run=run,
		update=update,
		load=0,//[0,10]
		temp=0,
		wear=0,//[0,??]
		pwr=0
	}
end

function update_load(c)
	if btnp(⬅️) then
		c.load=max(0,c.load-1)
	end
	
	if btnp(➡️) then
		c.load=min(10,c.load+1)
	end
end

function draw_load_pwr(c,y,n)
	print("lod",26,y,13)
	local cr=1
	if c.load>8 then
		cr=8
	elseif c.load>6 then
		cr=9
	elseif c.load>2 then
		cr=11
	elseif c.load>0 then
		cr=6
	end
	print(format(c.load,2),42,y,cr)
	print(n,59,y,13)
	print(format(c.pwr,4),72,y,7)
end

function draw_temp(c,x,y)
	local lft=x+16
	local t=c.temp/c.t_max
	if t>0 then
		rectfill(lft+1,y+1,
			lft+32*t,y+3,6)
	end
	rect(lft,y,lft+34,y+4,1)
	line(lft,y,lft+34,y,8)
	line(lft,y,lft+34*(c.t_bad/c.t_max),y,9)
	line(lft,y,lft+34*(c.t_min/c.t_max),y,11)
end

function new_engine(name)
	local e=new_comp(
		draw_engine,
		run_engine,
		update_load
	)

	-- consts
	e.name=name
	e.pwr_max=100
	e.t_eff=0.5
	e.t_max=flr(e.pwr_max*e.t_eff)*10
	e.t_bad=flr(e.t_max*0.5)
	e.t_min=flr(e.t_max*0.2)
	
	return e
end

function draw_engine(e,y,actv)
	if actv then
		print("<  >",38,y,7)
		rectfill(4,y,18,y+4,9)
	end
	print(e.name,4,y,7)
	draw_load_pwr(e,y,"pwr")
	draw_temp(e,74,y)
end

function run_engine(e)
	local p=rtr_on and min(
		(e.load/10)*e.pwr_max,
		fuel_cur) or 0
	local h=p-p*e.t_eff
	
	e.pwr=p-h
	fuel_cur-=p*0.1
		
	if p==0 then
		e.temp=max(0,e.temp-1) //natural cooling
	else
		e.temp+=h	
	end
end

-- battery
function new_battery()
	local b=new_comp(
		draw_battery,
		run_battery,
		update_battery
	)

	-- consts
	b.pwr_max=1000
	b.t_eff=0.5
	b.t_max=flr(b.pwr_max*b.t_eff)*10
	b.t_bad=flr(b.t_max*0.5)
	b.t_min=flr(b.t_max*0.2)
	
	// 0:off not charging
	// 1:off charging
	// 2:on  not charging
	// 3:on  charging
	b.mode=0
	b.charge_rate=100
	b.charging=false
	b.can_send=false	
	return b
end

function draw_battery(b,y,actv)
	if actv then
		print("<       >",16,y,7)
		rectfill(4,y,14,y+4,9)
	end
	
	print("bat",4,y,7)
	local s1,cr1,cr2="off",1,7
	if(b.mode>1)s1,cr1="on",7
	if b.mode%2==0 then
		cr2=1
		line(32,y+2,46,y+2,1)
	end
	print(s1,20,y,cr1)
	print("chrg",32,y,cr2)
	print(format(b.pwr,4)..
		"/"..
		format(b.pwr_max,4),
		52,y,7)
	draw_temp(b,74,y)
end

function update_battery(b)
	if btnp(⬅️) then
		b.mode=max(0,b.mode-1)
	elseif btnp(➡️) then
		b.mode=min(3,b.mode+1)
	end
end

function run_battery(b)
	b.charging=false
	b.can_send=false
			      
	local p=0
	if rtr_on and b.mode%2!=0 then
		p=min(
					min(
						b.charge_rate,
			 		b.pwr_max-b.pwr
			 	),
		   fuel_cur
		  )
	end
	
	if(p!=0)b.charging=true
	
	local h=p-p*b.t_eff
	b.pwr+=p-h
	fuel_cur-=p*0.1
	
	if(b.pwr>0 and b.mode>1)b.can_send=true
		
	if p==0 then
		b.temp=max(0,b.temp-1) //natural cooling
	else
		b.temp+=h	
	end
end

-- radar
function new_radar()
	local r=new_comp(
		draw_radar,
		run_radar,
		update_load
	)

	-- consts
	r.pwr_max=100
	r.t_eff=0.5
	r.t_max=flr(r.pwr_max*r.t_eff)*10
	r.t_bad=flr(r.t_max*0.5)
	r.t_min=flr(r.t_max*0.2)
	
	return r
end

function draw_radar(r,y,actv)
	if actv then
		print("<  >",38,y,7)
		rectfill(4,y,18,y+4,9)
	end
	print("radar",4,y,7)
	draw_load_pwr(r,y,"rng")
	draw_temp(r,74,y)
end

function get_pwr(c)
	local p=(c.load/10)*c.pwr_max
	if comps[3].can_send then
		p=min(p,comps[3].pwr)
		comps[3].pwr-=p*0.1
	elseif rtr_on then
		p=min(p,fuel_cur)
		fuel_cur-=p*0.1
	end
	return p
end

function run_radar(r)
	local p=get_pwr(r)
	local h=p-p*r.t_eff
	r.pwr=p-h
	
	if p==0 then
		r.temp=max(0,r.temp-1) //natural cooling
	else
		r.temp+=h	
	end
end

-- shield
function new_shield()
	local s=new_comp(
		draw_shield,
		run_shield,
		update_load
	)

	-- consts
	s.pwr_max=100
	s.t_eff=0.3
	s.t_max=flr(s.pwr_max*s.t_eff)*10
	s.t_bad=flr(s.t_max*0.2)
	s.t_min=flr(s.t_max*0.1)
	
	return s
end

function draw_shield(s,y,actv)
	if actv then
		print("<  >",38,y,7)
		rectfill(4,y,18,y+4,9)
	end
	print("sheld",4,y,7)
	draw_load_pwr(s,y,"chg")
	draw_temp(s,74,y)
end

--[[
consider how shields work:
	- charge them up, they keep 
	their pwr until depleated by
	attacks.
	- power drains slowly, player
	should need to keep a little
	power there
]]--
function run_shield(s)
	local p=get_pwr(s)
	local h=p-p*s.t_eff
	s.pwr=max(0,s.pwr-1)
	s.pwr=min(
		s.pwr_max,
		s.pwr+(p-h)*0.1
	)
	
	if p==0 then
		s.temp=max(0,s.temp-1) //natural cooling
	else
		s.temp+=h	
	end
end


-->8


__gfx__
00000000777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700077700000077700000777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000007000000070700000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000077700000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777770007770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777770007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000077700007070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007000000007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
