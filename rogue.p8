pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
--constants
--=============
--cam
cam={x=0,y=0}

--hud
hud_h=4
hud_m1="..."
hud_m2="..."
hud_m3="..."

--menus
menu_w=42
menu_h=53
sub_w=22
sub_menu_i={"use","throw","drop"}
mm={
	open=-1,point=1,
	sub_m=0, in_sub=0, sub_pt=1,
	sub_pos=1
}

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
t_grss=38
t_soil=39

--level gen
levels={
--empty
{sp=t_emt0,autos=0,prob=0},
--thick grass
{sp=t_grss,autos=2,prob=20},
--thin grass
{sp=t_grss,autos=2,prob=10}
}

--player
pp={x=8,y=8,sp=1,sx=8,sy=8,
	ax=0,ay=0,as=0,//attack anim,
	xp=1,lvl=1,wpn=nil,
	hp_max=10,mn_max=10,
	hp=5,mn=5,
	//status stuff
	inv_tm=0,
	is_psn=false,
	is_par=false
	}

--throw
throw={open=-1,idx=nil,
	x=-1,y=-1}
throw_r=3//throw radius
	
--bag
bag={}
bag_l=4
	
--arrays
ens={}
l_itms={}

--items
item_tps={
k=		{sp=16,disp="key"},
hp=	{disp="hp+",val=2},
mn=	{disp="mana+",val=2},
inv={disp="inv",val=20},
psn={disp="psn"},
par={disp="par"},
h_psn={disp="heal psn"},
h_par={disp="heal par"},
}

