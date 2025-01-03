pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
--[[
	todo:
	update monza:
	- right side is too long
	- chicanes arent big enough
	
	car:
	- consider making breaks less
	effective, also consider same
	for turn grip. i can still take
	turns too fast.
]]--

version="0.0.2"
mode=0

times={}

map_sz=14
sec_sz=100

secx,secy=0,0
carx,cary,carz=0,0,0
wheels={
	{-1,-6,true},	//fr
	{1,-6,true},		//fl
	{-3,3,true},
	{3,3,true}
}
ang=0.25
grip=0
wht=0 //wheel time
last_a=0

--track dimensions
--wid: 16 meters

pvt_x=64
pvt_y=100
pov_h=50 	--pov hov?
pov_d=500 --pov distance
pov_o=13  --offset (hack?)

t_wid=16 -- half track width

gears={
	{// n
		min=0,max=0,acc=0.09
	},
	{// 1
		min=0,max=55,acc=0.03
	},
	{// 2
		min=0,max=90,acc=0.02
	},
	{// 3
		min=25,max=158,acc=0.01
	},
	{// 4
		min=50,max=200,acc=0.006
	},
	{// 5
		min=50,max=250,acc=0.004
	},
	{// 5
		min=100,max=300,acc=0.002
	}
}
break_s=0.8
turn_amt=0.05
turn_mod=0.007

uitf=0 --ui time fast

gt=nil --current ground tri

function _init()
	printh("=====start=====")
end

function _draw()
	cls()
	
	if mode==0 then
		draw_title()
	elseif mode==1 then
		draw_track_select()
	elseif mode==2 then
	
		draw_pov()
		draw_hud()
		if time_alert_t>0 then
			draw_time_alert()
		end
	end
	--[[
	if carx and cary then
	print(carx,camx+100,camy+1,8)
	print(cary,camx+100,camy+7,8)
	end
	]]--
	print(last_a,camx+100,camy+1,8)
	print(abs(last_a-ang),camx+100,camy+7,8)
end

function _update()
	uitf=(uitf+0.5)%30
	
	if mode==0 then
		update_title()
	elseif mode==1 then
		update_track_select()
	elseif mode==2 then
	
		if time_alert_t>0 then
			time_alert_t-=1
		end
	
		update_car()
	
		secx,secy=flr(carx/sec_sz),flr(cary/sec_sz)
	end
end

function reset_car()
	ang=car_sa
	carx=car_sx
	cary=car_sy
	
	start_time=nil
	sec1_time=nil
	sec2_time=nil
	//last_time=nil
	best_time=nil
	//times={}
	
	gear=1
	rpm=0
	spd=0
	turn=0

	last_flag=nil
end
-->8
-- pov

camx,camy=0,0
function draw_pov()
	camx=flr(carx-pvt_x)
	camy=flr(cary-pvt_y)
	camera(camx,camy)
	
	rectfill(
		camx,camy+64,
		camx+127,camy+127,3)
		
	local povx=flr(secx+2*cos(ang+0.0))
	local povy=flr(secy+2*sin(ang+0.0))
		
	for i=max(-map_sz,povx-3),min(map_sz,povx+3)do
	for j=max(-map_sz,povy-3),min(map_sz,povy+3)do
	
		//draw_tris(g_tris[i][j],15)
		draw_road_tris(r_tris[i][j])
		draw_road_tris(a_tris[i][j])
		draw_road_tris(c_tris[i][j])
		
		//draw_tris(c_tris[i][j],12)
	end end
	
	for o in all(objs)do
		draw_obj(o)
	end
	
	for k,v in pairs(sects)do
		draw_obj(v)
	end
		
	--[[
	currently based on the pov
	constants, the pov scale
	is about 5 times
	]]--
	
	palt(0,false)
	palt(4,true)
	
	local tl=turn<0
	if turn==0 then
		spr(7,carx-22,cary-13)
		spr(7,carx+14,cary-13,1,1,1)
	elseif abs(turn)<0.5 then
		spr(tl and 12 or 44,
			carx-22,cary-13)
		spr(tl and 44 or 12,carx+14,cary-13,1,1,1)
	else
		spr(tl and 28 or 60,carx-22,cary-13)
		spr(tl and 60 or 28,carx+14,cary-13,1,1,1)
	end

	sspr(8,0,19,32,carx-18,cary-24)
	sspr(8,0,19,32,carx,cary-24,19,32,1)
	
	for i=0,1 do
		spr(36+i*16+wht,carx-26,cary-8+8*i)
		spr(36+i*16+wht,carx+19,cary-8+8*i,1,1,1)
	end
	pal()
	
	pset(carx,cary,11)
	
	--wheels
	for i=1,2 do
		local wx=wheels[i][1]
		local wy=wheels[i][2]
		local wt=wheels[i][3]
		local cwx=carx-wx-pov_o*sgn(wx)
		local cwy=cary+wy
		//rect(cwx,cwy,
		//	cwx-4*sgn(wx),cwy-8,
		//	wt and 6 or 9)
		pset(cwx,cwy,11)
	end
	
	for i=3,4 do
		local wx=wheels[i][1]
		local wy=wheels[i][2]
		local wt=wheels[i][3]
		local cwx=carx-wx-pov_o*sgn(wx)
		local cwy=cary+wy
		//rect(cwx,cwy,
		//	cwx-7*sgn(wx),cwy-10,
		//	wt and 6 or 9)
		pset(cwx,cwy,11)
		//spr(1,cwx-7*sgn(wx),cwy)
	end
	--[[
	for j=0,3 do
		for i=-2,2 do
			spr(35-i,carx-3+i*8,cary)
		end
	end
	]]--
	
	if abs(last_a-ang) >0.3 then
	spr(65,camx+56,camy+56)
	spr(65,camx+64,camy+56,1,1,true)
	spr(65,camx+56,camy+64,1,1,false,true)
	spr(65,camx+64,camy+64,1,1,true,true)
	end
	
end

