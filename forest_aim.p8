pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
mode=0

anm_w={4,5,6,5,4,7,8,7}
anm_i={0,1,2,1}
anm_s={48,49,48,50}

pp={
	x=64,y=64,dx=1,dy=0,lpx=1,
	w=4,h=6,
	wt=0,it=0,at=0,--timings
	mode=0,a_mode=1,
	hb=nil,jmp_pnt=nil
}

hit_bs={
	{
		w=8,h=8,pwr=1,spd=4,
		at=4,n_a_mode=2
	},
	{
		w=8,h=8,pwr=2,spd=5,
		at=5,n_a_mode=3
	},
	{
		w=8,h=8,pwr=3,spd=5,
		at=6,n_a_mode=1
	},
}

cur_e=nil

enmy={} --enemies
spkl={} --sparkls

-- helpers
function rand(bot,top)
	return flr(rnd((top+1)-bot))+bot
end

function lerp(tar,pos,perc)
 return (1-perc)*tar + perc*pos;
end

function approx_dist(a,b)
	local dx=a.x-b.x
	local dy=a.y-b.y
 local maskx,masky=dx>>31,dy>>31
 local a0,b0=(dx+maskx)^^maskx,(dy+masky)^^masky
 if a0>b0 then
  return a0*0.9609+b0*0.3984
 end
 return b0*0.9609+a0*0.3984
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

function _init()
	printh("==== start ====")
	for i=0,10 do
		add_enmy(rand(10,118),rand(10,118))
	end
	cur_e=enmy[1]
end

function _draw()
	cls()
	if(mode==0)draw_game()
end

function _update()
	if(mode==0)update_game()
end

function draw_game()
	draw_player()
	// draw_bb(pp)
	if(pp.hb!=nil)draw_bb(pp.hb)
	draw_enmy()
	draw_cur_e()
	draw_spkl()
end

function update_game()
	update_player()
	update_enmy()
	update_spkl()
end

function draw_bb(a)
	local ax=a.x-a.w/2
	local ay=a.y-a.h/2
	rectfill(ax,ay,ax+a.w,ay+a.h,8)
	pset(a.x,a.y,8)
end

function draw_player()
	if pp.mode==2 then
		draw_player_atk()
		return
	end
	
	local px=(pp.x-pp.w/2)-1
	local py=(pp.y-pp.h/2)-2
	local oy=0
	
	-- bottom half
	if pp.mode==1 then
		local s=anm_w[flr(pp.wt)+1]
		spr(s,px,py)
	else
		oy=anm_i[flr(pp.it)+1]
		spr(4,px,py)
	end
	
	draw_player_top(oy)
end

function draw_player_top(oy)
	local px=(pp.x-pp.w/2)-1
	local py=(pp.y-pp.h/2)-2
	
	if pp.dy==-1 then
		spr(3,px,py+oy)
	elseif pp.lpx==-1 then
		spr(2,px,py+oy)
	else
		spr(1,px,py+oy)
	end
end

function draw_player_atk()
	draw_player_top(0)
	
	local px=(pp.x-pp.w/2)-1
	local py=(pp.y-pp.h/2)-2
	spr(4,px,py)
	
	local fx=false
	local fy=false
	local start=16

	if pp.dx==1 then
		start=32
	elseif pp.dx==-1 then
		start=32
		fx=true
	elseif pp.dy==-1 then
		fy=true
	end
	
	if pp.a_mode==1 then
		local s=flr(pp.at)+start
		spr(s,
			px+pp.dx*4,py+pp.dy*4,
			1,1,fx,fy
		)
	elseif pp.a_mode==2 then
		local s=flr(pp.at)+start+4
		spr(s,
			px+pp.dx*4,py+pp.dy*4,
			1,1,fx,fy
		)
	elseif pp.a_mode==3 then
		local s=flr(pp.at)+start+9
		spr(s,
			px+pp.dx,py+pp.dy,
			1,1,fx,fy
		)
		if pp.at<3 then
			circ(px+4,py+4,6+pp.at,1)
		end
	end
end

e_hit=false

