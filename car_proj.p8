pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
carx=0
cary=0
wheels={
	{-2,-3,true},
	{2,-3,true},
	{-3,3,true},
	{3,3,true}
}
ang=0.25

--track dimensions
--wid: 16 meters

pvt_x=64
pvt_y=100
pov_h=50 	--pov hov?
pov_d=500 --pov distance
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

uitf=0 --ui time fast

function _init()
	printh("=====start=====")
	create_track()
	carx=pts_base[1][1]
	cary=pts_base[1][2]
end

function _draw()
	cls()
	draw_pov()
	print(flr(carx).." "..flr(cary),camx,camy,7)
	//print(rpm,camx+80,camy+8,7)
	draw_hud()
	//draw_map()
	//draw_top_down()
	print("secx "..secx,camx,camy+8,7)
	print("secy "..secy,camx,camy+16,7)
end

secx,secy=0,0
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
	uitf=(uitf+0.5)%30
	
	--[[
	for i=-10,10 do
	for j=-10,10 do
		for t in all(r_tris[i][j]) do
			t[5]=false
		end
	end end
	]]--
	update_car()
	
	secx,secy=flr(carx/100),flr(cary/100)
end
-->8
-- pov

function draw_pov()
	camx=flr(carx-pvt_x)
	camy=flr(cary-pvt_y)
	camera(camx,camy)
	
	rectfill(
		camx,camy+64,
		camx+127,camy+127,3)
	
	for i=max(-10,secx-1),min(10,secx+1)do
	for j=max(-10,secy-1),min(10,secy+1)do
	
		draw_tris(r_tris[i][j])
		draw_tris(a_tris[i][j])
		draw_tris(c_tris[i][j])
		
		//draw_tris(c_tris[i][j],12)
	end end
		
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
		local cwx=carx-wx-pov_o*sgn(wx)
		local cwy=cary+wy
		rect(cwx,cwy,
			cwx-4*sgn(wx),cwy-8,
			wt and 6 or 9)
		pset(cwx,cwy,7)
	end
	
	for i=3,4 do
		local wx=wheels[i][1]
		local wy=wheels[i][2]
		local wt=wheels[i][3]
		local cwx=carx-wx-pov_o*sgn(wx)
		local cwy=cary+wy
		rect(cwx,cwy,
			cwx-7*sgn(wx),cwy-10,
			wt and 6 or 9)
		pset(cwx,cwy,7)
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

function draw_tris(v)
	
	for t in all(v) do
		local p1x,p1y,t1=pov(t[1][1],t[1][2])
		local p2x,p2y,t2=pov(t[2][1],t[2][2])
		local p3x,p3y,t2=pov(t[3][1],t[3][2])
		
		//local tt=t1 or t2 or t3
		//if p1x!=nil and 
		//			p2x!=nil and 
		//			p3x!=nil then
			//p01_triangle_163(
			//p01_triangle_335(
			//azufasttri(
			//azulocalfast(
			//if col then
				//printh(t[5])
			//end
			pelogen_tri(
				p1x,p1y,
				p2x,p2y,
				p3x,p3y,
				//col and col or t[5])
				t[5])
				//p3x,p3y,1+c%2)
		//end
		//`c+=1
	end
end

function pov(x,y)
	local dx=x-carx
	local dy=y-cary
	
	local rx,ry=rot(
		dx,-dy,-ang+0.75)	
	
	local de=max(0.1,ry+pov_o)
	
	local povy=max(
		-pvt_y+((pvt_y-64)-pov_d/(de)),
		-128
	)
	
	local povx=rx*min(60/de,7.5)
	povx-=pvt_x
	
	return camx-povx,camy-povy//,true,rx
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
		for t=ceil(t),min(flr(m),512) do
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
	
	--break
	local breaking=false
	if btn(⬇️) then
		// this is too fast breaking
		spd=max(0,spd-1.1)
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
		printh("stall")
		rpm=0
	end
		
	--turning
	local tamt=0.05
	if spd>150 then
		tamt=0.1
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
	//dftx,dfty=0,0
	
	for i=1,#wheels do
		local w=wheels[i]
		w[3]=true

		local rx,ry=rot(
			w[1],w[2],ang+0.25)
		
		if not on_track(carx+rx,cary+ry) then
			grip=max(0,grip-0.15)
			w[3]=false
			if spd>50 then
				spd-=0.5
			end
		end
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
		ang=(ang-turn_actual*0.01)%1
	end
	
	//1 k/h ~= 0.278 m/s
	local fx=cos(ang)*spd*0.278/30
	local fy=sin(ang)*spd*0.278/30
	
	carx+=fx//+dftx
	cary+=fy//+dfty
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
end
-->8
-- track

