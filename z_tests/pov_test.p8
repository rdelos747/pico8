pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
mode="top_down"
px,py=0,0
ang=0.25 // pointing up

pvt_x=64
pvt_y=100

//pov_h=70 	--horizontal angle?
//pov_v=500 --vertical angle
pov_o=13  --offset (hack?)

pts_l={
{14,-200},
{14,-170},
{14,-150},
{14,-110},
	{14,-70},
	{14,-30},
	{14,-10},
	{14,0},
}

pts_r={
{-14,-200},
{-14,-170},
{-14,-150},
{-14,-110},
	{-14,-70},
	{-14,-30},
	{-14,-10},
	{-14,0},
}


function _init()
	printh("===== start =====")
	//-pvt_y+(36-500/(de))
	--[[
	v=-100+(36-500/1)
	printh(v)
	]]--
	lastv=0
	for i=10,-10,-1 do
		local fy=1-(500/i)
		//dist=500-i*10
		//vvv=(dist)/500
		//vvv=500/dist
		//vvv/=2
		//d=vvv-lastv
		//lastv=vvv
		printh(comb_a({i,fy,fy/i}))
	end
end

function _draw()
	cls()
	
	camx=flr(px-64)
	camy=flr(py-64)
	camera(camx,camy)
	
	if mode=="top_down" then
	draw_top_down()
	else
	draw_pov()
	end
	
	print("ang: "..ang,camx,camy,7)
	print("x: "..flr(px),camx,camy+6,7)
	print("y: "..flr(py),camx,camy+12,7)
end

function _update()
	if btn(⬆️) then
		px+=cos(ang)
		py+=sin(ang)
	elseif btn(⬇️) then
		px-=cos(ang)
		py-=sin(ang)
	end
	if(btn(⬅️))ang+=0.01
	if(btn(➡️))ang-=0.01
	if btnp(❎) then
		if mode=="pov" then
			mode="top_down"
		else
			mode="pov"
		end
	end
end

function comb_a(arr,t)
	if(t==nil)t=" "
	local s=arr[1]
	if #arr>1 then
		for i=2,#arr do
			s=s..t..arr[i]
		end
	end
	return s
end
-->8
-- draw functions
function draw_pt(x,y,info,clamp)
	if(clamp==nil)clamp=false
	if clamp then
		y=mid(camy,y,camy+121)
		x=mid(camx,x,camx+120)
	end
	pset(x,y,12)
	--[[
	for i=1,#info do
		s=info[i]
		print(s,x,y+2+(i-1)*7,7)
	end
	]]--
	print(
		comb_a(info),
		x+1,y,7)
end


function draw_top_down()
	for p in all(pts_l) do
		local cx,cy=rot(
			p[1]-px,-(p[2]-py),-ang+0.75)
		
		draw_pt(
			camx-cx+64,
			camy-cy+64,
			{cy})
	end
	
	for p in all(pts_r) do
		local cx,cy=rot(
			p[1]-px,-(p[2]-py),-ang+0.75)
		
		draw_pt(
			camx-cx+64,
			camy-cy+64,
			{cy})
	end
	
	pset(camx+64,camy+64+pov_o,8)
	pset(px+0,py+0,11)
end

function draw_pov()
	rectfill(
		camx,camy+64,
		camx+127,camy+127,1)
		
	draw_pov_secs(pts_l)
	draw_pov_secs(pts_r)
	
	pset(camx+pvt_x,camy+pvt_y,8)
end

function draw_pov_secs(arr)
	for i=1,#arr do
		local p1=arr[i]
		
		local povx1,povy1,ry1,de1=pov(p1[1],p1[2])
		
		if i<#arr then
			local p2=arr[i+1]
			local povx2,povy2=pov(p2[1],p2[2])
		
			line(povx1,povy1,povx2,povy2,5)
		end
		
		
		draw_pt(
			povx1,
			povy1,
			//{})
			//{p[1].." "..p[2],ry,povy})
			//{ry1.." "..de1.." "..povx1},true)
			//{ry1,f1,povx},true)
			{ry1,povy1},true)
	end
end
-->8
--pov

--[[
computes the point of view
projection of points relative
to the player and camera
]]--
function pov(x,y)
	local dx=x-px//-pov_o*cos(ang)
	local dy=y-py//-pov_o*sin(ang)
	
	--points after top-down roation
	local rx,ry=rot(
		dx,-dy,-ang+0.75)	
	--ry>0: points infront of player
	--ry<0: points behind player

	//local povx,povy=rx,ry
	
	//local de=max(0.1,ry+pov_o)
	local de=max(0.1,ry+pov_o)
	--deminator for algo below.
	--if de=0, lua freaks out
	--if de<0, values wrap to top of screen,
	-- so just cap at min 0.1
	
	
	local pov_d=500
	--how far in the distance points
	-- appraoch.
	--lower values are faster,
	--higher values are slower

	local povy=max(
		-pvt_y+((pvt_y-64)-pov_d/(de)),
		-128
	)
	--y point on screen after distance
	-- factored in.
	--its basically how far from the
	-- top of the screen to render the
	-- y coord. 
	--note: (pvt_y-64) is the horizon 
	-- relative to the pivot y coord.

	local povx=rx*min(60/de,7.5)
	povx-=pvt_x

	return camx-povx,camy-povy,ry,de
	--return values relative to camera,
	-- just to save tokens later

end

function rot(x,y,a)
	local rx=x*cos(a)+y*sin(a)
	local ry=x*sin(a)-y*cos(a)
	return rx,ry
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