--status stuff
psn_chance=20
par_chance=20
	
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
	init_items()
	local ll=levels[
		rand(1,#levels)
	]
	new_lvl(ll)
	item_test()
end

function init_items()
	--set fnd=false
	for i in all(item_tps) do
		i.fnd=false
	end
	--set "k" type stuff
	item_tps["k"].fnd=true
	
	--randomize potions
	keys={"hp","mn","inv","psn",
		"par","h_psn","h_par"}
	sprites={4,5,6,7,8,9,10,11}
	for key in all(keys) do
		local idx=rand(1,#sprites)
		item_tps[key].sp=sprites[idx]
		del(sprites,sprites[idx])
	end
end

--draw
--=============
function _draw()
	cls()
	camera(cam.x*8,cam.y*8)
	draw_hud()
	draw_lvl()
		--player
	spr(pp.sp,(pp.x*8)+pp.ax,
	(pp.y*8)+pp.ay)
	
	if(mm.open==1)draw_menu()
	if(throw.open==1)draw_throw()
end

function draw_hud()
	local cx=(cam.x*8)+2
	local r1=(cam.y*8)+99
	local r2=(cam.y*8)+106
	local r3=(cam.y*8)+113
	local r4=(cam.y*8)+121
	rect(cx-2,r1-2,cx+125,r4+6,1)
	-- stats
	print("hp  :"..pp.hp.."/"..pp.hp_max,
		cx,r1,7)
	print("mana:"..pp.mn.."/"..pp.mn_max,
		cx,r2,7)
	print("wpn :",cx,r3,7)
	spr(3,cx+18,r3-3)
	print("(+1)",cx+25,r3,5)
	print("lvl :"..pp.lvl,cx,r4,7)
	print("xp:"..pp.xp.."/100",
		cx+30,r4,5)
	--log rows
	line(cx+48,r1-1,cx+48,r4-2,1)
	line(cx-1,r4-2,cx+128,r4-2,1)
	print(hud_m1,cx+50,r1,5)
	print(hud_m2,cx+50,r2,6)
	print(hud_m3,cx+50,r3,7)
	--player status
	local sts_pt=cx+69
	--psn
	if pp.is_psn then
		print("psn",sts_pt,r4,2)
		sts_pt+=14
	end
	--par
	if pp.is_par then
		print("par",sts_pt,r4,9)
		sts_pt+=14
	end
	--inv
	if pp.inv_tm>0 then
		print("inv("..pp.inv_tm..")",
			sts_pt,r4,6)
	end
end

function draw_menu()
	--draw box
	local mx=(pp.x*8)+8
	local my=(pp.y*8)+8
	if(xmax-pp.x<9)mx-=menu_w+8
	if(ymax-pp.y<6)my-=menu_h+8
	rectfill(mx,my,mx+menu_w,my+menu_h,0)
	rect(mx,my,mx+menu_w,my+menu_h,7)
	--draw title
	if mm.point==0 then
		rectfill(mx+1,my+1,mx+5,my+7,2)
		print("<",mx+2,my+2,7)
		print("menu",mx+6,my+2,7)
	else
		print("menu",mx+2,my+2,7)
	end
	line(mx,my+8,mx+menu_w,my+8,7)
	--help item
	if mm.point>0 and mm.point<3 then
	rectfill(mx+1,
		my+9+((mm.point-1)*6),
		mx+menu_w-1,
		my+15+((mm.point-1)*6),
		2)
	end
	print("help",mx+2,my+10,12)
	print("log",mx+2,my+16,12)
		
	--draw bag
	local i=1
	local hl_c=8
	for key in all(bag) do
		if i==mm.point-2 then
			local hl_c=2
			if(mm.in_sub==1)hl_c=1
			rectfill(mx+1,
				my+21+((i-1)*8),
				mx+menu_w-1,
				my+28+((i-1)*8),
				hl_c)
			if mm.sub_m==1 then
				draw_sub_m(mx,my+20+((i-1)*8))
			end 
		end
		local sp=item_tps[key].sp
		local disp=item_tps[key].disp
		spr(sp,mx+1,
				my+20+((i-1)*8))
		if item_tps[key].fnd then
			print(disp,mx+10,
				my+23+((i-1)*8),7)
		else
			print("??",mx+10,
				my+23+((i-1)*8),5)
		end
		i+=1
	end
end

function draw_sub_m(x,y)
	local sx=x+menu_w
	local sy=y
	mm.sub_pos=1
	if x<=pp.x*8 then
		sx-=(menu_w+sub_w)
		mm.sub_pos=-1
	end
	rectfill(sx,sy,sx+sub_w,sy+20,0)
	rect(sx,sy,sx+sub_w,sy+20,7)
	-- get correct sub menu
	local sub_menu=sub_menu_i
	
	local i=1
	for t in all(sub_menu) do
		if mm.in_sub==1 and 
					mm.sub_pt==i then
			rectfill(sx+1,sy+1+((i-1)*6),
				sx+sub_w-1,sy+7+((i-1)*6),
				2)
		end
		print(t,sx+2,sy+2+((i-1)*6),7)
		i+=1
	end
	
	//hack, 2 lazy
	if mm.sub_pt>#sub_menu then
		mm.sub_pt=#sub_menu
	end
end

function draw_throw()
	local imin=max(pp.x-throw_r,1)
	local imax=min(pp.x+throw_r,xmax-2)
	local jmin=max(pp.y-throw_r,1)
	local jmax=min(pp.y+throw_r,ymax-2)
	rect(imin*8,jmin*8,
		(imax*8)+8,(jmax*8)+8,9)
	rect(throw.x*8,throw.y*8,
		(throw.x*8)+8,(throw.y*8)+8,10)
end

function draw_lvl()
	for j=cam.y,cam.y+(15-hud_h)do
	for i=cam.x,cam.x+15 do
		local dd=true
		--items
		for it in all(l_itms) do
			if i==it.x and j==it.y then
				dd=false
				spr(item_tps[it.key].sp,
					i*8,j*8)
		end end
		--enemies
		--items
		for e in all(ens) do
			if e.inv_tm==0 then
				if i==e.x and j==e.y then
					dd=false
					spr(e.sp,(i*8)+e.ax,
						(j*8)+e.ay)
					if e.see then
						spr(18,(e.x*8)+6,e.y*8)
					end
				end
		end end
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
	
	if mm.open==1 then
		update_menu(mv)
	elseif mv.b==1 then
		mm.open=1
		throw.open=-1
	elseif throw.open==1 then
		update_throw(mv)
	else
		if move_p(mv) then
			move_e()
			update_status(pp)
		end
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
		elseif mm.point==2 then
			//log
		elseif mm.in_sub==1 then
			//do item action
			use_item(mm.point-2,mm.sub_pt)
			mm.open=-1
			mm.in_sub=-1
			mm.point=1
			mm.sub_pt=1
			return
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
		elseif mv.y==1 and mm.point<#bag+2 then
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
		mm.open=-1
	end
end

function update_throw(mv)
	local imin=max(pp.x-throw_r,1)
	local imax=min(pp.x+throw_r,xmax-2)
	local jmin=max(pp.y-throw_r,1)
	local jmax=min(pp.y+throw_r,ymax-2)
	throw.x+=mv.x
	throw.y+=mv.y
	throw.x=max(throw.x,imin)
	throw.x=min(throw.x,imax)
	throw.y=max(throw.y,jmin)
	throw.y=min(throw.y,jmax)
	
	if mv.a==1 then
		key=bag[throw.idx]
		--[[
		if item_tps[key].fnd then
			//only set fnd if hits player
			// or enemy
			message("threw "..
				item_tps[key].disp)
		else
			message("threw ??")
		end]]--
		if throw.x==pp.x and
				throw.y==pp.y then
			message("threw "..
				item_tps[key].disp)
			apply_item(key,pp)
		else
			local hit_e=false
			for e in all(ens) do
				if throw.x==e.x and
						throw.y==e.y then
					hit_e=true
					message("threw "..
						item_tps[key].disp)
					apply_item(key,e)
				end
			end
			if not hit_e then
				message("threw ??")
				apply_item(key,nil)
			end
		end
		del(bag,bag[throw.idx])
		throw.open=-1
		mm.open=-1
	end
end

function move_p(mv)
	local nx=pp.x+mv.x
	local ny=pp.y+mv.y
	// should we return true if
	// spell casted or item used?
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
			return true
		end
	end
	--pick up item
	for it in all(l_itms) do
		if it.x==nx and it.y==ny then
			if #bag < bag_l then
				if item_tps[it.key].fnd then
					message("picked up "..
						item_tps[it.key].disp)
				else
					message("picked up ??")
				end
				add(bag,it.key)
				del(l_itms,it)
			else	
				message("bag full")
			end
		end
	end
	-- move player
	pp.x=nx
	pp.y=ny
	
	-- change grass
	if lvl[pp.y][pp.x]==t_grss then
		lvl[pp.y][pp.x]=t_soil
	end
	
	-- door
	
	return true
end

function update_status(o)
	if(o.inv_tm>0)o.inv_tm-=1
	if o.is_psn and chance(psn_chance) then
		local o_name="plr"
		if(o.name!=nil)o_name=o.name
		o.hp-=1
		if o.hp<=0 then
			message(o_name.." killed by psn")
		else
			message(o_name.." hurt by psn")
		end
	end
end

function use_item(idx,action)
	key=bag[idx]
	if key=="k" then
		message("you cant do that")
		return end
		
	if action==1 then --use
		item_tps[key].fnd=true
		message("used "..item_tps[key].disp)
		apply_item(key,pp)
		del(bag,bag[idx])
	elseif action==2 then --throw
		throw.open=1
		throw.idx=idx
		throw.x=pp.x
		throw.y=pp.y
	elseif action==3 then --drop
		if item_tps[key].fnd then
			message("dropped "..
				item_tps[key].disp)
		else
			message("dropped ??")
		end
		del(bag,bag[idx])
	end
end

function apply_item(key,o)
	item_tps[key].fnd=true
	local it=item_tps[key]
	if o==nil then
		// some items can spread yeah?
	else
		--apply hp
		if key=="hp" then
			o.hp+=it.val
			if(o.hp>o.hp_max)o.hp=o.hp_max
		--apply mana
		elseif key=="mn" then
			if o.mn != nil then
				o.mn+=it.val
				if(o.mn>o.mn_max)o.mn=o.mn_max
			end
		--apply inv
		elseif key=="inv" then
			o.inv_tm+=it.val
		--apply psn
		elseif key=="psn" then
			o.is_psn=true
		--apply par
		elseif key=="par" then
			o.is_par=true
		--apply h_psn
		elseif key=="h_psn" then
			o.is_psn=false
		--apply_h_par
		elseif key=="h_par" then
			o.is_par=false
		end
	end
end

function attack_p(e)
	if e.is_par and chance(par_chance) then
		message(e.name.." par-no atk")
	else
		pp.hp-=1
		message(e.name.." hit you")
	end
end

function move_e()
	for e in all(ens) do
		update_status(e)
		if e.hp<=0 then
			pp.xp+=e.xp
			del(ens,e)
			return
		end
		
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
		if(pp.inv_tm>0)e.see=false
	end
end

function attack_e(e)
	if pp.is_par and chance(par_chance) then
		message("plr par-no atk")
	end
	local atk=pp.lvl
	if pp.wpn != nil then
		atk+=item_tps[pp.wpn].val
	end
	e.hp-=atk
	if e.hp <= 0 then
		message("you killed "..e.name)
	else
		message("you hit "..e.name)
	end
end

--creators
--=============
function message(t)
	hud_m1=hud_m2
	hud_m2=hud_m3
	hud_m3=t
end

--level gen
function new_lvl(config)
	xmax=rand(xmax_min,xmax_max)
	ymax=rand(ymax_min,ymax_max)
	
	lvl={}
	for j=0,ymax-1 do
		lvl[j]={}
		for i=0,xmax-1 do
			lvl[j][i]=t_emt0
	end end
	local cells = cell_auto(
		config.autos,config.prob
	)
	
	for j=0,ymax-1 do
		for i=0,xmax-1 do
			if cells[j][i]==1 then
				lvl[j][i]=config.sp
			elseif chance(50) then
				lvl[j][i]=t_emt1
			elseif chance(50) then
				lvl[j][i]=t_emt2
			end
	end end
	
	make_walls()
	add_e()
	//add_i()
	//add_k()
	//add_door()
end

function make_walls()
	for j=0,ymax-1 do
		lvl[j][0]=t_wall
		lvl[j][xmax-1]=t_wall
	end
	for i=0,xmax-1 do
		lvl[0][i]=t_wall
		lvl[ymax-1][i]=t_wall
	end
end

function cell_auto(num,prob)
	local tt={}
	--basic noise
	for j=0,ymax-1 do
		tt[j]={}
		for i=0,xmax-1 do
			tt[j][i]=0
			if chance(prob) then
				tt[j][i]=1
			end 
		end 
	end
	
	local runs = num
	while runs > 0 do
		runs -= 1
		
		--make copy of tt
		local temp={}
		for j=0,ymax-1 do
			temp[j]={}
			for i=0,xmax-1 do
				temp[j][i]=tt[j][i]
		end end
		
		--cgl(kinda)
		for j=0,ymax-1 do
		for i=0,xmax-1 do
			local n=get_surr(j,i,tt)
			if tt[j][i]==0 and n>3 then
				temp[j][i]=1
			elseif tt[j][i]==1 and n<1 then
				temp[j][i]=0
			end
		end end
		
		-- copy back to tt
		for j=0,ymax-1 do
		for i=0,xmax-1 do
			tt[j][i]=temp[j][i]
		end end
	end
	return tt
end

function get_surr(j,i,a)
	local jmin=max(j-1,0)
	local jmax=min(ymax-1,j+1)
	local imin=max(i-1,0)
	local imax=min(xmax-1,i+1)
	local n=0
	for jj=jmin,jmax do
	for ii=imin,imax do
		if jj != j or ii != i then
			if a[jj][ii]==1 then
				n+=1
			end
		end
	end end
	return n
end

function add_e()
	ens={}
	for j=1,ymax-2 do
	for i=1,xmax-2 do
		if chance(1) then
			add(ens,{
				x=i,y=j,sp=2,xp=1,
				ax=0,ay=0,as=0,
				hp=2,hp_max=2,
				see=false,
				name="test e",
				//status stuff
				inv_tm=0,
				is_psn=false,
				is_par=false
			})
	end end end
end

function add_i()
	local keys={}
	for k,v in pairs(item_tps) do
		if(k!="k")add(keys,k) 
	end
		
	for j=1,ymax-2 do
	for i=1,xmax-2 do
		if chance(1) then
			add(l_itms,{
				x=i,y=j,
				key=keys[rand(1,#keys)]
			})
	end end end
end

function item_test()
	local x=1
	local y=1
	for k,v in pairs(item_tps) do
		add(l_itms,{
		x=x,y=y,key=k
		})
		add(l_itms,{
		x=x,y=y+1,key=k
		})
		x+=1
		if x>14 then
			x=0
			y+=2
		end
	end
end

function add_k()
	while true do
	local rx=rand(1,xmax-2)
	local ry=rand(1,ymax-2)
	local place=true
	for it in all(l_itms) do
		if rx==it.x and ry==it.y then
			place=false
	end end
	if place then
		add(l_itms,{
			x=rx,y=ry,key="k"
		})
		return
	end end
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000aaa000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0070070000a000a00000700000007000000080000000c0000000b0000000e000000090000000d0000000a0000000f00000000000000000000000000000000000
0007700000a00aa00000000000007000000080000000c0000000b0000000e000000090000000d0000000a0000000f00000000000000000000000000000000000
0007700000a0a0a00007700000070000000080000000c0000000b0000000e000000090000000d0000000a0000000f00000000000000000000000000000000000
0070070000a00aa00000700000070000000080000000c0000000b0000000e000000090000000d0000000a0000000f00000000000000000000000000000000000
0000000000a000000000700000700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000aaaa00007770000700000000080000000c0000000b0000000e000000090000000d0000000a0000000f00000000000000000000000000000000000
00000000000000009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000aa00000000009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000aa00000000009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000aaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000aaa00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000002222220000990000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000011000000000010022000022000990000001100000030000000000000000000000000000000000000000000000000000000000000000000000000000
00000000010000000000100020000002000990000001100000303030000003000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000020000002999999991111111103000300003000000000000000000000000000000000000000000000000000000000000000000000
00000000000001000000000020000002999999991111111100030000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000020000002000990000001100000303030000003000000000000000000000000000000000000000000000000000000000000000000
00000000000100000000100022000022000990000001100003000300003000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000001000002222220000990000001100000000000000000000000000000000000000000000000000000000000000000000000000000000000