function update_player()
	if pp.mode==2 then
		update_player_atk()
		return
	elseif pp.mode==3 then
		update_player_jmp()
		return
	end
	
	e_hit=false
	
	local dx,dy=0,0
	
	if(btn(⬅️))dx=-1
	if(btn(➡️))dx=1
	if(btn(⬆️))dy=-1
	if(btn(⬇️))dy=1
	
	if dx!=0 then
		pp.lpx=dx
	end
	
	if dx!=0 or dy!=0 then
		pp.dx,pp.dy=dx,dy
		pp.x+=pp.dx
		pp.y+=pp.dy
		pp.mode=1
		pp.wt=(pp.wt+0.5)%7
		pp.it=0
	else
		pp.mode=0
		pp.wt=0
		pp.it=(pp.it+0.3)%4
	end
	
	-- attack
	if btnp(❎) and pp.mode!=2 then
		local pnt=calc_atk_pnt()
		if pnt==nil then
			pp.mode=2
		else
			pp.mode=3
			pp.j_pnt=pnt
		end
	end
	
	if btnp(🅾️) then
		calc_cur_e()
	end
end

function update_player_atk()
	pp.at=(pp.at+0.5)
	local hb=hit_bs[pp.a_mode]
	
	if pp.at<2 then
		pp.hb={
			x=pp.x+pp.dx*2,
			y=pp.y+pp.dy*2,
			w=hb.w,
			h=hb.h,
			pwr=hb.pwr,
			spd=hb.spd
		}
		for e in all(enmy)do
			if col_bb(pp.hb,e) then
				e_hit=true
				hit_enmy(e,pp.hb)
				
				if e.hp<=0 then
					calc_cur_e()
				end
			end
		end
	else
		pp.hb=nil
	end
	
	local at=hb.at
	if pp.at>=at then
		pp.at=0
		pp.mode=0
		pp.a_mode=hb.n_a_mode
	end
end

function update_player_jmp()
	local d=approx_dist(pp,pp.j_pnt)
	if d<8 then
		pp.mode=2
		pp.j_pnt=nil
		return
	end
	
	if pp.x>pp.j_pnt.x then
		pp.dx,pp.lpx=-1
	else
		pp.dx,pp.lpx=1
	end
	
	if pp.y>pp.j_pnt.y then
		pp.dy=-1
	else
		pp.dy=1
	end
	
	pp.x=lerp(pp.x,pp.j_pnt.x,0.5)
	pp.y=lerp(pp.y,pp.j_pnt.y,0.5)
end

m_atk_d=30

function calc_atk_pnt()
	if(cur_e==nil)return nil
	
	local d=approx_dist(pp,cur_e)
	if(d>m_atk_d)return nil
	
	return {x=cur_e.x,y=cur_e.y}
end

function calc_cur_e()
	printh("=calcing=")
	local min_d=10000
	local min_e=nil
	for e in all(enmy) do
		local d=approx_dist(pp,e)
		if d<min_d and e.hp>0 then
			min_d=d
			min_e=e
		end
	end
	
	if min_e !=nil then
		cur_e=min_e
		
		if cur_e.x<pp.x then
			pp.lpx=-1
		else
			pp.lpx=1
		end
	end
end

function add_spkl(x,y)
	add(spkl,{x=x,y=y,dx=-1,dy=-1,t=0})
	add(spkl,{x=x,y=y,dx=-1,dy=1,t=0})
	add(spkl,{x=x,y=y,dx=1,dy=-1,t=0})
	add(spkl,{x=x,y=y,dx=1,dy=1,t=0})
end

function draw_spkl()
	for s in all(spkl)do
		rectfill(s.x,s.y,s.x+2,s.y+2,7)
	end
end

function update_spkl()
	for s in all(spkl)do
		s.x+=s.dx*1
		s.y+=s.dy*1
		s.t+=1
		if(s.t>10)del(spkl,s)
	end
end




-->8
-- enemies

function add_enmy(x,y)
	add(enmy,{
		x=x,y=y,at=rand(0,3),
		w=8,h=6,
		spd=0.1,ang=0,
		hp=10,
		mode=0
	})
end

cur_e_t=0

function draw_cur_e()
	if cur_e!=nil then
		cur_e_t+=0.03
		local ex=cur_e.x-cur_e.w/2
		local ey=(cur_e.y-cur_e.h/2)-1
		local off=cos(cur_e_t)*2+10
		spr(9,ex,ey-off)
	end
end

function draw_enmy()
	for e in all(enmy)do
		local ex=e.x-e.w/2
		local ey=(e.y-e.h/2)-1
		local s=anm_s[flr(e.at)+1]
		spr(s,ex,ey)
		// draw_bb(e)
	end
