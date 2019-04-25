pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
ms=0.5 //max speed
ac=0.05 //accel
st=0 //spawn time
eb_st=0
ebst_m=200
sm=100 //spawn max
p={x=50,y=50,xa=0,ya=0}
p.hb={x=4,y=4}
//a=0
scr=0
rsr=10
hp=6
col_e=0

e_tm=0 //enemy time
e={} //enemies
e_max=10
se=0 //selected enemy
aim=false
slct=false
shtng=false
wd=0 //wind delay
wm=5 //wind max
wind=11

b={} //bullet
hit_p=0
hit_f=0
hit_x=0
hit_y=0
del_b={}
del_e={}
shake_p=0
shake_x=2

r={} //resource
rt=0
rm=300
rb={} //big resource

function len(t)
	n=0
	for tt in all(t) do
		n+=1
	end
	return n
end

function _update()
	if(col_e>0 and shake_p==0)col_e-=1
	if(hit_p>0)then
		hit_p-=1
	elseif(shake_p>0)then
		if(shake_p%2==0)shake()
		shake_p-=1
	else
		del_dead()
		move()
		select()
		shoot()
		spawn()
		spawn_b()
		spawn_r()
		update_enemies()
	end
end

function _draw()
	cls()
	spr(1,p.x,p.y)
	if(hit_p==0)then
		for ee in all(e)do
			if(ee.sh>0)then
				spr(flr(ee.sh),ee.x,ee.y)
			else
				spr(ee.sp,ee.x,ee.y)
			end
		end
		for rr in all(r)do
			spr(rr.sp,rr.x,rr.y)
		end
		for rr in all(rb)do
			spr(9,rr.x,rr.y)
		end
	else
		for ee in all(del_e)do
			if(ee.sp==2)spr(18,ee.x,ee.y)
			if(ee.sp==19)spr(20,ee.x,ee.y)
		end
	end
	if(se>0 and aim)then
		spr(3,e[se].x,e[se].y)
		if(wind<11)then
			circ(e[se].x+3,e[se].y+3,wind)
		end
	end
	for bb in all(b)do
		if(bb.sp==-1)then
			line(bb.x,bb.y,
				bb.x+bb.dx,bb.y+bb.dy)
		else
			spr(bb.sp,bb.x,bb.y)
		end
	end
	if(hit_p<1 and hit_f>3 and hit_f<8)then
		spr(flr(hit_f),hit_x,hit_y)
		hit_f+=0.5
	end
	hud()
end

function hud()
	//print("score:"..scr)
	//print("  ")
	//print("resource:"..rsr)
	//ss="score:"..scr.."  "
	//ss=ss.."resource:"..rsr
	//print(ss)
	if(hp==1)spr(12,0,0)
	if(hp>=2)spr(11,0,0)
	if(hp==3)spr(12,9,0)
	if(hp>=4)spr(11,9,0)
	if(hp==5)spr(12,18,0)
	if(hp==6)spr(11,18,0)
	spr(10,30,0)
	print(":"..rsr,34,0)
end

function del_dead()
	for bb in all(del_b)do
		del(b,bb)
		del(del_b,bb)
	end
	for ee in all(del_e)do
		if(flr(rnd(3))==0)then
			local q={x=ee.x,y=ee.y}
			q.hb={x=0,y=0}
			add(rb,q)
		end
		del(e,ee)
		del(del_e,ee)
		scr+=1
	end
end

