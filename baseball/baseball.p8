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
	
	// test runners:
	// must be added in the
	// correct order
	
	local r=plyr("-64,64",thrd)
		r.run=false
		r.tgidx=4
		r.trg=home
		r.bs=home
		r.spd=21
		r.out=false
	add(rnnrs,r)
	
	local r=plyr("64,64",frst)
		r.run=false
		r.tgidx=2
		r.trg=scnd
		r.bs=scnd
		r.spd=21
		r.out=false
	add(rnnrs,r)
	
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
	
	//pria({
	//	camx,camy,camz,
	//	g_mode,
	//	ball_s,ball_a,ball_fair})
	pria({
		g_mode,
		rnnrs_done,
		fldrs_done
	})
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
		if(f==trg_f)pal(13,10)
		
		if f.throw_t>0 then
			spr(40+f.throw_t,dx-4,dy-9)
		else
			local s=36
			if(f.run)s=38
			spr(s+uits()%2,dx-4,dy-9)
		end
		pal()
		::skip_draw::
	end
end

function draw_runners()
	for r in all(rnnrs)do
		dx,dy=projp(r.pos)
		spr(52+uits()%2,dx-4,dy-5)
		if r.out then
			spr(16,dx-4,dy-5)
		end
	end
end
-->8
--game