pts_base={
	{-100,100},
	{-100,0,"start"},// start
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

--[[
segment and outer list params:
1: x
2: y
3: flag (start, bend, etc)
4: color
]]--

function create_track()
	local pt_segs=create_segs(
		pts_base,false,20)
		
	local apexs_0=create_outer(
		pt_segs,0.75,t_wid)
	local crnrs_0=create_outer(
		pt_segs,0.25,t_wid)
	r_tris=create_tris(
		pt_segs,
		crnrs_0,
		apexs_0)
	
	local apexs_1=create_outer(
		pt_segs,0.75,t_wid-1,"side")
	local apexs_2=create_outer(
		pt_segs,0.75,t_wid+1,"side")
	local apex_segs_1=create_segs(
		apexs_1,false)
	local apex_segs_2=create_segs(
		apexs_2,false)
	a_tris=create_tris(
		apex_segs_1,
		apex_segs_1,
		apex_segs_2)
		
	local crnrs_1=create_outer(
		pt_segs,0.25,t_wid-1,"side")
	local crnrs_2=create_outer(
		pt_segs,0.25,t_wid+1,"side")
		local crnr_segs_1=create_segs(
		crnrs_1,false)
	local crnr_segs_2=create_segs(
		crnrs_2,false)
	c_tris=create_tris(
		crnr_segs_1,
		crnr_segs_1,
		crnr_segs_2)
end

function create_outer(pts,v,wid,flag)
	printh("create outer")
	local out={}
	local last_a=nil
	for i=1,#pts do
	
		local prv=pts[i==1 and #pts or i-1]
		local cur=pts[i]
		local nxt=pts[i%#pts+1]
			
		local px,py=prv[1],prv[2]
		local cx,cy=cur[1],cur[2]
		local nx,ny=nxt[1],nxt[2]
		
		local a=atan2(nx-px,ny-py)
		local dff=0
		if last_a!=nil then
			dff=abs(a-last_a)
		end
		last_a=a
		local amtx=abs(wid/cos(a+v))
		local amty=abs(wid/sin(a+v))
		//printh(cur[4])
		add(out,{
			flr(cx+cos(a+v)*amtx),
			flr(cy+sin(a+v)*amty),
			cur[3] and cur[3] or 
			dff>0 and "bend" or flag
		})
	end
	return out
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
		
		local cx,cy=cur[1],cur[2]
		local nx,ny=nxt[1],nxt[2]
		
		local sex=flr(cx/100)
		local sey=flr(cy/100)
		
		local a=atan2(nx-cx,ny-cy)
		local go=true
		local px,py=cx,cy
		
		--[[
		local is=cur[3] or nxt[3]
		local col=is and c+7 or 5
		]]--
		col=1
		if cur[3]=="start" then
			col=9
		elseif cur[3]=="bend" or 
									nxt[3]=="bend" then
			col=c+7
		elseif cur[3]=="side" then
			col=5
		end
		
		local o={cx,cy,cur[3],col}
		//printh(o[4])
		if is_map then
			add(out[sex][sey],o)
		else
			add(out,o)
		end
		c*=-1
		
		while go do
			local d=dist(px,py,nx,ny)
			if d>v then
				px+=v*cos(a)
				py+=v*sin(a)
			
				local o2={px,py,cur[3],col}
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

function create_tris(pts,crnr,apex)
	//printh("creating tri")
	out=create_map()
	
	for i=1,#crnr do
		local cur_c=crnr[i]
		local cur_p=apex[i]
		local nxt_c=crnr[i%#crnr+1]
		local nxt_p=apex[i%#apex+1]
		local pt=pts[i]
		
		local cx=flr(pt[1]/100)
		local cy=flr(pt[2]/100)
		
		--[[
		local col=pt[3]
		if cur_c[4]=="start" then
			col=9
			printh("herererere")
			printh(col)
		end
		]]--
		
		add(out[cx][cy],{
			{cur_c[1],cur_c[2]},
			{nxt_c[1],nxt_c[2]},
			{cur_p[1],cur_p[2]},
			{pt[1],pt[2]},//center
			pt[4] //color
		})
		//printh(pt[3])
		add(out[cx][cy],{
			{nxt_c[1],nxt_c[2]},
			{nxt_p[1],nxt_p[2]},
			{cur_p[1],cur_p[2]},
			{pt[1],pt[2]},//center
			pt[4] //color
		})
	end
	return out
end

function create_map()
	local out={}
	for i=-10,10 do
		local row={}
		for j=-10,10 do
			row[j]={}
		end
		out[i]=row
	end
	return out
end

function on_track(x,y)
	local found=false
	local cx=flr(x/100)
	local cy=flr(y/100)
	
	for i=max(-10,cx-1),min(10,cx+1)do
	for j=max(-10,cy-1),min(10,cy+1)do
	for t in all(r_tris[i][j])do
		local close=false
		for i=1,4 do
			if dist(carx,cary,
							t[i][1],t[i][2])
						<250 then
				close=true
			end
		end
		if close and pt_in_tri(x,y,t) then
			//t[5]=true //debug
			found=true
		end
	end
	end end
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
