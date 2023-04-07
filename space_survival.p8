pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- space survival

// story=0
--[[
0 begin
1 john 1
2 john 2
3 blue key

99 green key // test
100 red key // test
]]--

splt={} -- blood splat
strs={} -- stars
flames={}

lvls={
	crew={
		top=0,lft=64,bot=15,rht=112,
		doors={
			{x=66,y=6,dir="h"},
			{x=78,y=6,dir="h"},
			{x=82,y=6,dir="h",story=2}, //story=2 is a hack
			{x=79,y=13,dir="v",to="cpu",story=3},
			{x=84,y=8,dir="v"},
			{x=110,y=11,dir="h",to="hall"},
			{x=64,y=8,dir="v",to="cat_walk",story=99}
		},
		enemy_map={
			--x,y,typ,story,sleep
			{103,8,0},
			{105,9,0},
			{106,4,0,3},
			{90,8,0,3},
			{67,9,1,0,3}
		}
	},
	bridge={
		top=0,lft=0,bot=0,rht=0,
		doors={
			{x=112,y=33,dir="v",to="hall"}
		},
	},
	hall={
		top=11,lft=108,bot=41,rht=112,
		doors={
			{x=110,y=11,dir="h",to="crew"},
			{x=112,y=33,dir="v",to="bridge"}
		},
	},
	cpu={
		top=10,lft=79,bot=23,rht=103,
		doors={
			{x=79,y=13,dir="v",to="crew"},
			{x=79,y=20,dir="v",to="pipes",story=16},
			{x=103,y=14,dir="v",to="m2",story=8},
			{x=103,y=21,dir="v",to="m2",story=8}
		},
		enemy_map={
			{87,13,0},
			{97,18,0},
			{93,21,1,4,16}
		}
	},
	m2={
		top=10,lft=103,bot=1000,rht=108,
		doors={
			{x=103,y=14,dir="v",to="cpu"},
			{x=103,y=21,dir="v",to="cpu"},
			{x=106,y=28,dir="h",story=100},
		}
	},
	pipes={
		top=0,lft=0,bot=0,rht=0,
		doors={}
	},
	cat_walk={
		top=0,lft=0,bot=0,rht=0,
	},
}

ds={} // door popups, also story popups?
ds[2]={
	"blue key card\nrequired"
}
ds[3]={
	"cpu room.\nblue key card\nrequired.",
	"used the blue\nkey."
}
ds[8]={
	"maintenance m2\naccess locked.",
	"accessing m2."
}
ds[16]={
	"maintenance m1\naccess locked.",
	"accessing m1."
}

lvl=nil

x_icon=nil
x_icon_t=0
popup=nil
notif=nil
notif_t=0

function _init()
	printh("====game start====")	
	add_stars()
	init_lvl(nil)
end

function init_lvl(from_door)
	printh("init level")
	popup=nil
	if from_door==nil then
		lvl=lvls[strt_lvl] --hack
	else
		lvl=lvls[from_door.to]
		printh("new level "..from_door.to)
	end
	
	-- add doors
	for d in all(lvl.doors)do
		if d.dir=="v" then
			mset(d.x,d.y,47)
		else 
			mset(d.x,d.y,46)
		end
	end
	
	-- init enemy list
	if lvl.enemies==nil then
		lvl.enemies={}
	end
	
	-- add enmies
	for em in all(lvl.enemy_map)do
		printh(em[4])
		if em[4]==nil or story>=em[4] then
			local slp=em[5]!=nil and em[5] or 0
			printh("adding slp")
			printh(slp)
			add_enemy(em[1]*8+6,em[2]*8,em[3],slp,lvl.enemies)
			del(lvl.enemy_map,em)
		end
	end
	
	-- reset living enemies
	for e in all(lvl.enemies)do
		e.agro=0
	end
	
	-- flames
	flames={}
	for j=lvl.top,lvl.bot do
	for i=lvl.lft,lvl.rht do
		if mget(i,j)==56 then
			add_flame(i,j)
		end
	end end
	
	if(from_door==nil)return
	
	-- move player to other side
	if from_door.dir=="h" then
		if pp.y<from_door.y*8 then
			pp.y=from_door.y*8+12
		else
			pp.y=from_door.y*8-9
		end
	else
		if pp.x<from_door.x*8 then
			pp.x=from_door.x*8+12
		else
			pp.x=from_door.x*8-9
		end
	end
end

function _draw()
	cls()
	if mode==90 then
		draw_buff()
	else
		draw_game()
	end
end

function draw_buff()
	for j=0,31 do
	for i=0,31 do
		if buff[j][i]==0 then
			pset(camx+i,camy+j,0)
		else
			pset(camx+i,camy+j,8)
		end
	end end
end

function draw_game()
	camera(camx,camy)
	
	local m_x=flr(camx/8)-1
	local m_y=flr(camy/8)-1
	local m_filter=0
	--if(pause>0)m_filter=1	???
	
	palt(0,false)
	foreach(strs,draw_star)
	
	map(m_x,m_y,m_x*8,m_y*8,
		18,18,m_filter)
	palt()
	
	for d in all(lvl.npc_d) do
		d()
	end
	
	foreach(lvl.enemies,draw_enemy)
	foreach(splt,draw_splt)
	foreach(flames,draw_flame)
	draw_lighting()
	draw_player()

	draw_hud()
	
	if x_icon!=nil then
		spr(flr(x_icon_t)%2==0 and 25 or 26,x_icon.x,x_icon.y)
	end
	
	if popup!=nil then
		rectfill(camx+18,camy+50,camx+110,camy+84,0)
		print(popup,camx+20,camy+52,7)
		
		rect(camx+18,camy+50,camx+110,camy+84,7)
		spr(flr(x_icon_t)%2==0 and 25 or 26,camx+102,camy+76)
	end
	
	if notif!=nil then
		local len=#notif*4/2
		print(notif,pp.x-len,pp.y-(8+notif_t),7)
	end
	
	print("x: "..pp.x..", y: "..pp.y,camx,camy,7)
	print("story: "..story,camx,camy+8,7)
end

