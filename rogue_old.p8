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
show_help=false
--player
pp={x=8,y=8,sp=1,sx=8,sy=8,
				ax=0,ay=0,as=0,//attack anim
				hp=5,mn=5}
itm_l=4 //items length
spl_l=4 //spells length
change_room=nil
change_dly=2
--menus
menu_w=32
menu_h=40
sub_w=22
sub_menu_i={"use","throw","drop"}
sub_menu_w={"equip","drop"}
sub_menu_s={"set","drop"}
items={}
spells={}
mm={
	open=-1,point=1,
	sub_m=0, in_sub=0, sub_pt=1,
	sub_pos=1
}
--level
xmax_min=16
xmax_max=26
ymax_min=16
ymax_max=26
xmax=-1
ymax=-1
lvl={}
t_emt0=32
t_emt1=33
t_emt2=34
t_wall=35
t_door=36
t_cdor=37

--arrays
ens={}
l_itms={}
l_spls={}

--all items
--each value is the amount
-- that stat increases,
-- or the effect it has,
-- eg, fire=1 creates fire.
-- also, cl=color,fnd=found
all_itms={
{sp=4,fnd=-1,hp=1,mn=0},
{sp=5,fnd=-1,hp=0,mn=1}
}

-- helpers
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
	--cam
	camera(cam.x*8,cam.y*8)
	if show_help then
		draw_hud_help()
 else
 	if change_room==nil then
 		--level
			draw_lvl()
			--menu
			if(mm.open==1)draw_menu()
		end
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
		--hud
		draw_hud()
	end
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
		for e in all(ens) do
			if e.x==i and e.y==j then
				dd=false
		 end
		end
		for it in all(l_itms) do
			if it.x==i and it.y==j then
				dd=false
				spr(it.sp,it.x*8,it.y*8)
			end
		end
		for w in all(l_wpns) do
			if w.x==i and w.y==j then
				dd=false
				spr(w.sp,w.x*8,w.y*8)
			end
		end
		if(pp.x==i and pp.y==j)dd=false
		if(dd)spr(lvl[j][i],i*8,j*8)
	end end
end

function draw_menu()
	--draw box
	local mx=(pp.x*8)+8
	local my=(pp.y*8)+8
	if(xmax-pp.x<8)mx-=menu_w+8
	if(ymax-pp.y<8)my-=menu_w+8
	rect(mx,my,mx+menu_w,my+menu_h,7)
	--draw title
	if mm.point==0 then
		rectfill(mx+1,my+1,mx+5,my+7,8)
		print("<",mx+2,my+2,7)
		print("menu",mx+6,my+2,7)
	else
		print("menu",mx+2,my+2,7)
	end
	line(mx,my+8,mx+menu_w,my+8,7)
	--help item
	if mm.point==1 then
	rectfill(mx+1,
		my+9+((mm.point-1)*6),
		mx+menu_w-1,
		my+15+((mm.point-1)*6),
		8)
	end
	print("help",mx+2,my+10,12)
		
	--draw list
	local i=1
	local hl_c=8
	for t in all(items) do
		if i==mm.point-1 then
			local hl_c=8
			if(mm.in_sub==1)hl_c=2
			rectfill(mx+1,
				my+15+((i-1)*6),
				mx+menu_w-1,
				my+21+((i-1)*6),
				hl_c)
			if mm.sub_m==1 then
				draw_sub_m(mx,my+15+((i-1)*6))
			end 
		end
		local idx=t.idx
		local name=all_itms[idx].name
		local sp=all_items[idx].sp
		spr(sp,mx+2,
				my+16+((i-1)*6))
		i+=1
	end
	--[[
	local i=1
	for t in all(mm.menus[mm.page])do
		if i==mm.point then
			local hl_c=8
			if(mm.in_sub==1)hl_c=2
			rectfill(mx+1,my+9+((i-1)*6),
				mx+menu_w-1,my+15+((i-1)*6),
				hl_c)
			if(mm.sub_m==1)draw_sub_m(mx,my+9+((i-1)*6))
		end
		print(t.name,mx+2,my+10+((i-1)*6),7)
		i+=1
	end
	]]--
end

function draw_sub_m(x,y)
	local sx=x+menu_w
	local sy=y-1
	mm.sub_pos=1
	if x<=pp.x*8 then
		sx-=(menu_w+sub_w)
		mm.sub_pos=-1
	end
	rect(sx,sy,sx+sub_w,sy+20,7)
	-- get correct sub menu
	local sub_menu=sub_menu_i
	--[[
	if mm.pages[mm.page]=="items"
				and items[mm.point].typ=="weapon" then
		sub_menu=sub_menu_w
	elseif mm.pages[mm.page]=="spells" then
		sub_menu=sub_menu_s
	end
	]]--
	
	local i=1
	for t in all(sub_menu) do
		if mm.in_sub==1 and 
					mm.sub_pt==i then
			rectfill(sx+1,sy+1+((i-1)*6),
				sx+sub_w-1,sy+7+((i-1)*6),
				8)
		end
		print(t,sx+2,sy+2+((i-1)*6),7)
		i+=1
	end
	
	//hack, 2 lazy
	if mm.sub_pt>#sub_menu then
		mm.sub_pt=#sub_menu
	end
end

--update
--=============
function _update()
	if change_room!=nil then
		anim_change()
		return
	end
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
	
	if show_help then
		if mv.a==1 or mv.b==1 then
			show_help=false
		end return
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
	
	if mm.open==1 then
		update_menu(mv)
	elseif mv.b==1 then
		mm.open=1
	else
		if(move_p(mv))move_e()
		move_cam()
	end
end

