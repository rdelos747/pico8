pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- baseball

--consants
fric=1

-- pov
fov=0.11
fov_c=-2.778 // 1/tan(fov/2)
zfar=500
znear=10
lam=zfar/(zfar-znear)

--globals
logo_t=0
mode="title"
camx,camy,camz=0,-90,-135
cam_pi,cam_ya=0.95,0
g_mode="wait"

_uits,_uitf=0,0

function _init()
	printh("====start====")
	
	home=pt("0,0")
	frst=pt("64,64")
	scnd=pt("0,128")
	thrd=pt("-64,64")
	mond=pt("0,64")
	
	bases={
		frst,
		scnd,
		thrd,
		home
	}
	
	dirt=pt_a(
		"0,-5;94,64;0,163;-94,64"
	)
	
	dirt_cover=pt_a(
		"100,-5;100,92;-100,-5;-100,92"
	)
	
	home_dirt=pt_a(
		"0,-8;8,8;0,8;-8,8"
	)
	
	//ptchr=plyr("0,64","0,64")
	//bttr=pt("-3,2")
	ball=pt(0,0,0)
	
	fldrs={
		pi=plyr("0,64",mond),
		ct=plyr("0,-9",home), 
		b1=plyr("64,64",frst), 
		b2=plyr("40,110",scnd),
		b3=plyr("-64,64",thrd),
		ss=plyr("-40,110",nil),
		lf=plyr("-130,300",nil),
		cf=plyr("0,350",nil),
		rf=plyr("130,300",nil),
	}
	ptchr=fldrs.pi
	
	for _,f in pairs(fldrs)do
		f.spd=21
	end
	
	rnnrs={}
	
	reset_players()
	
	printh(distp(home,frst))
end

function _draw()
	if logo_t<180 then
		draw_logo()
		return
	end
	
	if mode=="title" then
		draw_title()
	elseif mode=="game" then
		draw_game()
	end
end

function _update()
	if logo_t<180 then
		logo_t+=2
		if logo_t<90 and btnp(❎) then
			logo_t=90
		elseif btnp(❎) then
			logo_t=180
		end
		return
	end
		
	_uits=(_uits+0.1)%30
	_uitf=(_uitf+0.5)%30
	
	if mode=="title" then
		if btnp(❎) then
			mode="game"
		end
	elseif mode=="game" then
		update_game()
	end
end

function draw_logo()
	cls()
	local t=flr(logo_t/6)
	sspr(
		64,56,
		mid(0,logo_t-30,64),8,
		32,60)
	spr(
		119,
		logo_t,60,
		1,1,
		(t-1)%4>1,
		t%4<2)
end
-->8
--draw

function draw_title()
	cls()
	print("title")
	print("press ❎ to start")
end

function draw_game()
	cls(3)
	
	pts=get_proj_pts({
		{home,frst,scnd,thrd}, --1,4
		dirt, --5,8
		dirt_cover, --9,12
		home_dirt, --13,16
	})
	
	-- infield dirt
	ovalfill(
		pts[8].x,
		pts[7].y,
		pts[6].x,
		pts[5].y,15)
	
	-- cover dirt in foul area
	p_trip(pts[5],pts[9],pts[10],3)
	p_trip(pts[5],pts[11],pts[12],3)
	
	-- cover dirt inside bases
	p_trip(pts[1],pts[2],pts[3],3)
	p_trip(pts[1],pts[3],pts[4],3)
	
	-- home plate dirt
	ovalfill(
		pts[16].x,
		pts[15].y,
		pts[14].x,
		pts[13].y,15)

	-- bases and lines
	for i=1,4 do
		local p1=pts[i]
		local p2=pts[i%4+1]
		line(p1.x,p1.y+1,p2.x,p2.y+1,7)
		spr(
			i==1 and 1 or 2,
			p1.x-4,p1.y-2)
	end
	
	-- mound
	px,py=projp(mond)
	spr(3,px-8,py-4,2,1)
	
	--test center field
	px,py=projp(pt("0,408"))
	pset(px,py,8)
	
	if g_mode!="play" then
		draw_pitcher_catcher()
	end
	if g_mode!="play" or 
				bat_sw!=0 or
				not ball_fair then
		draw_batter()
	end
	
	draw_fielders()
	draw_runners()
	draw_ball()
	
	pria({
		camx,camy,camz,
		g_mode,
		ball_s,ball_a,ball_fair})