function draw_hud()
	rectfill(camx,camy+120,camx+128,camy+128,0)
	if ammo==0 then
		print("no ammo",camx+1,camy+122,7)
	elseif reload_t>0 then
		if flr(reload_t/10)%2==1 then
			print("reloading",camx+1,camy+122,7)
		end
	else
		local a=ammo%8==0 and 8 or ammo%8
		for i=0,a-1 do
			line(camx+2+(i*2),camy+122,camx+2+(i*2),camy+125,5)
			pset(camx+2+(i*2),camy+122,9)
		end
	end
	
	if story>=3 then
		pal(15,12)
		spr(27,camx+120,camy+120)
	end
	if story>=99 then
		pal(15,11)
		spr(27,camx+112,camy+120)
	end
	if story>=100 then
		pal(15,8)
		spr(27,camx+104,camy+120)
	end
	pal()
end

buff={}

function draw_lighting()	
	for j=0,34 do
		buff[j]={}
	for i=0,34 do
		buff[j][i]=0
	end end
	
	draw_cone_32()
	
	-- player lighting
	for j=-2,1do
	for i=-2,1do
		local pi=flr(pp.x/4)+i
		local pj=flr(pp.y/4)+j
		local bi=(pi+1)-cami4 
		local bj=(pj+1)-camj4
		buff[bj][bi]=1
	end end
	
	-- draw buff
	pal(7,0)
	for j=0,32 do
	for i=0,32 do
		local x=cami4*4+i*4
		local y=camj4*4+j*4
		local m=mget(flr(cami4+i)/2,flr(camj4+j)/2)
		if x<0 or x>128*8 or 
					y<0 or y>128*4 or
					m==0 then
			goto continue
		end
		local v=buff[j][i]
		
		if v==0 then			
			if (buff[max(j-1,0)][i]==1 or
						buff[min(j+1,31)][i]==1 or
						buff[j][max(i-1,0)]==1 or
						buff[j][min(i+1,31)]==1) then
				spr(24,x,y)
			else
				rectfill(x,y,x+4,y+4,0)
			end
		end
		::continue::
	end end
	pal()
end

function draw_cone_32()
	--local pts={}
	
	local a=atan2(dx,dy) -- player angle
	a=(a-0.18)%1 --start angle, minus one half of the total
	local frac=0.36/64
	
	for x=0,63 do
		local cx=pp.x
		local cy=pp.y
		local step=0
		while step<14 do
			local i,j=flr(cx/4),flr(cy/4)
			local bi=(i+0)-cami4 --offset in buffer
			local bj=(j+0)-camj4 --offset in buffer
			if light_free(flr(i/2),flr(j/2)) then
				buff[bj][bi]=1
				step+=1
				--add(pts,{cx,cy,8})
			else
				-- if hit wall, 
				-- apply same lighting 
				-- but exit loop
				buff[bj][bi]=1
				step=1000
				--add(pts,{cx,cy,11})
			end
			cx+=cos(a)*4
			cy+=sin(a)*4
		end
		a=(a+frac)%1
	end
	
	//for p in all(pts)do
	//	pset(p[1],p[2],p[3])
	//end
end

function _update()
	update_game()
end

function update_game()
	x_icon=nil
	
	update_strs()
	-- player update must come before npc
	update_player()
	for u in all(lvl.npc_u) do
		u()
	end
	foreach(lvl.enemies,update_enemy)
	foreach(splt,update_splt)
	foreach(flames,update_flame)
	update_cam()
	
	x_icon_t=(x_icon_t+0.2)%2
	
	if notif !=nil then
		notif_t+=0.5
		if notif_t>15 then
			notif=nil
		end
	end
end

camx,camy=0,0
cami4,camj4=0,0
cami8,camj8=0,0
function update_cam()
	camx=pp.x-64
	camy=pp.y-64
	
	//local cur=lvl[cur_lvl]
	//camx=mid(camx,cur.left*8+64,cur.right*8+64)
	//camy=mid(camy,cur.top*8+64,cur.bot*8+64)

	cami8=flr(camx/8)
	camj8=flr(camy/8)
	--used for offsets when 
	--placing into buff
	cami4=flr(camx/4)
	camj4=flr(camy/4)
end

function round(n)
 return (n%1<0.5) and flr(n) or ceil(n)
end

function rand(bot,top)
	return flr(rnd((top+1)-bot))+bot
end

function randf(bot,top)
	return bot+(top-bot)*rnd() 
end

-- approx dist
function dist(a,b)
	local dx=a.x-b.x
	local dy=a.y-b.y
 local maskx,masky=dx>>31,dy>>31
 local a0,b0=(dx+maskx)^^maskx,(dy+masky)^^masky
 if a0>b0 then
  return a0*0.9609+b0*0.3984
 end
 return b0*0.9609+a0*0.3984
end

function place_free_bb(o,x,y)
	local ox=(o.x-o.w/2)
	local oy=(o.y-o.h/2)
	local f=true
	if(not place_free(ox+x,oy+y))f=false
	if(not place_free(ox+x+o.w,oy+y))f=false
	if(not place_free(ox+x,oy+y+o.h))f=false
	if(not place_free(ox+x+o.w,oy+y+o.h))f=false
	return f
end

function place_free(x,y)
	local i=flr(x/8)
	local j=flr(y/8)
	local b=mget(i,j)
	return b<32 or b>63
end

function light_free(i,j)
	local b=mget(i,j)
	return b<32 or b>47
end

function col_bb(a,b)
	local ax=a.x-a.w/2
	local ay=a.y-a.h/2
	local bx=b.x-b.w/2
	local by=b.y-b.h/2
	return ax<=bx+b.w and
		ax+a.w>=bx and ay<=by+b.h and
		ay+a.h>=by
end

function add_splt(a,x,y)
	for i=0,3 do
		local ra=randf(-0.1,0.1)
		add(splt,{
			x=x,y=y,a=a+ra,
			t=rand(0,5),s=3
		})
	end
end

function draw_splt(s)
	pset(s.x,s.y,8)
end

function update_splt(s)
	s.x+=cos(s.a)*s.s
	s.y+=sin(s.a)*s.s
	s.s*=0.5
	
	s.t+=1
	if s.t>10 then
		del(splt,s)
	end
end

