pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--constants
--=============
--cam
cam={x=0,y=0}

--hud
hud_h=3
hud_m1="..."
hud_m2="..."
hud_m3="..."

--level
xmax_min=16
xmax_max=16
ymax_min=16
ymax_max=16
xmax=-1
ymax=-1
lvl={}
t_emt0=32
t_emt1=33
t_emt2=34
t_wall=35
t_door=36
t_cdor=37

--player
pp={x=8,y=8,sp=1,sx=8,sy=8,
	ax=0,ay=0,as=0,//attack anim
	hp=5,mn=5}
	
--bag
bag={}
bag_l=4
	
--arrays
ens={}
l_itms={}

--items
item_tps={
{sp=4,fnd=false,disp="hp+"},
{sp=5,fnd=false,disp="mana+"}
}
	
-- helpers
--=============
function rand(bot,top)
	return flr(rnd((top+1)-bot))+bot
end

function chance(n)
	return rand(0,100) < n
end

--init
--=============
function _init()
	new_lvl()
end

--draw
--=============
function _draw()
	cls()
	camera(cam.x*8,cam.y*8)
	draw_hud()
	draw_lvl()
	--enemies
	for e in all(ens) do
		spr(e.sp,(e.x*8)+e.ax,
				(e.y*8)+e.ay)
		if e.see then
			spr(18,(e.x*8)+6,e.y*8)
	end end
		--player
	spr(pp.sp,(pp.x*8)+pp.ax,
	(pp.y*8)+pp.ay)
end

function draw_hud()
	local cx=(cam.x*8)
	local r1=(cam.y*8)+105
	local r2=(cam.y*8)+113
	local r3=(cam.y*8)+121
	-- stats
	print("hp  :"..pp.hp,cx,r1,7)
	print("mana:"..pp.mn,cx,r2,7)
	print("wpn :",cx,r3,7)
	spr(3,cx+18,r3-3)
	print("(+1)",cx+25,r3,5)
	--log rows
	print(hud_m1,cx+50,r1,5)
	print(hud_m2,cx+50,r2,6)
	print(hud_m3,cx+50,r3,7)
end

function draw_lvl()
	for j=cam.y,cam.y+(15-hud_h)do
	for i=cam.x,cam.x+15 do
		local dd=true
		--items
		for it in all(l_itms) do
			if i==it.x and j==it.y then
				dd=false
				spr(item_tps[it.idx].sp,
					i*8,j*8)
		end end
		--enemies
		// blah blah
		
		if(pp.x==i and pp.y==j)dd=false
		if(dd)spr(lvl[j][i],i*8,j*8)
	end end
end

--update
--=============
function _update()
	local mv={x=0,y=0,b=0,a=0}
	if btnp(➡️) then
		mv.x=1
	elseif btnp(⬅️) then
		mv.x=-1
	elseif btnp(⬇️) then
		mv.y=1
	elseif btnp(⬆️) then
		mv.y=-1
	elseif btnp(🅾️) then
		mv.b=1
	elseif btnp(❎) then
		mv.a=1
	end
	if pp.as>0 then
		pp.as-=1
		if pp.as==0 then
			pp.ax=0
			pp.ay=0
		end
		return
	end
	for e in all(ens) do
		if e.as>0 then
			e.as-=1
			if e.as==0 then
				e.ax=0
				e.ay=0
			end
			return
		end
	end
	
	if(move_p(mv))move_e()
	move_cam()
end

function move_cam()
	cam.x=pp.x-8
	cam.y=pp.y-(8-hud_h)
	if(cam.x<0)cam.x=0
	if(cam.y<0)cam.y=0
	if(cam.x>xmax-16)cam.x=xmax-16
	if(cam.y>ymax-(16-hud_h))cam.y=ymax-(16-hud_h)
end