end

function update_enmy()
	for e in all(enmy)do
		-- enemy move
		if e.mode==0 then
			e.at=(e.at+0.3)%4
			
			e.ang=atan2(pp.x-e.x,pp.y-e.y)
			e.x+=cos(e.ang)*e.spd
			e.y+=sin(e.ang)*e.spd
			
			if e.hp<=0 then
				if(e==cur_e)cur_e=nil
				add_spkl(e.x,e.y)
				del(enmy,e)
				return
			end
			
		-- enemy got hit
		elseif e.mode==1 then
			e.x+=cos(e.ang)*e.spd
			e.y+=sin(e.ang)*e.spd
			e.spd*=0.5 -- consider enemy weight
			if e.spd<1 then
				e.mode=0
				e.spd=0.1
			end
		end
	end
end

function hit_enmy(e,hb)
	-- if(e.mode!=0)return false
	e.mode=1
	e.at=0
	e.hp-=hb.pwr
	e.spd=hb.spd
	e.ang=atan2(hb.x-e.x,hb.y-e.y)
	e.ang=(e.ang+0.5)%1
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700007777000077770000777700000000000000000000000000000000000000000009000090000000000000000000000000000000000000000000000000
00077000007777000077770000777700000000000000000000000000000000000000000009900990000000000000000000000000000000000000000000000000
00077000007c7c0000c7c70000777700000000000000000000000000000000000000000009099090000000000000000000000000000000000000000000000000
00700700007777000077770000777700000000000000000000000000000000000000000009000090000000000000000000000000000000000000000000000000
00000000000000000000000000000000007007000070070000700000007007000000070000900900000000000000000000000000000000000000000000000000
00000000000000000000000000000000007007000070000000700000000007000000070000099000000000000000000000000000000000000000000000000000
0000000000000000000000000000000008000000880000000000000800000008000000000000000bb000000b00bbb00000bbbbb0000bbbbb000bbbbb00000000
0c0000000000000000000000000000000080000088800000000000080000000800000008000000b0bb0000bb0bbb00000bbb000000b0000000b0000000000000
0cc000000000000c0000000000000000008000008880008000000080000000800000008000000b00bbb00bbbbbb00000bb0000000b0000000000000000000000
0cc000000c0000c0000000000000000000080000888800800800008000000080000000800000b000bbbbbbbbbb000000bb000000b00000000000000000000000
00c000000c0000c00c0000c0000000c0000800000888088008800880080000800000008000000000bbbbbbbbbb000000bb000000b00000000000000000000000
000c000000c0ccc000c00cc0000000c00000800008888880088888800800088000000880000000000bbbbbb00bb000b00b0000000b0000000000000000000000
0000000000cccc0000cccc0000000c000000000000888800008888000000080000000800000000000bbbbbb000bbbb0000b0000000b000000000000000000000
00000000000cc000000cc000000cc000000000000008800000088000000880000000000000000000000bb000000bb000000b0000000000000000000000000000
0000000000c0000000000000000000000000000000000000880000008800000008000000b0000000bbbbb0000000000000000000b0000000b000000000000000
00000000000ccc000000cc000000cc0000000000008888000088880000888800008888000b0000000bbbbbb000000b00b0000000b0000000b000000000000000
0000000000000cc000000cc0000000c0000000000000888000008880000008800000088000b0000000bbbbb0000000b0b0000000b0000000b000000000000000
0000000000000ccc000000cc0000000c0000080000000888000008880000000800000000000b0000000bbbbbb00000bbb0000000b0000000b000000000000000
00000c00000000cc000000cc0000000c000880000008888800000888000000080000000000000000000bbbbbbb0000bbbb00000bb0000000b000000000000000
00ccc00000000cc000000cc00000000008800000088888800000888000000000000000000000000000bbbbb0bbb00bb0bb0000b00b0000b00b00000000000000
0ccc0000000cc0000000c000000000008000000088888800000888000000880000000000000000000bbbbbb00bbbbb000bbbbb0000b00b000000000000000000
00000000000000000000000000000000000000008888000000000000000000000000000000000000bbbbb00000bbb00000bbb000000bb0000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000bbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000bb0000b3333b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00b33b000b7337b000bbbb0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0b3333b0b373373b0b3333b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b373373bb333333bb333333b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
b171171bb311113bb771177b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0bbbbbb00bbbbbb00bbbbbb000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
