pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
mode="menu"
m_idx=0 --menu idx
mx,my=0,0 --mouse x,y
zoom=1

show_coords=false

sel_pt=nil
cls_pt=nil
flag=nil

x_cncl=false --x cancel
x_dn=false --x down
x_pr=false --x pressed
x_re=false --x released

history={}

auto_t_max=1000
auto_t=auto_t_max

function _init()
	printh("====== start ======")
	poke(0x5f2d, 0x1)
	update_outer()
end

function _draw()
	cls()
	camx=mx/zoom-64
	camy=my/zoom-64
	camera(camx,camy)
	
	
	draw_outer()
	draw_pts()
	
	for i=0,8 do
		if(m_idx==i)pal(9,10)
		spr(1+i,camx+i*9,camy)
		pal()
	end
	print(#pts,camx+100,camy,6)
	print("z"..zoom,camx+18,camy+9,6)
	
	if mode=="menu" then
		spr(17,camx+m_idx*9+7,camy+7)
	end
	
	spr(m_idx+17,mx/zoom,my/zoom)
	print("("..mx..","..my..")",
		mx/zoom+6,my/zoom+5,
		6)
end

function draw_pts()
	for i=1,#pts do
		local cur=pts[i]
		local nxt=pts[i%#pts+1]
		local x1,y1=cur[1],cur[2]
		local x2,y2=nxt[1],nxt[2]
		line(
			x1/zoom,y1/zoom,
			x2/zoom,y2/zoom,6)
		pset(
			x1/zoom,y1/zoom,
			cur==sel_pt and 10 or 
			cur==cls_pt and 14 or 3)
		if show_coords and i%max(1,zoom)==0 then
			print("("..x1..","..y1..")",
				x1/zoom+1,y1/zoom+1,2)
		end
		if cur[4] then
			line(x1/zoom,y1/zoom,x1/zoom,y1/zoom-10,12)
			print(cur[4],x1/zoom+2,y1/zoom-10,12)
		end
	end
	pset(
		pts[1][1]/zoom,pts[1][2]/zoom,
		pts[1]==sel_pt and 10 or
		pts[1]==cls_pt and 14 or 3)
end

function draw_outer()
	for i=1,#pts do
		local cur_a=apexs[i]
		local nxt_a=apexs[i%#apexs+1]
		local x1_a,y1_a=cur_a[1],cur_a[2]
		local x2_a,y2_a=nxt_a[1],nxt_a[2]
		
		local cur_c=crnrs[i]
		local nxt_c=crnrs[i%#crnrs+1]
		local x1_c,y1_c=cur_c[1],cur_c[2]
		local x2_c,y2_c=nxt_c[1],nxt_c[2]
		
		line(
			x1_a/zoom,y1_a/zoom,
			x2_a/zoom,y2_a/zoom,1)
			
		line(
			x1_c/zoom,y1_c/zoom,
			x2_c/zoom,y2_c/zoom,1)
			
		line(
			x1_a/zoom,y1_a/zoom,
			x1_c/zoom,y1_c/zoom,1)
	end
end

function _update()
	auto_t-=1
	if auto_t==0 then
		auto_t=auto_t_max
		printh("autosaving")
		export_points()
	end
	
	if btn(❎) then
		if(not x_dn)x_pr=true
		x_dn=true
	else
		if(x_dn)x_re=true
		x_dn=false
		x_cncl=false
	end
	
	if mode=="menu" then
		update_menu_mode()
	elseif mode=="edit" then
		update_edit_mode()
	end
	
	x_pr=false
	x_re=false
	
	check_kb()
end

function update_menu_mode()
	if(btnp(⬅️))m_idx=max(0,m_idx-1)
	if(btnp(➡️))m_idx=min(8,m_idx+1)
	if(btnp(🅾️))mode="edit"
	if x_pr then
		if(m_idx==0)mode,flag="edit",nil
		if(m_idx==1)mode,flag="edit",nil
		if(m_idx==2)mode,flag="edit",nil
		if(m_idx==3)find_sel_pt(-1)
		if(m_idx==4)find_sel_pt(1)
		if(m_idx==5)show_coords=not show_coords
		if(m_idx==6)mode,flag="edit","start"
		if(m_idx==7)mode,flag="edit","sec1"
		if(m_idx==8)mode,flag="edit","sec2"
		x_cncl=true
		//if(m_idx==3)zoom=min(10,zoom+1)
		//x_pr=false
	end
end

function update_edit_mode()
	if(btnp(🅾️))mode="menu"
	
	if m_idx==0 then
		update_drag()
	elseif m_idx==1 then
		update_erase()
	elseif m_idx==2 then
		update_zoom()
	elseif m_idx>5 and m_idx<9 then
		update_set_flag()
	end
end

function move_mouse()
	if(btn(⬆️))my-=1*zoom
	if(btn(⬇️))my+=1*zoom
	if(btn(⬅️))mx-=1*zoom
	if(btn(➡️))mx+=1*zoom
end

function pt_at_m()
	for p in all(pts)do
		local dx=abs(p[1]-mx)
		local dy=abs(p[2]-my)
		if dx<10 and dy<10 then
			return p
		end
	end
	return nil
end

function update_drag()
	move_mouse()
	local pt=pt_at_m()
	if pt then
		cls_pt=pt
	else
		cls_pt=nil
	end
	
	if x_pr then
		if pt then
			mx=pt[1]
			my=pt[2]
			sel_pt=pt
		else
			local p={mx,my,0}
			if not sel_pt then
				add(pts,p)
				sel_pt=p
				
				add_history(p,nil)
			else
				pts[#pts+1]=p
				local idx=#pts-1
				while pts[idx]!=sel_pt do
					local tmp=pts[idx]
					pts[idx]=pts[idx+1]
					pts[idx+1]=tmp
					idx-=1
				end
				add_history(p,sel_pt)
				sel_pt=p
			end
			update_outer()
		end
	end
	
	if x_dn and not x_cncl and sel_pt then
		sel_pt[1]=mx
		sel_pt[2]=my
	end
	
	
	if x_re and sel_pt then
		//sel_pt=nil
		update_outer()
	end
end

function update_erase()
	move_mouse()
	if x_re then
		local pt=pt_at_m()
		if pt then
			del(pts,pt)
			if pt==sel_pt then
				sel_pt=nil
			end
			update_outer()
		end
	end
end

function update_zoom()
	if x_dn then
		if(btnp(⬆️))set_zoom(-1)
		if(btnp(⬇️))set_zoom(1)
	else
		move_mouse()
	end
end

function set_zoom(v)
	zoom=mid(1,zoom+v,20)
end

function find_sel_pt(d)
	if(not sel_pt)return
	local idx=-1
	for i,v in ipairs(pts)do
		if(v==sel_pt)idx=i
	end
	
	if d==1 and idx==#pts then
		idx=1
	elseif d==-1 and idx==1 then
		idx=#pts
	else
		idx+=d
	end
	sel_pt=pts[idx]
end

function update_set_flag()
	move_mouse()
	local pt=pt_at_m()
	if x_pr and pt then
		for p in all(pts)do
			if(p[4]==flag)p[4]=nil
		end
		pt[4]=flag
	end
end
-->8
-- points
pts={
{1445,-317,0},
{1522,-296,0},
{1572,-253,0},
{1598,-206,0},
{1598,-170,0},
{1570,-112,0},
{1522,-62,0},
{1467,-23,0},
{1380,4,0},
{1078,42,0,"start"},
{540,30,0},
{-223,30,0},
{-242,11,0},
{-242,-3,0},
{-248,-24,0},
{-276,-24,0},
{-338,13,0},
{-439,29,0},
{-466,29,0},
{-629,12,0},
{-749,-84,0},
{-784,-199,0},
{-831,-492,0,"sec1"},
{-841,-581,0},
{-861,-691,0},
{-873,-705,0},
{-897,-706,0},
{-913,-712,0},
{-949,-786,0},
{-985,-851,0},
{-1095,-1066,0},
{-1097,-1104,0},
{-1079,-1138,0},
{-1021,-1182,0},
{-742,-1248,0},
{-708,-1252,0},
{-682,-1220,0},
{-485,-872,0},
{-203,-551,0,"sec2"},
{-76,-413,0},
{-33,-388,0},
{54,-406,0},
{99,-403,0},
{159,-365,0},
{198,-320,0},
{277,-315,0},
}
-->8
-- track bounds

crnrs={}
apexs={}

function update_outer()
	crnrs=create_outer(pts,0.25,14)
	apexs=create_outer(pts,0.75,14)
end

function create_outer(pts,v,wid)
	local out={}
	//local last_a=nil
	for i=1,#pts do
	
		local prv=pts[i==1 and #pts or i-1]
		local cur=pts[i]
		local nxt=pts[i%#pts+1]
			
		local px,py=prv[1],prv[2]
		local cx,cy,cz=cur[1],cur[2],cur[3]
		local nx,ny=nxt[1],nxt[2]
		
		local a=atan2(nx-px,ny-py)
		//local dff=0
		//if last_a!=nil then
		//	dff=abs(a-last_a)
		//end
		//last_a=a
		
		local amtx=abs(wid/cos(a+v))
		local amty=abs(wid/sin(a+v))
		//printh(cur[4])
		add(out,{
			flr(cx+cos(a+v)*amtx),
			flr(cy+sin(a+v)*amty),
			cz,
			//cur[4] and cur[4] or 
			//dff>0 and "bend" or flag
		})
		
		--[[
		this is a hack but whatever
		]]--
		//local flag=cur[4]
		//if sects[flag] then
		//	printh(flag.." at: "..cx.." "..cy.." "..a)
		//	sects[flag]={x=cx,y=cy,z=cz,a=a}
		//end
	end
	return out
end
-->8
-- general

function check_kb()
	local kb=stat(31)
	//printh(kb_input)
	//if kb_input=='•' then
	//	printh("escaped")
	//end
	if kb!='' then
		//printh(kb)
	end
	
	if(kb=='u')undo()
	if(kb=='s')export_points()
	if(kb=='q')find_sel_pt(-1)
	if(kb=='w')find_sel_pt(1)
	if(kb=='r')set_zoom(-1)
	if(kb=='e')set_zoom(1)
end

function add_history(pt,prev_sel)
	add(history,{
		pt=pt,prev_sel=prev_sel
	})
end

function undo()
	if(#history<=0)return
	local last=history[#history]
	del(pts,last.pt)
	sel_pt=last.prev_sel
	
	del(history,last)
	
	update_outer()
end

function export_points()
	local s="\n"
	for p in all(pts)do
		s=s.."{"
		for i=1,#p-1 do
			local v=p[i]
			s=s..val_str(p[i])..","
		end
		s=s..val_str(p[#p]).."},\n"
	end
	printh(s)
end

function val_str(v)
	if type(v)=="string" then
		return "\34"..v.."\34"
	else
		return v
	end
end
__gfx__
00000000999999999999999999999999999999999999999999999999999999999999999999999999000000000000000000000000000000000000000000000000
00000000900000099777000990007009900700099000700990770009907700099077000990770009000000000000000000000000000000000000000000000000
00700700907770099700000990077709907000099000070997000009970000099700000997000009000000000000000000000000000000000000000000000000
00077000907700099770777990007009970007099070007997007779977777799777077997770779000000000000000000000000000000000000000000000000
00077000907070099700707990000009907000099000070997007079900707099007007990070079000000000000000000000000000000000000000000000000
00700700900007099777770990770009900700099000700990777079977007099770007997700709000000000000000000000000000000000000000000000000
00000000900000099000707990000009900000099000000990007779900007099000007990000779000000000000000000000000000000000000000000000000
00000000999999999999999999999999999999999999999999999999999999999999999999999999000000000000000000000000000000000000000000000000
00000000777700007777000077770000000000000000000000000000777700007777000077770000000000000000000000000000000000000000000000000000
00000000700000007000000070000000000000000000000000000000700000007000000070000000000000000000000000000000000000000000000000000000
00000000707000007070007070007000000000000000000000000000700770007007700070077000000000000000000000000000000000000000000000000000
00000000700700007007070070077700000000000000000000000000707000007070000070700000000000000000000000000000000000000000000000000000
00000000000070000000700000007000000000000000000000000000007777770077707700777077000000000000000000000000000000000000000000000000
00000000000000000007070000000000000000000000000000000000000070700000700700007007000000000000000000000000000000000000000000000000
00000000000000000070007000077700000000000000000000000000007700700077000700770070000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000700000000700000077000000000000000000000000000000000000000000000000
