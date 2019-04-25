pico-8 cartridge // http://www.pico-8.com
version 16
__lua__
// player
p = {}
p.x = 20
p.y = 20
p.s = 1
p.frame = 0
p.fmax = 3
p.m=false
p.t=false
p.t_frame=0
p.t_max=1
p.t_dir=1
p.m_btn=-1
p.t_dist=20
p.a=false
p.a_frame=0
p.a_max=1
p.as=0
p.ax=0
p.ay=0
p.axd=1
p.ayd=1
p.axf=false
p.ayf=false

function _update()
	p.m=false
	p.m_btm=-1
	if (btn(0) and not p.a) then
		p.m=true
		p.m_btn=0
		p.ax=-4
		p.ay=-4
		p.axd=-2
		p.ayd=1
		p.axf=true
		p.ayf=false
	end
	if (btn(1) and not p.a) then
		p.m=true
		p.m_btn=1
		p.ax=4
		p.ay=4
		p.axd=2
		p.ayd=-1
		p.axf=false
		p.ayf=true
	end
	if (btn(2) and not p.a) then
		p.m=true
		p.m_btn=2
		p.ax=4
		p.ay=-4
		p.axd=-2
		p.ayd=-1
		p.axf=true
		p.ayf=true
	end
	if (btn(3) and not p.a) then
		p.m=true
		p.m_btn=3
		p.ax=-4
		p.ay=4
		p.axd=2
		p.ayd=1
		p.axf=false
		p.ayf=false
	end
	if (btn(4)) then
		p.m=false
		if (p.t==false) then
			p.t_frame=p.t_max
			p.t=true
			p.s=5
		end
	end
	if (btn(5)) then
		if (not p.t and not p.a) then
			p.a=true
			p.a_frame=p.a_max
			p.as=9
			//p.ax=-4
			//p.ay=4
		end
	end
	if (p.t) then
		p_tele()
	elseif (p.a) then
		p_attk()
	elseif (p.m) then
		p_move()
	else
		p.s=1
	end
end

function _draw()
	cls()
	spr(p.s,p.x,p.y)
	if(p.a) then
		spr(p.as,p.x+p.ax,p.y+p.ay,
			1,1,p.axf,p.ayf)
	end
end

function p_move()
	if (p.frame==0) then
		p.frame=p.fmax
		if (p.s==1) then
			p.s=4
		else
			p.s-=1
		end
	else
		p.frame-=1
	end
	if (p.m_btn==0)then p.x-=1 end
	if (p.m_btn==1)then p.x+=1 end
	if (p.m_btn==2)then p.y-=1 end
	if (p.m_btn==3)then p.y+=1 end
end

function p_tele()
	if (p.t_frame==0) then
		if (p.s==8 and p.t_dir==1) then
			p.t_dir=-1
			if (p.m_btn==0) then
				p.x-=p.t_dist
			elseif (p.m_btn==1) then
				p.x+=p.t_dist
			elseif (p.m_btn==2) then
				p.y-=p.t_dist
			elseif (p.m_btn==3) then
				p.y+=p.t_dist
			end
		elseif (p.s==5 and p.t_dir==-1) then
			p.t=false
			p.t_frame=0
			p.t_dir=1
		else
			p.s+=p.t_dir
			p.t_frame=p.t_max
		end
	else
		p.t_frame-=1
	end
end

function p_attk()
	if (p.a_frame==0) then
		if (p.as==13) then
			p.a=false
			p.as=0
			p.ax=0
			p.ay=0
		else
			p.a_frame=p.a_max
			p.as+=1
			p.ax+=p.axd
			p.ay+=p.ayd
		end
	else
		p.a_frame-=1
	end
end
__gfx__
0000000000000000077777700000000007777770700000070070070000c00c000000000000000000000070000000000700000000000000000000000000000000
000000000777777007000070077777700700007070000007c070070c00c00c000000000000000000000070700c000077000000c0000000000000000000000000
007007000700007007000070070000700700007070000007c070070c00c00c00000cc000000000000000707700cc0c77000000c0000000000000000000000000
000770000700007007c00c700700007007c00c7070700707c070070c00c00c00000cc000000000000000707700cc0c77000c00c7000000000000000000000000
0007700007c00c700767777007c00c700777767070700707c070070c00c00c00000cc000000000077777707700000c770000ccc70000000c0000000000000000
007007000777777000777600077777700067770070000007c070070c00c00c00000cc000000000070000007700cccc770000ccc70000000c0000000000000000
000000000067760000770700006776000070770070000007c070070c00c00c00000000000000000707777777077777770cccccc70000000c0000000000000000
0000000000700700007000000070070000000700700000070070070000c00c0000000000000077770077777777777777000777770000cccc0000000000000000
