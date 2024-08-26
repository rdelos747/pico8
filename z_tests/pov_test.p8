pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
mode="top_down"
px,py=0,0
ang=0.25 // pointing up

pvt_x=64
pvt_y=100

pov_h=70 	--horizontal angle?
pov_v=500 --vertical angle
pov_o=13  --offset (hack?)

pts={
	{-30,-30},
	{30,-30},
	{-30,0},
	{30,0}
	//{-30,30},
	//{30,30},
}


function _init()
	//-pvt_y+(36-500/(de))
	v=-100+(36-500/1)
	printh(v)
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

function rot(x,y,a)
	local rx=x*cos(a)+y*sin(a)
	local ry=x*sin(a)-y*cos(a)
	return rx,ry
end
-->8
-- draw functions
function draw_pt(x,y,info,clamp)
	if(clamp==nil)clamp=false
	if clamp then
		y=mid(camy,y,camy+121)
	end
	pset(x,y,11)
	for i=1,#info do
		s=info[i]
		print(s,x,y+2+(i-1)*7,7)
	end
end


function draw_top_down()
	pset(camx+64,camy+64,8)
	for p in all(pts) do
		local cx,cy=rot(
			p[1]-px,-(p[2]-py),-ang+0.75)
		
		draw_pt(
			camx-cx+64,
			camy-cy+64,
			{p[1],p[2],cy})
	end
end

function draw_pov()
	rectfill(
		camx,camy+64,
		camx+127,camy+127,1)
		
	for p in all(pts) do
		local povx,povy,ry=pov(p[1],p[2])
		
		draw_pt(
			camx-povx,
			camy-povy,
			//{p[1].." "..p[2],ry,povy})
			{ry.." "..povy},true)
	end
	
	pset(camx+pvt_x,camy+pvt_y,8)
end

function pov(x,y)
	local dx=x-px//-pov_o*cos(ang)
	local dy=y-py//-pov_o*sin(ang)
	
	--points after top-down roation
	local rx,ry=rot(
		dx,-dy,-ang+0.75)
	//rx+=pov_o*cos(ang+0.75)
	//ry+=pov_o*sin(ang+0.75)
//	if(abs(ry)<0.1)ry=1*sgn(ry)
	
	--ry>0: points infront of player
	--ry<0: points behind player

	local povx,povy=rx,ry
	
	//ry=ry
	//if(abs(ry)<0.1)ry=1*sgn(ry)
	local de=ry+pov_o
	if(abs(de)<0.1)de=1*sgn(de)
	povy=-pvt_y+(36-500/(abs(de)))
	//povy-=pov_o
	
	
	//				(64-0 ) == 64
	//				(64-32) == 32
	//    (64-64) == 0

	povx-=pvt_x
	
	return povx,povy,ry
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
