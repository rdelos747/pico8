pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- nuclear semiotics

--[[
make update to how rad poison
works:
- player should want to leave
		poison area, they should not
		be able to just tank their
		way through:
		- make rp rise and fall faster
		- 
]]--

ppx,ppy,ppz=0,-8,-12
pp_pi,pp_ya=0,0
pp_rp=0 --rad poisoning temp
pp_rp2=0 --rad poisoning perm

camx,camy,camz=0,0,0
cam_ya,cam_pi=0,0
cam_d=0
cam_h=0

sunx,suny,sunz=0,0,0

fov=0.11
fov_c=-2.778 //1/tan(fov/2)
zfar=500
znear=-14
lam=zfar/(zfar-znear)

//secs={}
areas={}
secsz=100
sex,sez=0,0
//secr=2 --render radius for sectors
secm=9 --map width in sectors

d_mode=0
mode=0
cur_term=nil
t_idx_x=0 	--term idx left/right
t_idx_y=-1 --term idx up/down
t_pr_t=0 --term press time

alert=nil

function _init()
	printh("====== init ======")
	
	for t in all(hand_tris)do
		add(t,{5,nil})
	end
	hand=obj(
		hand_tris,
		0,0,0,
		0,0,0,
		0,0,
		nil)
		
	srand(2)

	areas={}
	//add_me_area(0,500,2)
	add_st_area(0,0)
	//add_me_area(-111,-700,2)
	
	srand(time())
end

function _draw()
	secr=2
	//if l_num_o>25 then
		//secr=1
	//end
	
	if d_mode==1 then
		draw_top_down()
		return
	elseif d_mode==2 then
		draw_full_map()
		return
	end
	
	if mode==0 then
		draw_pov()
	elseif mode==1 then
		draw_term()
	end
end

function draw_pov()
	cls(7)
	camera(0,0)
	
	local gh=64+pp_pi*1024
	gh=mid(0,gh,128)
	rectfill(0,gh,127,gh+127,15)
	
	//n_t_sort=0
	t_sorted_ll=nil
	nos=0
	
	proj_spr(
		obj(
			draw_sun,
			sunx,suny,sunz,
			0,0,0,0,0,
			nil
		)
	)
	
	proj_secs(secr,"sp")
	proj_secs(1,"sh")
	proj_secs(1,"sy")
	proj_secs(1,"tr")
	
	draw_sorted()
	
	for i=1,pp_rp do
		pset(
			rand(0,127),
			rand(0,127),
			2)
	end
	for i=1,pp_rp2 do
		pset(
			rand(0,127),
			rand(0,127),
			0)
	end
	
	if alert then
		print(
			alert,
			64-#alert*2.5,
			80,
			11)
	end
	
	pria({tsa},0,0,5)
	pria({nos},0,6,5)
	pria({ppx,ppz},0,12,5)
	//print(pp_ya,0,12,5)
	//print(num_o,0,18,8)
	//pria({"rp",pp_rp},0,24,3)
	//pria({"rp2",pp_rp2},0,30,3)
end

function proj_secs(r,k)
	//local povx=round(sex+1*sin(pp_ya))
	//local povz=round(sez+1*cos(pp_ya))
	
	for a in all(areas)do
	local asx=flr(a.x/secsz)
	local asz=flr(a.z/secsz)
	local povx=round(
		(sex-asx)+1*sin(pp_ya))
	local povz=round(
		(sez-asz)+1*cos(pp_ya))
		
	//local jmin=max(0,
	//loga({povx,povz})
	if k!="sp" and 
				(abs(povx)>2 or 
				abs(povz)>2) then
		return
	end
			
	local jmin=max(0,povz-2)
	local jmax=min(max(0,povz+2),a.ws)
	local imin=max(0,povx-2)
	local imax=min(max(0,povx+2),a.ws)
	
	for j=jmin,jmax do
	for i=imin,imax do
	for o in all(a.secs[j][i][k]) do
		sx,sy,dz=proj(o.x,o.y,o.z)

		if on_scr_x(sx) then
			proj_obj(
				o,
				k=="sp" and 
					i!=sex and 
					j!=sez
			)
		end
	end end end end
end

