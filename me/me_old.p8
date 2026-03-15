pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- menacing earthworks

ppx,ppy,ppz=0,-6,-10
ppv=0
pp_ya,pp_pi=0,0
//bow={x=0,y=0,z=0,ya=0,pi=0,ro=0}
bp=0

camx,camy,camz=0,0,0
cam_ya,cam_pi=0,0
cam_d=5
cam_h=0

fov=0.11
fov_c=-2.778 //1/tan(fov/2)
zfar=500
znear=-14
lam=zfar/(zfar-znear)

txw=24 //tex width

function _init()
	printh("==== start arch ====")
	
	lvl={
		spike(0,0,0,0,0,0),
		//target(0,0,-50,0,0,0)
	}
end

function _draw()
	cls()
	
	p_sorted_ll=nil
	n_i_sorted=0
	n_i_sorted_d=0
	n_o_proj=0
	
	draw_pov()
	
	print(n_i_sorted,8)
	print(n_i_sorted_d,8)
	print(ppx.." "..ppy.." "..ppz,8)
	print(cam_ya.." "..cam_pi,8)
end

function _update()
	update_player()
	update_cam()
end
-->8
-- pov

function draw_pov()
	camera(0,0)
	cls(7)
	rectfill(0,65,127,127,15)
	
	for o in all(lvl)do
		local px,py=proj(o.x,o.y,o.z)
		
		//proj_obj(o)
		n_o_proj+=1
		for tr in all(o.tris) do
			proj_pts(tr,o)
		end
		proj_pts(o.face,o)
	end
	
	--[[
	for tr in all(bow_tris(bp)) do
		proj_pts(
			tr,
			bow
		)
	end
	]]--
	draw_sorted()
end