function move()
	ac_x=false
	ac_y=false
	x_dir=0
	y_dir=0
	if (btn(0)) then
		ac_x=true
		x_dir=-1
	end
	if (btn(1)) then
		ac_x=true
		x_dir=1
	end
	if (btn(2)) then
		ac_y=true
		y_dir=-1
	end
	if (btn(3)) then
		ac_y=true
		y_dir=1
	end
	
	if(ac_x)then
		if(p.xa>=-ms and p.xa<=ms)then
			p.xa+=(ac*x_dir)
		else
			p.xa=ms*x_dir
		end
	elseif(p.xa>0)then
		p.xa-=0.02
	elseif(p.xa<0)then
		p.xa+=0.02
	end
	
	if(ac_y)then
		if(p.ya>=-ms and p.ya<=ms)then
			p.ya+=(ac*y_dir)
		else
			p.ya=ms*y_dir
		end
	elseif(p.ya>0)then
		p.ya-=0.02
	elseif(p.ya<0)then
		p.ya+=0.02
	end
	
	p.x+=p.xa
	p.y+=p.ya
	
	for rr in all(r)do
		if(col(p,rr)>0)then
			if(rr.sp==8)rsr+=1
			if(rr.sp==24 and hp<6)hp+=1
			del(r,rr)
		end
	end
	for rr in all(rb)do
		if(col(p,rr)>0)then
			rsr+=3
			del(rb,rr)
		end
	end
	if(col_e==0)then
		for ee in all(e)do
			if(col(p,ee)==1)then
				hp-=1
				e_angle(ee,1)
				col_e=10
				shake_p=10
			end
		end
		for bb in all(b)do
			if(bb.sp!=-1 and col(p,bb)==1)then
				hp-=1
				col_e=10
				shake_p=10
				del(b,bb)
			end
		end
	end
end

function select()
	if(btn(4) and not slct)then
		slct=true
		se+=1
		aim=true
		wind=11
		if(se>len(e))se=1
		if(len(e)==0)se=0
	elseif(not btn(4) and slct)then
		slct=false
	end
end

function shoot()
	if(btn(5)and aim)then
		shtng=true
		if(wd==0)then
			wd=wm
			if(wind>0)wind-=1
		elseif(abs(p.xa)<0.02 and abs(p.ya)<0.02)then
			wd-=1
		else
			wind=10
		end
	elseif(not btn(5) and shtng)then
		shtng=false
		wd=0
			if(se>0 and rsr>0)then
			local ee=e[se]
			local rx=rnd(wind*2)-wind
			local ry=rnd(wind*2)-wind
			local ox=ee.x+rx
			local oy=ee.y+ry
			send_a(p.x,p.y,ox,oy,5,-1)
			rsr-=1
		end
		wind=11
	end
	
	for bb in all(b)do
		if(bb.x>=0 and 
					bb.x<=128 and 
					bb.y>=0 and 
					bb.y<=128)then
			bb.x+=bb.dx
			bb.y+=bb.dy
			if(bb.sp==-1)then
				for ee in all(e)do
					local cc=col(bb,ee)
					if(cc==1)then
						add(del_b,bb)
						add(del_e,ee)
						hit_x=ee.x
						hit_y=ee.y
						hit_f=4
						hit_p=8
						aim=false
					elseif(cc==2)then
						e_angle(ee,1)
					end
				end
			end
		else
			del(b,bb)
		end
	end
end	

function spawn()
	if(len(e)<=e_max)then
		if (st<=0) then
			st=sm
			local rx=flr(rnd(120))+4
			local ry=flr(rnd(120))+4
			local q={x=rx,y=ry,m=0,a=0,s=0.1}
			q.hb={x=3,y=3}
			q.sp=2
			q.sh=-1
			add(e,q)
		else
			st-=1
		end
	end
end

function spawn_b()
	if(len(e)<=e_max)then
		if(eb_st<=0)then
			eb_st=ebst_m
			local rx=flr(rnd(120))+4
			local ry=flr(rnd(120))+4
			local q={x=rx,y=ry,m=0,a=0,s=0.1}
			q.hb={x=3,y=3}
			q.sp=19
			q.sh=0
			add(e,q)
		else
			eb_st-=1
		end
	end
end

function spawn_r()
	if (rt<=0) then
		rt=rm
		local rx=flr(rnd(120))+4
		local ry=flr(rnd(120))+4
		local q={x=rx,y=ry}
		q.hb={x=3,y=3}
		q.sp=8
		if(flr(rnd(2))==0)q.sp=24
		add(r,q)
	else
		rt-=1
	end
end