function add_stars()
	for _=0,50 do
		local spd=randf(0.1,1)
		local c=7
		if(spd<0.5)c=16
		add(strs,{
			x=rand(1,128),y=rand(1,126),
			spd=spd,c=c
		})
	end
end

function draw_star(s)
	pset(camx+s.x,camy+s.y,s.c)
end

function update_strs()
	//if rand(0,100)>50 then
	//	add_star()
	//end
	for s in all(strs) do
		s.x-=3*s.spd
		if(s.x<=0)s.x=128
	end
end

function set_x_icon(x,y)
	x_icon={x=x,y=y}
end

function set_notif(s)
	notif=s
	notif_t=0
end

function add_flame(i,j)
	add(flames,{
		x=i*8,y=j*8,t=0,
		parts={}
	})
end

function draw_flame(f)
	for p in all(f.parts)do
		local col=6
		local sz=0
		if(p.t>5)col,sz=8,1
		if(p.t>10)col,sz=9,2
		if(p.t>15)col,sz=10,2
		rectfill(p.x,p.y,p.x+sz,p.y+sz,col)
	end
end

function update_flame(f)
	if f.t==0 then
		f.t=3
		add(f.parts,{
			x=f.x+rand(0,8),
			y=f.y+rand(0,8),
			t=rand(10,20)
		})
	end
	
	for p in all(f.parts) do
		p.y-=0.5
		p.t-=1
		if(p.t==0)del(f.parts,p)
	end
	
	f.t-=1
end
-->8
-- player
pp={
	w=4,h=7,
	//x=528,y=24,
	x=82*8,y=21*8,--test
}
dx=0
dy=1

//strt_lvl="crew"
strt_lvl="cpu"

//story=0
story=16

p_mode="norm"
walk_t=0
aim=0
ammo=0
reload_t=0
shot_t=0 --shot reset time
shot_f_t=0 --shot fire time, just for drawing
x_pressed,l_x_press=false,0
z_pressed,l_z_press=false,0
target=nil
cur_door=nil

anim_walk={2,3,2,1,2,3,2,1}

function draw_player()
	local idx=flr(walk_t)
	local px=(pp.x-pp.w/2)-1
	local py=(pp.y-pp.h/2)-4
	
	-- head
	local off_y_h=aim==1 and 1 or 0
	--if(idx%4!=0)off_y_h=1
	if dy==1 then
		if dx==1 then
			spr(7,px,py+off_y_h)
		elseif dx==-1 then
			spr(7,px,py+off_y_h,1,1,true,false)
		else
			spr(4,px,py+off_y_h)
		end
	elseif dy==-1 then
		spr(6,px,py+off_y_h)
	elseif dx==1 then
		spr(5,px,py+off_y_h)
	elseif dx==-1 then
		spr(5,px,py+off_y_h,1,1,true,false)
	end

	-- legs
	local s=anim_walk[idx+1]
	local fx=idx>3 and true or false
	spr(s,px,py+8,1,1,fx,false)
	
	-- arms
	if shot_f_t>0 then
		local mfx=0 --muzzle flash x offset
		local mfy=0 --muzzle flash x offset
		if dy==1 and dx==-1 then
			-- sw
			spr(18,px-1,py+5)
			mfx=-1
			mfy=-1
		elseif dy==1 and dx==1 then
			-- se
			spr(18,px+1,py+5,1,1,true,false)
			mfx=3
			mfy=0		
		elseif dy==1 and dx==0 then
			-- s
			spr(16,px,py+6)
			mfy=-1
		elseif dy==-1 and dx==-1then
			-- nw
			spr(19,px,py,1,1,true, false)
			mfx=1
			mfy=-2
		elseif dy==-1 and dx==1 then
			-- ne
			spr(19,px,py)
			mfy=-2
			mfx=1
		elseif dy==-1 and dx==0 then
			-- n
			spr(10,px-2,py-2,1,1,false,true)
			mfx=1
			mfy=-1
		elseif dy==0 and dx==1 then
			-- e
			spr(17,px+3,py+3)
			mfx=2
		elseif dy==0 and dx==-1 then
			-- w
			spr(17,px-3,py+3,1,1,true,false)
			mfx=-1
		end
		
		--muzzle flash
		local a=atan2(dx,dy)
		for j=-3,2 do
		for i=-3,2 do
			if rnd(1)>0.8 then
				pset(
					((pp.x+mfx)+i)+cos(a)*8,
					((pp.y+mfy)+j)+sin(a)*8
					,10
				)
			end
		end end
	elseif aim==1 then
		if dy==1 and dx==-1 then
			-- sw
			spr(14,px-1,py+6)
		elseif dy==1 and dx==1 then
			-- se
			spr(14,px+1,py+6,1,1,true,false)
		elseif dy==1 and dx==0 then
			-- s
			spr(12,px,py+6)
		elseif dy==-1 and dx==-1then
			-- nw
			spr(15,px,py,1,1,true, false)
		elseif dy==-1 and dx==1 then
			-- ne
			spr(15,px,py)
		elseif dy==-1 and dx==0 then
			-- n
			spr(10,px-2,py-3,1,1,false,true)
		elseif dy==0 and dx==1 then
			-- e
			spr(13,px+3,py+6)
		elseif dy==0 and dx==-1 then
			-- w
			spr(13,px-3,py+6,1,1,true,false)
		end
	else
		local off_y=6
		if(idx%4!=0)off_y=5
		if dy==1 then
			spr(8,px,py+off_y)
		elseif dy==-1 then
			spr(10,px,py+off_y)
		elseif dx==1 then
			spr(9,px+1,py+off_y)
		elseif dx==-1 then
			spr(11,px-1,py+off_y)
		end
	end
	
	if p_mode=="grabbed" then
		set_x_icon(px,py-8)
	end
	
	if cur_door!=nil then
		spr(25,px,py-8)
	end
	
	-- draw hit box
	//rect(
	//pp.x-pp.w/2,pp.y-pp.h/2,
	//pp.x+pp.w/2,pp.y+pp.h/2,8
	//)
	//pset(pp.x,pp.y,8)
end

