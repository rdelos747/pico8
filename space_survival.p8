pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- space survival

enmy={}
splt={} -- blood splat

function _init()
	printh("====game start====")
	// test enemys
	//add_enemy(40,30)
	//add_enemy(60,48)
	//add_enemy(70,50)
	--[[
	add_enemy(20,60)
	add_enemy(100,60)
	add_enemy(20,100)
	add_enemy(60,100)
	add_enemy(100,100)
	]]--
	for j=0,127 do
	for i=0,127 do
		local m=mget(i,j)
		//if m==4 then
		//	pp.x,pp.y=i*8,j*8
		//	mset(i,j,0)
		//end
	end end
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

camx,camy=0,0
cami4,camj4=0,0
cami8,camj8=0,0
function draw_game()
	camera(camx,camy)
	cami8=flr(camx/8)
	camj8=flr(camy/8)
	
	--used for offsets when 
	--placing into buff
	cami4=flr(camx/4)
	camj4=flr(camy/4)
	
	local m_x=flr(camx/8)-1
	local m_y=flr(camy/8)-1
	local m_filter=0
	--if(pause>0)m_filter=1	???
	
	map(m_x,m_y,m_x*8,m_y*8,
		18,18,m_filter)
	pal()
		
	draw_player()
	foreach(enmy,draw_enemy)
	foreach(splt,draw_splt)
	draw_lighting()
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
		if x<0 or x>128*8 or 
					y<0 or y>128*4 or
					mget(flr(cami4+i)/2,flr(camj4+j)/2)==0 then
			goto continue
		end
		local v=buff[j][i]
		
		if v==0 then			
			if buff[max(j-1,0)][i]==1 or
						buff[min(j+1,31)][i]==1 or
						buff[j][max(i-1,0)]==1 or
						buff[j][min(i+1,31)]==1 then
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
	local a=atan2(dx,dy) -- player angle
	a=(a-0.18)%1 --start angle, minus one half of the total
	local frac=0.36/128
	
	for x=0,127 do
		local cx=pp.x
		local cy=pp.y
		local step=0
		while step<14 do
			local i,j=flr(cx/4),flr(cy/4)
			local bi=(i+1)-cami4 --offset in buffer
			local bj=(j+1)-camj4 --offset in buffer
			if mget(flr(i/2),flr(j/2))<48 then
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
end

function _update()
	update_game()
end

function update_game()
	update_player()
	foreach(enmy,update_enemy)
	foreach(splt,update_splt)
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
	return b<48
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

-->8
-- player
pp={
	x=90*8,y=3*8,w=4,h=10
}
dx=0
dy=1

anim_walk={2,3,2,1,2,3,2,1}