function draw_segs(v,c_d)
	pset(camx,camy,12)
	local c=0
	for i=1,#v-2 do
		local p=v[i]		
		local px,py,t,ry=pov(p[1],p[2])
		
		local p2=v[i+1]
		local p2x,p2y=pov(p2[1],p2[2])

		line(px,py,p2x,p2y,
			t and 9 or 7+c%2)
		if t then
			print(ry,
				max(camx,px),
				min(camy+120,py),
				13+c%2)
		end
		c+=1
	end
end

function draw_obj(o)
	for t in all(o.tris)do
		draw_tri(t,o.col)
	end
end

function draw_road_tris(arr)
	for t in all(arr) do
		draw_tri(t,t[6])
	end
end

function draw_tri(t,c)
	local p1x,p1y,p1d=pov(t[1][1],t[1][2],t[1][3])
	local p2x,p2y,p2d=pov(t[2][1],t[2][2],t[2][3])
	local p3x,p3y,p3d=pov(t[3][1],t[3][2],t[3][3])
		
	if p1d>-13 or p2d>-13 or p3d>-13 then
	//if p1d>0 or p2d>0 or p3d>0 then	
		pelogen_tri(
			p1x,p1y,
			p2x,p2y,
			p3x,p3y,
			c)
	end
end

function pov(x,y,z)
	if(z==nil)z=0
	
	local dx=x-carx
	local dy=y-cary
	
	local rx,ry=rot(
		dx,-dy,-ang+0.75)	
	
	local de=max(0.1,ry+pov_o)
	--[[
	local povy
	
	if z>0 then
		povy=min(
			pov_d/(de),
		128
	)
	else
		povy=max(
			-pov_d/(de),
			-129-z
		)
	end
	]]--
	povy=pov_d/de
	povy=-pvt_y+(pvt_y-64)-povy
	povy+=(z-carz)*(20/de)
	povy=mid(-128,povy,128)
	
	local povx=rx*min(60/de,7.5)
	povx-=pvt_x
	
	return camx-povx,camy-povy,ry//,true,rx
	--[[
	return ry along with the rest
	of the values. use the ry vals
	to sort triangles by distance,
	and render them based on distance.
		
		also see if we can use this to
		determine the car's height off
		of the ground basedon what 
		triangle it is touching
	]]--
end

function rot(x,y,a)
	local rx=x*cos(a)+y*sin(a)
	local ry=x*sin(a)-y*cos(a)
	return rx,ry
end

function dist(x1,y1,x2,y2)
 local a0,b0=abs(x1-x2),abs(y1-y2)
 return max(a0,b0)*0.9609+min(a0,b0)*0.3984
end

--[[
function draw_top_down()		
	local a=-ang+0.75
	
	for i=max(-10,secx-1),min(10,secx+1)do
	for j=max(-10,secy-1),min(10,secy+1)do
		for t in all(tris[i][j]) do
			for i=1,3 do
				local cur=t[i]
				local nxt=t[i%3+1]
							
				local cx,cy=rot(
					cur[1]-carx,
					-(cur[2]-cary),
					a)
				local nx,ny=rot(
					nxt[1]-carx,
					-(nxt[2]-cary),
					a)
				line(
					camx-cx+64,
					camy-cy+64,
					camx-nx+64,
					camy-ny+64,
					t[5] and 7 or 5)
			end
		end
	end end
	
	--wheels
	for i=1,2 do
		local wx=wheels[i][1]
		local wy=wheels[i][2]
		local wt=wheels[i][3]
		local cwx=camx+wx
		local cwy=camy+wy
		pset(cwx+64,cwy+64,11)
	end
	
	for i=3,4 do
		local wx=wheels[i][1]
		local wy=wheels[i][2]
		local wt=wheels[i][3]
		local cwx=camx+wx
		local cwy=camy+wy
		pset(cwx+64,cwy+64,11)
	end
end
]]--