function update_player()
//	if 
	if btn(❎) then
		if l_x_press==0 then
			x_pressed=true
			//if popup_tried==
			//popup=nil
		else
			x_pressed=false
		end
		l_x_press=1
	else
		l_x_press=0
		x_pressed=false
	end
	
	if btn(🅾️) then
		if l_z_press==0 then
			z_pressed=true
		else
			z_pressed=false
		end
		l_z_press=1
	else
		l_z_press=0
		z_pressed=false
	end
	
	//if(popup!=nil)return
	
	if(p_mode=="norm")update_player_norm()
	if(p_mode=="hurt")update_player_hurt()
	if(p_mode=="grabbed")update_player_grabbed()
end

function update_player_norm()	
	-- aiming
	aim=0
	if(btn(🅾️))aim=1
	if aim==0 then
		target=nil
	elseif aim==1 and target==nil then
		target=calc_target()
	end
	
	if(shot_f_t>0)shot_f_t-=1
	
	if shot_t>0 then
		shot_t-=1
	elseif aim==1 and x_pressed and reload_t==0 then
		if ammo>0 then
			shot_t=10
			shot_f_t=2
			ammo-=1
			shoot()
			if ammo>0 and ammo%8==0 then
				reload_t=80
			end
		end
	end
	
	if reload_t>0 then
		reload_t-=1
	end
	
	-- other x button stuff
	//mode=0
	//if aim==0 and btn(❎) then
	//	mode=90 --test, remove
	//end
	
	--[[
	if not btn(❎) then
		x_press=0
	end
	--]]
	
	-- direction
	local ndx,ndy=0,0
	
	if (btn(⬇️))ndy=1	
	if (btn(⬆️))ndy=-1
	if (btn(➡️))ndx=1
	if (btn(⬅️))ndx=-1

	-- movement
	if ndx!=0 or ndy!=0 then
		if ndx!=dx or ndy!=dy then
			target=nil --reset target if we change dir
		end
		dx,dy=ndx,ndy
		if aim==0 then
			walk_t=(walk_t+0.35)%8
			
			local nx,ny=dx,dy
			if dx!=0 and dy!=0 then
				nx=dx*0.707
				ny=dy*0.707
			end
			if popup==nil then
				move_player(nx,ny)
			end
		end
	else
		walk_t=0
	end
	
	-- collide doors
	cur_door=nil
	for d in all(lvl.doors)do
		local drx,dry=d.x*8+4,d.y*8+4	
		if dist(pp,{x=drx,y=dry})<10 and mget(d.x,d.y)!=69 then
			cur_door=d
		end
	end
	
	-- open doors
	if cur_door!=nil and x_pressed then
		if cur_door.story==nil or story>cur_door.story then
			if cur_door.to==nil then
				mset(cur_door.x,cur_door.y,69)
			else
				init_lvl(cur_door)
			end
		elseif popup==nil then
			show_door_popup(cur_door.story)
		else
			popup=nil
		end
	end
	
	-- collide enemy
	for e in all(lvl.enemies)do
		-- todo, dont count dead enemies
		if count(e.trgts)>0 and e.slp<=story then
			if col_bb(pp,e) then
				p_mode="grabbed"
				grab_t=0
				grab_e=e
				grab_amt=1
			end
		end
	end
	
	--pickup amo
	if mget(flr(pp.x/8),flr(pp.y/8))==30 then
		mset(flr(pp.x/8),flr(pp.y/8),69)
		ammo+=8
		set_notif("got 8 rounds")
	end
end

grab_e=nil
grab_t=0
grab_amt=0
function update_player_grabbed()
	local a=atan2(pp.x-grab_e.x,pp.y-grab_e.y)
	if grab_t==0 then
		grab_t=40
		grab_amt=min(1,grab_amt+0.5)
		add_splt(
			a,
			pp.x+cos((a+0.5)%1)*4,
			pp.y+sin((a+0.5)%1)*4
		)
	end
	if x_pressed then
		printh("pushing back "..grab_amt)
		grab_amt-=0.2
		if grab_amt<=0 then
			hit_enemy(grab_e,0,(a+0.5)%1,20)
			p_mode="norm"
		end
	end
	
	grab_t-=1
end

hurt_t=0
function update_player_hurt()
	local nx=cos(hurt_a)*hurt_s
	local ny=sin(hurt_a)*hurt_s
	move_player(nx,ny)
	hurt_s*=0.7
	hurt_t-=1
	if(hurt_t==0)p_mode="norm"
end

function move_player(nx,ny)
	if place_free_bb(pp,round(nx),0)then
		pp.x+=nx
	end
	if place_free_bb(pp,0,round(ny))then
		pp.y+=ny
	end
	pp.x=round(pp.x)
	pp.y=round(pp.y)
end

sht_ang_rad=0.08
function calc_target()
	local found=nil //{} consider returning a sorted list
	local found_d=10000
	local pa=atan2(dx,dy)
	for e in all(lvl.enemies) do
		-- find if pointing at enemy
		if count(e.trgts)==0 then
			goto trgt_find_cont
		end
		local ea=atan2(e.x-pp.x,e.y-pp.y)
		local dif_a=abs(pa-ea)
		local pnt_a=min(dif_a,1-dif_a)
		if pnt_a<sht_ang_rad then
			-- check wall between
			local lx,ly=pp.x,pp.y
			local wall=0
			while abs(lx-e.x)>8 or abs(ly-e.y)>8 do
				if not light_free(flr(lx/8),flr(ly/8)) then
					wall=1
				end
				lx+=8*cos(ea)
				ly+=8*sin(ea)
			end
			
			local d=dist(pp,e)
			if d<found_d and wall==0 then
				//printh("found "..e.id)
				found_d=d
				found=e
			end
		end
		::trgt_find_cont::
	end
	return found
end

function shoot()
	if target!=nil then
		target.wt=0
		t=target.trgts[1]
		local tx=target.x+t.x
		local ty=target.y+t.y
		local a=(atan2(pp.x-tx,pp.y-ty)+0.5)%1
		add_splt(a,tx,ty)
		hit_enemy(target,1,a,4)
		
		
		if count(target.trgts)==0 then
			target=nil
		end
		
	end
end
	