end

function get_proj_pts(arrs)
	pts={}
	for a in all(arrs)do
	for p in all(a) do
		local x,y=projp(p)
		add(pts,pt(x,y,0))
	end end
	return pts
end

function draw_ball()
	if(not ball_m)return
	
	if ball_trg then
		dx,dy=projp(ball_trg)
		pset(dx,dy,8)
	end
	
	if ball_r_trg then
		dx,dy=projp(ball_r_trg)
		pset(dx,dy,8)
	end
	
	dx,dy=proj(ball.x,0,ball.z)
	pset(dx,dy,5)
	dx,dy=projp(ball)
	pset(dx,dy,7)
end

function draw_pitcher_catcher()
	dx,dy=projp(ptchr.pos)
	if ptchr.t==0 then
		spr(20,dx-4,dy-9)
	else
		spr(21+ptchr.t,dx-4,dy-9)
	end
	
	px,py=projp(pt("0,-8"))
	spr(11,px-4,py-4)
end

function draw_batter()
	px,py=projp(pt("-3,2"))
	spr(6+min(bat_t,4),px-4,py-4)
end

function draw_fielders()
	for k,f in pairs(fldrs)do
		if g_mode!="play" and
					(k=="pi" or k=="ct") then
			goto skip_draw
		end
		dx,dy=projp(f.pos)
		spr(36+uits()%2,dx-4,dy-9)
		
		::skip_draw::
	end
end

function draw_runners()
	for r in all(rnnrs)do
		dx,dy=projp(r.pos)
		spr(38+uits()%2,dx-4,dy-5)
	end
end
-->8
--game

function reset_players()
	//ptchr.pos=cpt(ptchr.st)
	//ptchr.t=0
	
	bat_t=0
	bat_sw=0
	
	ball=pt(0,0,68)
	ball_m=false
	ball_a=0
	ball_air_t=0
	ball_air_t_m=0
	//ball_t=0
	ball_spd=0
	ball_trg=nil
	ball_r_trg=nil
	
	ball_fair=false
	
	for _,f in pairs(fldrs)do
		f.pos=cpt(f.st)
	end
	fldrs.pi.t=0
	targ_f=nil
	
	//bat_sw=false
	//bat_strk=false
	calc_pitch()
	
	--temp for testing
	for r in all(rnnrs)do
		del(rnnrs,r)
	end
end

function update_game()
	//todo
	// it should zoom out and
	// slightly pan when the
	// ball goes far
	
	//camx=ball.x
	//camz=min(-135,ball.z-135)
	//camz=camz-135
	
	if g_mode=="wait" then
		if btnp(❎) then
			g_mode="pitch"
		end
		
		bat_t=uits()%2
	elseif g_mode=="pitch" then
		if ptchr.t<5 then
			ptchr.t+=1/15
		elseif ptchr.t<8 then
			ptchr.t+=1/4
		end
		
		if ptchr.t>6 then
			ball.z-=146/30 //100 mph
			ball_m=true
		end
		
		if ball.z<20 and will_sw then
			//bat_t=min(bat_t+0.5,4)
			bat_sw=1
		end
		if did_cont and ball.z<=0 then
			calc_contact()
			g_mode="play"
		elseif ball.z<=-8 then
			//ball.z=-8
			calc_no_contact()
			g_mode="wait"
		end
	elseif g_mode=="play" then
		move_ball_play()
		update_fielders()
		update_runners()
		if(btnp(❎)) then
			reset_players()
			g_mode="wait"
		end
	end
	
	if bat_sw!=0 then
		bat_t=bat_t+bat_sw*0.5
		if bat_t>8 then
			// bat_t draws until 4, any
			// amt after that is for 
			// delay until batter starts
			// running
			if ball_fair then
				//create runner to 1st here
				bat_sw=0
				local r=plyr("0,0",home)
				r.run=true
				r.tgidx=1
				r.tg=frst
				r.spd=21
				add(rnnrs,r)
				t1=time()
			else
				bat_sw=-1
			end
		elseif bat_t<=0 then
			bat_sw=0
		end
	end
