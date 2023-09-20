pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- ship sim

function _init()
	printh("====== start ======")
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
end

function _draw()
	cls()
	--rect(0,cam_y,127,cam_y+128,15)
	
	draw_trip()
	draw_comps(128)
	draw_ship(256)
end


function draw_trip()
--[[
	at the bottom show control rows:
	- zoom level
	- heat signature
	- radar dist
	- some could be combined into
			one row similar to bat mode
]]--
end

function draw_comps(y)
	-- reactor
	if idx==1 then
		rectfill(4,y,30,y+4,9)
		print("<   >",32,y,7)
	elseif idx==#comps+2 then
		rectfill(4,y+120,30,y+124,9)
		print("< >",50,y+120,7)
	end
	print("reactor",4,y,7)
	local rs,rc="off",1
	if(rtr_on)rs,rc="on",7
	print(rs,36,y,rc)
	print(format(fuel_cur,5)
		,52,y,7)
	print("/",72,y,7)
	print(fuel_max,76,y,7)
		
	local r_pwr=false
	local b_pwr=false
	
	-- components from battery
	for i=#comps,4,-1 do
		local dy=i*6+y+20
		local c=comps[i]
		c:draw(dy,idx-1==i)
		
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
	comps[3]:draw(y+32,idx==4)
	if comps[3].charging then
		r_pwr=true
	end
	line(0,y+34,2,y+34,comps[3].charging and 7 or 1)
	line(0,y+34,0,y+25,r_pwr and 7 or 1)
	
	-- components from reactor
	for i=2,1,-1 do
		local dy=i*6+y+10
		local c=comps[i]
		c:draw(dy,idx-1==i)
		if(c.pwr>0)r_pwr=true
		line(0,dy+2,2,dy+2,c.pwr>0 and 7 or 1)
		line(0,dy+2,0,dy-3,r_pwr and 7 or 1)
	end
	
	-- reactor lines
	line(0,y+2,0,y+12,r_pwr and 7 or 1)
	line(0,y+2,2,y+2,r_pwr and 7 or 1)
	
	
	-- cooling system
	print("cooling",4,y+120,7)
	print("rads",34,y+120,13)
	print(rad_cur,54,y+120,7)
	print(format(cool_cur,5),70,y+120,7)
	print("/",90,y+120,7)
	print(format(cool_max,5),94,y+120,7)
	
	--print("cycle:"..cycle,0,123+y,7)
end

function draw_ship(y)
	print("ship stat",0,y,7)
end

idx,last_idx=0,0
cycle_t=0
cam_y,cam_targ=0,0
function _update()	
	if cam_y!=cam_targ then
		cam_y+=sgn(cam_targ-cam_y)*16
	end
	camera(0,cam_y)
	
	if(btnp(⬆️))idx=max(idx-1,0)
	if(btnp(⬇️))idx=min(idx+1,#comps+3)
	
	if (idx==1 and last_idx==0) or
				(idx==#comps+2 and last_idx==#comps+3) then
		cam_targ=128
	elseif idx==0 and last_idx==1 then
		cam_targ=0
	elseif idx==#comps+3 and last_idx==#comps+2 then
		cam_targ=256
	end
	
	last_idx=idx
	
	if idx==1 then
		if btnp(⬅️) then
			rtr_on=false
		elseif btnp(➡️) then
			rtr_on=true
		end
	elseif idx>1 and idx<#comps+2 then
		comps[idx-1]:update()
	elseif idx==#comps+2 then
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

cycle=0
function run_cycle()
	cycle+=1
	
	--rtr_load=0
	cool_cur=0
	cool_max=rad_cur*rad_size
	
	local r={}
	for i=1,#comps do
		add(r,i)
	end
	shuffle(r)
	for c in all(r)do
		comps[c]:run()
		comps[c]:cool()
	end
end

-- coolant
cool_max=0
cool_cur=0
rad_size=50
rad_max=4
rad_cur=2

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

-- reactor
fuel_max=10000
fuel_cur=10000
rtr_on=true
--rtr_load=0
--rtr_load_max=1000

function run_reactor(r)
	
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

--[[
function draw_load(c,y)
	print("lod",26,y,13)
	print(format(c.load,2),42,y,7)
	print("pwr",59,y,13)
	print(format(c.pwr,4),72,y,7)
end
]]--

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
	print("lod",26,y,13)
	print(format(e.load,2),42,y,7)
	print("pwr",59,y,13)
	print(format(e.pwr,4),72,y,7)
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
	print("lod",26,y,13)
	print(format(r.load,2),42,y,7)
	print("pwr",59,y,13)
	print(format(r.pwr,4),72,y,7)
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
	print("lod",26,y,13)
	print(format(s.load,2),42,y,7)
	print("pwr",59,y,13)
	print(format(s.pwr,4),72,y,7)
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



-->8


__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
