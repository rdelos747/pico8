pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
px,py=0,0
ang=0.25
dftx,dfty=0,0
spd=0
camx,camy=0,0

gear=1
gears={
	{// n
		min=0,max=0,acc=0.03
	},
	{// 1
		min=0,max=40,acc=0.03
	},
	{// 2
		min=0,max=80,acc=0.02
	},
	{// 3
		min=25,max=120,acc=0.01
	},
	{// 4
		min=50,max=150,acc=0.006
	},
	{// 5
		min=100,max=200,acc=0.004
	}
}
rpm=0 //[0,1]
//acc=0.03

turn=0
turn_actual=0 //debug
grip=0

skids={}

wheels={
	{-3,-5,true},//fl
	{3,-5,true},	//fr
	{-3,5,true},	//rl
	{3,5,true}   //rr
}

function _init()
	printh("=== start ===")

	create_track()
	
	px=pts[1][1]
	py=pts[1][2]
end

function _draw()
	cls()
	draw_pov()	
end

on_track_lf=true
function _update()
	--reset triangles
	for t in all(tris) do
		t[5]=false
	end
	
	local last_gear=gear
	if(btnp(❎))gear=min(#gears,gear+1)
	if(btnp(🅾️))gear=max(1,gear-1)
	local g=gears[gear]
	
	-- tie rpm to speed
	if gear>1 then
		rpm=(spd-g.min)/(g.max-g.min)
	end
	
	--throttle
	if btn(⬆️) then
		rpm=min(1,rpm+g.acc)
		if gear>1 then
			//hack but w/e
			spd=max(spd,1)
		end
	else		
		rpm=max(0,rpm-g.acc)
	end
	
	--only accel if proper gear
	if spd>g.min and spd<=g.max then
		spd=(g.max-g.min)*rpm+g.min
	else
		spd=max(0,spd-1)
	end
	
	--break
	if btn(⬇️) then
		spd=max(0,spd-2)
	end
	
	--bad shifts
	if rpm>1 then
		printh("bad downshift")
		rpm=1
	elseif rpm<=0 and gear>1 then
		printh("stall")
		rpm=0
	end
		
	last_gear=gear
		
	if btn(⬅️) then
		turn=max(-1,turn-0.1)
	elseif btn(➡️) then
		turn=min(1,turn+0.1)
	elseif turn<0 then
		turn=min(0,turn+0.05)
	elseif turn>0 then
		turn=max(0,turn-0.05)
	end
	
	-- forward vel
	local fx=cos(ang)*spd/30
	local fy=sin(ang)*spd/30
	
	grip=min(1,1-((spd-80)/300))
	
	local car_on_track=true
	for i=1,#wheels do
		local w=wheels[i]
		w[3]=true

		local rx,ry=rot_pt(w[1],w[2],ang+0.25)
		
		if not on_track(px+rx,py+ry) then
			grip-=0.15
			w[3]=false
			car_on_track=false
		end
	end
	//on_track(px,py)
	
	-- drift vel
	dftx,dfty=0,0
	if abs(turn)>grip then
		add(skids,{px,py})
		dftx=cos(ang+0.25*abs(turn)*sgn(turn))*1
		dfty=sin(ang+0.25*abs(turn)*sgn(turn))*1
	end
	
	turn_actual=turn*grip
	ang=(ang-turn*grip*0.01)%1

	px+=fx+dftx
	py+=fy+dfty
	
	on_track_lf=car_on_track
	
	local off=flr(rpm*23)*5
	sfx(flr(off/30),0,off%30)
	sfx(flr(off/30)+5,1,off%30)
end

-->8
-- draw

function draw_pov()
	camx=flr(px-64)
	camy=flr(py-115)
	camera(camx,camy)
	
	--points
	for i=1,#pts do
		local cp1=crnrs[i]
		local cp2=crnrs[(i%#crnrs)+1]
		local cx1,cy1=rot(cp1[1],cp1[2])
		local cx2,cy2=rot(cp2[1],cp2[2])
		
		local ap1=apexs[i]
		local ap2=apexs[(i%#apexs)+1]
		local ax1,ay1=rot(ap1[1],ap1[2])
		local ax2,ay2=rot(ap2[1],ap2[2])
		
		line(cx1,cy1,cx2,cy2,7)
		line(ax1,ay1,ax2,ay2,7)
		ppx,ppy=rot(pts[i][1],pts[i][2])
		pset(ppx,ppy,8)
	end
	
	--skids
	for s in all(skids) do
		local x,y=rot(s[1],s[2])
		spr(1,x,y)
	end
	
	-- player
	rect(px-3,py-5,px+3,py+5,7)
	for w in all(wheels)do
		pset(px-w[1],py+w[2],
			w[3] and 11 or 8)
	end
	
	-- debug
	print("ang:"..ang,camx,camy,7)
	print("x,y:"..px..","..py,camx,camy+8)
	print("spd:"..spd,camx,camy+16)
	print("trn:"..turn,camx,camy+24)
	print("grp:"..grip,camx,camy+32)
	print("turn a:"..turn_actual,camx,camy+40)
	print("dft:"..dftx.." "..dfty,camx,camy+48)
			
	-- map
	rect(camx,camy+100,camx+28,camy+127,7)
	
	for i=1,#pts do
		local cur=pts[i]
		local nxt=pts[i%#pts+1]
			
		local cx,cy=cur[1],cur[2]
		local nx,ny=nxt[1],nxt[2]
		line(
			camx+((cx+500)/1000)*28,
			camy+100+((cy+500)/1000)*28,
			camx+((nx+500)/1000)*28,
			camy+100+((ny+500)/1000)*28,
			14)
	end
	
	--debug
	for t in all(tris) do
		//if t[5] then
			for i=1,3 do
				local cur=t[i]
				local nxt=t[i%3+1]
			
				local cx,cy=cur[1],cur[2]
				local nx,ny=nxt[1],nxt[2]
				if t[5] then
					line(
						camx+((cx+500)/1000)*28,
						camy+100+((cy+500)/1000)*28,
						camx+((nx+500)/1000)*28,
						camy+100+((ny+500)/1000)*28,
						11)
				end
					
				cx,cy=rot(cur[1],cur[2])
				nx,ny=rot(nxt[1],nxt[2])
				line(cx,cy,nx,ny,t[5]and 11or 1)
			end
		//end
	end
	
	mx=((px+500)/1000)*28
	my=((py+500)/1000)*28
	mx2=mx+cos(ang)
	my2=my+sin(ang)
	pset(camx+mx,camy+100+my,7)
	pset(camx+mx2,camy+100+my2,9)
	
	--tach
	circ(camx+116,camy+122,10,7)
	local a=rpm*0.8+0.3
	line(camx+116,camy+122,
		camx+116+cos(a)*5,
		camy+122+sin(-a)*5,
		7)
	print(gear>1 and gear-1 or "n",
		camx+115,camy+106,7)

	--speed
	circ(camx+90,camy+122,10,7)
	a=(spd/200)*0.8+0.3
	line(camx+90,camy+122,
		camx+90+cos(a)*5,
		camy+122+sin(-a)*5,
		7)
	print(flr(spd),
		camx+85,camy+106,7)

	--turn
	rect(camx+54,camy+122,camx+74,camy+127)
	rectfill(camx+64,camy+123,
		camx+64+flr(turn*10),camy+126,8)
	line(camx+64,camy+125,
		camx+64+10*grip,camy+125,11)
	line(camx+64,camy+125,
		camx+64-9*grip,camy+125,11)
end
-->8
-- track

crnrs={}
apexs={}
tris={}

pts={
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
pts={
	{-100,-100},
	{100,-100},
	{100,100},
	{-100,100}
}
]]--

function create_track()
	-- calculate corners and apexes
	for i=1,#pts do
	
		local prv=pts[i==1 and #pts or i-1]
		local cur=pts[i]
		local nxt=pts[i%#pts+1]
			
		local px,py=prv[1],prv[2]
		local cx,cy=cur[1],cur[2]
		local nx,ny=nxt[1],nxt[2]
		
		local a=atan2(nx-px,ny-py)
		local amtx=abs(30/cos(a+0.25))
		local amty=abs(30/sin(a+0.25))
		//amtx,amty=30,30
		add(crnrs,{
			flr(cx+cos(a+0.25)*amtx),
			flr(cy+sin(a+0.25)*amty)
		})
		amtx=abs(30/cos(a+0.75))
		amty=abs(30/sin(a+0.75))
		//amtx,amty=30,30
		add(apexs,{
			flr(cx+cos(a+0.75)*amtx),
			flr(cy+sin(a+0.75)*amty)
		})	
	end
	
	-- calculate triangles
	for i=1,#crnrs do
		local cur_c=crnrs[i]
		local cur_p=apexs[i]
		local nxt_c=crnrs[i%#crnrs+1]
		local nxt_p=apexs[i%#apexs+1]
		local pt=pts[i]
		//printh(pt[1].." "..pt[2])
		
	//	local 
		
		add(tris,{
			{cur_c[1],cur_c[2]},
			{nxt_c[1],nxt_c[2]},
			{cur_p[1],cur_p[2]},
			{pt[1],pt[2]},//center
			{false} //debug
		})
		add(tris,{
			{nxt_c[1],nxt_c[2]},
			{nxt_p[1],nxt_p[2]},
			{cur_p[1],cur_p[2]},
			{pt[1],pt[2]},//center
			{false} //debug
		})
	end
end

function on_track(x,y)
	local found=false
	for t in all(tris)do
		local close=false
		for i=1,4 do
			if dist(px,py,
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


--1839
--[[
function pt_in_tri(x,y,tr)
	local p1x,p1y=tr[1][1],tr[1][2]
	local p2x,p2y=tr[2][1],tr[2][2]
	local p3x,p3y=tr[3][1],tr[3][2]
	
	local d1=sign(x,y,p1x,p1y,p2x,p2y)
	local d2=sign(x,y,p2x,p2y,p3x,p3y)
	local d3=sign(x,y,p3x,p3y,p1x,p1y)
	
	local neg=(d1<0)or(d2<0)or(d3<0)
	local pos=(d1>0)or(d2>0)or(d3>0)
	
	if not(neg and pos) then
		//printh("n "..(neg and "y" or "n"))
		//printh("p "..(pos and "y" or "n"))
		return true
	end
	
	return false
end

function sign(p1x,p1y,p2x,p2y,p3x,p3y)
	local v=(p1x-p3x)*(p2y-p3y)-(p2x-p3x)*(p1y-p3y)
	//printh("v "..v)
	return v
end
]]--
-->8
--util

function rot(x,y)
	x-=px
	y-=py
	local rx,ry=rot_pt(x,-y,-ang+0.25)
	rx+=camx+64
	ry+=camy+115
	return rx,ry
end

function rot_pt(x,y,a)
	local rx=x*cos(a)+y*sin(a)
	local ry=x*sin(a)-y*cos(a)
	return rx,ry
end

function dist(x1,y1,x2,y2)
 local a0,b0=abs(x1-x2),abs(y1-y2)
 return max(a0,b0)*0.9609+min(a0,b0)*0.3984
end

__gfx__
00000000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
450100000025000250002500025000250012500125001250012500125002250022500225002250022500325003250032500325003250042500425004250042500425005250052500525005250052500000000000
4501000006250062500625006250062500725007250072500725007250082500825008250082500825009250092500925009250092500a2500a2500a2500a2500a2500b2500b2500b2500b2500b2500000000000
450100000c2500c2500c2500c2500c2500d2500d2500d2500d2500d2500e2500e2500e2500e2500e2500f2500f2500f2500f2500f250102501025010250102501025011250112501125011250112500000000000
450100001225012250122501225012250132501325013250132501325014250142501425014250142501525015250152501525015250162501625016250162501625017250172501725017250172500020000200
010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
d70100000015000150001500015000150011500115001150011500115002150021500215002150021500315003150031500315003150041500415004150041500415005150051500515005150051500010000100
d701000006150061500615006150061500715007150071500715007150081500815008150081500815009150091500915009150091500a1500a1500a1500a1500a1500b1500b1500b1500b1500b1500010000100
d70100000c1500c1500c1500c1500c1500d1500d1500d1500d1500d1500e1500e1500e1500e1500e1500f1500f1500f1500f1500f150101501015010150101501015011150111501115011150111500010000100
d70100001215012150121501215012150131501315013150131501315014150141501415014150141502115015150151501515015150161501615016150161501615017150171501715017150171500010000100
010100000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000000000000000000000000000
010100000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000000000000000000000000000
010100000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000000000000000000000000000
010100000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000000000000000000000000000
010100000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000000000000000000000000000
010100000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000000000000000000000000000
010100000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000000000000000000000000000
010100000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100001000010000100000000000000000000000000000000
010a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