function update_enemies()
	for ee in all(e)do
		if(ee.m==0)then
			if(flr(rnd(50))==0)then
				e_angle(ee,0)
			end
		elseif(ee.m>0)then
			ee.m-=1
			ee.x+=cos(ee.a)*ee.s
			ee.y+=sin(ee.a)*ee.s
			if(ee.x<4)ee.x=4
			if(ee.x>124)ee.x=124
			if(ee.y<4)ee.y=4
			if(ee.y>124)ee.y=124
		end
		if(ee.sh==0)then
			if(flr(rnd(200))==0)then
				ee.sh=21
			end
		elseif(ee.sh>0 and ee.sh<24)then
			ee.sh+=0.2
			if(ee.sh>=24)then
				ee.sh=0
				send_a(ee.x,ee.y,p.x,p.y,1,17)
			end
		end
	end
end

function e_angle(ee,tt)
	if(tt==0)then
		ee.s=0.1
		ee.m=flr(rnd(30))+10
	elseif(tt==1)then
		ee.s=0.5
		ee.m=flr(rnd(100))+50
	end
	ee.a=rnd(1)
end

function col(o1,o2)
	local tr=2
	local tr2=5
	local o1x=o1.x+o1.hb.x
	local o2x=o2.x+o2.hb.x
	local o1y=o1.y+o1.hb.y
	local o2y=o2.y+o2.hb.y
	if(o1x>o2x-tr and o1x<o2x+tr and
		o1y>o2y-tr and o1y<o2y+tr)then
		return 1
	elseif(o1x>o2x-tr2 and o1x<o2x+tr2 and
		o1y>o2y-tr2 and o1y<o2y+tr2)then
		return 2
	end
	return 0
end

function shake()
	shake_x*=-1
	p.x+=shake_x
	for ee in all(e)do
		ee.x+=shake_x
	end
	for bb in all(b)do
		bb.x+=shake_x
	end
	for rr in all(r)do
		rr.x+=shake_x
	end
	for rr in all(rb)do
		rr.x+=shake_x
	end
end

function send_a(x1,y1,x2,y2,v,f)
	local a=atan2(x2-x1,y2-y1)
	local bb={}
	bb.hb={x=0,y=0}
	bb.dx=cos(a)*v
	bb.dy=sin(a)*v
	bb.x=x1+3
	bb.y=y1+3
	bb.sp=f
	add(b,bb)
end
__gfx__
00000000000000000000000077000770000000000000000000ffff00000660000000000000000000060000000880880008800000000000000000000000000000
0000000000000000000000007000007000000000000000000faaaaf0066006600000000000000000040000008888888088880000000000000000000000000000
00700700000cc000000800000000000000000000000aa000faa00aaf060000600bb00b0000000000040000008888888088880000000000000000000000000000
000770000007700000070000000000000009900000a00a00fa0000af6000000600b0b00000000000040000000888880008880000000000000000000000000000
000770000007700000070000000000000009900000a00a00fa0000af60000006000bb00000000000646000000088800000880000000000000000000000000000
0070070000077000000000007000007000000000000aa000faa00aaf06000060000b000006008000606000000008000000080000000000000000000000000000
0000000000000000000000007700077000000000000000000faaaaf0066006600000000006600660000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000ffff00000660000000000000000000000000000000000000000000000000000000000000000000
00000000880000000000000000000000000000000000000000eee00000e8e0000000000000000000000000000000000000000000000000000000000000000000
0000000088000000000900000000000000000000000e00000e080e000e8a8e000080000000000000000000000000000000000000000000000000000000000000
000000000000000000090000009990000099900000eee0000e888e0008aaa8000080000000000000000000000000000000000000000000000000000000000000
00000000000000000009000000878000009a9000008e80000e787e000e8a8e000008080000000000000000000000000000000000000000000000000000000000
00000000000000000000000000777000009a90000077700000eee00000e8e0000008800000000000000000000000000000000000000000000000000000000000
00000000000000000000000000777000009990000077700000777000007770000008000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000
