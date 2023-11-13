pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- track collision test
px,py,ang=0,0,0.25

pts={
	{-50,-50},
	{50,-50},
	{50,50},
	{-50,50}
}
crnrs={}
apexs={}
tris={}

wheels={
	{-3,-5,false},
	{3,-5,false},
	{-3,5,false},
	{3,5,false}
}

draw_mode=0

function rot(x,y)
	x-=px
	y+=py
	local rx,ry=rot_pt(x,y,-ang+0.25)
	rx+=camx+64
	ry+=camy+115
	return rx,ry
end

function rot_pt(x,y,a)
	local rx=x*cos(a)+y*sin(a)
	local ry=x*sin(a)-y*cos(a)
	return rx,ry
end


function _init()
	printh("===== start =====")
	
	for i=1,#pts do
		local prv=pts[i==1 and #pts or i-1]
		local cur=pts[i]
		local nxt=pts[i%#pts+1]
			
		local px,py=prv[1],prv[2]
		local cx,cy=cur[1],cur[2]
		local nx,ny=nxt[1],nxt[2]
				
		local a=atan2(nx-px,ny-py)
		local amtx=abs(5/cos(a+0.25))
		local amty=abs(5/sin(a+0.25))
		
		add(crnrs,{
			cx+cos(a+0.25)*amtx,
			cy+sin(a+0.25)*amty})
		
		amtx=abs(5/cos(a+0.75))
		amty=abs(5/sin(a+0.75))
		
		add(apexs,{
			cx+cos(a+0.75)*amtx,
			cy+sin(a+0.75)*amty
		})
	end
	
	-- calculate triangles
	for i=1,#crnrs do
		local cur_c=crnrs[i]
		local cur_p=apexs[i]
		local nxt_c=crnrs[i%#crnrs+1]
		local nxt_p=apexs[i%#apexs+1]
		
		add(tris,{
			{cur_c[1],cur_c[2]},
			{nxt_c[1],nxt_c[2]},
			{cur_p[1],cur_p[2]},
			false
		})
		add(tris,{
			{nxt_c[1],nxt_c[2]},
			{nxt_p[1],nxt_p[2]},
			{cur_p[1],cur_p[2]},
			false
		})
	end
end

function _draw()
	cls()
	
	if draw_mode==0 then
		draw_top_down()
	else
		draw_pov()
	end
end

function _update()
	if btnp(❎) then
		if draw_mode==0 then
			draw_mode=1
		else
			draw_mode=0
		end
	end
	
	if(btn(⬅️))ang=(ang+0.01)%1
	if(btn(➡️))ang=(ang-0.01)%1
	if btn(⬆️) then
		px+=cos(ang)*1
		py+=sin(ang)*1
	end
	
	for t in all(tris)do
		t[4]=false
	end
	
	for w in all(wheels)do
		local rx,ry=rot_pt(w[1],w[2],ang+0.25)
		w[3]=false
		if on_track(px+rx,py+ry) then
			w[3]=true
		end
	end
end
-->8
-- draws
function draw_top_down()
	camera(-64,-64)
	
	for i=1,#pts do
		local cur=pts[i]
		local nxt=pts[i%#pts+1]
		
		local cx,cy=cur[1],cur[2]
		local nx,ny=nxt[1],nxt[2]
		line(cx,cy,nx,ny,7)
	end
	
	for t in all(tris) do
		for i=1,3 do
			local cur=t[i]
			local nxt=t[i%3+1]
			
			local cx,cy=cur[1],cur[2]
			local nx,ny=nxt[1],nxt[2]
			line(
				cx,cy,nx,ny,1)
		end
	end
	
	for t in all(tris) do
		if t[4] then
			for i=1,3 do
				local cur=t[i]
				local nxt=t[i%3+1]
			
				local cx,cy=cur[1],cur[2]
				local nx,ny=nxt[1],nxt[2]
				line(
					cx,cy,nx,ny,3)
			end
		end
	end
	
	pset(px,py,7)
	pset(px+cos(ang),py+sin(ang),9)
	for w in all(wheels)do
		local rx,ry=rot_pt(w[1],w[2],ang+0.25)
		pset(
			px+rx,
			py+ry,
			w[3] and 11 or 8)
	end
end

function draw_pov()
	camx=flr(px-64)
	camy=flr(py-115)
	camera(camx,camy)
	
	for t in all(tris) do
			for i=1,3 do
				local cur=t[i]
				local nxt=t[i%3+1]
			
				local cx,cy=cur[1],cur[2]
				local nx,ny=nxt[1],nxt[2]
					
				cx,cy=rot(cur[1],cur[2])
				nx,ny=rot(nxt[1],nxt[2])
				line(cx,cy,nx,ny,cur[4] and 11 or 1)
			end
	end
	
	-- player
	rect(px-3,py-5,px+3,py+5,7)
	for w in all(wheels)do
		pset(px-w[1],py+w[2],
			w[3] and 11 or 8)
	end
end
-->8
--triangles

function on_track(x,y)
	for t in all(tris)do
		if pt_in_tri(x,y,t) then
			t[4]=true //debug
			return true
		end
	end
	return false
end

function pt_in_tri(x,y,tr)
	local p0x,p0y=tr[1][1],tr[1][2]
	local p1x,p1y=tr[2][1],tr[2][2]
	local p2x,p2y=tr[3][1],tr[3][2]
	
	local dx=x-p2x
	local dy=y-p2y
	local dx21=p2x-p1x
	local dy12=p1y-p2y
	local d=dy12*(p0x-p2x)+dx21*(p0y-p2y)
	local s=dy12*dx+dx21*dy
	local t=(p2y-p0y)*dx+(p0x-p2x)*dy
	if d<0 then
		return s<=0 and t<=0 and s+t>=d
	end
	
	return s>=0 and t>=0 and s+t<=d
end
__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
