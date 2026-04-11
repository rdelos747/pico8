pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- hike

world_seed=123

secs=20
src_dp=4				--search depth
src_ns=6				--search num slices
src_ag=0.1 --search angle
src_sd=0.5		--search slice depth

ppx,ppy,ppz=0,-1,0
pp_ya,pp_pi=0,0
ppw=0 --walk

camx,camy,camz=0,0,0
cam_ya,cam_pi=0,0
cam_d=12
cam_h=0

fov=0.15
fov_c=-2.778 //1/tan(fov/2)
zfar=500
znear=-14
lam=zfar/(zfar-znear)

lvl={{}}
lvl_sz=0
td_mode=false

function _init()
	loga({"==== start hike ===="})
end

function _draw()
	cls()
	
	n_o_fnd=0
	n_o_proj=0
	n_t_sorted=0
	t_sorted_ll=nil
	
	if td_mode then
		draw_td()
	else
		cls(12)
		camera(0,0)
		draw_pov()
		draw_sorted()
		draw_log()
	end
end

function draw_log()
	print(pp_ya,0,0,7)
	pria({
		flr(ppx),flr(ppz),sex,sez
	},0,6,7)
	print(lvl_sz,0,12,2)
	
	pria({"nof",n_o_fnd},0,18,7)
	pria({"nop",n_o_proj},0,24,7)
	pria({"nts",n_t_sorted},0,30,7)
end

function _update()
	if(btnp(🅾️))td_mode=not td_mode
	update_player()
	update_cam()
	
	sex=flr(ppx/secs)
	sez=flr(ppz/secs)
	
	check_gen()
end

function check_gen()
	local fnd={}
	search_grid(function(i,j)
		local id=i.."+"..j
		if not lvl[id] then
			local s=create_sec(i,j)
			fnd[id]=s
		else
			fnd[id]=lvl[id]
		end
	end)
	lvl=fnd
	
	lvl_sz=0
	for k,s in pairs(lvl)do
		lvl_sz+=1
	end
end
-->8
-- pov

function draw_pov()
	camera(0,0)
	
	local gh=64+pp_pi*1024
	gh=mid(0,gh,152)
	rectfill(
		-10,gh,
		137,gh+127,
		15)
		
	srand(flr((ppx+ppz)/10))
	for i=0,15 do
		spr(
			1+flr(rnd()*3),
			i*8,
			gh-24,
			1,3)
		if i<7 or i>8 then
		spr(
			4+flr(rnd()*3),
			i*8,
			gh-6,
			1,3)
		end
	end
	srand(time())
		
	search_grid(function(
	i,j,n,x1,z1,x2,z2)
		local id=i.."+"..j
		local sec=lvl[id]
		for t in all(sec.trees)do
			sx,sy,dz=proj(t.x,t.y,t.z)
			if on_scr_x(sx) then
				n_o_fnd+=1
				draw_tree(t,sx,sy,n)
			end
		end
		if n<2 then
			for b in all(sec.bushs)do
				sx,sy,dz=proj(b.x,b.y,b.z)
				if on_scr_x(sx) then
					n_o_fnd+=1
					proj_spr(b)
				end
			end
		end
	end)
end

function draw_tree(t,x,y,n)
	if n<1 then
		proj_obj(t,true)
	else					
		local tr=t.tris[1].pts[3]
		local sx2,sy2=proj(
			tr.x+t.x,
			tr.y+t.y,
			tr.z+t.z)
		line(sx,sy,sx2,sy2,n<5 and 5 or 1)
	end
			
	-- draw branches
	if n>0 and n<3 then
		for b in all(t.brc)do
			bx1,by1=proj(
				t.x,
				t.y+b.y1,
				t.z)
			bx2,by2=proj(
				t.x+b.x,
				t.y+b.y2,
				t.z+b.z)
			if on_scr_y(bx2,by2) then
				line(bx1,by1,bx2,by2,5)
			end
		end
	end
end

function draw_bush(b)
	//spr(10,b.pts[1].x,b.pts[1].y)
	//sspr(80,0,16,16
	//loga({b.dz})
	local dz=max(0.5,(100-b.dz)/50)
	//loga({dz})
	sspr(
		80,0,
		16,16,
		b.pts[1].x-8*dz,
		b.pts[1].y,
		16*dz,
		16*dz)
end