function proj_pts(p,o)
	local pts={}
	local dz_max=-1
	
	for i=1,#p-1 do
		local pp={}
		//printh(p[i])
		if type(p[i])=="string" then
			local sp=split(p[i],",",true)
			//printh(sp[1])
			pp.x=sp[1]
			pp.y=sp[2]
			pp.z=sp[3]
		else
			pp=p[i]
		end
		x,y,z=rot3d(
			pp.x,
			pp.y,
			pp.z,
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
		if px<0 or px>127 or
					py<0 or py>127 then
			dz=0
		end
		dz_max=max(dz_max,dz)			
		add(pts,{x=px,y=py})
	end
	sort_itm(pts,p[#p],dz_max)
end

function sort_itm(pts,col,dz)
	if dz>1 then
		n_i_sorted+=1
		
		local newn={
			pts=pts,
			col={col,nil},//temp, later add flip thing if needed
			dz=dz,
			nxt=nil,
			prv=nil
		}
		
		//n_t_sort+=1
		if p_sorted_ll==nil then
			p_sorted_ll=newn
			return
		end
		
		local node=p_sorted_ll
		while node!=nil do
			//i+=1
			if dz>node.dz then
				if node.prv then
					node.prv.nxt=newn
				else
					p_sorted_ll=newn
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
		//alert="oops"
	end
end

function draw_sorted()
	local node=p_sorted_ll
	while node!=nil do
		if #node.pts==3 then
			//draw_sprite(t)
			//node.tri[1](node)
			n_i_sorted_d+=1
			draw_tri(
				node.pts,
				node.col[1],
				node.col[2]
			)
		elseif #node.pts==4 then
			n_i_sorted_d+=1
			draw_tex_v(
				node.pts,
				node.col[1]
				)
		end
		node=node.nxt
	end
end


function draw_tri(t,c)
	pelogen_tri(
	 t[1].x,t[1].y,
	 t[2].x,t[2].y,
	 t[3].x,t[3].y,
	 c,f)
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

function draw_tex_v(pts,col)
	pal(15,0)
	local tl=pts[1]
	local tr=pts[2]
	local bl=pts[3]
	local br=pts[4]
	local qw=tr.x-tl.x
	local qh=bl.y-tl.y
	
	if(qw<1)return
	
	for i=0,qw do
		local per=i/flr(qw)
		local mx=min(2.99,per/(8/txw))
		
		local top=tl.y+(tr.y-tl.y)*per
		local bot=bl.y+(br.y-bl.y)*per
		local ht=bot-top
		
		tline(
			tl.x+i,top,tl.x+i,bot,
			0+mx,0,
			0,1/(ht/3)
		)
		
		--[[
		pset(tl.x,tl.y,8)
		pset(tr.x,tr.y,8)
		pset(bl.x,bl.y,8)
		pset(br.x,br.y,8)
		]]--
	end
	pal()
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
	return rx,ry
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
	
	//amt=0.01
	//if btn(❎) then
	//	bp-=0.05
	//	amt=0.001
	//else
	//	bp=0
	//end
	
	if btn(⬅️) then
		pp_ya+=0.01
	elseif btn(➡️) then
		pp_ya-=0.01
	end

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
	
	can_x,can_z=true,true //todo
	if(can_x)ppx-=dx
	if(can_z)ppz-=dz
	
	//dx*=2
	//dz*=2
	
	//bow.ya=pp_ya
	//bx,by,bz=rot3d(
	//	1,0,1,
	//	pp_pi,
	//	pp_ya,
	//	0)
	
	//bow.x=ppx+bx
	//bow.y=ppy+by
	//bow.z=ppz+bz
end

//function draw
-->8
-- helpers


function rand(bot,top)
	return flr(rnd((top+1)-bot))+bot
end

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
-->8
-- models
function bow_tris(a)
	return {
		{
			"-0.2,0,0",
			"0.1,0,0",
			"0,-7,"..a,
			13
		},
		{
			"-0.2,0,0",
			"0.1,0,0",
			"0,7,"..a,
			13
		},
	}
end

function spike(x,y,z,ya,pi,ro)
	rx,rz=rand(-40,40),rand(-40,40)
	
	local s=nil
	s_num=-1
	if s_num>-1 then
		if(dr==nil)dr=rand(1,4)
		local sya=0
		if(dr==1)rx,rz,sya=-10,0,-0.25
		if(dr==2)rx,rz,sya=10,0,0.25
		if(dr==3)rx,rz=0,-10
		if(dr==4)rx,rz,sya=0,10,0.5
	end
	
	local rt=""..rx..",-100,"..rz

	return {
		x=x,y=y,z=z,
		ya=ya,pi=pi,ro=ro,
		tris={
			{ -- west face
				"-10,0,-10",
				"-10,0,10",
				rt,
				1
			},
			{ -- east face
				"10,0,10",
				"10,0,-10",
				rt,
				0
			},
			{ -- north face
				"10,0,-10",
				"-10,0,-10",
				rt,
				0
			},
			{ --south face
				"-10,0,10",
				"10,0,10",
				rt,
				1
			}
		},
		face={
			"-5,-80,-20",
			"5,-80,-20",
			"-5,-70,-20",
			"5,-70,-20",
			9999
		}
	}
end
__gfx__
00000000777777770ffffff077777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777ffffffffffff777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070077777ffffffffffffff77777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000770007777fffffccccccfffff7777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000777ffffccccccccccffff777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070077ffffccccccccccccffff77000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000007ffffccccc8888cccccffff7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000007fffcccc88888888ccccfff7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000fffccc8888888888cccfff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000fffcccc888aaaa888ccccfff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000fffccc888aaaaaa888cccfff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000fffccc888aa99aa888cccfff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000fffccc888aa99aa888cccfff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000fffccc888aaaaaa888cccfff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000fffcccc888aaaa888ccccfff000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000fffccc8888888888cccfff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000007fffcccc88888888ccccfff7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000007ffffccccc8888cccccffff7000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000077ffffccccccccccccffff77000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777ffffccccccccccffff777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000007777fffffccccccfffff7777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000077777ffffffffffffff77777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777ffffffffffff777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000777777770ffffff077777777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0102030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1112130000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2122230000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
