pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
carx=0
cary=0
ang=0.25

pvt_x=64
pvt_y=100
pov_h=20 	--horizontal angle?
pov_v=500 --vertical angle

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
gear=1
rpm=0
spd=0
turn=0

function _init()
	printh("=====start=====")
	create_pts()
end

function _draw()
	cls()
	draw_pov()
	print(camx.." "..camy,camx,camy)
	draw_hud()
end

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
	update_car()
end
-->8
-- pov

--pts={
--	{-30,-30,1},
--	{30,-30,2},
--	{30,30,3},
--	{-30,30,4}
--}
--[[
pts={
	{-30,-100},{30,-100},
	{-30,-80},{30,-80},
	{-30,-60},{30,-60},
	{-30,-40},{30,-40},
	{-30,-20},{30,-20},
	{-30,0},{30,0},
}
]]--
pts={}
function create_pts()
	for i=0,20 do
		add(pts,{-30,i*-30})
		add(pts,{30,i*-30})
	end
end

function draw_pov()
	camx=flr(carx-pvt_x)
	camy=flr(cary-pvt_y)
	camera(camx,camy)
	
	rectfill(
		camx,camy+64,
		camx+127,camy+127,1)
	
	for i=1,#pts do
		local p=pts[i]
		local px,py=pov(p[1],p[2],true)
		if px!=nil then
			if py<camy+128 then
				if i<#pts then
					local p2=pts[i+1]
					local p2x,p2y=pov(p2[1],p2[2],false)
					if p2x!=nil then
						line(px,py,p2x,p2y,5)
					end
				end
				pset(px,py,8)
			end
		end
	end
	
	pset(carx,cary,11)
end

pp_t=0
function pov(x,y,pp)
	local d=dist(
		carx,cary,x,y)
	
	local dx=x-carx
	local dy=y-cary
	
	local rx,ry=rot(
		dx,-dy,-ang+0.25)
		
	rx*=(pov_h/max(abs(ry),1))
	rx+=camx+pvt_x
	
	ry=-(pov_v/ry)
	if ry>64 or ry<0 then
		return nil
	end
	//local ry2=ry
	ry+=camy+64
	
	--[[
	if pp then
		print(ry2,0,ry,7)
	end
	]]--
	
	return rx,ry
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
	if btn(⬇️) then
		spd=max(0,spd-2)
	end
	
	local fx=cos(ang)*spd/30
	local fy=sin(ang)*spd/30
	
	--turning
	if btn(⬅️) then
		turn=max(-1,turn-0.1)
	elseif btn(➡️) then
		turn=min(1,turn+0.1)
	elseif turn<0 then
		turn=min(0,turn+0.05)
	elseif turn>0 then
		turn=max(0,turn-0.05)
	end
	
	--[[
	this should change from just
	grip to under vs over steer.
	or at least, at low speeds
	its under and high its over??
	]]--
	grip=min(1,1-((spd-80)/300))
	
	ang=(ang-turn*grip*0.01)%1
	
	dftx,dfty=0,0
	if abs(turn)>grip then
		//add(skids,{px,py})
		dftx=cos(ang+0.25*abs(turn)*sgn(turn))*1
		dfty=sin(ang+0.25*abs(turn)*sgn(turn))*1
	end
	
	carx+=fx+dftx
	cary+=fy+dfty
	
	if(btn(⬅️))ang+=0.01
	if(btn(➡️))ang-=0.01
end
-->8
-- hud

function draw_hud()
	--tach
	local x,y=camx+20,camy+115
	circfill(x,y,15,0)
	circ(x,y,15,6)
	local a=rpm*0.8+0.3
	line(x+cos(a)*4,y+sin(-a)*4,
		x+cos(a)*12,y+sin(-a)*12,7)
	
	print(gear>1 and gear-1 or "n",x,y,7)
	
	--speed
	x,y=camx+108,camy+115
	circfill(x,y,15,0)
	circ(x,y,15,6)
	print(spd,x,y,7)
	
	--turn
	rect(camx+44,camy+113,
		camx+84,camy+117,0)
		
	x=camx+64+20*turn
	line(x,camy+113,x,camy+117,7)
	
	x=camx+64+20*grip
	line(x,camy+113,x,camy+117,13)
	x=camx+64-20*grip
	line(x,camy+113,x,camy+117,13)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