function reset_players()
	//ptchr.pos=cpt(ptchr.st)
	//ptchr.t=0
	
	rnnrs_done=false
	fldrs_done=false
	
	bat_t=0
	bat_sw=0
	
	ball=pt(0,0,68)
	ball_m=false
	ball_a=0
	ball_air_t=0
	ball_air_t_m=0
	ball_from_bat=true
	//ball_t=0
	ball_spd=0
	ball_trg=nil
	ball_r_trg=nil
	ball_throw_d=0
	ball_fair=false
	
	for _,f in pairs(fldrs)do
		f.pos=cpt(f.st)
		f.throw_t=0
	end
	fldrs.pi.t=0
	
	trg_f=nil
	trg_f_try_c=false
	
	//bat_sw=false
	//bat_strk=false
	calc_pitch()
	
	for r in all(rnnrs)do
		//del(rnnrs,r)
		if r.out then
			del(rnnrs,r)
		else
			r.pos=cpt(r.st)
			r.run=false
		end
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
		update_runners()
		update_fielders()
		if(btnp(❎)) then
			reset_players()
			g_mode="wait"
		end
		if rnnrs_done and 
					fldrs_done then
			reset_players()
			g_mode="wait"
		end
		
		if not b_air() and
					not ball_fair then
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
				r.trg=frst
				r.bs=frst
				r.spd=21
				r.out=false
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
	printh("==contact==")
	local rx=rand(-100,100)
	local rz=rand(-20,300) //todo 
	
	//testing values
	rx,rz,s=-70,235,146.0015
	send_ball(rx,rz,s)
	
	--calc ball roll targ
	local bs=ball_spd
	local roll=cpt(ball_trg)
	while bs>0 do
		roll.x-=cos(ball_a)*bs/30
		roll.z-=sin(ball_a)*bs/30
		bs-=fric
	end
	ball_r_trg=roll
	
	if ball_a>=0.125 and 
				ball_a<=0.375 then
		ball_fair=true
	end
	
	// determine if runners
	// should go
	update_fielders()
	
	local dtca=distp(trg_f.pos,ball_trg)
	loga({#rnnrs, dtca, trg_f_try_c})
	if not trg_f_try_c or
				dtca>90 then
		calc_forced_runners()
		calc_unforced_runners()
	end
end

function send_ball(x,z,spd,delay)
	ball_trg=pt(x,0,z)
	ball_r_trg=cpt(ball_trg)
	ball_a=atan2(
		ball.x-x,ball.z-z
	)
	
	-- calc ball targ,spd,time
	
	local d=dist(ball.x,ball.z,x,z)
	if spd then
		ball_spd=spd
		ball_air_t=d/spd
	else
		ball_air_t=max(
			rnd(4),
			d/146
		)
		ball_spd=d/ball_air_t
	end
	ball_air_t_m=ball_air_t
	
	if delay then
		ball_throw_d=0.2
	end
	
	
	loga({
		"ball x:",x,"z:",z,
		"s:",ball_spd,
		//ball_a,
		//d,
		//ball_air_t,
	})
end

function move_ball_play()
	if ball_throw_d>0 then
		ball_m=false
		ball_throw_d-=1/30
		return
	end
	
	ball_m=true
	local bs=ball_spd/30
	ball.x-=cos(ball_a)*bs
	ball.z-=sin(ball_a)*bs
	
	local at2=ball_air_t_m/2
	ball.y=min(
		0,
		(at2-abs(ball_air_t-at2))*-20
	)
	
	ball_air_t-=1/30
	if not b_air() then
		ball_spd=max(0,ball_spd-fric)
		ball_from_bat=false
	end
end

function b_air()
	return ball_air_t>0
end

t1=0
t2=0
function update_runners()
	rnnrs_done=true
	local next_r=nil
	for r in all(rnnrs)do
		if r.run and not r.out then
			local rs=r.spd/30
			local a=atan2p(r.pos,r.trg)
			r.pos.x-=cos(a)*rs
			r.pos.z-=sin(a)*rs
		
			if distp(r.pos,r.trg)<=1 then
				//r.run=false
				printh("at target")
				t2=time()
				printh(t2-t1)
				
				if r.tgidx==4 then
					del(rnnrs,r)
					return
				end
				
				r.tgidx+=1
				r.st=r.bs
				r.bs=bases[r.tgidx]
				r.trg=cpt(bases[r.tgidx])
				calc_should_run(r,next_r)
			end
			next_r=r
		end
		if r.run and not r.out then
			rnnrs_done=false
		end
	end
end

function calc_should_run(r,next_r)
	r.run=true
	local dtfb=distp(
		trg_f.pos,ball)
	local drpb=distp(
		r.pos,ball)
	local drtb=distp(
		r.trg,ball)
	
	if next_r and 
				next_r.run==false then
		r.run=false
	end
	
	--hack but whatever
	if ball_from_bat then
		drpb=30000
		drtb=30000
	end
	
	loga({
		"cr",
			dtfb,drpb,drtb,
			ball_from_bat
		})
	
	if dtfb<50 or 
			 drpb<50 or
				drtb<50 then
		r.run=false
	end
end

function calc_forced_runners()
	printh("calc forced")
	if #rnnrs>0 then
		rnnrs[#rnnrs].run=true
	end
	for i=#rnnrs-1,1,-1 do
		loga({"  check ", i})
		local cr=rnnrs[i]
		local pr=rnnrs[i+1]
		if pr.bs==cr.st and 
					not pr.out then
			cr.run=true
		end
	end
end

function calc_unforced_runners()
	printh("calc unforced")
	local next_r=nil
	for i=1,#rnnrs do
		local r=rnnrs[i]
		loga({"  check",i})
		if not r.run then
			calc_should_run(r,next_r)
		end
		next_r=r
	end
end

function update_fielders()
	--calc targ fielder
	local mind_a=30000
	local mind_r=30000
	local trgf_a,trgf_r=nil,nil
	for k,f in pairs(fldrs)do
		if f.bs!=nil then
			//shouldnt need to copy this
			f.trg=f.bs 
		else
			f.trg=nil
		end
		
		local ad=distp(f.pos,ball_trg)
		local rd=distp(f.pos,ball_r_trg)
		if ad<mind_a then
			mind_a=ad
			trgf_a=f
		end
		if rd<mind_r then
			mind_r=rd
			trgf_r=f
		end
	end
	
	trgf_a.trg=ball_trg
	trg_f=trgf_a
	trg_f_try_c=true
	if not b_air() then
		trgf_a.trg=ball_r_trg
	end
	if trgf_a!=trgf_r then
		trgf_r.trg=ball_r_trg
		
		local dta=distp(
			trgf_a.pos,ball_r_trg)
		local dtr=distp(
			trgf_r.pos,ball_r_trg)

		if dtr<dta then
			trg_f=trgf_r
			trg_f_try_c=false
			if trgf_a.bs then
				trgf_a.trg=trgf_a.bs
			end
		end
	end
	
	if ball_spd==0 then
		trg_f.trg=ball
	end
	
	-- move fielders
	for k,f in pairs(fldrs)do
		f.run=false
		if f.trg !=nil then
			if distp(f.pos,f.trg)>1 then
				f.run=true
				local fs=f.spd/30
				local a=atan2p(f.pos,f.trg)
				f.pos.x-=cos(a)*fs
				f.pos.z-=sin(a)*fs
			end
			
			if ball_m and
						distp(f.pos,ball)<3 and 
						ball.y>-4 then
				loga({"ball catch", k})
				ball_catch()
			end
		end
		
		if f.throw_t>0 then
			f.throw_t+=0.3
			if f.throw_t>4 then
				f.throw_t=0
			end
		end
	end 
end

function ball_catch()
	local thrower=trg_f
	local close_d=30000
	local close_r=nil
	
	if ball_from_bat then
		printh("caught from air")
		loga({ball.y})
		//todo
		//del(rnnrs,rnnrs[#rnnrs])
		if ball_fair and #rnnrs>0 then
			rnnrs[#rnnrs].out=true
		end
		calc_unforced_runners()
	else
		printh("caught from grnd or throw")
	end
	
	for r in all(rnnrs)do
		if not r.run or r.out then
			goto skip_rnnr
		end
		local drt=distp(
			r.pos,r.trg)
		local dtf=distp(
			trg_f.pos,r.trg)
		if dtf<1 and drt>1 then
			printh("runner thrown out")
			r.out=true
		elseif dtf<close_d then
			close_d=dtf
			close_r=r
		end		
	end
		
	::skip_rnnr::
	
	if not close_r then
		printh("no viable runners")
		fldrs_done=true
		return
	end		
	
	if pteq(close_r.bs,trg_f.trg) then
		// this is a hack. if the
		// runners trg is the same as
		// the fielders run to trg,
		// we "throw" the ball to
		// that trg at the same speed
		// as the fielders run speed.
		// this triggers a throw anim
		// which i should fix at some
		// point
		send_ball(
			close_r.trg.x,
			close_r.trg.z,
			trg_f.spd, false)
	else
		send_ball(
			close_r.trg.x,
			close_r.trg.z,
			100, true)
		trg_f.throw_t=0.1
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

function pteq(p1,p2)
	return p1.x==p2.x and
								p1.y==p2.y and
								p1.z==p2.z
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
		trg=pt(0,0,0), //target
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
00000000000000000000000000000000000ddd00000ddd00000ddd00000ddd00000ddd00000ddd00000000000000000000000000000000000000000000000000
08000800777777770007700000000000000dddd0000dddd000dddd0000dddd0000dddd0000dddd00070ddd00000ddd00000ddd00000ddd000000000000000000
0080800077777777067777700000000000099900000999000009990000099900000999000079990000dddd00000ddd00000dddd0000dddd00000000000000000
0008000067777777677777770000000000099900000979000079920000099d000079dd000029dd00002999000029990000099920000999000000000000000000
0080800006777770066777700000000000027d2000022d2000022d00007dd200002d2d0000022d000009dd000079990000099920000999000000000000000000
08000800006777000006700000000000000d2200000dd200000ddd0000022d000002dd0000d0dd0000022d00000dd220002ddd000002dd200000000000000000
00000000000660000000000000000000000ddd00000ddd00000ddd00000ddd00000d0d0000d00d0000d0dd00000d0d000002000000020d000000000000000000
00000000000000000000000000000000000d0d00000d0d00000d0d00000d0d0000000d0000000d0000d00d00000d0000000d0000000d00000000000000000000
0000000000000000000000000000000000ddd0000000000000ddd0000000000000ddd00000ddd000000000000000000000000000000000000000000000000000
000000000000000000000000000000000dddd00000ddd00000dddd0000ddd00000dddd0000d2dd0000ddd00000ddd00000000000000000000000000000000000
00000000000000000000000000000000009990000dddd0000099900000dddd00009990000092900000dddd0000dddd0000000000000000000000000000000000
00000000000000000000000000000000009990000099900000999000009990000099900000929000009920000099900000000000000000000000000000000000
0000000000000000000000000000000002ddd20000999000002dd20000999000002d2000002dd000009290000299900000000000000000000000000000000000
0000000000000000000000000000000002ddd20002ddd20002ddd000002dd00000d2d00000ddd000002dd0000022d00000000000000000000000000000000000
0000000000000000000000000000000000ddd00002ddd20000d00d0000d2d00000ddd00000d00d0000ddd00000dd200000000000000000000000000000000000
0000000000000000000000000000000000d0d00000d0d00000d00d000d00d00000d0d00000d00d000d00d0000d00d00000000000000000000000000000000000
0d07700000000000000000000000000000ccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dd700000000000000000000000000000cccc0000ccc00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000dd0000000000000000000000000000cc900000cccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000
000700700000000000000000000000000099900000c9900000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077700000000000000000000000000006cc6000099900000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006700000000000000000000000000006ccc000006cc00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0006070000000000000000000000000000c00c0000c6c00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0060700000000000000000000000000000c00c000c00c00000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