function draw_td()
	local zm=2
	camera(ppx/zm-64,ppz/zm-64)
	
	for j=-2,2 do
	for i=-2,2 do
		local sx=(i+sex)*secs
		local sz=(j+sez)*secs
		rect(
			sx/zm,sz/zm,
			(sx+secs)/zm,(sz+secs)/zm,
			1)
	end end
	
	search_grid(function(
	i,j,n,x1,z1,x2,z2)
		line(
			x1/zm,z1/zm,
			x2/zm,z2/zm,
			n%2==0 and 7 or 5)
		
		local sx=i*secs
		local sz=j*secs
		//rect(
		//	sx/zm,sz/zm,
		//	(sx+secs)/zm,(sz+secs)/zm,
		//	2)
		
		local id=i.."+"..j
		local sec=lvl[id]
		for o in all(sec.trees)do
			pset(
				o.x/zm,
				o.z/zm,n<2 and 11 or 13)
		end
	end)
	
	line(
		ppx/zm,ppz/zm,
		ppx/zm+sin(pp_ya)*10,
		ppz/zm+cos(pp_ya)*10,
		8)
end
-->8
-- proj

function proj_spr(s)
	n_o_proj+=1
	local px,py,dz=proj(
		s.x,s.y,s.z)
	if px<0 or px>127 or
				py<0 or py>127 then
		dz=0
	end
	sort_itm({
		draw=s.tris,
		pts={{x=px,y=py}},
		data=s,
		dz=dz
	})
end

