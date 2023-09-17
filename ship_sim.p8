pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- ship sim

function new_comp()
	return {
		load=0,//[0,10]
		temp=0,
		wear=0,//[0,??]
	}
end

function _init()
	comps={
		new_engine(),
		new_engine()
	}
end

function _draw()
	cls()
	
	draw_trip()
	draw_comps()
end


function draw_trip()
end

function draw_comps()
	rectfill(0,(idx-1)*6+128,100,(idx-1)*6+4+128,9)
	for i=0,#comps-1 do
		local c=comps[i+1]
		c:draw(0,i*6+128)
	end
	
	draw_cool(0,50+128)
	
	print("cycle:"..cycle,0,123+128,7)
end

idx,last_idx=1,1
cycle_t=0
cam_y=0
cam_targ=0
function _update()
--[[
	if(view==0)update_view_trip()
	if(view==1)update_view_comps()
	]]--
	
	if cam_y!=cam_targ then
		cam_y+=sgn(cam_targ-cam_y)*16
	end
	camera(0,cam_y)
	
	if(btnp(⬆️))idx=max(idx-1,0)
	if(btnp(⬇️))idx=min(idx+1,#comps)
	
	if idx==1 and last_idx==0 then
		cam_targ=128
	elseif idx==0 and last_idx==1 then
		cam_targ=0
	end 
	
	last_idx=idx
	
	if idx>0 then
		local c=comps[idx]
	
		if btnp(⬅️) then
			c.load=max(0,c.load-1)
		end
	
		if btnp(➡️) then
			c.load=min(10,c.load+1)
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
	
	for c in all(comps)do
		c:run()
	end
	
	run_cool()
end

function format(v,b)
	if(b==nil)b=99
	local s=""
	while b>v and b>10 do
		b=b/10
		if(b>v)s=s.."0"
	end
	return s..v
end
-->8
-- engines
function new_engine()
	local e=new_comp()
	e.draw=draw_engine
	e.run=run_engine
	
	-- consts
	e.name="eng"
	e.max_pwr=100
	e.t_eff=0.5
	e.t_max=flr(e.max_pwr*e.t_eff)*10
	e.t_bad=flr(e.t_max*0.5)
	e.t_min=flr(e.t_max*0.2)
	
	--vars
	e.pwr=0
	
	return e
end

function draw_engine(e,x,y)
	print(e.name.."("..e.t_eff..")",x,y,7)
	print(e.load.."("..e.pwr..")",x+35,y,7)
	print(e.temp..
		":"..e.t_min..
		"/"..e.t_bad..
		"/"..e.t_max,
		x+60,y,7)
end

function run_engine(e)
	if e.load==0 then
		e.temp=max(0,e.temp-1) //natural cooling
	else
		local p=flr((e.load/10)*e.max_pwr)
		local h=flr(p*e.t_eff)
		e.pwr=p-h
		e.temp+=h
	end
end

-- coolant
cool_max=95
cool_cur=0

function draw_cool(x,y)
	print("coolant "..cool_cur.."/"..cool_max,x,y,7)
end

function run_cool()
	--local n=cool_max
	cool_cur=0
	--[[
	might need to impliment some
	kind of flow rate here. 
	]]--
	for c in all(comps)do
		local d=max(0,c.temp-c.t_min)
		d=min(d,cool_max-cool_cur)
		cool_cur+=d
		c.temp-=d
	end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
