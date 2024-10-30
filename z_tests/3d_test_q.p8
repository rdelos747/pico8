pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- 3d test quaternion

tris={
	{
		{-10,0,10},
		{0,-10,0},
		{10,0,10},
		10
	},
	{
		{-10,0,-10},
		{0,-10,0},
		{10,0,-10},
		9
	}
}

objs={}

camx,camy,camz=0,0,0
fov=0.1
zfar=100
znear=3
v_fwd,v_right,v_up={0,0,1},{1,0,0},{0,1,0}

function _init()
	printh("====== start ======")
	
	add(objs,{0,0,-40})
end

function _draw()
	cls()
	
	for o in all(objs)do
		draw_obj(o)
	end
	
	line(27,120,64,100,7)
	line(100,120,64,100,7)
end

function _update()
	lam=(zfar/zfar-znear)
end

function tan(a)
	return sin(a)/cos(a)
end
-->8
-- draw

function draw_obj(o)
	for t in all(tris)do
		tt={}
		for i=1,3 do
			local x=t[i][1]+o[1]
			local y=t[i][2]+o[2]
			local z=t[i][3]+o[3]
			x=x-camx
			y=y-camy
			z=z-camz
			
			local px=x*(1/tan(fov/2))
			local py=y*(1/tan(fov/2))
			local pz=z*lam-lam*znear
			
			pz=max(pz,1)
			px=-64*px/pz+64
			py=-64*py/pz+64
			
			add(tt,{px,py})
		end
		
		draw_tri(tt,t[4])
	end
end

function draw_tri(t,c)
		pelogen_tri(
			t[1][1],t[1][2],
			t[2][1],t[2][2],
			t[3][1],t[3][2],
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
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