function draw_top_down()
	cls(0)
	local scz10=secsz/10
	local nd=0
	local pmx=ppx/scz10
	local pmz=ppz/scz10

	camera(pmx-64,pmz-64)

	for a in all(areas)do
		local asx=flr(a.x/secsz)
		local asz=flr(a.z/secsz)
		local povx=round(
			(sex-asx)+1*sin(pp_ya))
		local povz=round(
			(sez-asz)+1*cos(pp_ya))
			--[[
		local jmin=max(0,povz-secr)
		local jmax=mid(1,povz+secr,a.ws)
		local imin=max(0,povx-secr)
		local imax=mid(1,povx+secr,a.ws)
		]]--
		local jmin=max(0,povz-2)
		local jmax=min(max(0,povz+2),a.ws)
		local imin=max(0,povx-2)
		local imax=min(max(0,povx+2),a.ws)
		//loga({jmin,jmax,imin,imax})
		for j=jmin,jmax do
		for i=imin,imax do
			rect(
				i*secsz/scz10+a.x/scz10,
				j*secsz/scz10+a.z/scz10,
				i*secsz/scz10+a.x/scz10+scz10,
				j*secsz/scz10+a.z/scz10+scz10,
				(i==povx and j==povz)and 13 or 1)
			for o in all(a.secs[j][i].sp) do
				local c=6
				sx,sy,dz=proj(o.x,o.y,o.z)
			 if on_scr(sx,sy)then
			 	c=12
			 	nd+=1
			 end
				rect(
					(o.x/scz10)-1,(o.z/scz10)-1,
					(o.x/scz10)+1,(o.z/scz10)+1,
					c
				)
			end
			for r in all(a.secs[j][i].rs) do
				pset(r.x/scz10,r.z/scz10,11)
				circ(r.x/scz10,r.z/scz10,r.r/scz10,11)
			end
		end end 
	end
		
		//spr(1,ppx-4,ppz-4)
	pset(pmx,pmz,8)
		
	line(
		pmx,pmz,
		pmx-cos(pp_ya+0.75)*40,
		pmz+sin(pp_ya+0.75)*40,
		9)
		
	pria({ppx,ppz},
		pmx-64,pmz-64,8)
	pria({sex,sez},
		pmx-64,pmz-58,8)
	print(
		"a "..pp_ya,
		pmx-64,pmz-52,8)
	pria({"num",nd},
		pmx-64,pmz-46,8)
	pria({"rp",pp_rp},
		pmx-64,pmz-40,3)
	pria({"rp2",pp_rp2},
		pmx-64,pmz-34,3)
end

function draw_full_map()
	//local w=0
	//local h=0
	cls()
	camera(-64,-64)
	for a in all(areas)do
		for j=1,a.ws do
		for i=1,a.ws do
			for o in all(a.secs[j][i].sp)do
				pset(o.x/100,o.z/100,5)
			end
		end end
	end
end

function draw_term()
	cls(1)
	camera(0,0)
	//spr(41,60,60,2,2)
	
	rectfill(10,10,118,50,0)
	
	t_sorted_ll=nil
	nos=0
	
	for i=-1,1 do
		for j=0,1 do	
			spr(115,56+34*i,57+20*j,2,1)
			spr(66,52+34*i,60+20*j)
			spr(69,68+34*i,60+20*j)
		
		--[[
			spr(115,56+34*i,77,2,1)
			spr(66,52+34*i,80)
			spr(69,68+34*i,80)
			]]--
		
			rectfill(
				52+34*i,68+20*j,
				75+34*i,70+20*j,
				5)
			
			local off=0
			if i==t_idx_x and
						(
							(j==0 and t_idx_y==-1) or
							(j==1 and t_idx_y==1)
						)then
				off=(1-abs(t_pr_t-5)/5)*2
			end
			spr(
				64+32*j,
				56+34*i,
				//60+(t_idx_y==-1 and off or 0),
				60+20*j+off,
				2,2)
			--[[
			spr(
				96,
				56+34*i,
				80+(t_idx_y==1 and off or 0),
				2,2)
				]]--
		
			spr(115,56+34*i,71+20*j,2,1)
			spr(114,52+34*i,71+20*j)
			spr(117,68+34*i,71+20*j)
		
		--[[
			spr(115,56+34*i,92,2,1)
			spr(114,52+34*i,92)
			spr(117,68+34*i,92)
			]]--
		end
		
		local s=cur_term.inpt[i+2]
		local o=symb(10*i,-10,40,s)
		proj_obj(
			o,
			false,
			false
		)
	end
	
	proj_obj(hand,false)
	
	draw_sorted()
end

function _update()
 alert=nil
 if mode==1 then
 	update_term()
 	return
 end
 
	//if(btnp(❎))d_mode=(d_mode+1)%3
	
	update_player()
	update_cam()
	
	sunx=ppx-1000
	sunz=ppz
	suny=-100
	
	sex=flr(ppx/secsz)
	sez=flr(ppz/secsz)
end
-->8
-- pov

function proj_spr(s)
	local px,py,dz=proj(
		s.x,s.y,s.z)
	if px<0 or px>127 or
				py<0 or py>127 then
		dz=0
	end
	sort_tri(
		{s.tris,{px,py}},s,dz)
	
	//add(tt,dz,1)
	//add(tt,col,2)
	//add(
	//	t_sorted,
	//	{dz,nil,s.tris,{px,py}}
	//)