end

function calc_pitch()
	will_sw=true
	did_cont=true
	// todo: determine if batter
	// will swing
end

function calc_no_contact()
end

function calc_contact()
	local rx=rand(-100,100)
	local rz=rand(-20,300) //todo 
	local d=dist(0,0,rx,rz)
	
	-- calc ball targ,spd,time
	ball_trg=pt(rx,0,rz)
	ball_a=atan2(
		ball.x-rx,ball.z-rz
	)
	ball_air_t=max(
		rnd(4),
		d/146
	)
	ball_air_t_m=ball_air_t
	ball_spd=d/ball_air_t
	
	--calc ball roll targ
	local bs=ball_spd
	local roll=cpt(ball_trg)
	while bs>0 do
		//local bs=ball_spd/30
		roll.x-=cos(ball_a)*bs/30
		roll.z-=sin(ball_a)*bs/30
		bs-=fric
		//loga({roll.x,roll.z,bs})
	end
	ball_r_trg=roll
	
	if ball_a>=0.125 and 
				ball_a<=0.375 then
		ball_fair=true
	end
	
	loga({
		rx,rz,
		ball_a,
		d,d/146,
		ball_air_t,
		ball_spd,
		ball_fair
	})
end

function move_ball_play()
	local bs=ball_spd/30
	ball.x-=cos(ball_a)*bs
	ball.z-=sin(ball_a)*bs
	
	local at2=ball_air_t_m/2
	ball.y=min(
		0,
		(at2-abs(ball_air_t-at2))*-10
	)
	
	ball_air_t-=1/30
	if not b_air() then
		ball_spd=max(0,ball_spd-fric)
	end
end

function b_air()
	return ball_air_t>0
end

t1=0
t2=0
function update_runners()
	for r in all(rnnrs)do
		if r.run then
			local rs=r.spd/30
			local a=atan2p(r.pos,r.tg)
			r.pos.x-=cos(a)*rs
			r.pos.z-=sin(a)*rs
		
			if distp(r.pos,r.tg)<=1 then
				//r.run=false
				t2=time()
				printh(t2-t1)
				r.bs=r.tg
				r.tgidx+=1
				r.tg=bases[r.tgidx]
			end
		end
	end
end

function update_fielders()
	--calc targ fielder
	local mind_a=30000
	local mind_r=30000
	//local a_trg,r_trg=nil,nil
	trgf_a,trgf_r=nil,nil
	trgf_an,trgf_rn="",""
	for k,f in pairs(fldrs)do
		if f.bs!=nil then
			f.tg=cpt(f.bs)
		else
			f.tg=nil
		end
		
		local ad=distp(f.pos,ball_trg)
		local rd=distp(f.pos,ball_r_trg)
		//local d=min(ad,rd)
		//local t=nil
		if ad<mind_a then
			mind_a=ad
			trgf_a=f
			trgf_an=k
			//t=ball_trg
			//a_trg=ball_trg
		end
		if rd<mind_r then
			mind_r=rd
			trgf_r=f
			trgf_rn=k
			//t=ball_r_trg
			//r_trg=ball_r_trg
		end
	end
	
	trgf_a.tg=cpt(ball_trg)
	trgf_r.tg=cpt(ball_r_trg)
	//if not b_air() or
	//			mind_r<mind_a then
	//	trgf_a.tg=cpt(ball_r_trg)
	//end
	
	local dta=distp(
		trgf_a.pos,ball_r_trg)
	local dtr=distp(
		trgf_r.pos,ball_r_trg)
		
	loga({
		"t air f", trgf_an,dta," | ",
		"t rol f", trgf_rn,dtr
	})	
	
	if not b_air() then
		if trgf_a!=trgf_r and
					dtr<dta then
			printh("jere")
			if trgf_a.bs then
				trgf_a.tg=cpt(trgf_a.bs)
			end
		end
	end
	
	//if(a_trgf)a_trgf.tg=a_trg
	//if(r_trgf)r_trgf.tg=r_trg
	
	
	for k,f in pairs(fldrs)do
		if f.tg !=nil then
			local fs=f.spd/30
			local a=atan2p(f.pos,f.tg)
			f.pos.x-=cos(a)*fs
			f.pos.z-=sin(a)*fs
			
			if distp(f.pos,f.tg)<=1 then
				//r.run=false
				
			end
		end
	end 
