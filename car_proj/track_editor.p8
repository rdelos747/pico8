pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
mode="menu"
m_idx=0 --menu idx
mx,my=0,0 --mouse x,y
mvd=false

sel_pt=nil

x_dn=false --x down
x_pr=false --x pressed
x_re=false --x released

function _init()
end

function _draw()
	cls()
	camx,camy=mx-64,my-64
	camera(camx,camy)
	
	for i=1,#pts do
		local cur=pts[i]
		local nxt=pts[i%#pts+1]
		local x1,y1=cur[1],cur[2]
		local x2,y2=nxt[1],nxt[2]
		line(x1,y1,x2,y2,1)
		pset(x1,y1,cur==sel_pt and 10 or 3)
	end
	
	for i=0,1 do
		if(m_idx==i)pal(9,10)
		spr(2+i,camx+i*9,camy)
		pal()
	end
	
	if mode=="menu" then
		spr(1,camx+m_idx*9+7,camy+7)
	else
		spr(1,mx,my)
		print("("..mx..","..my..")",mx+6,my+5,6)
	end
end

function _update()
	if btn(❎) then
		if(not x_dn)x_pr=true
		x_dn=true
	else
		if(x_dn)x_re=true
		x_dn=false
	end
	
	if mode=="menu" then
		update_menu_mode()
	elseif mode=="mouse" then
		update_mouse_mode()
	end
	
	x_pr=false
	x_re=false
end

function update_menu_mode()
	if(btnp(⬅️))m_idx=max(0,m_idx-1)
	if(btnp(➡️))m_idx=min(1,m_idx+1)
	if(btnp(❎))mode="mouse"
end

function update_mouse_mode()
	if(btn(⬆️))my-=1
	if(btn(⬇️))my+=1
	if(btn(⬅️))mx-=1
	if(btn(➡️))mx+=1
	if(btnp(🅾️))mode="menu"
	
	if m_idx==0 then
		update_drag()
	elseif m_idx==1 then
		update_erase()
	end
end

function pt_at_m()
	for p in all(pts)do
		if p[1]==mx and p[2]==my then
			return p
		end
	end
	return nil
end

function update_drag()
	if x_pr then
		sel_pt=pt_at_m()
		if not sel_pt then
			local p={mx,my,0}
			local ep=pts[#pts]
			pts[#pts+1]=p
			
			while 
			//local ep=pts
			//add(pts,sel_pt)
		end
	end
	
	if x_dn and sel_pt then
		sel_pt[1]=mx
		sel_pt[2]=my
	end
	
	--[[
	if x_re and sel_pt then
		sel_pt=nil
	end
	]]--
end

function update_erase()
	if x_re then
		local pt=pt_at_m()
		if pt then
			del(pts,pt)
		end
	end
end
-->8
-- points
pts={
	{-10,-10,0,"start"},
	{10,-10,0},
	{10,10,0},
	{-10,10,}
}
__gfx__
00000000777700009999999999999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000700000009000000990000009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700707000009099990990999009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000700700009099000990900009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000070009090900990900009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000009090090990999009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000009000000990000009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000009999999999999999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