end

--[[
sorting all of the symbol tris
is causing a huge slow down.
it should be possible to project
the symbol tris all at once
]]--

function proj_obj(o,f)
	local ts={}
	//local dz_max_all=-1
	local flat_max=-1
	for t in all(o.tris)do
		local pts={} --projected pts
		local dz_max=-1
		for i=1,3 do
			x,y,z=rot3d(
				t[i][1],
				t[i][2],
				t[i][3],
				0,
				0,
				o.ro)
			x,y,z=rot3d(
				x,y,z,
				o.pi,
				o.ya,
				0)
			
			local px,py,dz=proj(
				x+o.x,y+o.y,z+o.z)
			--[[
			if px<-20 or px>147 or
						py<-20 or py>147 then
				dz=0
			end
			]]--
			if(not on_scr_y(py))dz=0
			//loga({px,py,dz})
			//if 
			dz_max=max(dz_max,dz)
			add(pts,{px,py})
		end
		
		--[[
		local i=1
		while i<#ts do
			//if dz_max>dz_max_all then
			//end
			if i
			i+=1
		end
		]]--
		//loga({" ",dz_max})
		local i=1
		while i<=#ts+1 do
			//loga({i,#ts})
			if i>#ts or
						dz_max>ts[i][3] then
				add(ts,{pts,t[4],dz_max},i)
				i=#ts+2
			end
			i+=1
		end
		
		//sort_tri(pts,t[4],dz_max)
	end
	
	//printh(#ts)
	
	--[[
	todo:
	change f to be a number of
	faces to render. at farther
	distances render less faces
	]]--

	//f=false
	local imin=1
	if(f)imin=#ts-1
	for i=max(1,imin),#ts do
		local t=ts[i]
		sort_tri(t[1],t[2],t[3])
	end
end

--[[
	inserts 2 infos:
	1:z dist (highest of all pts in tri or sprite)
	2:color (or sprite obj if sprite)
	3..: existing info shifted
]]--
function sort_tri(tt,col,dz)
	//if dz>1 and dz<zfar then
	if dz>1 then
		nos+=1
		//
		//add(
		//	tt,
		//	flat and "flat" or col
		//)
		//add(tt,dz)
		//tt.nxt=nil
		local newn={
			tri=tt,
			col=col,
			dz=dz,
			nxt=nil,
			prv=nil
		}
		
		//n_t_sort+=1
		if t_sorted_ll==nil then
			t_sorted_ll=newn
			return
		end
		
		local node=t_sorted_ll
		while node!=nil do
			//i+=1
			if dz>node.dz then
				if node.prv then
					node.prv.nxt=newn
				else
					t_sorted_ll=newn
				end
				newn.prv=node.prv
				newn.nxt=node
				node.prv=newn
				return
			end
			if node.nxt==nil then
				node.nxt=newn
				newn.prv=node
				return
			end
			node=node.nxt
		end
		
		printh("node not added")
		alert="oops"
	end
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

--[[
	hack for sprites:
	when creating sprites, we set
	the "tris" field to its 
	render function. when the sort
	function is called, the data
	is shifted, and t[3] is either
	the existing tris, or the 
	render function
]]--

function draw_sorted()
	tsa=0
	local node=t_sorted_ll
	while node!=nil do
		
		if type(node.tri[1])=="function" then
			//draw_sprite(t)
			node.tri[1](node.tri)
		else
			tsa+=1
			draw_tri(
				node.tri,
				node.col[1],
				node.col[2]
			)
		end
		node=node.nxt
	end
end