end


-->8
-- pov

function projp(pt)
	return proj(pt.x,pt.y,pt.z)
end

function proj(x,y,z)
	z,y,x=rot3d(
		z-camz,
		y-camy,
		x-camx,
		0,
		-cam_ya,
		-cam_pi)
						
	local dz=z*lam-lam*znear
	local dz0=max(1,dz)	
	
	local px=mid(
		-500,
		(x*fov_c)/dz0,
		500
	)
	local py=mid(
		-500,
		(y*fov_c)/dz0,
		500
	)
			
	px=-64*px+64
	py=-64*py+64
	
	return px,py,dz//,pxz,pyz
end

function rot2d(x,y,a)
	local rx=x*cos(a)-y*sin(a)
	local ry=x*sin(a)+y*cos(a)
	return rx,ry,pz
end

function rot3d(x,y,z,pi,ya,ro)
	--x axis rotation (pitch) 
	local y1,z1=rot2d(y,z,pi)
	--y axis rotation (yaw) 
	local z2,x1=rot2d(z1,x,ya)
	--z axis rotation (roll) 
	local x2,y2=rot2d(x1,y1,ro)
	
	return x2,y2,z2
end

function p_trip(p1,p2,p3,c)
	pelogen_tri(
		p1.x,p1.y,
		p2.x,p2.y,
		p3.x,p3.y,
		c)
end

function pelogen_tri(l,t,c,m,r,b,col,f)
	color(col)
	fillp(f)
	if(t>m) l,t,c,m=c,m,l,t
	if(t>b) l,t,r,b=r,b,l,t
	if(m>b) c,m,r,b=r,b,c,m
	local i,j,k,r=(c-l)/(m-t),(r-l)/(b-t),(r-c)/(b-m),l
	while t~=b do
		for t=ceil(t),min(flr(m),1024) do
			rectfill(l,t,r,t)
			r+=j
			l+=i
		end
		l,t,m,i=c,m,b,k
	end
end

-->8
--utils

function uits()
	return flr(_uits)
end

function uitf()
	return flr(_uitf)
end

function pt(x,y,z)
	if type(x)=="string" then
		x,z=unpack(split(x))
		y=0
	end
	return {x=x,y=y,z=z}
end

function cpt(pt)
	return {x=pt.x,y=pt.y,z=pt.z}
end

function rand(bot,top)
	return flr(rnd((top+1)-bot))+bot
end

function dist(x1,y1,x2,y2)
 local a0,b0=abs(x1-x2),abs(y1-y2)
 return max(a0,b0)*0.9609+min(a0,b0)*0.3984
end

function distp(p1,p2)
	return dist(p1.x,p1.z,p2.x,p2.z)
 //local a0,b0=abs(p1.x-p2.x),abs(p1.y-p2.y)
 //return max(a0,b0)*0.9609+min(a0,b0)*0.3984
end

function atan2p(p1,p2)
	return atan2(p1.x-p2.x,p1.z-p2.z)
end

-- split a table of string 
-- world points into a table 
-- of world pts
function pt_a(s)
	local vs=split(s,";")
	local out={}
	for v in all(vs)do
		add(out,pt(v))
	end
	return out
end

function plyr(sst,bs)
	if type(bs)=="string" then
		bs=pt(bs)
	end
	return {
		st=pt(sst), //start point
		bs=bs, //targ base idx
		tg=pt(0,0,0), //target
		pos=pt(0,0,0),
		t=0 //time
	}
end

--debug functions
--todo remove
function a_to_s(arr)
	local s=arr[1]
	for i=2,#arr do
		s=s.." "..tostr(arr[i])
	end
	return s
end

function loga(arr)
	printh(a_to_s(arr))
end

function pria(arr,x,y,c)
	print(a_to_s(arr),x,y,c)