function draw_map()
	rectfill(camx,camy,
		camx+40,camy+40,0)
	rect(camx,camy,
		camx+40,camy+40,7)
		
	for i=1,#pts_base do
		local cur=pts_base[i]
		local nxt=pts_base[i%#pts_base+1]
			
		local cx,cy=cur[1],cur[2]
		local nx,ny=nxt[1],nxt[2]
		line(
			camx+((cx+500)/1000)*28,
			camy+((cy+500)/1000)*28,
			camx+((nx+500)/1000)*28,
			camy+((ny+500)/1000)*28,
			14)
	end
	
	for t in all(tris) do
			for i=1,3 do
				local cur=t[i]
				local nxt=t[i%3+1]
			
				local cx,cy=cur[1],cur[2]
				local nx,ny=nxt[1],nxt[2]
				if t[5] then
					line(
						camx+((cx+500)/1000)*28,
						camy+((cy+500)/1000)*28,
						camx+((nx+500)/1000)*28,
						camy+((ny+500)/1000)*28,
						10)
				end
					
				--[[
				cx,cy=rot(cur[1],cur[2])
				nx,ny=rot(nxt[1],nxt[2])
				line(cx,cy,nx,ny,t[5]and 11or 1)
			]]--
			end
		//end
	end
end

--trifill
function pelogen_tri(l,t,c,m,r,b,col,f)
	color(col)
	fillp(f)
	if(t>m) l,t,c,m=c,m,l,t
	if(t>b) l,t,r,b=r,b,l,t
	if(m>b) c,m,r,b=r,b,c,m
	local i,j,k,r=(c-l)/(m-t),(r-l)/(b-t),(r-c)/(b-m),l
	while t~=b do
		--[[
		not sure why the flr(..,512)
		was necessary. for tracks where
		y values are greater it was
		causing issues. i raised it
		to 1024, but if its not an 
		issue i should maybe just make
		it uncapped???
		]]--
		for t=ceil(t),min(flr(m),1024) do
			rectfill(l,t,r,t)
			r+=j
			l+=i
		end
		l,t,m,i=c,m,b,k
	end
end

-->8
-- car

function update_car()
	if btnp(❎) then
		gear=min(gear+1,#gears)
	elseif btnp(🅾️) then
		gear=max(gear-1,1)
	end
	
	local g=gears[gear]
	
	if gear>1 then
		rpm=(spd-g.min)/(g.max-g.min)
	end
	
	--[[
	todo:
	play some gt7 and observe
	how a manual car in gear
	decelerates (without breaking),
	as this might affect the
	calculation.
	
	also see what happens when
	you break in a high gear but
	dont downshift
	]]--
	if btn(⬆️) then
		rpm=min(rpm+g.acc,1)
		//spd+=
		//acc=
		
		if gear>1 then
			//hack but w/e
			spd=max(spd,1)
		end
	else
	//	rpm-=
		rpm=max(rpm-g.acc,0)
	end
	
	if spd>g.min and spd<=g.max then
		spd=(g.max-g.min)*rpm+g.min
	else
		spd=max(0,spd-1)
	end
	
	--breaking
	local breaking=false
	if btn(⬇️) then
		spd=max(0,spd-break_s)
		breaking=true
	end
	
	--bad shifts
	if rpm>1 then
		printh("money shift")
		rpm=1
		--[[
		todo: punishment for money
		shifting
		if the money shift is over
		some percent...
		else, just let it happen
		]]--
	elseif rpm<0 and gear>1 then
		//printh("stall")
		rpm=0
	end
		
	--turning
	if spd>150 then
		//tamt=0.1
	end
	if btn(⬅️) then
		turn=max(-1,turn-turn_amt)
	elseif btn(➡️) then
		turn=min(1,turn+turn_amt)
	elseif turn<0 then
		turn=min(0,turn+turn_amt)
	elseif turn>0 then
		turn=max(0,turn-turn_amt)
	end
	
	turn_actual=turn
	grip=min(1,1-((spd-80)/300))
	//dftx,dfty=0,0
	
	//on_ground=true
	local touch_flag=nil
	for i=1,#wheels do
		local w=wheels[i]
		w[3]=true

		local rx,ry=rot(
			w[1],w[2],ang+0.25)
		
		local tri=on_track(carx+rx,cary+ry,r_tris)
		if not tri then
			grip=max(0,grip-0.15)
			w[3]=false
			if spd>50 then
				spd-=1
			end
		end
		
		local wsx=flr((carx+rx)/sec_sz)
		local wsy=flr((cary+ry)/sec_sz)
		
		for k,v in pairs(sects)do
			if wsx==v.sex and wsy==v.sey then
				for t in all(v.tris) do
					if pt_in_tri(carx+rx,cary+ry,t) then
						touch_flag=v.name
					end
				end
			end
		end
	end
	
	if touch_flag=="start" and
				last_flag!="start" then
		printh("here")
		if start_time!=nil then
			lap_time=time()-start_time
			local at={
				lap_time,
				sec1_time,
				sec2_time
			}
			add(times,at)
			set_time_alert(
				lap_time,
				best_time and lap_time-best_time[1] or nil
			)
			if best_time==nil or 
						lap_time<best_time[1] then
				best_time=at
			end
		end
		start_time=time()
	elseif touch_flag=="sec1" and
								last_flag!="sec1" then
		if start_time then
		sec1_time=time()-start_time
		set_time_alert(
			sec1_time,
			(best_time and best_time[2]) and 
			sec1_time-best_time[2] or nil
		)
		end
	elseif touch_flag=="sec2" and
								last_flag!="sec2" then
		if start_time then
		sec2_time=time()-start_time
		set_time_alert(
			sec2_time,
			(best_time and best_time[3]) and 
			sec2_time-best_time[3] or nil
		)
		end
	end
	
	if touch_flag!=nil then
		last_flag=touch_flag
	end
	
	--[[
	ok so this is feeling alright.
	it might still be necessary
	to keep track of two angles:
	- velocity angle
	- vehicle point angle
	
	with the point angle, we can
	do stuff like spinning out etc..
	]]--
	if abs(turn)>grip then
		//add(skids,{px,py})
		//turn_actual=0
		//dftx=cos(ang+0.0*abs(turn_actual)*sgn(turn))*1
		//dfty=sin(ang+0.0*abs(turn_actual)*sgn(turn))*1
		turn_actual=grip*sgn(turn)
		
		if breaking then
			//turn_actual=0
			//dftx=cos(ang+0.0*abs(turn)*sgn(turn))*1
			//dfty=sin(ang+0.0*abs(turn)*sgn(turn))*1
		else	
		end
	end

	if spd>0 then
		ang=(ang-turn_actual*turn_mod)%1
	end
	
	//1 k/h ~= 0.278 m/s
	local fx=cos(ang)*spd*0.278/30
	local fy=sin(ang)*spd*0.278/30
	
	//lastx=carx
	//lasty=cary
	
	
	
	gt=on_track(carx+fx,cary+fy,g_tris) 
	if gt then
		carx+=fx//+dftx
		cary+=fy//+dfty
		last_a=gt[5]
	else
		spd=max(0,spd-1)
	end
	
	--calculate z
	if gt then
		local pmin,zmin=nil,10000
		local pmax,zmax=nil,-10000
		for i=1,3 do
			if gt[i][3]<zmin then
				zmin=gt[i][3]
				pmin=gt[i]
			end
			if gt[i][3]>zmax then
				zmax=gt[i][3]
				pmax=gt[i]
			end
		end
	
		local _,ry_max=rot(
			pmax[1]-carx,
			-(pmax[2]-cary),
			-ang+0.75)
	
		local _,ry_min=rot(
			pmin[1]-carx,
			-(pmin[2]-cary),
			-ang+0.75)
	
		cdst=abs(ry_max-ry_min)
	
		carz=(zmax-zmin)*((cdst-abs(ry_max))/cdst)
		carz+=zmin
	end
			
	local off=flr(rpm*72)*1
	local cut=4
	if rpm==1 and gear<4 then
		cut=4
	end
	sfx(flr(off/30),   0, off%30,cut)
	sfx(flr(off/30)+3, 1, off%30,cut)

	wht=(wht+(spd/100))%8
end
-->8
-- hud

function draw_hud()
	--tach
	local x,y=camx+20,camy+115
	circfill(x,y,15,0)
	circ(x,y,15,rpm==1 and 8 or rpm>0.85 and flr(uitf)%2==0 and 8 or 7)
	local a=rpm*0.8+0.3
	line(x+cos(a)*4,y+sin(-a)*4,
		x+cos(a)*12,y+sin(-a)*12,7)
	
	print(gear>1 and gear-1 or "n",x,y,7)
	
	--speed
	x,y=camx+108,camy+115
	circfill(x,y,15,0)
	circ(x,y,15,6)
	a=spd/gears[#gears].max*0.8+0.3
	line(x+cos(a)*4,y+sin(-a)*4,
		x+cos(a)*12,y+sin(-a)*12,7)
	print(spd,x,y,7)
	
	--turn
	rect(camx+44,camy+113,
		camx+84,camy+117,0)
		
	x=camx+64+20*turn
	line(x,camy+113,x,camy+117,7)
	print(turn,camx+60,camy+120)
	
	x=camx+64+20*grip
	line(x,camy+113,x,camy+117,13)
	x=camx+64-20*grip
	line(x,camy+113,x,camy+117,13)
	
	--time
	if start_time!=nil then
		print(ftime(time()-start_time),
		camx+50,camy+1,7)
	else
		print("---.--",camx+50,camy+1,7)
	end
	
	if best_time==nil then
		print("bt:---.--",camx,camy+1,13)
	else
		print("bt:"..ftime(best_time[1]),
		camx,camy+1,14)
	end

	for i=0,5 do
		local s="---.--"
		if #times-i>0 then
			s=times[#times-i][1]
		end
		print("p"..(i+1)..":"..ftime(s),
				camx,camy+7+i*6,13)
	end
end

time_alert_t=0
time_alert={}
function set_time_alert(t,d)
	time_alert_t=60
	if d then
		time_alert={
			t,
			d<0 and d or "+"..d,
			d<0 and 12 or 8
		}
	else
		time_alert={t}
	end
end

function draw_time_alert()
	if time_alert[2] then
		print(time_alert[1],
			camx+38,camy+50,7)
		print(time_alert[2],
			camx+67,camy+50,
			time_alert[3])
	else
		print(time_alert[1],
			camx+52,camy+50,7)
	end
end

function ftime(t)
	if type(t)!="number" then
		return t
	end
	local mins=flr(t/60)
	local s=""
	if mins>0 then
		s=s..mins..":"
	end
	return s..t%60
end
-->8
-- track

pts_base={
	{
		{-100,100,0,"car"},
		{-100,0,30,"start"},// start
		{-100,-100,30},//start chicane
		{0,-100,30},
		{0,-200,0},
		{40,-240,0},
		{150,-240,0,"sec1"},
		{400,-210,0},
		{400,200,0},
		{370,300,-20},
		{300,300,-20,"sec2"},
		{270,270,-20},
		{270,200,-20},
		{230,170,0},
		{200,170,0}
	},
	{
	{1350,-317,0},
{1447,-305,0},
{1493,-271,0},
{1538,-206,0},
{1538,-152,0},
{1498,-103,0},
{1351,-38,0},
{1161,4,0},
{1002,22,0,"car"},
{727,33,0,"start"},
{540,30,0},
{-223,30,0},
{-242,11,0},
{-242,-23,0},
{-248,-60,0},
{-284,-60,0},
{-322,-31,0},
{-374,1,0},
{-443,29,0},
{-510,29,0},
{-629,12,0},
{-749,-84,0},
{-784,-199,0},
{-831,-492,0,"sec1"},
{-841,-581,0},
{-849,-691,0},
{-865,-705,0},
{-923,-705,0},
{-951,-736,0},
{-991,-837,0},
{-1037,-942,0},
{-1095,-1066,0},
{-1097,-1104,0},
{-1079,-1138,0},
{-1021,-1182,0},
{-742,-1248,0},
{-708,-1252,0},
{-682,-1220,0},
{-485,-872,0},
{-203,-551,0,"sec2"},
{-76,-413,0},
{-33,-388,0},
{54,-406,0},
{99,-403,0},
{159,-365,0},
{198,-320,0},
{277,-315,0},
	}
}


--[[
pts_base={
	{-100,-100},
	{100,-100},
	{100,100},
	{-100,100}
}
]]--

--[[
segment and outer list params:
1: x
2: y
3: flag (start, bend, etc)
4: color
]]--

function create_track(idx)
	printh("==create track "..idx.."==")
	
	objs=clear(objs)
	pt_segs=clear(pt_segs)
	apexs_r=clear(apexs_r)
	crnrs_r=clear(crnrs_r)
	r_tris=clear(r_tris)
	g_tris=clear(g_tris)
	a_tris=clear(a_tris)
	c_tris=clear(c_tris)

	sects={
		start={},
		sec1={},
		sec2={}
	}
	car_sx=-1
	car_sy=-1
	car_sa=-1
	
	minx=30000
	miny=30000
	maxx=-30000
	maxy=-30000
	widx=0
	widy=0
	
	track=pts_base[idx]
	
	mis=30000
	mas=-30000
	
	for p in all(track)do
		minx=min(minx,p[1])
		miny=min(miny,p[2])
		maxx=max(maxx,p[1])
		maxy=max(maxy,p[2])
	end
	
	twid=abs(maxx-minx)
	thgt=abs(maxy-miny)
	for p in all(track)do
		p[1]-=minx+flr(twid/2)
		p[2]-=miny+flr(thgt/2)
	end
	
	pt_segs=create_segs(
		track,false,30)
		
	apexs_r=create_outer(
		pt_segs,0.75,t_wid,"road")
	crnrs_r=create_outer(
		pt_segs,0.25,t_wid,"road")
	r_tris=create_tris(
		pt_segs,
		crnrs_r,
		apexs_r)
		
	//printh(mis.." "..mas)
		
	local apexs_g=create_outer(
		pt_segs,0.75,t_wid*2,"grnd")
	local crnrs_g=create_outer(
		pt_segs,0.25,t_wid*2,"grnd")
	g_tris=create_tris(
		pt_segs,
		crnrs_g,
		apexs_g)
	
	local apexs_1=create_outer(
		pt_segs,0.75,t_wid-1,"side")
	local apexs_2=create_outer(
		pt_segs,0.75,t_wid+1,"side")
	--[[
	local apex_segs_1=create_segs(
		apexs_1,false)
	local apex_segs_2=create_segs(
		apexs_2,false)
	]]--
	a_tris=create_tris(
		apexs_1,
		apexs_1,
		apexs_2)
		
	local crnrs_1=create_outer(
		pt_segs,0.25,t_wid-1,"side")
	local crnrs_2=create_outer(
		pt_segs,0.25,t_wid+1,"side")
	--[[
	local crnr_segs_1=create_segs(
		crnrs_1,false)
	local crnr_segs_2=create_segs(
		crnrs_2,false)
	]]--
	c_tris=create_tris(
		crnrs_1,
		crnrs_1,
		crnrs_2)
	
	for k,v in pairs(sects)do
		create_sect_obj(k,v)
	end
	
	printh("done")
end

function create_segs(pts,is_map,v)
	printh("creating segs")
	if(v==nil)v=10
	
	local out={}
	if is_map then
		out=create_map()
	end
	
	local c=1
	for i=1,#pts do
		local cur=pts[i]
		local nxt=pts[i%#pts+1]
		
		local cx,cy,cz=cur[1],cur[2],cur[3]
		local nx,ny=nxt[1],nxt[2]
		
		local sex=flr(cx/sec_sz)
		local sey=flr(cy/sec_sz)
		
		local a=atan2(nx-cx,ny-cy)
		
		local flag_c=cur[4]
		local flag_n=nxt[4]
		
		--[[
		this is a hack but whatever
		]]--
		if flag_c=="car" then
			car_sx=cx
			car_sy=cy
			car_sa=a
		elseif sects[flag_c] then
			//printh(flag.." at: "..cx.." "..cy.." "..a)
			sects[flag_c]={
				x=cx,y=cy,z=cz,a=a,
				sex=flr(cx/sec_sz),sey=flr(cy/sec_sz)
			}
		end
		
		local o={cx,cy,cz}
		if is_map then
			add(out[sex][sey],o)
		else
			add(out,o)
		end
		c*=-1
		
		local px,py=cx,cy
		local go=true
		while go do
			local d=dist(px,py,nx,ny)
			if d>v then
				px+=v*cos(a)
				py+=v*sin(a)

				local o2={px,py,cz}
				if is_map then
					add(out[sex][sey],o2)
				else
					add(out,o2)
				end
			else
				go=false
			end
		end
	end
	
	return out
end

function create_outer(pts,v,wid,typ)
	printh("create outer: "..typ)
	local out={}
	local last_a=nil
	local c=true
	for i=1,#pts do
	
		local prv=pts[i==1 and #pts or i-1]
		local cur=pts[i]
		local nxt=pts[i%#pts+1]
			
		local px,py=prv[1],prv[2]
		local cx,cy,cz=cur[1],cur[2],cur[3]
		local nx,ny=nxt[1],nxt[2]
		
		local a=atan2(nx-px,ny-py)
		local dff=0
		if last_a!=nil then
			dff=abs(a-last_a)
		end
		last_a=a
		
		local col=1
		if typ=="side" then
			if dff>0.01 then
				c=not c 
				col=c and 8 or 7
			else
				col=5
			end
		end
		
		local amtx=abs(wid/cos(a+v))
		local amty=abs(wid/sin(a+v))
		//printh(cur[4])
		add(out,{
			flr(cx+cos(a+v)*amtx),
			flr(cy+sin(a+v)*amty),
			cz,
			a,
			col
		})
	end
	return out
end

function create_tris(pts,crnr,apex)
	printh("creating tri")
	out=create_map()
	
	for i=1,#crnr do
		local cur_c=crnr[i]
		local cur_p=apex[i]
		local nxt_c=crnr[i%#crnr+1]
		local nxt_p=apex[i%#apex+1]
		local pt=pts[i]
		
		local cx=flr(pt[1]/sec_sz)
		local cy=flr(pt[2]/sec_sz)
		
		mis=min(mis,cx)
		mis=min(mis,cy)
		mas=max(mas,cx)
		mas=max(mas,cy)
		add(out[cx][cy],{
			{cur_c[1],cur_c[2],cur_c[3]},
			{nxt_c[1],nxt_c[2],nxt_c[3]},
			{cur_p[1],cur_p[2],cur_p[3]},
			{pt[1],pt[2]},//center
			cur_c[4], //angle
			cur_c[5] //color
		})
		add(out[cx][cy],{
			{nxt_c[1],nxt_c[2],nxt_c[3]},
			{nxt_p[1],nxt_p[2],nxt_p[3]},
			{cur_p[1],cur_p[2],cur_p[3]},
			{pt[1],pt[2]},//center
			cur_c[4], //angle
			cur_c[5] //color
		})
	end
	return out
end

function create_sect_obj(name,t)		
	local plx=t.x+cos(t.a+0.25)*30
	local ply=t.y+sin(t.a+0.25)*30
	local prx=t.x+cos(t.a+0.75)*30
	local pry=t.y+sin(t.a+0.75)*30
	
	local plx2=plx+cos(t.a)*10
	local ply2=ply+sgn(t.a)*10
	local prx2=prx+cos(t.a)*10
	local pry2=pry+sgn(t.a)*10
	
	local o={
		tris={
			{
				{plx,ply,t.z+50},
				{plx,ply,t.z+70},
				{prx,pry,t.z+50}
			},
			{
				{plx,ply,t.z+70},
				{prx,pry,t.z+50},
				{prx,pry,t.z+70}
			},
		},
		col=12
	}
	add(objs,o)
	
	t.tris={
		{
		 {plx,ply,t.z+0},
		 {plx2,ply2,t.z+0},
		 {prx2,pry2,t.z+0}
		},
		{
			{plx,ply,t.z+0},
			{prx2,pry2,t.z+0},
			{prx,pry,t.z+0}
		}
	}
	t.col=10
	t.name=name
end

function create_map()
	local out={}
	for i=-map_sz,map_sz do
		local row={}
		for j=-map_sz,map_sz do
			row[j]={}
		end
		out[i]=row
	end
	return out
end

function on_track(x,y,arr)
	//local found=false
	local cx=flr(x/sec_sz)
	local cy=flr(y/sec_sz)
	for i=max(-map_sz,cx-1),min(map_sz,cx+1)do
	for j=max(-map_sz,cy-1),min(map_sz,cy+1)do
	for t in all(arr[i][j])do
		--[[
		local close=false
		for i=1,4 do
			if dist(carx,cary,
							t[i][1],t[i][2])
						<250 then
				close=true
			end
		end
		]]--
		if pt_in_tri(x,y,t) then
			//t[5]=true //debug
			return t
		end
	end
	end end
	return nil
end


function pt_in_tri(x,y,tr)
	local p0x,p0y=tr[1][1],tr[1][2]
	local p1x,p1y=tr[2][1],tr[2][2]
	local p2x,p2y=tr[3][1],tr[3][2]
	
	local dx=x-p2x
	local dy=y-p2y
	local dx21=p2x-p1x
	local dy12=p1y-p2y
	local d=dy12*(p0x-p2x)+dx21*(p0y-p2y)
	local s=dy12*dx+dx21*dy
	local t=(p2y-p0y)*dx+(p0x-p2x)*dy
	if d<0 then
		return s<=0 and t<=0 and s+t>=d
	end
	
	return s>=0 and t>=0 and s+t<=d
end

function clear(arr)
	if arry and #arr>0 then
		for o in all(arr)do
			if type(o)=="table" then
				clear(o)
			end
			del(arr,o)
		end
	end
	
	return {}
end
-->8
-- title

function draw_title()
	print("pico f1 time trial",1,1,7)
	print("ver: "..version,1,7,7)
	
	print("⬅️/➡️: turn",1,21,7)
	print("⬆️   : accel",1,27,7)
	print("⬇️   : break",1,33,7)
	print("❎   : up shift",1,39,7)
	print("🅾️   : down shift",1,45,7)

	print("press ❎ to start",1,67,7)
end

function update_title()
	if btnp(❎) then
		mode=1
	end
end

function draw_track_select()
	rectfill(0,0,127,127,9)
	
	if apexs_r and crnrs_r then
		draw_track_outer(apexs_r)
		draw_track_outer(crnrs_r)
		
		for i=1,10 do
			local idx=mid(1,flr(ut_tm)-i,#track)
			local cur=track[idx]
			local x,y=tp_at_scale(cur)
			pset(x+60,y+60,11)
		end
	end
	
	print("select track",5,5,0)
	line(5,11,122,11,0)
	
	rectfill(
		9,19+ut_idx*7,
		9+ut_tm2,25+ut_idx*7,0)
	pal(7,0)
	spr(64,3,20+ut_idx*7)
	pal()
	
	for i=0,5 do
		print("track 1",
			ut_idx==i and 10 or 5,
			20+i*7,
			ut_idx==i and 7 or 0)
	end
	
	print("press ❎ to continue",5,120,0)
	line(5,118,122,118,0)
end

function draw_track_outer(arr)
	for i=1,#arr do
			local cur=arr[i]
			local nxt=arr[i%#arr+1]
			local x1,y1=tp_at_scale(cur)
			local x2,y2=tp_at_scale(nxt)
			
			line(
				x1+60,y1+60,
				x2+60,y2+60,7)
		end
end

function tp_at_scale(pt)
	local m=max(twid,thgt)
	local x=((pt[1])/m)*80
	local y=((pt[2])/m)*80
	return x,y
end

ut_idx=-1
ut_tm=1
ut_tm2=0
function update_track_select()
	if btnp(❎) then
		mode=2
		//create_track()
		reset_car()
		menuitem(1,"reset car",reset_car)
	end
	
	local l_ut_idx=ut_idx
	if btnp(⬆️) then
		ut_idx-=1
	elseif btnp(⬇️) then
		ut_idx+=1
	end
	ut_idx=mid(0,ut_idx,5)
	
	if l_ut_idx!=ut_idx then
		create_track(ut_idx+1)
		ut_tm=1
		ut_tm2=1
	end
	
	ut_tm2=min(ut_tm2+7,50)
	
	if apexs_r then
		ut_tm=(ut_tm+1)%(#apexs_r+20)
	end
end
__gfx__
00000000444444444444444444444444000000000000000000000011400000004000000444000004440000004440000040000004000000000000000000000000
00000000444444444444444444444444000000000000000000000011000000000000000040000000400000004400000000000000000000000000000000000000
00700700444444444444444444444444000000000000000000000011000000000000000040000000400000004400000000000000000000000000000000000000
00077000444444444444444444444444000000000000000000000011000000000010000040010000400000004400000000100000000000000000000000000000
00077000444444444444444444444444000000000000000000000011000000000010000040010000400000004400000000100000000000000000000000000000
00700700444444444444444444444444000000000000000000000011000000000010000040010000400000004400000000100000000000000000000000000000
00000000444444444444444444444444000000000000000000000011000000000010000040010000400000004400000000100000000000000000000000000000
0000000044440ddddddddddd44444444000000000000000000000011000000000010000040010000400000004400000000100000000000000000000000000000
4444444444440dddddddddddddd44444000000000000000000000000111111110000000000000000000000000000000044000004000000000000000000000000
4444444444440dddddddddddddd44444000000000000000000000000111111110000000000000000000000000000000040000000000000000000000000000000
44444444444405555555555555544444000000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000
4444444444440dddddddddddddd44444000000000000000000000000000000000000000000000000000000000000000040010000000000000000000000000000
4444444444440dddddddddddddd44444000000000000000000000000000000000000000000000000000000000000000040010000000000000000000000000000
44444444444404444444776777744444000000000000000000000000000000000000000000000000000000000000000040010000000000000000000000000000
44444444444404777766776777744444000000000000000000000000000000000000000000000000000000000000000040010000000000000000000000000000
44444444444470776677767777744444000000000000000000000000000000000000000000000000000000000000000040010000000000000000000000000000
40000000004770777777677777744444400000004000000040000000400000004000000040000000400000004000000044000000000000000000000000000000
000100000dd777077777777700044444000000000000000100010000000100000000000000000001000000000000000040000000000000000000000000000000
001000000dd775055700000000044444000000000000000000100000000000000000000000000010000000000000000040000000000000000000000000000000
001000000dd757077555550005044444000000000000000000100000000000000000001000000010000000000000000040000000000000000000000000000000
001000000d5577077000005550544444000000000010000000100000000000000000001000000000000000000000000040000000000000000000000000000000
001000000dd757075555555500544444000000000010000000000000000000000000001000000000000000000000000040000000000000000000000000000000
001000000d5555555555555500544444000000000010000000000000000000000000001000000000000000000000000040000000000000000000000000000000
001000000dd755550000000000044444001000000010000000000000000000100000000000000000000000000000000040000000000000000000000000000000
001000000d555000dd5dd5dddd544444001000000010000000000000000000100000000000000000000000000000000044400000000000000000000000000000
001000000d000555dd5dd5dddd544444001000000000000000000000000000100000000000000000000000000000000044000000000000000000000000000000
001000000d555555dd5dd5dddd544444001000000000000000000000000000100000000000000000000000000000000044000000000000000000000000000000
0001000000044444445dd5dddd544444000100000000000000000001000000010000000000000000000000000001000044000000000000000000000000000000
40000000004444444444444444444444400000004000000040000000400000004000000040000000400000004000000044000000000000000000000000000000
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444000000000000000000000000000000
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444000000000000000000000000000000
44444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444444000000000000000000000000000000
00070000000008888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00707000000888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008888888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00707000088888888888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00070000088888888888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000888888888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000887777777777778800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000887777777777778800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000887777777777778800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000887777777777778800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000888888888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000088888888888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000088888888888888000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000008888888888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000008888880000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000070700000700070007770700000000000000000
ddd0ddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000070700000700070000070700000000000000000
d0d00d000d0000000000000000000000000000000000000000000000000000000000000000000000000000000077700000777077700070777000000000000000
dd000d000000ddd0ddd0ddd00000ddd0ddd000000000000000777077707770000077707770000000000000000000700000707070700070707000000000000000
d0d00d000d0000000000000000000000000000000000000000000000000000000000000000000000000000000000700700777077700070777000000000000000
ddd00d0000000000000000000d000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd0dd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0d00d000d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd00d000000ddd0ddd0ddd00000ddd0ddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0000d000d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d000ddd000000000000000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd0ddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0d000d00d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd0ddd00000ddd0ddd0ddd00000ddd0ddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d000d0000d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d000ddd000000000000000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd0ddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0d000d00d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd00dd00000ddd0ddd0ddd00000ddd0ddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d00000d00d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d000ddd000000000000000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd0d0d0000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000
d0d0d0d00d0000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000
ddd0ddd00000ddd0ddd0ddd00000dddcdddcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000
d00000d00d0000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000
d00000d000000000000000000d000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000
00000000000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000
ddd0ddd0000000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000
d0d0d0000d0000000000000000000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000
ddd0ddd00000ddd0ddd0ddd00000ddd0ddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d00000d00d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d000ddd000000000000000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd0d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d0d0d0000d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
ddd0ddd00000ddd0ddd0ddd00000ddd0ddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d000d0d00d0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d000ddd000000000000000000d000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333361111111111111111111111111111111111111111111111111113333366633333333333
33333333333333333333333333333333333333333333333333333335111111111111111553333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333551111111111111111115533333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333351111111111111111111111555333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333511111111111111111111111115533333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333351111111111111111111111111111555333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333199999999999999999999999999999999133333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333319999999999999999999999999999999999991333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333339999999999999999999999999999999999999999993333333333333333333333333333333333333333333
33333333333333333333333333333333333333333999999999999999999999999999999999999999999999933333333333333333333333333333333333333333
33333333333333333333333333333333333333339999999999999999999999999999999999999999999999993333333333333333333333333333333333333333
33333333333333333333333333333333333335511111111111111111111111111111111111111111111111555553333333333333333333333333333333333333
33333333333333333333333333333333333355111111111111111111111111111111111111111111111111115555333333333333333333333333333333333333
33333333333333333333333333333333335511111111111111111111111111111111111111111111111111111555553333333333333333333333333333333333
33333333333333333333333333333333551111111111111111111111111111111111111111111111111111111115555533333333333333333333333333333333
333333333333333333333333333333551111111111111111110ddddddddddd11111ddddddddddd01111111111111555555333333333333333333333333333333
333333333333333333333333333355511111111111111111110ddddddddddddddddddddddddddd01111111111111115555553333333333333333333333333333
333333333333333333333333333551111111111111111111110ddddddddddddddddddddddddddd01111111111111111555555333333333333333333333333333
33333333333333333333333335511111111111111111111111055555555555555555555555555501111111111111111115555553333333333333333333333333
333333333333333333333335551111111111111111100000000ddddddddddddddddddddddddddd00000001111111111111555555533333333333333333333333
333333333333333333333555111111111111111111000000000ddddddddddddddddddddddddddd00000000111111111111115555555333333333333333333333
33333333333333333333551111111111111111111100000000011111117767777777677111111100000000111111111111111155555533333333333333333333
33333333333333333355511111111111111111111100000000017777667767777777677667777100000000111111111111111115555555333333333333333333
33333333333333335551111111111111111111111100000000707766777677777777767776677070000000111111111111111111155555553333333333333333
33333333333333555111111111111111111111100000000007707777776777777777776777777077000000000011111111111111115555555533333333333333
33333333333355551111111111111111111111000000000dd7770777777777000007777777770777dd0000000001111111111111111155555555333333333333
33333333333555111111111111111111111111000000000dd7b505570000000000000000075505b7dd0000000001111111111111111115555555533333333333
33333333355511111111111111111111111111000000100dd7570775555500050500055555770757dd0010000001111111111111111111155555555333333333
33333335555111111111111111111111111111000000100d557707700000555050555000007707755d0010000001111111111111111111115555555553333333
33333555511111111111111111111111111111000000100dd7570755555555005005555555570757dd0010000001111111111111111111111155555555533333
33355551111111111111111111111111111111000000100d555555555555550050055555555555555d0010000001111111111111111111111111555555555333
33555511111111111111111111111111111111000000000dd7555500000000000000000000055557dd0000000001111111111111111111111111155555555533
55551111111111111777777711111111111111000000000d555000dd5dd5ddddbdddd5dd5dd000555d0000000001111111111111166666661111111555555555
55511111111111777000000077711111111111000000000d000555dd5dd5dddd5dddd5dd5dd555000d0000000001111111111166600000006661111155555555
51111111111177000000000000077111111111000000000d555555dd5dd5dddd5dddd5dd5dd555555d0000000001111111116600000000000006611111555555
111111111117000000000000000007111111110000000000b11111115dd5dddd5dddd5dd51111111b00000000001111111160007000000000000061111155555
11111111117000000000000000000071111111100000000011111111111111111111111111111111100000000011111111600007000000000000006111111555
11111111170000000000000000000007111111111111111111111111111111111111111111111111111111111111111116000000700000000000000611111155
11111111700000000000000000000000711111111111111111111111111111111111111111111111111111111111111160000000700000000000000061111111
11111117000000000000000000000000071111111111111111111111111111111111111111111111111111111111111600000000070000000000000006111111
11111117000000000000000000000000071111111111111111111111111111111111111111111111111111111111111600000000070000000000000006111111
11111170000000000000000000000000007111111111111111111111111111111111111111111111111111111111116000000000070000000000000000611111
11111170000000000000000000000000007111111111111111111111111111111111111111111111111111111111116000000000007000000000000000611111
11111170000000000000000000000000007111111111111111111111111111111111111111111111111111111111116000000000007000000000000000611111
11111700000000000000000000000000000711111111111111111111111111111111111111111111111111111111160000000000000000000000000000061111
111117000000000000000000000000000007111111110000d000000000000000700000000000000d000001111111160000000000000000000000000000061111
111117000000000000000000000000000007111111110111d111111111111111711111111111111d111101111111160000000000000000000000000000061111
111117000000000000007777777000000007111111110111d111111111111111711111111111111d111101111111160000000000000077007070707000067171
111117000000000000000070000777770007111111110111d111111111111111711111111111111d111101111111160000000000000007007070707000067171
111117000000000000000770000000000007111111110000d000000000000000700000000000000d000001111111160000000000000007007770777000067771
11111700000000000000007000000000000711111111111111111111111111111111111111111111111111111111160000000000000007000070007000061171
11111170000000000000777000000000007111111111111111111111111111111111111111111111111111111111116000000000000077700070007007611171
11111170000000000000000000000000007111111111111111111111111177711111111111111111111111111111116000000000000000000000000000611111
11111170000000000000000000000000007111111111111111111111111171711111111111111111111111111111116000000000000000000000000000611111
11111117000000000000000000000000071111111111111111111111111171711111111111111111111111111111111600000000000000000000000006111111
11111117000000000000000000000000071111111111111111111111111171711111111111111111111111111111111600000000000000000000000006111111
11111111700000000000000000000000711111111111111111111111111177711111111111111111111111111111111160000000000000000000000061111111
11111111170000000000000000000007111111111111111111111111111111111111111111111111111111111111111116000000000000000000000611111111
11111111117000000000000000000071111111111111111111111111111111111111111111111111111111111111111111600000000000000000006111111111
11111111111700000000000000000711111111111111111111111111111111111111111111111111111111111111111111160000000000000000061111111111

__sfx__
170200000c3000c3300c3300d3300c3300d3300d3300d3300d3300e3300d3300e3300e3300e3300e3300f3300e3300f3300f3300f3300f330103300f330103301033010330103301133010330113300c3000c300
170200001133011330113301233011330123301233012330123301333012330133301333013330133301433013330143301433014330143301533014330153301533015330153301633015330163300c3000c300
17020000163301633016330173301633017330173301733017330183301733018335183351833518335203001330014300143001430014300143001430015300143001530014300153000c3000c3000030000300
470200000006000060000600106000060010600106001060010600206001060020600206002060020600306002060030600306003060030600406003060040600406004060040600506004060050600000000000
470200000506005060050600606005060060600606006060060600706006060070600706007060070600806007060080600806008060080600906008060090600906009060090600a060090600a0600000000000
470200000a0600a0600a0600b0600a0600b0600b0600b0600b0600c0600b0600c0600c0600e0600c0600100002000010000200002000020000200002000020000300002000030000200003000000000000000000
590100000340003400034000340003400044000340004400034000440004400044000440004400044000540004400054000440005400054000540005400054000540006400054000640005400064000040000400
590100000640006400064000640006400074000640007400064000740007400074000740007400074000840007400084000740008400084000840008400084000840009400084000940008400094000040000400
5901000009400094000940009400094000a400094000a400094000a4000a4000a4000a4000a4000a4000b4000a4000b4000a4000b4000b4000b4000b4000b4000b4000c4000b4000c4000b4000c4000040000400
590100000c4000c4000c4000c4000c4000c4000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
a503000000300003000130001300023000230003300033000430004300053000530006300063000730007300083000830009300093000a3000a3000b3000b3000c3000c300003000030000300003000030000300
a10200000030000300003000130000300013000130001300013000230001300023000230002300023000330002300033000330003300033000430003300043000430004300043000530004300053000030000300
a10200000530005300053000630005300063000630006300063000730006300073000730007300073000830007300083000830008300083000930008300093000930009300093000a300093000a3000030000300
a10200000a3000a3000a3000b3000a3000b3000b3000b3000b3000c3000b3000c3000c3000c3000c3000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
