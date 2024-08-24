pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
carx=0
cary=0
wheels={
	{-4,-4,true},
	{4,-4,true},
	{-5,4,true},
	{5,4,true}
}
ang=0.75

pts={}
crnrs,crnr_segs={}
apexs,apex_segs={}
tris={}

--car dimensions
--len: 4.0 meters
--wid: 2.0 meters (6 to scale)

--track dimensions
--wid: 16 meters

pvt_x=64
pvt_y=100
pov_h=70 	--horizontal angle?
pov_v=500 --vertical angle
pov_o=13  --offset (hack?)

t_wid=14 -- half track width

gears={
	{// n
		min=0,max=0,acc=0.03
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
	}
}
gear=1
rpm=0
spd=0
turn=0

function _init()
	printh("=====start=====")
	create_track()
	carx=pts_base[1][1]
	cary=pts_base[1][2]
end

function _draw()
	cls()
	draw_pov()
	print(carx.." "..cary,camx+80,camy,7)
	print(rpm,camx+80,camy+8,7)
	draw_hud()
	draw_map()
end

function _update()
--[[
	if btn(⬆️) then
		carx+=cos(ang)*1
		cary+=sin(ang)*1
	elseif btn(⬇️) then
		carx-=cos(ang)*1
		cary-=sin(ang)*1
	end
	//if(btn(⬇️))cary-=1
	if(btn(⬅️))ang+=0.01
	if(btn(➡️))ang-=0.01
	]]--
	for t in all(tris) do
		t[5]=false
	end
	update_car()
end
-->8
-- pov

function draw_pov()
	camx=flr(carx-pvt_x)
	camy=flr(cary-pvt_y)
	camera(camx,camy)
	
	rectfill(
		camx,camy+64,
		camx+127,camy+127,1)
		
	draw_segs(apex_segs)
	draw_segs(crnr_segs)
	
	--[[
	currently based on the pov
	constants, the pov scale
	is about 5 times
	]]--
		
	pset(carx,cary,11)
	
	--wheels
	for i=1,2 do
		local wx=wheels[i][1]
		local wy=wheels[i][2]
		local wt=wheels[i][3]
		local cwx=carx-wx
		local cwy=cary+wy
		rect(cwx,cwy,
			cwx-2*sgn(wx),cwy-4,
			wt and 6 or 9)
		pset(cwx,cwy,7)
	end
	
	for i=3,4 do
		local wx=wheels[i][1]
		local wy=wheels[i][2]
		local wt=wheels[i][3]
		local cwx=carx-wx
		local cwy=cary+wy
		rect(cwx,cwy,
			cwx-3*sgn(wx),cwy-6,
			wt and 6 or 9)
		pset(cwx,cwy,7)
	end
end