end
__gfx__
000000000000000000000000000000000000000000000000004d000040dd000000dd000000ddd00000ddd0000000000000000000000000000000000000000000
000000006666666600066000000055ffffff000000000000004ddd0040dddd0000dddd0000dddd0000ddd0000000000000000000000000000000000000000000
0070070067777776066776600055ffffffffff0000000000004d900004dd900000dd900000ddd00400ddd40000ddd00000000000000000000000000000000000
000770006777777667777776055fff7777fffff00000000000499000049990000094900000999040009994000dddd00000000000000000000000000000000000
000770000677776006677660055ffffffffffff000000000024d2000024d200000242000002d240002ddd2000099920000000000000000000000000000000000
00700700006776000006600000555fffffffff000000000022922000229220000029000000d2900000ddd90002ddd20000000000000000000000000000000000
0000000000066000000000000000555fffff00000000000000dd000000dd000000dd000000dd000000ddd00000ddd00000000000000000000000000000000000
0000000000000000000000000000000000000000000000000d00d0000d00d0000d00d00000d0d00000d0d0000d000d0000000000000000000000000000000000
0000000000000000000000000000000000ddd00000ddd00000ddd00000ddd00000ddd00000ddd000000000000000000000000000000000000000000000000000
000000007777777700077000000000000dddd0000dddd00000dddd0000dddd0000dddd0000dddd0000ddd07000ddd00000ddd00000ddd0000000000000000000
0000000077777777067777700000000000999000009990000099900000999000009990000099970000dddd0000ddd0000dddd0000dddd0000000000000000000
0000000067777777677777770000000000999000009790000029970000d9900000dd970000dd9200009992000099920002999000009990000000000000000000
0000000006777770066777700000000002d7200002d2200000d22000002dd70000d2d20000d2200000dd90000099970002999000009990000000000000000000
000000000067770000067000000000000022d000002dd00000ddd00000d2200000dd200000dd0d0000d22000022dd00000ddd20002dd20000000000000000000
0000000000066000000000000000000000ddd00000ddd00000ddd00000ddd00000d0d00000d00d0000dd0d0000d0d0000000200000d020000000000000000000
0000000000000000000000000000000000d0d00000d0d00000d0d00000d0d00000d0000000d0000000d00d000000d0000000d0000000d0000000000000000000
0000000000000000000000000000000000ddd0000000000000ddd000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000dddd00000ddd00000dddd0000ddd0000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000009990000dddd00000dd900000dddd000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000999000009990000099900000d990000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000002ddd20000999000002dd200009990000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000002ddd20002ddd20002ddd000002dd0000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000ddd00002ddd20000d00d0000d2d0000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000d0d00000d0d00000d00d000d00d0000000000000000000000000000000000000000000000000000000000000000000
0d077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dd7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000dd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00070070000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00067000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00060700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00607000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000077780000aaaaa000aaaaa000aaa0000aaaaa00aaaaaaaaaaaaaaaa00aaaaa00aaaaaa0
00000000000000000000000000000000000000000000000000000000077787700aaaaaaa0aaaaaaa00aaa0000aaaaaa0aaaaaaaaaaaaaaaa0aaaaaa0aaaaaaaa
0000000000000000000000000000000000000000000000000000000077778777aaa000aaaaa00aaa0aaaa0000aa00aaa000aaa000aa000000aa00aa0aaaaaaaa
0000000000000000000000000000000000000000000000000000000077787777aa000000aa0000aa0aaa0000aaa000aa00aaaa00aaaaaa00aaa00aa0aa0aa0aa
0000000000000000000000000000000000000000000000000000000078877788aa00aaaaaa0000aa0aaa0000aaa000aa00aaa000aaaaaa00aa000aaaaa0aa0aa
0000000000000000000000000000000000000000000000000000000087777877aaa000aaaaa00aaaaaaa0000aa000aaa0aaaa000aa00000aaaaaaaaaa00000aa
0000000000000000000000000000000000000000000000000000000007778770aaaaaaa0aaaaaaa0aaaaaaaaaaaaaaa00aaa0000aaaaaaaaa0000aaaa00000aa
00000000000000000000000000000000000000000000000000000000007787000aaaaa000aaaaa00aaaaaaaaaaaaa0000aaa0000aaaaaaaaa0000aaaa00000aa