function draw_player()
	local idx=flr(walk_t)
	local px=(pp.x-pp.w/2)-1
	local py=(pp.y-pp.h/2)-1
	
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
		for j=-1,1 do
		for i=-1,1 do
			if rnd(1)>0.8 then
				pset(
					((pp.x+mfx)+i)+cos(a)*6,
					((pp.y+mfy)+j)+sin(a)*6
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
	
	-- draw hit box
	// rect(
	// 	pp.x-pp.w/2,pp.y-pp.h/2,
	// 	pp.x+pp.w/2,pp.y+pp.h/2,8
	// )
	// pset(pp.x,pp.y,8)
end

p_mode="norm"
walk_t=0
aim=0
shot_t=0 --shot reset time
shot_f_t=0 --shot fire time, just for drawing
x_press=0
target=nil

function update_player()
	if(p_mode=="norm")update_player_norm()
	if(p_mode=="hurt")update_player_hurt()
	camx=pp.x-64
	camy=pp.y-64
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
	elseif aim==1 and btn(❎) and x_press==0 then
		x_press=1
		shot_t=10
		shot_f_t=2
		shoot()
	end
	
	-- other x button stuff
	mode=0
	if aim==0 and btn(❎) then
		x_press=1
		mode=90 --test, remove
	end
	
	if not btn(❎) then
		x_press=0
	end
	
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
			move_player(nx,ny)
		end
	else
		walk_t=0
	end
	
	for e in all(enmy)do
		if col_bb(pp,e) then
			p_mode="hurt"
			hurt_t=10
			hurt_s=2
			hurt_a=atan2(pp.x-e.x,pp.y-e.y)
			add_splt(
				hurt_a,
				pp.x+cos((hurt_a+0.5)%1)*4,
				pp.y+sin((hurt_a+0.5)%1)*4
			)
		end
	end
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
	for e in all(enmy) do
		-- find if pointing at enemy
		local ea=atan2(e.x-pp.x,e.y-pp.y)
		local dif_a=abs(pa-ea)
		local pnt_a=min(dif_a,1-dif_a)
		if pnt_a<sht_ang_rad then
			-- check wall between
			local lx,ly=pp.x,pp.y
			local wall=0
			while abs(lx-e.x)>8 or abs(ly-e.y)>8 do
				if not place_free(lx,ly) then
					wall=1
				end
				lx+=8*cos(ea)
				ly+=8*sin(ea)
			end
			
			local d=dist(pp,e)
			if d<found_d and wall==0 then
				printh("found "..e.id)
				found_d=d
				found=e
			end
		end
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
		hit_enemy(target,1,a)
		
		if count(target.trgts)==0 then
			del(enmy,target)
			target=nil
		end
	end
end
-->8
-- enemy

z_anim_walk={21,22,21,22}
e_spd=0.1

function add_enemy(x,y)
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
	
	add(enmy,{
		id=count(enmy),
		x=x,y=y,w=4,h=10,wt=0,
		trgts=t, -- hit targets,
		mode="norm",
		hit_s=0,
		hit_a=0	
	})
end

function draw_enemy(e)
	local ex=(e.x-e.w/2)-1
	local ey=(e.y-e.h/2)-1
	local idx=flr(e.wt)

	-- head
	if(pp.y<e.y)pal(13,6)
	spr(20,ex,ey+idx%2,1,1,pp.x>e.x and true or false, false)
	pal()
	-- legs
	local s=z_anim_walk[idx+1]
	local fx=idx>2 and true or false
	spr(s,ex,ey+8,1,1,fx,false)
	
	-- arms
	line(ex+2,ey+7,ex+0,ey+9,6)
	line(ex+5,ey+7,ex+3,ey+9,6)
	
	-- targets
	if target==e then
		for t in all(e.trgts) do
			spr(32,e.x+t.x,e.y+t.y)
		end
	end
	
	-- draw hit box
	//rect(
	//	e.x-e.w/2,e.y-e.h/2,
	//	e.x+e.w/2,e.y+e.h/2,8
	//)
	// print(e.id,ex,ey,8)
end

function update_enemy(e)
	if(e.mode=="norm")update_enemy_norm(e)
	if(e.mode=="hit")update_enemy_hit(e)
end

function move_enemy(e,nx,ny)
	if place_free_bb(e,nx,0)then
		e.x+=nx
	end
	if place_free_bb(e,0,ny)then
		e.y+=ny
	end
end

function update_enemy_norm(e)
	e.wt=(e.wt+0.05)%4
	local a=atan2(pp.x-e.x,pp.y-e.y)
	if flr(e.wt)%2==1 then
		local nx=cos(a)*e_spd
		local ny=sin(a)*e_spd
		move_enemy(e,nx,ny)
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

function hit_enemy(e,amt,a)
	t=e.trgts[1]
	t.hp-=amt
	e.mode="hit"
	e.hit_s=4
	e.hit_a=a
	if t.hp<=0 then
		del(e.trgts,t)
	end
end
__gfx__
00000000076666700766667007666670000000000000000000000000000000007d0000000d000000000000d0000000d000d00d0000007770000d000000000070
00000000076666700766667007666670007777000077770000777700007777007d000d0000d00000000000d000000d0000d50d000000555707550dd000000757
00700700076666700766667007667700079999700799997007999970079999707d00d00000d00000000000d000000d000005d000dd0dd770757dd00000000570
0007700007666670076677000766700007999970079999700799997007999970005d0000000d5000000007570000d0000005000000d000000700000000000d70
00077000007777000077000000770000079dd97007999d70079999700799dd70005000000000500000000070000d000000000000000000000000000000000d70
00700700000000000000000000000000079dd97007999d70079999700799dd700000000000000000000000000000000000000000000000000000000000000d70
00000000000000000000000000000000079999700799997007999970079999700000000000000000000000000000000000000000000000000000000000000d70
00000000000000000000000000000000076666700766667007666670076666700000000000000000000000000000000000000000000000000000000000000000
00d5dd00000005005000000000000050000000000066660000666600000000000707000000000000000000000000000000000000000000000000000000000000
00000000000050000550000000000050000000000066660000666600000000007070000000000000000000000000000000000000000000000000000000000000
00000000d0050000000ddd00000000d0000660000060060000600600000000000707000000000000000000000000000000000000000000000000000000000000
000000000d0d000000000000000000d0006666000060060000600000000000007070000000000000000000000000000000000000000000000000000000000000
0000000000d0000000000000000000d000d6d6000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000006666000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b000000111111111111111111111111111111110000000010000001777777775551555500000000000000000000000000000000000000000000000000000000
bbb00000000000000000000110000000100000010000000000000000777777775151515500000000000000000000000000000000000000000000000000000000
0b00000001555551015555111155555111555551000000000000000060cccc065550555500000000000000000000000000000000000000000077770000777700
0000000005555555055555511555555515555551000000000000000060cccc061100001100000000000000000000000000000000000000000077770000777700
00000000155555651555556115555565155555510000000000000000777777775550dd5500000000000000000000000000000000000000000077dd00007dd700
00000000155556551555565115555655155555510000000000000000787879775150d15500000000000000000000000000000000000000000077dd00007dd700
00000000015555510155551111555551115555510000000000000000696b6a665551555500000000000000000000000000000000000000000077770007777770
00000000000000000000000000000000100000010000000010000001666666665551555500000000000000000000000000000000000000000067660007666670
11111111100000011111111110000001100000011111111111111111100000011000000110000001100000011111111111111111111111110067770000766770
00000000100000010000000100000001100000001000000000000000000000010000000010000000100000011000000010000001000000010066675000657600
00000000100000010000000100000001100000001000000000000000000000010000000010000000100000011000000010000001000000010066665000656600
00000000100000010000000100000001100000001000000000000000000000010000000010000000100000011000000010000001000000010066660000666600
00000000100000010000000100000001100000001000000000000000000000010000000010000000100000011000000010000001000000010000660000660000
00000000100000010000000100000001100000001000000000000000000000010000000010000000100000011000000010000001000000010000000000000000
00000000100000010000000100000001100000001000000000000000000000010000000010000000100000011000000010000001000000010000000000000000
11111111100000011000000111111111111111111000000110000001100000011111111110000001111111111111111110000001111111110000000000000000
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
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000013
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000c3000000000000000000000000000013
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000013000000000000000000000000000013
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000013000000000000000000000000005333
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000013000000000000000000005303033300
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000013000000000000000000001300000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000013000000000000000000001300000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000043030303030303030303033300000000
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
3130303030303031313030303030303130303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303030303630303030303030363030303030303030303030303030303032000000000000000000000000000000
3000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002121213121212121212121312121212721212721212121212121212131000000000000000000000000000000
3000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003126262626262626312626262626262626262626262626262631000000000000000000000000000000
3000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003126262626262626312626262626262626262626262626262631000000000000000000000000000000
3000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003126262626262626312626262626353226262626262626262631000000000000000000000000000000
3000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003126262626262626312626262626343326262626262626262631000000000000000000000000000000
3000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000303830303d263b3030332626262626272726262626262626262631000000000000000000000000000000
3100000000000031300000000000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000232121212226232121222626262626262626262626262626262631000000000000000000000000000000
3100000000000030310000000000003100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000262626262626262626262626262626262626262626262626262631000000000000000000000000000000
3000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000262626262626262626262626262626262626262626262626262631000000000000000000000000000000
3000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000303030303030303030303030303030303030303030322626262631000000000000000000000000000000
3000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000312626262631000000000000000000000000000000
3000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000312626262631000000000000000000000000000000
3000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000312626262631000000000000000000000000000000
3000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000312626262631000000000000000000000000000000
3130303030303031313030303030303100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000312626262631000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000312626262631000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000312626262631000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000312626262631000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000312626262631000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000312626262631000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000312626262631000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000312626262631000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000312626262631000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000312626262639303030303030303030303200000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000312626262631212121212121212121213100000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000310000000031000000000000000000003100000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000310000000031000000000000000000003430303200
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000031000000000000000000002321213432
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000031000000000000000000000000002331
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003a000000000000000000000000000031
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000024000000000000000000000000000031