function draw_segs(v)
	local c=0
	for i=1,#v do
		local p=v[i]
		local px,py=pov(p[1],p[2])
		if px!=nil and py<camy+128 then
				local p2=v[i%#v+1]
				local p2x,p2y=pov(p2[1],p2[2])
				if p2x!=nil then
					line(px,py,p2x,p2y,
						7+c%2)
				end
			end
		c+=1
	end
end

function pov(x,y)	
	local dx=x-carx+pov_o*cos(ang)
	local dy=y-cary+pov_o*sin(ang)
	
	local rx,ry=rot(
		dx,-dy,-ang+0.25)
		
	rx*=(pov_h/max(abs(ry),1))
	rx+=camx+pvt_x
	
	ry=-(pov_v/ry)
	if ry>64 or ry<0 then
		return nil
	else
		ry+=camy+64
	end
	
	return rx,ry
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

function draw_top_down()
	rectfill(camx,camy,
		camx+40,camy+40,0)
	rect(camx,camy,
		camx+40,camy+40,7)
		
	local a=-ang+0.25
	
	for i=1,#pts do
		local cp1=crnrs[i]
		local cp2=crnrs[(i%#crnrs)+1]
		local cx1,cy1=rot(cp1[1],cp1[2],a)
		local cx2,cy2=rot(cp2[1],cp2[2],a)
		line(cx1,cy1,cx2,cy2,7)
		
		local ap1=apexs[i]
		local ap2=apexs[(i%#apexs)+1]
		local ax1,ay1=rot(ap1[1],ap1[2],a)
		local ax2,ay2=rot(ap2[1],ap2[2],a)
			line(ax1,ay1,ax2,ay2,7)
	end
	
	pset(camx+20,camy+20,11)
	//pset(camx+20-1
end

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
	
	--break
	local breaking=false
	if btn(⬇️) then
		spd=max(0,spd-1.1)
		breaking=true
	end
	
	--bad shifts
	if rpm>1 then
		printh("bad downshift")
		rpm=1
	elseif rpm<0 and gear>1 then
		printh("stall")
		rpm=0
	end
	
	//on_track(carx,cary)
	
	local car_on_track=true
	for i=1,#wheels do
		local w=wheels[i]
		w[3]=true

		local rx,ry=rot(
			w[1],w[2],ang+0.25)
		
		if not on_track(carx+rx,cary+ry) then
			grip-=0.15
			w[3]=false
			car_on_track=false
		end
	end
	
	--[[
	this should change from just
	grip to under vs over steer.
	or at least, at low speeds
	its under and high its over??
	]]--
	
	--turning
	local tamt=0.1
	if spd>150 then
		tamt=0.2
	end
	if btn(⬅️) then
		turn=max(-1,turn-tamt)
	elseif btn(➡️) then
		turn=min(1,turn+tamt)
	elseif turn<0 then
		turn=min(0,turn+0.05)
	elseif turn>0 then
		turn=max(0,turn-0.05)
	end
	
	turn_actual=turn
	grip=min(1,1-((spd-80)/300))
	dftx,dfty=0,0
	
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
		
			//turn_actual=grip*sgn(turn)	
		end
	end

	ang=(ang-turn_actual*grip*0.01)%1
	
	//1 k/h ~= 0.278 m/s
	local fx=cos(ang)*spd*0.278/30
	local fy=sin(ang)*spd*0.278/30
	
	carx+=fx+dftx
	cary+=fy+dfty
end
-->8
-- hud

function draw_hud()
	--tach
	local x,y=camx+20,camy+115
	circfill(x,y,15,0)
	circ(x,y,15,6)
	local a=rpm*0.8+0.3
	line(x+cos(a)*4,y+sin(-a)*4,
		x+cos(a)*12,y+sin(-a)*12,7)
	
	print(gear>1 and gear-1 or "n",x,y,7)
	
	--speed
	x,y=camx+108,camy+115
	circfill(x,y,15,0)
	circ(x,y,15,6)
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
end
-->8
-- track


pts_base={
	{-100,100},
	{-100,0},// start
	{-100,-100},//start chicane
	{0,-100},
	{0,-200},
	{40,-240},
	{150,-240},
	{400,-210},
	{400,200},
	{370,300},
	{300,300},
	{270,270},
	{270,200},
	{230,170},
	{200,170}
}


--[[
pts_base={
	{-100,-100},
	{100,-100},
	{100,100},
	{-100,100}
}
]]--

function create_track()
	apexs=create_outer(
		pts_base,0.75)
		
	crnrs=create_outer(
		pts_base,0.25)
		
	create_tris()
		
	apex_segs=create_segs(apexs)
	crnr_segs=create_segs(crnrs)
end

function create_outer(pts,v)
	local out={}
	for i=1,#pts do
	
		local prv=pts[i==1 and #pts or i-1]
		local cur=pts[i]
		local nxt=pts[i%#pts+1]
			
		local px,py=prv[1],prv[2]
		local cx,cy=cur[1],cur[2]
		local nx,ny=nxt[1],nxt[2]
		
		local a=atan2(nx-px,ny-py)
		local amtx=abs(t_wid/cos(a+v))
		local amty=abs(t_wid/sin(a+v))
		add(out,{
			flr(cx+cos(a+v)*amtx),
			flr(cy+sin(a+v)*amty)
		})
	end
	return out
end

function create_segs(pts)
	local out={}
	for i=1,#pts do
		local cur=pts[i]
		local nxt=pts[i%#pts+1]
		
		local cx,cy=cur[1],cur[2]
		local nx,ny=nxt[1],nxt[2]
		
		local a=atan2(nx-cx,ny-cy)
		local go=true
		local px,py=cx,cy
		add(out,{cx,cy})
		while go do
			local d=dist(px,py,nx,ny)
			if d>10 then
				px+=10*cos(a)
				py+=10*sin(a)
				add(out,{px,py})
			else
				go=false
			end
		end
	end
	
	return out
end

function create_tris()
	for i=1,#crnrs do
		local cur_c=crnrs[i]
		local cur_p=apexs[i]
		local nxt_c=crnrs[i%#crnrs+1]
		local nxt_p=apexs[i%#apexs+1]
		local pt=pts_base[i]
		
		add(tris,{
			{cur_c[1],cur_c[2]},
			{nxt_c[1],nxt_c[2]},
			{cur_p[1],cur_p[2]},
			{pt[1],pt[2]},//center
			false //debug
		})
		add(tris,{
			{nxt_c[1],nxt_c[2]},
			{nxt_p[1],nxt_p[2]},
			{cur_p[1],cur_p[2]},
			{pt[1],pt[2]},//center
			false //debug
		})
	end
end

function on_track(x,y)
	local found=false
	for t in all(tris)do
		local close=false
		for i=1,4 do
			if dist(carx,cary,
							t[i][1],t[i][2])
						<250 then
				close=true
			end
		end
		if close and pt_in_tri(x,y,t) then
			t[5]=true //debug
			found=true
		end
	end
	return found
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
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