function show_door_popup(s)
	printh("trying door "..s)
	local d=ds[s]
	if d!=nil then
		if story==s and d[2]!=nil then
			popup=d[2]
			story+=1
		else
			popup=d[1]
		end
	end
	//else
	//end
end

-->8
-- enemy

imp_anim_walk={21,22,21,22}
zomb_anim_walk={1,2,1,2}
e_spd=0.2
e_spd_h=0.1

function add_enemy(x,y,typ,slp,arr)
	-- add targets, dont add
	-- two in the same place
	local t={}
	for i=0,2 do // should be a while, not for
		local rx=rand(-2,2)
		local ry=rand(-5,5)
		local skip=false
		for tg in all(t) do
			if(t.x==rx and t.y==ry)skip=true
		end
		if not skip then
			add(t,{
				x=rx,y=ry,hp=2
			})
		end
	end
	
	add(arr,{
		x=x,y=y,w=4,h=10,wt=0,
		trgts=t, -- hit targets,
		mode="norm",
		typ=typ,
		slp=slp,
		hit_s=0,
		hit_a=0,
		agro=0
	})
end

function draw_enemy(e)
	if(e.typ==0)draw_imp(e)
	if(e.typ==1)draw_zomb(e)
end

function draw_zomb(e)
	local ex=(e.x-e.w/2)-1
	local ey=(e.y-e.h/2)-1
	
	if count(e.trgts)==0 or 
				story<e.slp or 
				(story>=e.slp and e.agro==0) then
		spr(28,ex,ey)
		spr(29,ex+8,ey)
		return
	end
	
	local idx=flr(e.wt)
	
	
	pal(12,13)
	
	if e.slp!=-1 then
		if idx==0 then
			spr(28,ex,ey+2) --leg
			spr(29,ex+6,ey)
		elseif idx==1 then
			spr(2,ex,ey+4) --leg
			--spr(7,ex+4,ey)
			spr(29,ex+2,ey+1)
		elseif idx==2 then
			spr(7,ex+1,ey,1,1,pp.x<e.x and true or false, false)
			spr(2,ex,ey+6) --leg
			
		elseif idx==3 then
			spr(7,ex,ey)
			spr(2,ex,ey+7) --leg
		end
		return
	end
	
	-- head
	if(pp.y>e.y)pal(13,0)
	//pal(12,13)
	spr(7,ex,ey,1,1,pp.x<e.x and true or false, false)
	pal()
	
	-- legs
	local s=zomb_anim_walk[idx+1]
	local fx=idx>2 and true or false
	spr(s,ex,ey+8,1,1,fx,false)
end

function draw_imp(e)
	local ex=(e.x-e.w/2)-1
	local ey=(e.y-e.h/2)-1
	
	if count(e.trgts)==0 then
		spr(23,ex,ey)
		return
	end
	
	local idx=flr(e.wt)

	-- head
	if(pp.y<e.y)pal(13,6)
	spr(20,ex,ey+idx%2,1,1,pp.x>e.x and true or false, false)
	pal()
	-- legs
	local s=imp_anim_walk[idx+1]
	local fx=idx>2 and true or false
	spr(s,ex,ey+8,1,1,fx,false)
	
	-- arms
	line(ex+2,ey+7,ex+0,ey+9,6)
	line(ex+5,ey+7,ex+3,ey+9,6)
	
	-- targets
	if target==e then
		for t in all(e.trgts) do
			//spr(32,e.x+t.x,e.y+t.y)
			pset(e.x+t.x,e.y+t.y,11)
		end
	end
	
	-- draw hit box
	//rect(
	//	e.x-e.w/2,e.y-e.h/2,
	//	e.x+e.w/2,e.y+e.h/2,8
	//)
end

function update_enemy(e)
	if(count(e.trgts)==0)return
	if(story<e.slp)return
	if(e.mode=="norm")update_enemy_norm(e)
	if(e.mode=="hit")update_enemy_hit(e)
	if(e.mode=="push")update_enemy_push(e)
end

function move_enemy(e,nx,ny)
	if place_free_bb(e,nx,0)then
		e.x+=nx
	end
	if place_free_bb(e,0,ny)then
		e.y+=ny
	end
end

agro_d={}
agro_d[0]=100
agro_d[1]=40

function update_enemy_norm(e)
	//e.agro=0
	if(dist(pp,e)<agro_d[e.typ])e.agro=1
	
	e.wt+=0.05
	if e.wt>4 then
		e.wt=0
		if(e.agro==1)e.slp=-1
	end
	if flr(e.wt)%2==1 and e.slp==-1 then
		local nx,ny=0,0
		local s=e_spd
		if(count(e.trgts)==1)s=e_spd_h
		if(pp.x-e.x>2)nx=s
		if(pp.x-e.x<-2)nx=-s
		if(pp.y-e.y>2)ny=s
		if(pp.y-e.y<-2)ny=-s
		if(e.agro==1)move_enemy(e,nx,ny)
	end
end

function update_enemy_hit(e)
	e.hit_s*=0.3
	local nx=cos(e.hit_a)*e.hit_s
	local ny=sin(e.hit_a)*e.hit_s
	move_enemy(e,nx,ny)
	if e.hit_s<=0.01 then
		e.mode="norm"
	end
end

function hit_enemy(e,amt,a,s)
	t=e.trgts[1]
	t.hp-=amt
	e.mode="hit"
	e.hit_s=s
	e.hit_a=a
	if t.hp<=0 then
		del(e.trgts,t)
	end
end
-->8
-- npcs

-- john
john={x=111*8,y=33*8,t=0,
	popup={
		"the captain's locked\nherself in! you need \nto go to the cpu room\nto override the door.",
		"here, take my key\ncard and some ammo.\n\nhurry!",
		"go to the cpu room\nto unlock the door!"
	}
}

function d_john()
	local t=flr(john.t)
	pal(12,11)
	spr(5,john.x,john.y)
	spr(2,john.x,john.y+8)	
	if t==1 or t==3 then
		line(john.x+4,john.y+8,
		john.x+7,john.y+6,3)
	else
		line(john.x+4,john.y+8,
		john.x+5,john.y+5,3)
	end
	pal()
end

