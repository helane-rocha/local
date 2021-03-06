dofile("modules.lua")
require("win")
require("gl2")
require("array")
require("lpt")

vert=array.double(6)
pnt=array.double(2);

tree=lpt.lpt2d_tree()
selected=nil

cnv = win.New("lpt2d")

function draw_triangle(c)
	c:simplex(vert:data())
  gl.Begin('TRIANGLES')
  gl.Vertex(vert:get(0),vert:get(1))
	if c:orientation()>0 then 
    gl.Vertex(vert:get(2),vert:get(3))
    gl.Vertex(vert:get(4),vert:get(5))
	else
    gl.Vertex(vert:get(4),vert:get(5))
    gl.Vertex(vert:get(2),vert:get(3))
	end
	gl.End()
	gl.Color(1,1,1)
	gl.Begin('LINE_LOOP')
 	gl.Vertex(vert:get(0),vert:get(1))
 	gl.Vertex(vert:get(2),vert:get(3))
 	gl.Vertex(vert:get(4),vert:get(5))
	gl.End()
end

-- chamada quando a janela OpenGL � redimensionada
function cnv:Reshape(width, height)
  gl.Viewport(0, 0, width, height) -- coloca o viewport ocupando toda a janela
	self.width=width
	self.height=height
  gl.MatrixMode('PROJECTION')      -- seleciona matriz de proje��o matrix
  gl.LoadIdentity()                -- carrega a matriz identidade
  gl.MatrixMode('MODELVIEW')       -- seleciona matriz de modelagem
  gl.LoadIdentity()                -- carrega a matriz identidade
end

-- chamada quando a janela OpenGL necessita ser desenhada
function cnv:Display()
  -- limpa a tela e o z-buffer
  gl.Clear('COLOR_BUFFER_BIT,DEPTH_BUFFER_BIT')
  gl.MatrixMode('MODELVIEW')       -- seleciona matriz de modelagem
	gl.LoadIdentity()         
  tree:node_reset()
  repeat 
    if tree:node_is_leaf() then
	    local c=tree:node_code()
      gl.Color(1,0,0)
			draw_triangle(c)
  	end
  until not tree:node_next()

  if selected~=nil then
	  for i=0,2 do 
		  local n=lpt.lpt2d()
			if tree:neighbor(selected,i,n) then
        gl.Color(1,0,1)
				draw_triangle(n)
		  end
      gl.Color(0,0,1)
			draw_triangle(selected)
		end
	end

end

-- chamada quando a janela OpenGL � criada
function cnv:Init()
  gl.ClearColor(0.0,0.0,0.0,0.5)                  -- cor de fundo preta
  gl.ClearDepth(1.0)                              -- valor do z-buffer
  gl.Disable('DEPTH_TEST')                         -- habilita teste z-buffer
  gl.Enable('CULL_FACE')                         
  gl.ShadeModel('FLAT')
end

-- chamada quando uma tecla � pressionada
function cnv:Keyboard(c,x,y)
  if c == 27 then
  -- sai da aplica��o
    os.exit()
	elseif c == 115 then 
	  if selected~=nil then 
		  tree:compat_bisect(selected)
			selected=nil
		end
  end
end

function cnv:Mouse(button,state,x,y)
  if button==glut.LEFT_BUTTON and
        state==glut.DOWN then 
	  pnt:set(0,x/self.width*2-1)
	  pnt:set(1,1-y/self.height*2)
    selected=tree:search(pnt:data())
		selected:print_simplex()
		print(" - ",tree:id(selected))
	else 
	end
end

win.Loop()