function proj_obj(o,f)
	n_o_proj+=1
	local ts={}
	for t in all(o.tris)do
		local pts={} --projected pts
		local dz_max=-1
		for p in all(t.pts) do
			x,y,z=rot3d(
				p.x,
				p.y,
				p.z,
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
			if(not on_scr_y(py))dz=0 
			dz_max=max(dz_max,dz)
			add(pts,{x=px,y=py})
		end
		
		local i=1
		while i<=#ts+1 do
			if i>#ts or
						dz_max>ts[i].dz then
				add(ts,{
					pts=pts,
					col=t.c,
					dz=dz_max
				},i)
				i=#ts+2
			end
			i+=1
		end
	end
	
	local imin=1
	if(f)imin=#ts-1
	for i=max(1,imin),#ts do
		sort_itm(ts[i])
	end
end

function sort_itm(itm)
	if itm.dz>1 then
		n_t_sorted+=1
	
		itm.nxt=nil
		itm.prv=nil
		
		if t_sorted_ll==nil then
			t_sorted_ll=itm
			return
		end
		
		local node=t_sorted_ll
		while node!=nil do
			if itm.dz>node.dz then
				if node.prv then
					node.prv.nxt=itm
				else
					t_sorted_ll=itm
				end
				itm.prv=node.prv
				itm.nxt=node
				node.prv=itm
				return
			end
			if node.nxt==nil then
				node.nxt=itm
				itm.prv=node
				return
			end
			node=node.nxt
		end
		
		printh("node not added")
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

	return px,py,dz
end

function draw_sorted()
	n_t_sorted_d=0
	local node=t_sorted_ll
	while node!=nil do
		
		if type(node.draw)=="function" then
			node.draw(node)
		else
			n_t_sorted_d+=1
			draw_tri(
				node.pts,
				node.col,
				node.dz
			)
		end
		node=node.nxt
	end
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

//dz_cols={1,13,15}
function draw_tri(t,c,dz)
	local ddz=min(ceil(dz/200),4)
	//if story==0 and ddz>1 then
	//	c=dz_cols[ddz-1]
	//end
	
	pelogen_tri_hvb(
	 t[1].x,t[1].y,
	 t[2].x,t[2].y,
	 t[3].x,t[3].y,
	 c,
	 ddz)
end

function pelogen_tri_hvb(l,t,c,m,r,b,col,ddz)
	color(col)
	local a=rectfill
	::_w_::
	if(t>m)l,t,c,m=c,m,l,t
	if(m>b)c,m,r,b=r,b,c,m
	if(t>m)l,t,c,m=c,m,l,t

	local q,p=l,c
	if (q<c) q=c
	if (q<r) q=r
	if (p>l) p=l
	if (p>r) p=r
	if b-t>q-p then
		l,t,c,m,r,b,col=t,l,m,c,b,r
		goto _w_
	end

	local e,j,i=l,(r-l)/(b-t)
	while m do
		i=(c-l)/(m-t)
		local f=m\1-1
		f=f>127 and 127 or f
		if(t<0)t,l,e=0,l-i*t,b and e-j*t or e
		if col then
			for t=t\1,f do
				a(l,t,e,t)
				l=i+l
				e=j+e
			end
		else
			for t=t\1,f,1 do
				a(t,l,t,e)
				l=i+l
				e=j+e
			end
		end
		l,t,m,c,b=c,m,b,r
	end
	--[[
	if i<8 and i>-8 then
		if col then
			pset(r,t)
		else
			pset(t,r)
		end
	end
	]]--
end

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
	if(btn(⬅️))pp_ya+=0.01
	if(btn(➡️))pp_ya-=0.01
	pp_ya=pp_ya%1
	
	if btn(❎) then
		if btn(⬆️) then
			pp_pi+=0.01
		elseif btn(⬇️) then
			pp_pi-=0.01
		end
	else
		pp_pi=0
		if btn(⬆️) then
			ppx+=sin(pp_ya)
			ppz+=cos(pp_ya)
			ppw+=1
		elseif btn(⬇️) then
			ppx-=sin(pp_ya)
			ppz-=cos(pp_ya)
			ppw-=1
		end
	end
end

-->8
-- level gen

function search_grid(cb)
	//loga("==search==")
	local fnd={}
	local id=sex.."+"..sez
	fnd[id]=true
	cb(sex,sez,0,ppx,ppz,ppx,ppz)
	
	local sd=secs*src_sd
	for n=0,src_dp do
		local a=pp_ya-src_ag/2
		local am=src_ag/src_ns
		for s=0,src_ns do
			local aa=a+am*s
			local d=sd*n
			local d2=sd*(n+1)
			local x1=ppx+sin(aa)*d
			local z1=ppz+cos(aa)*d
			local x2=x1+sin(aa)*d2
			local z2=z1+cos(aa)*d2
			
			local i=flr(x2/secs)
			local j=flr(z2/secs)
			local id=i.."+"..j
			//loga({id})
			if fnd[id]==nil then
				fnd[id]=true
				
				cb(i,j,n,x1,z1,x2,z2)
			end
		end
	end
end

function create_sec(i,j)
	loga({"creating sec",i,j})
	
	local sd=(i<<8)+j
	sd=sd+(world_seed>>8)
	loga({"  seed",sd,dtb2(sd)})
	
	local sec={
		i=i,j=j,
		trees={},
		bushs={},
		grnd={}
	}
	local sx=i*secs
	local sz=j*secs
	
	srand(sd)
	local nt=rand(10,10)
	for i=1,nt do
		local c1,c2=5,13
		//if(rnd()>0.5)c1,c2=5,13
		local t=tree(
			rand(3,secs-3)+sx,
			0,
			rand(0,secs)+sz,
			20,30,
			c1,c2)
	
		add(sec.trees,t)
	end
	
	local nb=rand(20,20)
	for i=1,nb do
		local b=obj(
			draw_bush,
			rand(3,secs-3)+sx,
			0,
			rand(0,secs)+sz,
			0,0,0,
			0,0)
		add(sec.bushs,b)
	end
	
	srand(time())
	return sec
end
-->8
-- helpers

function obj(tris,x,y,z,ya,pi,ro,w,d,up)
	//if type
	local tt=nil
	if type(tris)=="function" then
		tt=tris
	else
		tt=read_tris(tris)
	end
	
	local o={
		tris=tt,
		x=x,y=y,z=z,
		ya=ya,pi=pi,ro=ro,
		w=w,d=d, --width/depth
		scrx=-1,scry=-1,
		update=up
	}
	return o
end

function read_tris(tr)
	local out={}
	for t in all(tr)do //evry tri
		local pts={}
		for pi=1,3 do //evry pt
			local sp=split(t[pi],",")
			add(pts,{
				x=sp[1],
				y=sp[2],
				z=sp[3]
			})
		end
		add(out,{
			pts=pts,
			c=t[4]
		})
	end
	
	return out
end

function rand(bot,top)
	return flr(rnd((top+1)-bot))+bot
end

function on_scr_x(x)
	return x>-40 and 
								x<168 
end

function on_scr_y(y)
	return y>-50 and 
								y<178
end


--debug functions
--todo remove
function a_to_s(arr)
	local s=tostr(arr[1])
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

function dtb2(num)
	local n1=num
	local n2=num
 local bin=""
	
	n2<<=1
	for i=1,16 do
  bin=n2 %2\1 ..bin
  n2<<=1
  if i%4==0 and i<32 then
   bin=" "..bin
  end
	end
	
	for i=1,16 do
  bin=n1 %2\1 ..bin
  n1>>>=1
  if i%4==0 and i<32 then
   bin=" "..bin
  end
	end
 
 return bin
end
-->8
-- models

tree_tris={
	{ -- west face
			"-1,0,-1",
			"-1,0,1",
			"0,-1,0",
			7
		},
		{ -- east face
			"1,0,1",
			"1,0,-1",
			"0,-1,0",
			7
		},
		{ -- north face
			"1,0,-1",
			"-1,0,-1",
			"0,-1,0",
			6
		},
		{ --south face
			"-1,0,1",
			"1,0,1",
			"0,-1,0",
			6
		}
}

function tree(x,y,z,mi,ma,c1,c2)
	local h=rand(mi,ma)
	local r=0.2
	
	local t=obj(
		tree_tris,
		x,y,z,
		0,0,0,
		r*2,h
	)
	
	-- modify trunk tris
	for t in all(t.tris)do
		for p in all(t.pts)do
			p.x*=r
			p.z*=r
		end
		t.pts[3].y=-h
	end
	t.tris[1].c=c1
	t.tris[2].c=c1
	t.tris[3].c=c2
	t.tris[4].c=c2
	
	-- create branches
	t.brc={}
	for i=1,5 do
		local rx=rand(-10,10)
		local rz=rand(-10,10)
		local ry=rand(h/2,h)*-1
		add(t.brc,{
			x=rand(-10,10),
			z=rand(-10,10),
			y1=rand(h/2,h)*-1,
			y2=rand(h/2,h)*-1
		})
			
	end
	
	return t
end
__gfx__
000000005000500000500500050050050000b000000b00300000000b000000000000000000000000000000000000000000000000000000000000000000000000
000000001050100050d005000500505030b030b3b0030b300000030b000000000000000000000000003000000300333000000000000000000000000000000000
0070070005d01050105050050550050530b030b3b0030b30030b0b0b000000000000000000000000000300003000300000000000000000000000000000000000
00077000055050500505505000d0505130b030b3b0030b00030b0b0b0000000000000000000000000330300030030b0000000000000000000000000000000000
00077000051010d055515155d000150003333303b033330330333330000000000000000000000000000303030030b00000000000000000000000000000000000
00700700015505055d00555d0050555033333333333b33333333b33300000000000000000000000000003303030b000000000000000000000000000000000000
000000000505050d05055105500050013b33b3b3b33333b3b3b333b30000000000000000000000000bb00303030b000000000000000000000000000000000000
00000000050115155050d505001001003333333333b3333333333333000000000000000000000000000b030303b0000000000000000000000000000000000000
000000005050505000500500050050053b3b3b3b33333b33333b3b3b000000000000000000000000000b00303b000b0005006004000000000000000000000000
0000000010555d0550d005000500d0103b3b3b333b33bbb33b333b3b0000000000000000000000000bb0b0303b00b00000400005000000000000000000000000
0000000005505055105050050d5005053b3b3b333b33bbb33b3b3b3b000000000000000000000000000b0b33b0bb000005050050000000000000000000000000
00000000515515510555d5105015d05d3b3b3b333b3bb3b3bbbbb3bb000000000000000000000000b000bb030b00000050005040000000000000000000000000
00000000555d515555155555150155053b333b33333b3333bb3bb3bb0000000000000000000000000bb0b0b3bb000bb000600500000000000000000000000000
000000005d5d555d5d5551550555115533333333333333333b33b333000000000000000000000000000b0bbbbbb0b00050050060000000000000000000000000
000000005d551555055155055d5155513333333333333333333333330000000000000000000000000000bb0bbb00b00005040004000000000000000000000000
00000000150555151055155d55d55dd533333333333333333333333300000000000000000000000000000bbbb00b000050505050000000000000000000000000
00000000150150d00550505005505051333333333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000
00000000510550d55151505550515555333333333333333333333333000000000000000000000000000000000000000000000000000000000000000000000000
000000005555155555555555555555d5333330303333303333333333000000000000000000000000000000000000000000000000000000000000000000000000
00000000551551511515551551555155030030000303303030333303000000000000000000000000000000000000000000000000000000000000000000000000
00000000d55555155555d55555515555030000000303003000303303000000000000000000000000000000000000000000000000000000000000000000000000
000000005155d5555515515555555555000000000303003000303000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555155d55d55155d55555515000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000555555555555555555551555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