function move_p(mv)
	local nx=pp.x+mv.x
	local ny=pp.y+mv.y
	if(nx==pp.x and ny==pp.y) return false
	if nx<0 or nx>xmax-1 or
				ny<0 or ny>ymax-1 then
		return false
	end
	if lvl[ny][nx]==t_wall then
		return false
	end
	for e in all(ens) do
		if e.x==nx and e.y==ny then
			pp.ax=mv.x*4
			pp.ay=mv.y*4
			pp.as=3
			attack_e(e)
			return
		end
	end
	--pick up item
	for it in all(l_itms) do
		if it.x==nx and it.y==ny then
			if #bag < bag_l then
				if item_tps[it.idx].found then
					message("picked up "..
						item_tps[it.idx].disp)
				else
					message("picked up ??")
				end
				add(bag,it.idx)
				del(l_itms,it)
			else	
				message("bag full")
			end
		end
	end
	-- move player
	pp.x=nx
	pp.y=ny
	
	-- door
	
	return true
end

function attack_p(e)
	pp.hp-=1
	message(e.name.." hit you")
end

function move_e()
	for e in all(ens) do
		local nx=e.x
		local ny=e.y
		if e.see then
			if(pp.x<e.x)nx-=1
			if(pp.x>e.x)nx+=1
			if(pp.y<e.y)ny-=1
			if(pp.y>e.y)ny+=1
		else
			nx+=rand(-1,1)
			ny+=rand(-1,1)
		end
		if ny==pp.y and nx==pp.x then
			e.ax=(nx-e.x)*4
			e.ay=(ny-e.y)*4
			e.as=3
			attack_p(e)
			return
		end
		if lvl[ny][nx] != t_wall and
					lvl[ny][nx] != t_door and
					lvl[ny][nx] != t_cdor then
			e.x=nx
			e.y=ny
		end
		if abs(pp.x-e.x)<5 and
					abs(pp.y-e.y)<5 then
			e.see=true
		end
	end
end

function attack_e(e)
	message("you hit "..e.name)
	del(ens,e)
end

--creators
--=============
function message(t)
	hud_m1=hud_m2
	hud_m2=hud_m3
	hud_m3=t
end

--level gen
function new_lvl()
	xmax=rand(xmax_min,xmax_max)
	ymax=rand(ymax_min,ymax_max)
	
	lvl={}
	for j=0,ymax-1 do
		lvl[j]={}
		for i=0,xmax-1 do
			if chance(50) then
				lvl[j][i]=t_emt0
			elseif chance(50) then
				lvl[j][i]=t_emt1
			else
				lvl[j][i]=t_emt2
			end
	end end
	make_square()
	add_e()
	add_i()
	//add_door()
end

function make_square()
	for j=0,ymax-1 do
		lvl[j][0]=t_wall
		lvl[j][xmax-1]=t_wall
	end
	for i=0,xmax-1 do
		lvl[0][i]=t_wall
		lvl[ymax-1][i]=t_wall
	end
end

function add_e()
	ens={}
	--[[
		see= sees player
	]]--
	for j=1,ymax-2 do
	for i=1,xmax-2 do
		if chance(1) then
			add(ens,{
				x=i,y=j,sp=2,
				ax=0,ay=0,as=0,
				see=false,
				name="test e"
			})
	end end end
end

function add_i()
	for j=1,ymax-2 do
	for i=1,xmax-2 do
		if chance(1) then
			idx=rand(1,#item_tps)
			add(l_itms,{
				x=i,y=j,idx=idx
			})
	end end end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000aaa00000000000000000000000000000000000000aa00000000000000000000000000000000000000000000000000000000000000000000000000
0070070000a000a00000700000007000000080000000c0000000a000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000a00aa00000000000007000000080000000c0000000aa00000000000000000000000000000000000000000000000000000000000000000000000000
0007700000a0a0a00007700000070000000080000000c0000000a000000000000000000000000000000000000000000000000000000000000000000000000000
0070070000a00aa00000700000070000000080000000c000000aaa00000000000000000000000000000000000000000000000000000000000000000000000000
0000000000a0000000007000007000000000000000000000000a0a00000000000000000000000000000000000000000000000000000000000000000000000000
00000000000aaaa00007770000700000000080000000c000000aaa00000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000008000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000002222220000990000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000011000000000010022000022000990000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000010000000000100020000002000990000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000020000002999999991111111100000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000001000000000020000002999999991111111100000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000020000002000990000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000100000000100022000022000990000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000001000002222220000990000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000