function u_john()
	john.t+=0.2
	if(john.t>=5)john.t=0
	
	if dist(pp,{x=john.x+4,y=john.y+4})<16 then
		if story<=3 then
			set_x_icon(john.x,john.y-8)
		end
		if x_pressed then
			if story==0 then
				story=1
				popup=john.popup[1]
			elseif story==1 then
				story=2
				popup=john.popup[2]
			elseif story==2 then
				story=3
				popup=nil
				ammo+=8
				set_notif("got the blue key card")
			elseif story==3 then
				if popup==nil then
					popup=john.popup[3]
				else
					popup=nil
				end
			end
		end
	end
end

-- add update/draw funcs to level
lvls.hall.npc_u={u_john}
lvls.hall.npc_d={d_john}

cpu1={x=97*8,y=16*8,t=0,st=1,
	popup={
		"acessing main pc...",
		"ship status:\n critial\nlife support:\n offline",
		"eng*ne st*t*s:\n fuel:20%\n speed:100%\n condition:red",
		"lab status:\n sam*le 1:locked\n sampl* 2:locked\n sample *:unknown",
		"***** ****\n ***** * **\n******* ****",
		"capta*in*s ove*ride\nin*effec******\n****** ********\n*****..",
		"******cold****\n** ****i can****see*\n ****them***** *blo*d\n*** i*si*e* *** my * \n * * sk*n*** *",
	}
}

function d_cpu1()
end

function u_cpu1()
	if dist(pp,{x=cpu1.x+4,y=cpu1.y+4})<16 then
		set_x_icon(cpu1.x,cpu1.y-8)
		if x_pressed then
			if cpu1.st>count(cpu1.popup) then
				popup=nil
				cpu1.st=1
			else
				popup=cpu1.popup[cpu1.st]
				cpu1.st+=1
			end
		end
	end
end

cpu2={x=83*8,y=18*8,t=0,st=1,
	popup={
		"maintenance access\nsystem...",
		"m1 [<-] locked\nm2 [->] locked",
		"unlock all?\n press to continue.",
		"m1 [<-] failure\nm2 [->] open",
		"m1 [<-] open\nm2 [->] open"
	}
}

function d_cpu2()
end

function u_cpu2()
	if dist(pp,{x=cpu2.x+4,y=cpu2.y+4})<16 then
		set_x_icon(cpu2.x,cpu2.y-8)
		if x_pressed then
			--[[
			if story==4 then
				story=5
				popup=cpu2.popup[1]
			elseif story==5 then
				story=6
				popup=cpu2.popup[2]
			elseif story==6 then
				story=7
				popup=cpu2.popup[3]
			elseif story==7 then
				story=8
				popup=cpu2.popup[4]
			]]--
			if story<8 then
				story+=1
				popup=cpu2.popup[story-4]
			elseif story==8 then
				if popup==nil then
					popup=cpu2.popup[4]
				else
					popup=nil
				end
			elseif story==16 then
				if popup==nil then
					popup=cpu2.popup[5]
				else
					popup=nil
				end
			end
		end
	end
end

lvls.cpu.npc_u={u_cpu1,u_cpu2,u_lary}
lvls.cpu.npc_d={d_cpu1,d_cpu2,d_lary}

lary={x=104*8,y=25*8+5,t=0,
	popup={
		"what? you're alive!?",
		"i thought those...\n\n...those things...\n\nkilled everyone!",
		"i tried to radio for \nhelp, but the camptain\nlocked us out of the\ncomputer!",
		"i think shes gone\ncrazy. we need to find\na way to take control\nof the ship!",
		"we can try going\nthrough the lab to the\nengine room, but i\ndon't have the key\ncard.",
		"try searching in\nthe other maintanence\nroom for it, im too\nscared to go back\nthere.",
		"find the key card\nin the m1 maintanence\nroom and meet me back\nhere."
	}
}

function d_lary()
	local t=flr(lary.t)
	pal(12,9)
	
	local oy=0
	if t==1 or t==3 then
		oy=1
	end
	if t>4 then
		spr(5,lary.x,lary.y+oy)
	else
		spr(6,lary.x,lary.y+oy)
	end
	
	spr(2,lary.x,lary.y+8)
	pal()
end

function u_lary()
	lary.t+=0.2
	if(lary.t>=9)lary.t=0
	
	if dist(pp,{x=lary.x+4,y=lary.y+4})<16 then
		if story<=16 then
			set_x_icon(lary.x,lary.y-8)
		end
		if x_pressed then
			if story<16 then
				story+=1
				popup=lary.popup[story-9]
			elseif story==16 then
				if popup==nil then
					popup=lary.popup[7]
				else
					popup=nil
				end
			end
		end
	end
end