function move_cam()
	cam.x=pp.x-8
	cam.y=pp.y-(8-hud_h)
	if(cam.x<0)cam.x=0
	if(cam.y<0)cam.y=0
	if(cam.x>xmax-16)cam.x=xmax-16
	if(cam.y>ymax-(16-hud_h))cam.y=ymax-(16-hud_h)
end

function update_menu(mv)
	-- o button
	if(mv.b==1)mm.open=-1
	-- x button
	if mv.a==1 then
		if mm.point==0 then
			mm.open=-1
		elseif mm.point==1 then
			show_help=true
			mm.open=-1
		else
			//do item action
		end
	end
	-- up/down
	if mm.in_sub==1 then
		if mv.y==-1 and mm.sub_pt>1 then
			mm.sub_pt-=1
		elseif mv.y==1 and mm.sub_pt<3 then
			mm.sub_pt+=1
		end
	else
		if mv.y==-1 and mm.point>0 then
			mm.point-=1
		elseif mv.y==1 and mm.point<#items+1 then
			mm.point+=1
		end
	end
	
	-- toggle sub menu
	if mm.point>1 then
		mm.sub_m=1
		if(mv.x!=0)mm.in_sub=mv.x*mm.sub_pos
	else
		mm.sub_m=0
		mm.in_sub=0
	end
	
	--special arrow stuff
	if mm.point==0 and mv.x==-1 then
		close_menu()
	end
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
	-- move player
	pp.x=nx
	pp.y=ny
	-- pickup item
	for it in all(l_itms) do
		if it.x==pp.x and it.y==pp.y then
			if #items >= itm_l then
				message("bag full")
				return
			end
			local idx=it.idx
			local sp=all_itms[idx].sp
			message("you got ")
			add(items,idx)
			del(l_itms,it)
		end
	end
	-- door
	if lvl[pp.y][pp.x]==t_door then
		create_change(mv)
		local ttt=rand(0,10)
		message("p hit door"..ttt)
	end
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

function anim_change()
	if change_dly>0 then
		change_dly-=1
		return
	else
		change_dly=1
	end
	local change=false
	if change_room.step_x>0 then
		change_room.step_x-=1
		pp.x+=change_room.dx
		change=true
	end
	if change_room.step_y>0 then
		change_room.step_y-=1
		pp.y+=change_room.dy
		change=true
	end
	if(change)return
	new_lvl()
	if change_room.side=="x" then
		if change_room.dx==1 then
			pp.x=xmax-1 else pp.x=0
		end
		if pp.y>8 then
			pp.y=(ymax-1)-(15-pp.y)
		end
	else
		if change_room.dy==1 then
			pp.y=ymax-1 else pp.y=0
		end
		if pp.x>8 then
			pp.x=(xmax-1)-(15-pp.x)
		end
	end
	move_cam()
	change_room=nil
	lvl[pp.y][pp.x]=t_cdor
end

--creators
--=============
function message(t)
	hud_m1=hud_m2
	hud_m2=hud_m3
	hud_m3=t
end

function create_change(mv)
	local side=""
	local step_x=0
	local step_y=0
	local dx=mv.x*-1
	local dy=mv.y*-1
	if mv.x!=0 then
		side="x"
		step_x=15
		pp.y-=cam.y
		local ny=rand(1,14-hud_h)
		step_y=abs(ny-pp.y)
		if(ny>pp.y)dy=1
		if(ny<pp.y)dy=-1
	else
		side="y"
		step_y=15-hud_h
		pp.x-=cam.x
		local nx=rand(1,14)
		step_x=abs(nx-pp.x)
		if(nx>pp.x)dx=1
		if(nx<pp.x)dx=-1
	end
	change_room={
		side=side,
		step_x=step_x,
		step_y=step_y,
		dx=dx,dy=dy
	}
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
	add_door()
	add_e()
	l_itms={}
	// pass lvl specific params
	// in these 
	add_i()
//	add_w()
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

function add_door()
	while 1 do
		local rx=rand(0,xmax-1)
		local ry=rand(0,ymax-1)
		if rx != 0 or ry !=0 or
					rx != xmax-1 or
					ry != ymax-1 then
		if lvl[ry][rx]==t_wall then
			lvl[ry][rx]=t_door
			return
		end end
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
			local idx=rand(1,#all_itms)
			add(l_itms,{
				idx=idx,
				x=i,y=j
			})
	end end end
end

--[[
function add_w()
	for j=1,ymax-2 do
	for i=1,xmax-2 do
		for it in all(l_
		if chance(1) then
			add(l_itms,{
				name="test item",
				typ="weapon",
				x=i,y=j,sp=4
			})
	end end end
end
]]--

--help
--=============
function draw_hud_help()
	local cx=(cam.x*8)
	local cy=(cam.y*8)
	local r1=(cam.y*8)+105
	local r2=(cam.y*8)+113
	local r3=(cam.y*8)+121
	--hud
	print("hud",cx,r1-8,5)
	print("hp  :",cx,r1,7)
	print("<health points>",cx+20,r1,12)
	print("mana:",cx,r2,7)
	print("<magic points>",cx+20,r2,12)
	print("wpn :",cx,r3,7)
	print("<current wpn>",cx+20,r3,12)
	print("(wpn power)",cx+75,r3,13)
	--explanations
	print("controls",cx,cy,5)
	print("❎:",cx,cy+8,7)
	print("attack/select",cx+16,cy+8,12)
	print("🅾️:",cx,cy+16,7)
	print("open/close menu",cx+16,cy+16,12)
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000aaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070000a000a00000700000007000000080000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000a00aa00000000000007000000080000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000a0a0a00007700000070000000080000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070000a00aa00000700000070000000080000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000a000000000700000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000aaaa00007770000700000000080000000c00000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
