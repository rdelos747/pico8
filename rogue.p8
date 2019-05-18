pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--constants
--=============
--cam
cam={x=0,y=0}
--player
pp={x=8,y=8,sp=1,sx=8,sy=8}
change_room=nil
change_dly=2
--menus
menu_w=32
sub_w=22
main_menu={
	{name="items"},
	{name="weapons"}
}
sub_menu={"equip","throw","drop"}
items={}
weapons={}
mm={
	open=-1, page=1, point=1,
	sub_m=0, in_sub=0, sub_pt=1,
	sub_pos=1,
	pages={"menu","items","weapons"},
	menus={
		main_menu,
		items,
		weapons
	}
}
--level
xmax_min=16
xmax_max=26
ymax_min=16
ymax_max=26
xmax=-1
ymax=-1
lvl={}
t_empt=48
t_wall=49
t_door=50

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
	create_item("test 1")
	create_item("test 2")
end

--draw
--=============
function _draw()
	cls()
	--cam
	camera(cam.x*8,cam.y*8)
 if change_room==nil then
 	--level
		draw_lvl()
		--menu
		if(mm.open==1)draw_menu()
	end
	--player
	spr(pp.sp,(pp.x*8)-1,(pp.y*8)-1)
	
end

function draw_lvl()
	for j=cam.y,cam.y+15 do
	for i=cam.x,cam.x+15 do
		spr(lvl[j][i],i*8,j*8)
	end end
end

function draw_menu()
	--draw box
	local mx=(pp.x*8)+8
	local my=(pp.y*8)+8
	if(xmax-pp.x<8)mx-=menu_w+8
	if(ymax-pp.y<8)my-=menu_w+8
	rect(mx,my,mx+menu_w,my+menu_w,7)
	--draw title
	local title=mm.pages[mm.page]
	if mm.point==0 then
		rectfill(mx+1,my+1,mx+5,my+7,8)
		print("<",mx+2,my+2,7)
		print(title,mx+6,my+2,7)
	else
		print(title,mx+2,my+2,7)
	end
	line(mx,my+8,mx+menu_w,my+8)
	--draw list
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
	
	if mm.open==1 then
		update_menu(mv)
	elseif mv.b==1 then
		mm.open=1
	else
		move_p(mv)
		move_cam()
	end
end

function move_cam()
	cam.x=pp.x-8
	cam.y=pp.y-8
	if(cam.x<0)cam.x=0
	if(cam.y<0)cam.y=0
	if(cam.x>xmax-16)cam.x=xmax-16
	if(cam.y>ymax-16)cam.y=ymax-16
end

function update_menu(mv)
	local am=mm.menus[mm.page]
	-- o button
	if(mv.b==1)close_menu()
	-- x button
	if mv.a==1 then
		if mm.point==0 then
			close_menu()
		elseif mm.page==1 then
			mm.page=mm.point+1
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
		elseif mv.y==1 and mm.point<#am then
			mm.point+=1
		end
	end
	
	-- toggle sub menu
	if mm.page>1 and mm.point>0 then
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

function close_menu()
	mm.point=1
	mm.sub_pt=1
	if mm.page==1 then
		mm.open=-1
	else
		mm.page=1
	end
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
		printh("ymax "..ymax)
		printh("end y0 "..pp.y)
		if pp.y>8 then
			pp.y=(ymax-1)-(15-pp.y)
			printh("end y1 "..pp.y)
		else
			printh("end y2 "..pp.y)
		end
	else
		if change_room.dy==1 then
			pp.y=ymax-1 else pp.y=0
		end
	end
	move_cam()
	change_room=nil
end

function move_p(mv)
	--check collision, then
	local nx=pp.x+mv.x
	local ny=pp.y+mv.y
	if nx<0 or nx>xmax-1 or
				ny<0 or ny>ymax-1 then
		return
	end
	if lvl[ny][nx]==t_wall then
		return
	end
	pp.x=nx
	pp.y=ny
	if lvl[pp.y][pp.x]==t_door then
		create_change(mv)
	end
end

--creators
--=============
function create_change(mv)
	//local dy=0
	//local dx=0
	//if mv.x!=0 then
	//	dy=rand
	//else
	//end
	printh(".....")
	printh("y "..pp.y)
	local side=""
	local step_x=0
	local step_y=0
	local dx=mv.x*-1
	local dy=mv.y*-1
	if mv.x!=0 then
		side="x"
		step_x=15
		pp.y-=cam.y
		local ny=rand(1,14)
		printh("to y "..ny)
		step_y=abs(ny-pp.y)
		printh("y% "..pp.y)
		printh("sy "..step_y)
		if(ny>pp.y)dy=1
		if(ny<pp.y)dy=-1
	else
		side="y"
		step_y=15
		pp.x=pp.x-cam.x
		local nx=rand(1,14)
		printh("to x "..nx)
		step_x=abs(nx-pp.x)
		printh("x% "..pp.x)
		if(nx>pp.x)dx=1
		if(nx<pp.x)dx=-1
	end
	change_room={
		side=side,
		step_x=step_x,
		step_y=step_y,
		dx=dx,dy=dy
	}
	printh("side"..side)
	printh("dx"..dx)
	printh("dy"..dy)
	
end

function create_item(n)
	local i={
		name=n
	}
	add(items,i)
end

--level gen
function new_lvl()
	xmax=rand(xmax_min,xmax_max)
	ymax=rand(ymax_min,ymax_max)
	
	lvl={}
	for j=0,ymax-1 do
		lvl[j]={}
		for i=0,xmax-1 do
			lvl[j][i]=t_empt
			//if(chance(20))lvl[j][i]=1
	end end
	make_square()
	add_door()
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
		local ry=rand(1,ymax-2)
		if lvl[ry][rx]==t_wall then
			lvl[ry][rx]=t_door
			return
		end
	end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000777000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700007000700000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000007007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000007070700007700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700007007700000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000007000000000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000777700007770000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
10000001022222200009900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000220000220009900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000200000020009900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000200000029999999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000200000029999999900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000200000020009900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000220000220009900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
10000001022222200009900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