lvls.m2.npc_u={u_lary}
lvls.m2.npc_d={d_lary}
__gfx__
00000000076666700766667007666670000000000000000000000000000000007c0000000c000000000000c0000000c000c00c0000007770000c000000000070
00000000076666700766667007666670007777000077770000777700007777007c000c0000c00000000000c000000c0000c50c000000555707550cc000000757
0070070007666670076666700766770007cccc7007cccc7007cccc7007cccc707c00c00000c00000000000c000000c000005c000cc0cc770757cc00000000570
0007700007666670076677000766700007cccc7007cccc7007cccc7007cccc70005c0000000c5000000007570000c0000005000000c000000700000000000c70
0007700000777700007700000077000007cddc7007cccd7007cccc7007ccdd70005000000000500000000070000c000000000000000000000000000000000c70
0070070000000000000000000000000007cddc7007cccd7007cccc7007ccdd700000000000000000000000000000000000000000000000000000000000000c70
0000000000000000000000000000000007cccc7007cccc7007cccc7007cccc700000000000000000000000000000000000000000000000000000000000000c70
00000000000000000000000000000000076666700766667007666670076666700000000000000000000000000000000000000000000000000000000000000000
00c5cc00000005005000000000000050000000000066660000666600000000000707000006666600000000000000000000007777777777006600000000000000
00000000000050000550000000000050000000000066660000666600000000007070000060d0d0600666660007777000000766666ddddd705509000000000000
00000000c0050000000ccc00000000c00006600000600600006006000000000007070000600d006060d0d06007fff70000076666dddddd705505000000000000
000000000c0c000000000000000000c0006666000060060000600000000006607070000060d0d060600d006007ffff700000766d6ddddd700000090000000000
0000000000c0000000000000000000c000d6d600000000000000000066066666000000005666665060d0d06007ffff700000766d8d00dd705900500000000000
00000000000000000000000000000000006666000000000000000000006666d600000000555555505666665007f66f70000007d5887777000000009000000000
00000000000000000000000000000000000660000000000000000000666060000000000005555500055555000776677000000825888280000590005000000000
00000000000000000000000000000000000660000000000000000000600006600000000000000000000000000000000000008020802200000000000000000000
1111111110000001111111111000000110000001111111111111111110000001100000011000000110000001111111111111111111111111000660000d0000d0
0000000010000001000000010000000110000000100000000000000000000001000000001000000010000001100000001000000100000001ddd66ddd0d0000d0
0000000010000001000000010000000110000000100000000000000000000001000000001000000010000001100000001000000100000001000660000d0000d0
00000000100000010000000100000001100000001000000000000000000000010000000010000000100000011000000010000001000000010000000066600666
00000000100000010000000100000001100000001000000000000000000000010000000010000000100000011000000010000001000000010000000066600666
0000000010000001000000010000000110000000100000000000000000000001000000001000000010000001100000001000000100000001000660000d0000d0
0000000010000001000000010000000110000000100000000000000000000001000000001000000010000001100000001000000100000001ddd66ddd0d0000d0
1111111110000001100000011111111111111111100000011000000110000001111111111000000111111111111111111000000111111111000660000d0000d0
66666666000000000000000660000000666666666666666660000000000000060010000000100000000000001111111100000000000000000000000000000000
5050505000000000000000066000000050505056605050506000000000000006150101001501010000dddd0000dddd0000000000000000000000000000000000
505050500000000000000006600000005050505660505050600000000000000601001055010010550d5555d05d5555d500000000000000000000000000000000
0000000000000000000000066000000000000006600000006000000000000006051055500510555001dddd1001dddd1000000000000000000000000000000000
00000000000000000000000660000000000000066000000060000000000000060505501105055011011aa110511aa11500000000000000000000000000000000
00000000666666660000000660000000000000066000000066666666666666661050100110501001011aa110011aa11000000000000000000000000000000000
000000005050505000000006600000000000000660000000505050505050505051155511511555110d1111d01d1111d100000000000000000000000000000000
0000000050505050000000066000000000000006600000005050505050505050551555515515555100dddd0000dddd0000000000000000000000000000000000
11111111111111111111111111111111000100010000000011111111555155551111111111111111000001111110000011111111777777770000000000000000
000000000005055115505500155005511010101001000010166666615151515500000000001551000001155555511000001111006b5bbbb60000000000000000
d5555555555005d11d5000551d5005d1010001000000000060cccc065550555501555551015d501000155dddddd55100011110106bbbbbb60000000000000000
d01d601dd00005011000000d1dd01dd1101010100000000060cccc06110000110555555515555011015dd555555dd510115d00016bbbbbb60000000000000000
5555d55d555005d11d5000551d5005d10001000100000000777777775550dd551555556515d55511015d55000055d51015110001666666660000000000000000
000000000005055115505500155005511010101000000000787879775150d1551555565515d5551115d5500110055d51115dd001777777770000000000000000
111111111111111111111111111111110100010001000010696b6a66555155550155555115d5501115d5501111055d5115110001666666660000000000000000
00000000000000000000000000000000101010100000000066666666555155550000000015d5501115d5501111055d5111500001666666660000000000000000
00000000000000000000000000000000006666000000000000000000000000000000000015d55001000000000000000015110001000000000000000000000000
00000000000000000000000000000000006666000000000000000000000000000000000015d55001000000000000000011500001000000000000000000000000
00000000000000000000000000000000000550000000000000000000000000000000000015d55011000000000000000015110001000000000000000000000000
00000000000000000000000000000000000550000000000000000000000000000000000011d55011000000000000000011500001000000000000000000000000
00000000000000000000000000000000000110000000000000000000000000000000000011010011000000000000000010010001000000000000000000000000
00000000000000000000000000000000000100000000000000000000000000000000000001101010000000000000000000000000000000000000000000000000
00000000000000000000000000000000000010000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000100000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000
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
0000000000000000000000000000000000000000000012e15454545452020232f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7
f7f7f7f7f7f7f7f7f7f7f7f7f7f700000000000000000000000000000000000000000000000000005454545412545454a2545454545454545454545454545412
0000000000000000000000000000000000000000000042020202020232f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7
f7f7f7f7f7f7f7f7f7f7f7f7f7f70000000000000000000000000000000000000000000000000000000000001254545454545454545454545454545454545412
00000000000000000000000000000000000000000000f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7
f7f7f7f7f7f7f7f7f7f7f7f7f7f700000000000000000000000000000000000000000000000000000000000012545454c2545454545454545454545454545232
00000000000000000000000000000000000000000000f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7
f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f70000000000000000000000000000000000000000000000000000001254545412545454545454545454545454541233
00000000000000000000000000000000000000000000f7f7f7f7f7f7f7f7f7f7f7f7f70000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001254545412545454545454545454545202023200
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001254545412545454545454545454541200000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001254545412545454545454545454541200000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001254c1d192020202020202020202023200000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000001254e15412000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000092d254b272000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000054545400000000000000000000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002020000020202
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000202000200000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000002000202
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000202020000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000202020000020200
__map__
3130303030303031313030303030303130303030303030303030303030303030303030303030303030303030313131313131313131313131313131313131313125202020262020202020202026202020262020202020202026202020262020202620202020202020202020202020202022000000000000000000000000000000
3000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000444444444444444444444421404040214040404040404021404040214040402140404021404040214040402140464040404640404046404049404921000000000000000000000000000000
300000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000030303030303030303030302145454521454545454545452145454521451c1d2145454521454545211e45452a45454545454545453631317f597f5921000000000000000000000000000000
30000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000214545452145454538454545384545452145451e21454545217f4545211e454543452c45454545454544444436317f7f21000000000000000000000000000000
3000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000021454545214545392145454545454545214545452145454521454545214545454545214545252245454444444444334a21000000000000000000000000000000
3000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000021454545214545452145454521454545214545452145454521454545214545452520234545242345453530303444335921000000000000000000000000000000
30000000000000000000000000000030000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000292d452b282d382b282d452b282d452b282d452b282d452b282d452b282d382b234041454546464545337f7f3244337f21000000000000000000000000000000
310000000000003130000000000000310000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002a414542404145424041454240414542404145422a41454240414542404139424145454545454545453631313744363121000000000000000000000000000000
3100000000000030310000000000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000045454545454545454545454538394545454545454545454545454545454545454545454545454545454545454545454521000000000000000000000000000000
300000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002c4545454545454538454545453845452c4545452c45454545454545454545454545454545454545454545454545454521000000000000000000000000000000
30000000000000000000000000000030000000000000000025202020202020202020202020202020202020202020202020202020202020202020202020202020282020202245452b2020202020202026282020202626202020202626202026262020202026262026202020202245454521000000000000000000000000000000
30000000000000000000000000000030000000000000000021404940494049404940494049404040404040404040404040404040404640404640403b404049404049404021454542404040404040402140464040242340404040242340402423404046402423402140404040292d452b27000000000000000000000000000000
300000000000000000000000000000300000000000000000217f597f597f597f597f597f593245454545454545454545454545454545454545453a3a337f59006e596e4a21451c1d454545384545452a4545454546464545454546464545464645454545464645213a3a451e2145454521000000000000000000000000000000
300000000000000000000000000000300000000000000000217f3131313131317f7f31313137454545454545454545454545453a3a45453a454535307f7f7f7f7f7f7f5921454545454538454545454545454545454545454545454545454545454545454545452a3a4545452145454521000000000000000000000000000000
3000000000000000000000000000003000000000000000002132444444444444333244444444443530303030303030344435303030303030344436313131313131317f6e21454545394545454545452c45454545454545454545454545454545452c4545454545454545453a2145454521000000000000000000000000000000
31303030303030313130303030303031000000000000000021324444442c4444363744353030307f313131313131313745367f7f7f7f7f7f32444444444444444444334a29202020202020202020202745454545454545452b2d45454545452b2028202d4545452c4545453a2145454521000000000000000000000000000000
0000000000000000000000000000000000000000000000002132444425274444444444334a2c4b321e454444444444454545334a25224b7f7f303030303030344444335921494040494040494040402145454545454545454646452c45454542464d4641454545213a45453a2145454521000000000000000000000000000000
00000000000000000000000000000000000000000000000021324444292730344435307f5949597f303030303034443530307f4a24234b7f7f7f7f7f7f7f7f324444337f21597f7f597f7f597f31312920202020202022451c1d1e292d4545444444444445454529202d452b2745454521000000000000000000000000000000
0000000000000000000000000000000000000000000000002132444429274b3244334a2c4b597f313131313131374436313131594949593131313131313131374444367f217f313131313131371c1d214640414d42402420202020234145454444444444452b2027454545452145454521000000000000000000000000000000
0000000000000000000000000000000000000000000000002132442b28234b324433594959313744444444444444444444444433595932444444444444444444444444332a324444444444444445452a45454545453a4240404040413a4545454545454545424621454545452145454521000000000000000000000000000000
0000000000000000000000000000000000000000000000002132443b49495932443631593244444444444444444444444444443631313744444444444444444444444433433244444444444444454545454545454545363131313137454545452b202d454545452a454545452145454521000000000000000000000000000000
0000000000000000000000000000000000000000000000002132453559597f32444545337f2b202020202d344444352c3444443a46463a4444353030303034443534443631374435303030303445452c454545454545444444444444454545454646464545454545454545452145454521000000000000000000000000000000
00000000000000000000000000000000000000000000000021324533313131374445452c7f4249404049413244443321324444454545454444337f7f7f7f324433324444444444337f7f7f7f321e452145454545454535303030303445454545454545454545452c454545452145454521000000000000000000000000000000
000000000000000000000000000000000000000000000000217f303244444444443530217f7f597f7f597f32444436217f30303030303030307f7f7f7f7f3244337f30303030307f7f7f7f7f7f303029202020202020202020202020202020202020202020202027454545452145454521000000000000000000000000000000
000000000000000000000000000000000000000000000000217f7f324444444444334a217f7f7f7f7f7f7f324444442a317f7f7f7f7f7f7f7f7f7f7f7f32374425202d7f2c7f2c7f7f31312b202d7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f292d4545452145454529202020202020202020202200000000
000000000000000000000000000000000000000000000000217f2c7f3034444444334a242020202020202020202d444344337f7f7f7f7f7f7f7f7f7f444444442a40497f497f497f321e454246417f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f21464545452145454521404040404040404040402100000000
00000000000000000000000000000000000000000000252023312a31313744252233594249404941434249403b41444444337f7f7f7f7f7f7f7f7f7f30303030427f597f597f597f32451e444444337f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f21454545452145454521454545454545454545452100000000
000000000000000000000000000000000000000000002142414543454545442423337f7f597f59313100593245454444443631313131317f7f31317f7f7f31317f7f3131313131313744443530307f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f21454545452145454521454545454545454545452420202200
0000000000000000000000000000000000000000000021454545454525224443433631313131371c1d3300323a454444444444444444442b2d453a2b202d45452b2d444444444444444444337f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f0029202d452b2145454521454545454545454545454240402422
0000000000000000000000000000000000000000000021452b20224524234444444444444444454545337f0030303030303030303034444241454542464145454241443530303030303030007f7f7f7f7f7f7f7f0000000000000000000000000000000000000021454545452145454521454545454545454545454545454221
00000000000000000000000000000000000000000000214542462a4543434435303030303030303030007f7f7f7f7f7f7f7f7f7f7f3244454545454545454545454544337f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f0000000000000000000000000000000000000000454545452145454521454545454545454545454545454521
0000000000000000000000000000000000000000000021454545434545454425202020202020202020202020202020202020202020202020202020202020202020202020202020202020202020200000000000000000000000000000000000000000000000000000454545452145454521454545454545454545454545454521