--[[
function draw_sorted()
	//sortdz(t_sorted)
	tsa=0
	for t in all(t_sorted)do
		if type(t[1])=="function" then
			//draw_sprite(t)
			t[1](t)
		elseif t[#t-1]=="flat" then
			loga({"xxx",#t})
			for i=1,#t-2 do
				//loga({"here",type(tf)})
				//
				local tf=t[i]
				loga({#tf[1],type(tf[2])})
				draw_tri(tf[1],tf[2][1],nil)
			end
		else
			tsa+=1
			draw_tri(t,t[4][1],t[4][2])
			//print(
			//	t[1],
			//	t[3][1],
			//	t[3][2],
			//	tsa%2==0 and 8 or 11)
		end
	end
end
]]--

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

function draw_tri(t,c,f)
	pelogen_tri(
	 t[1][1],t[1][2],
	 t[2][1],t[2][2],
	 t[3][1],t[3][2],
	 c,f)
	//p01_335(
	//	t[3][1],t[3][2],
	//	t[4][1],t[4][2],
	//	t[5][1],t[5][2],
	//	c,f
	//)
	//fillp()
end

function pelogen_tri(l,t,c,m,r,b,col,f)
	//poke(0x5f34, 0x3)
	color(col)
	fillp(f)
	
	if(t>m) l,t,c,m=c,m,l,t
	if(t>b) l,t,r,b=r,b,l,t
	if(m>b) c,m,r,b=r,b,c,m
	local i,j,k,r=(c-l)/(m-t),(r-l)/(b-t),(r-c)/(b-m),l
	while t~=b do
		for t=ceil(t),min(flr(m),128) do
			rectfill(l,t,r,t)
			r+=j
			l+=i
		end
		l,t,m,i=c,m,b,k
	end
end

function sortdz(a)
 for i=1,#a do
  local j=i
  while j>1 and a[j-1][1]>a[j][1] do
   a[j],a[j-1]=a[j-1],a[j]
   j=j-1
  end
 end
end

--[[
function p01_335(x0,y0,x1,y1,x2,y2,col)
 color(col)
 if(y1<y0)x0,x1,y0,y1=x1,x0,y1,y0
 if(y2<y0)x0,x2,y0,y2=x2,x0,y2,y0
 if(y2<y1)x1,x2,y1,y2=x2,x1,y2,y1
 if max(x2,max(x1,x0))-min(x2,min(x1,x0)) > y2-y0 then
  col=x0+(x2-x0)/(y2-y0)*(y1-y0)
  p01_trapeze_h(x0,x0,x1,col,y0,y1)
  p01_trapeze_h(x1,col,x2,x2,y1,y2)
 else
  if(x1<x0)x0,x1,y0,y1=x1,x0,y1,y0
  if(x2<x0)x0,x2,y0,y2=x2,x0,y2,y0
  if(x2<x1)x1,x2,y1,y2=x2,x1,y2,y1
  col=y0+(y2-y0)/(x2-x0)*(x1-x0)
  p01_trapeze_w(y0,y0,y1,col,x0,x1)
  p01_trapeze_w(y1,col,y2,y2,x1,x2)
 end
end
function p01_trapeze_h(l,r,lt,rt,y0,y1)
 lt,rt=(lt-l)/(y1-y0),(rt-r)/(y1-y0)
 if(y0<0)l,r,y0=l-y0*lt,r-y0*rt,0
 y1=min(y1,128)
 for y0=y0,y1 do
  rectfill(l,y0,r,y0)
  l+=lt
  r+=rt
 end
end
function p01_trapeze_w(t,b,tt,bt,x0,x1)
 tt,bt=(tt-t)/(x1-x0),(bt-b)/(x1-x0)
 if(x0<0)t,b,x0=t-x0*tt,b-x0*bt,0
 x1=min(x1,128)
 for x0=x0,x1 do
  rectfill(x0,t,x0,b)
  t+=tt
  b+=bt
 end
end
--]]
-->8
-- player

function update_cam()
	cam_ya=-pp_ya
	cam_pi=pp_pi
	
	dcy,dcz=rot2d(
		cam_h,cam_d,-cam_pi)
	dcz,dcx=rot2d(
		dcz,0,-cam_ya)
	
	camz=ppz+dcz
	camx=ppx+dcx
	camy=ppy+dcy
end

function update_player()
	if(btn(➡️))pp_ya-=0.01
	if(btn(⬅️))pp_ya+=0.01
	pp_ya=pp_ya%1
	
	local ppv=0
	if btn(❎) then
		if btn(⬇️) then
			pp_pi=max(-0.20,pp_pi-0.01)
		elseif btn(⬆️) then
			pp_pi=min(0.20,pp_pi+0.01)
		end
	else
		pp_pi=0
		if(btn(⬇️))ppv=1
		if(btn(⬆️))ppv=-1
	end
	
	dx,dy,dz=rot3d(
		0,0,ppv,
		pp_pi,
		pp_ya,
		0)
	
	dx*=2
	dz*=2
	
	local touch_r=false
	local po={x=ppx,z=ppz,w=8,d=8}
	local can_x,can_z=true,true
	
	for a in all(areas)do
	local asx=flr(a.x/secsz)
	local asz=flr(a.z/secsz)
	local povx=sex-asx
	local povz=sez-asz
		
	local jmin=max(0,povz-2)
	local jmax=min(max(0,povz+2),a.ws)
	local imin=max(0,povx-2)
	local imax=min(max(0,povx+2),a.ws)
	
	for j=jmin,jmax do
	for i=imin,imax do
		local sec=a.secs[j][i]
		
		-- check spike collision
		for o in all(sec.sp)do
			if(col_bb(po,o,-dx,0))can_x=false
			if(col_bb(po,o,0,-dz))can_z=false
		end
		
		-- check radiation
		for r in all(sec.rs)do
			local d=dist(ppx,ppz,r.x,r.z)
			if d<=r.r then
				touch_r=true
				pp_rp+=((r.r-d)/r.r)*2
			end
		end
		
		-- check term
		for t in all(sec.tr)do
			local d=dist(ppx,ppz,t.x,t.z)
			if d<15 do
				alert="❎ interact"
				if btnp(❎) then
					mode=1
					cur_term=t
				end
			end
		end
	end end end
	
	if touch_r and pp_rp>=100 then
		pp_rp=100
		pp_rp2+=1
	elseif not touch_r then
		pp_rp=max(0,pp_rp-0.5)
	end
	
	if(can_x)ppx-=dx
	if(can_z)ppz-=dz
	//ppy-=dy
end

function update_term()
	cam_ya=0
	cam_pi=0
	
	//dcy,dcz=rot2d(
	//	cam_h,cam_d,-cam_pi)
	//dcz,dcx=rot2d(
	//	dcz,0,-cam_ya)
	
	camz=0
	camx=0
	camy=0
	
	hand.ro=0.1
	hand.ya=0.05
	hand.pi=0.05
	
	if(btnp(🅾️))mode=0
	if btnp(⬅️) then
		t_idx_x=max(-1,t_idx_x-1)	
	elseif btnp(➡️) then
		t_idx_x=min(1,t_idx_x+1)
	end
	
	if btnp(⬆️) then
		t_idx_y=-1
	elseif btnp(⬇️) then
		t_idx_y=1
	end
	
	if btnp(❎) then
		t_pr_t=10
		local val=cur_term.inpt[t_idx_x+2]
		val=mid(
			1,
			9,
			val+t_idx_y)
		printh(inpt)
		cur_term.inpt[t_idx_x+2]=val
	end
	
	if t_pr_t>0 then
		t_pr_t-=1
	end
	
	hand.x=2.7*t_idx_x+4.2
	
	local off=1-abs(t_pr_t-5)/5
	hand.y=t_idx_y+3+0.5*off
end
-->8
-- helpers

function obj(tris,x,y,z,ya,pi,ro,w,d,up)
	local o={
		tris=tris,
		x=x,y=y,z=z,
		ya=ya,pi=pi,ro=ro,
		w=w,d=d, --width/depth
		scrx=-1,scry=-1,
		update=up
	}
	return o
end

function rand(bot,top)
	return flr(rnd((top+1)-bot))+bot
end

function round(n)
	if n-flr(n)>=0.5 then
		return flr(n)+1
	end
	return flr(n)
end

function col_bb(a,b,aox,aoz)
	local ax=(a.x+aox)-a.w/2
	local az=(a.z+aoz)-a.d/2
	local bx=(b.x)-b.w/2
	local bz=(b.z)-b.d/2
	
	return ax<=bx+b.w and
								ax+a.w>=bx and 
								az<=bz+b.d and
								az+a.d>=bz
end

function on_scr_x(x)
	return x>-20 and 
								x<148 
end

function on_scr_y(y)
	return y>-50 and 
								y<178
end

function on_scr(x,y)
	return on_scr_x(x) and 
								on_scr_y(y)
end

function dist(x1,y1,x2,y2)
 local a0,b0=abs(x1-x2),abs(y1-y2)
 return max(a0,b0)*0.9609+min(a0,b0)*0.3984
end

--debug functions
--todo remove
function a_to_s(arr)
	local s=arr[1]
	for i=2,#arr do
		s=s.." "..arr[i]
	end
	return s
end

function loga(arr)
	printh(a_to_s(arr))
end

function pria(arr,x,y,c)
	print(a_to_s(arr),x,y,c)
end
-->8
-- models
hand_tris={
	{ --arm 1
		{-1.5,2.5,0},
		{-1.5,8,0},
		{1.5,2.5,0}
	},
	{ --arm 2
		{1.5,2.5,0},
		{-1.5,8,0},
		{1.5,8,0},
	},
	{ --palm 1
		{-2,0,0},
		{2,0,0},
		{-1.5,2.5,0},
	},
	{ --palm 2
		{2,0,0},
		{1.5,2.5,0},
		{-1.5,2.5,0},
	},
	{ --thumb 1
		{-1.5,2.5,0},
		{-1.5,1,0},
		{-2.5,-1,0},
	},
	{ --thumb 2
		{-1.5,2.5,0},
		{-2.5,-1,0},
		{-2.8,0.5,0},
	},
	{ --index 1
		{-2,0,0},
		{-2.2,-2,0},
		{-1.2,-2,0},
	},
	{ --index 2
		{-2,0,0},
		{-1.2,-2,0},
		{-1.2,0,0},
	},
	{ --index 3
		{-2.2,-2,0},
		{-1.2,-2,0},
		{-1.7,-4.5,1},
	},
	{ --middle 1
		{-1,0,0},
		{-1,-2,0},
		{0,-2,0}
	},
	{ --middle 2
		{-1,0,0},
		{0,-2,0},
		{0,0,0}
	},
	{ --ring 1
		{0,0,0},
		{0.2,-1.8,0},
		{1,-1.8,0}
	},
	{ --ring 2
		{0,0,0},
		{1,-1.8,0},
		{1,0,0}
	},
	{ --pinky 1
		{1,0,0},
		{1.2,-1.6,0},
		{2,-1.6,0}
	},
	{ --pinky 2
		{1,0,0},
		{2,-1.6,0},
		{2,0,0}
	}
}

function spike(x,z,s_num,dr)
	rx,rz=rand(-40,40),rand(-40,40)
	
	local s=nil
	if s_num>-1 then
		if(dr==nil)dr=rand(1,4)
		local sya=0
		if(dr==1)rx,rz,sya=-10,0,-0.25
		if(dr==2)rx,rz,sya=10,0,0.25
		if(dr==3)rx,rz=0,-10
		if(dr==4)rx,rz,sya=0,10,0.5
		
		local sxo,szo=0,0
		if dr<3 then
			sxo=2*sgn(rx)
		else
			szo=2*sgn(rz)
		end
		
		s=symb(
			x+rx+sxo,-30,z+rz+szo,s_num)
		s.ya=sya
	end
	
	local sp_tris={
		{ -- west face
			{-10,0,-10},
			{-10,0,10},
			{rx,-100,rz},
			{1,}
		},
		{ -- east face
			{10,0,10},
			{10,0,-10},
			{rx,-100,rz},
			{0,nil}
		},
		{ -- north face
			{10,0,-10},
			{-10,0,-10},
			{rx,-100,rz},
			{0,nil}
		},
		{ --south face
			{-10,0,10},
			{10,0,10},
			{rx,-100,rz},
			{1,nil}
		}
	}
	local sh_tris={
		{
			{-50,0,-10},
			{-50,0,10},
			{50,0,0},
			{5,nil}
		}
	}
	
	local o_sp=obj(
		sp_tris,
		x,0,z,
		0,0,0,
		20,20,
		nil
	)
	local o_sh=obj(
		sh_tris,
		x+60,0,z,
		0,0,0,
		0,0,
		nil
	)
	return o_sp,o_sh,s
end

function term(x,z)
	local t_tris={
		{--scr 1
			{-2,-4,-5},{2,-4,-5},{2,-8,-5},
			{2,nil}
		},
		{--scr 2
			{-2,-4,-5},{-2,-8,-5},{2,-8,-5},
			{2,nil}
		},
		{--front 1
			{-4,0,-4},{4,0,-4},{4,-10,-4},
			{1,nil}
		},
		{--front 2
			{-4,0,-4},{-4,-10,-4},{4,-10,-4},
			{1,nil}
		},
		{--back 1
			{-4,0,4},{4,0,4},{4,-10,4},
			{13,nil}
		},
		{--back 2
			{-4,0,4},{-4,-10,4},{4,-10,4},
			{13,nil}
		},
		{--left 1
			{-4,0,-4},{-4,0,4},{-4,-10,-4},
			{13,nil}
		},
		{--left 2
			{-4,0,4},{-4,-10,4},{-4,-10,-4},
			{13,nil}
		},
		{--right 1
			{4,0,-4},{4,0,4},{4,-10,-4},
			{1,nil}
		},
		{--right 2
			{4,0,4},{4,-10,4},{4,-10,-4},
			{1,nil}
		},
	}
	local sh_tri={
		{
			{-10,0,-4},
			{-10,0,4},
			{10,0,0},
			{5,nil}
		}
	}
	local o_sh=obj(
		sh_tri,
		x+14,0,z,
		0,0,0,
		0,0,
		nil
	)
	local o_term=obj(
		t_tris,
		x,0,z,
		0,0,0,
		5,5,
		nil
	)
	o_term.inpt={
		3,3,3
	}
	return o_term,o_sh
end

function draw_sun(s)
	circfill(s[2][1],s[2][2],10,9)
end

function symb(x,y,z,n)
	//printh(n)
	local tri={
		{-1,-1,0},
		{1,-1,0},
		{0,1,0},
		{9,nil}
	}
	
	local tris={}
	for c=1,min(n,4) do
		add(tris,symb_tri(-0.25*c+0.25))
	end
	
	if n>4 then
	for c=1,4 do
		add(
			tris,
			symb_tri(
				-0.25*c+0.125,
				n>=c+5
			)
		)
	end end
	
	local o=obj(
		tris,
		x,y,z,
		0,0,0,
		0,0,
		nil
	)
	return o
end

function symb_tri(a,l)
	local tri={
		{-1,-4,0},
		{1,-4,0},
		{0,l==true and 0 or -2,0},
		{9,nil}
	}
	for i=1,3 do
		local x,y=rot2d(
			tri[i][1],tri[i][2],a)
			tri[i][1]=x
			tri[i][2]=y
		end
	return tri
end

function add_st_area(x,z)
	local secs={}
	secs[0]={}
	secs[0][0]={
		sp={},sh={},rs={},sy={},tr={}
	}
	local sps={
		{-30,0,5,3},
		{0,20,1,3},
		{30,0,6,3},
		{60,0,4,3},
	}
	for pt in all(sps)do
		local rx=pt[1]+x
		local rz=pt[2]+z
		//local symb_n=pt[3]
		local sp,sh,sy=spike(
			rx,rz,pt[3],pt[4])
		add(secs[0][0].sp,sp)
		add(secs[0][0].sh,sh)
		add(secs[0][0].sy,sy)
	end
	
	local term,t_sh=term(0,0)
	add(secs[0][0].tr,term)
	add(secs[0][0].sh,t_sh)
	
	add(areas,{
		x=x,z=z,
		ws=0, --width of area in sectors
		secs=secs
	})
end

function add_me_area(x,z,ws)
	local symbs={}
	for i=1,3 do
		symbs[i]={
			rand(0,ws),
			rand(0,ws),
			rand(1,9)
		}
		loga({
			"symb",
			symbs[i][1],
			symbs[i][2],
			symbs[i][3],
		})
	end
	
	local secs={}
	for j=0,ws do
		secs[j]={}
		for i=0,ws do
			secs[j][i]={
				sp={},sh={},rs={},sy={}
			}
			for k=1,1 do
				local symb_n=-1
				for sm in all(symbs)do
					if j==sm[2] and i==sm[1] then
						symb_n=sm[3]
					end
				end
				
				local rx=rand(0,secsz)+i*secsz+x
				local rz=rand(0,secsz)+j*secsz+z
				local sp,sh,sy=spike(rx,rz,symb_n)
				add(secs[j][i].sp,sp)
				add(secs[j][i].sh,sh)
				//local symb=symb(rx-10,-10,rz,1)
				add(secs[j][i].sy,sy)
			end
			local nrs=rand(1,3)
			for k=1,nrs do
			//temp removed for test
			--[[
				add(secs[j][i].rs,
					{
						x=rand(0,secsz)+i*secsz,
						z=rand(0,secsz)+j*secsz,
						r=rand(20,30)
					})
				]]--
			end
		end
	end
	
	add(areas,{
		x=x,z=z,
		ws=ws, --width of area in sectors
		secs=secs
	})
end
__gfx__
00000000009999000000000000000000000000000000005555500000000000555550000000000000000000000000000000000000000000000000000000000000
00000000090000900000000000000000000000000000555555550000000055555555000000009000000900000000000000000000000000000000900000090000
00700700900990090000000000000000000000000005555555555000000555555555500000099000000990000000000000000000000000000009900000099000
00077000909009090000000000000000000000000055555555555000005555555555500000999900009999000000000000000000000000000099990000999900
00077000909009090000000000000000000000000055550000000600005555000000060009999900009999900000006600000000000000000999990000999990
00700700900990900000000000000000000000000055500000000600005550000000060009999900009999900000000000000000000000000999990000999990
00000000090000000000000000000000000000000055000000000600005500000000060099999009900999990000000000000000000000009999900990099999
00000000009999900000000000000000000000000055066606660600005500600060060000000099990000000000000000000000000000000000009999000000
00000000000000000666666000000000000000000050006000600600005006660666060000000099990000000000000044444444444444440000009999000000
00000000000000006000000600000000000000000060000060000600006000006000060000000009900000000000000040000000000000040000000990000000
00000000000000006066066600000000000000000006600060006600000600000000060000000000000000000000000040009000000900040000000000000000
00000000000000006007007600000000000000000006060000060600000600066600060000000099990000000000000040099900009990040000009999000000
00000000000000006000000600000000000000000006006666600600000600600060060000000999999000000000000040099990099990040000099999900000
00000000000000000607777600000000000000000000600000006000000060666660600000009999999900000000000040099909909990040000999999990000
00000000000000000600000600000000000000000000600000006000000060000000600000009999999900000000000040000009900000040000999999990000
00000000000000000066666000000000000000000000066666660000000006666666000000000099990000000000000040000000000000040000009999000000
00010000000700000007000000070000000700000007000000070000000700000007000000070000000700000000000040000009900000040000000000000000
01010100000000000000000000000000000000000700070007070700070707000707070007070700070007000000000040000099990000040000000000000000
00111000000700000007000000070000000700000007000000077000000770000007700000777000000000000000000040000099990000040000000000000000
11111110007770000077707000777070707770707077707077777770777777707777777077777770700000700000000040000000000000040000000000000000
00111000000700000007000000070000000700000007000000070000000770000077700000777000000000000000000044444444444444440000000000000000
01010100000000000000000000000000000000000700070007070700070707000707070007070700070007000000000000000000000000000000000000000000
00010000000000000000000000070000000700000007000000070000000700000007000000070000000700000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000700000007000000070000000700000007000000070000000700000007000000070000000000000000770777700000000000000000700000000000
00000000000000000000000000000000000000000700070000000700000007000000070007000700000000000000007000070000000000000000070000000000
00070000007070000070700000707000007070000070700000707000007070000070700000707000000000000000070700007000000000000007007000000000
00707000000000000000007000000070700000707000007070000070700000707000007070000070000000000000070700007000000000000077007000000000
00070000007070000070700000707000007070000070700000707000007070000070700000707000000000007000070700000000000700007000007000000000
00000000000000000000000000000000000000000700070000000000000007000700070007000700000000007000070700007000000700000700070000000000
00000000000000000000000000070000000700000007000000070000000700000007000000070000000000000700007000000700007000000077700000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077770770000077770000000000000000000000
00000000000000000555555500000000000000005555555000000000000000000000000000000000000000000000000000000000000000000000000000000000
00022222222220005566d5550066d0000000000055566d5500000000000000000000000000000000000000000000000000000002200000000000000000000000
00222222222222005661dd550661dd000000000055661dd500000000000000000000000000000000000000000000000000000022220000000000000000000000
022222222222222056111d5506111d0000000000556111d500000000000000000000000000000000000000000000000000555222222555000000000000000000
02222225522222205661dd550661dd000000000055661dd500000000000000000000000000000000000000000000000005552222222255500000000000000000
022222522522222055ddd55000ddd00000000000055ddd5500000000000000000000000000000000000000000000000055522222222225550000000000000000
02222522225222205555550000000000000000000055555500000000000000000000000000000000000000000000000055222222222222550000000000000000
02225222222522205555500000000000000000000005555500000000000000000000000000000000000000000000000052222222222222250000000000000000
0222555555552220000000000000000000000000000000000000000000000000000000000000000000000000000000005dddddddddddddd50000000000000000
0222222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000005dddddddddddddd50000000000000000
0d222222222222d00000000000000000000000000000000000000000000000000000000000000000000000000000000005555555555555500000000000000000
0dd2222222222dd00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00dddddddddddd000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000dddddddddd0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002222222222222200000000000000000
0002222222222000000000000000000000000000000000000000000000000000000000000000000000000000000000000d222222222222d00000000000000000
0022222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000005dd2222222222dd50000000000000000
0222222222222220000000000000000000000000000000000000000000000000000000000000000000000000000000005ddd22222222ddd50000000000000000
02222222222222200000000000000000000000000000000000000000000000000000000000000000000000000000000055ddd222222ddd550000000000000000
022255555555222000000000000000000000000000000000000000000000000000000000000000000000000000000000555ddd2222ddd5550000000000000000
0222522222252220000000000000000000000000000000000000000000000000000000000000000000000000000000005555ddd22ddd55550000000000000000
02222522225222200000000000000000000000000000000000000000000000000000000000000000000000000000000055555dddddd555550000000000000000
022222522522222055555000000000000000000000055555000000000000000000000000000000000000000000000000555555dddd5555550000000000000000
0222222552222220555555000000000000000000005555550000000000000000000000000000000000000000000000000555555dd55555500000000000000000
02222222222222205566d550000000000000000005566d5500000000000000000000000000000000000000000000000000555555555555000000000000000000
0d222222222222d05661dd55000551155515500055661dd500000000000000000000000000000000000000000000000000000000000000000000000000000000
0dd2222222222dd056111d550005551555555000556111d500000000000000000000000000000000000000000000000000000000000000000000000000000000
00dddddddddddd005661dd55000555155155500055661dd500000000000000000000000000000000000000000000000000000000000000000000000000000000
000dddddddddd00055ddd5550005555551555000555ddd5500000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000555555500055555555550005555555000000000000000000000000000000000000000000000000000000000000000000000000000000000
