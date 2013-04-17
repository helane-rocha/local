dofile("modules.lua")
dofile("DiffLandMatch.lua")
require("win")

test_win=win.New("test")

test_win.lmk_src={}
test_win.lmk_dst={}

function test_win:Reshape(width, height)
    gl.Viewport(0, 0, width, height) -- coloca o viewport ocupando toda a janela
    gl.MatrixMode('PROJECTION')      -- seleciona matriz de proje��o matrix
    gl.LoadIdentity()                -- carrega a matriz identidade
    gl.MatrixMode('MODELVIEW')       -- seleciona matriz de modelagem
    gl.LoadIdentity()                -- carrega a matriz identidade
    self.w=width
    self.h=height
    self.px=math.max(2/width,2/height)
end

-- chamada quando a janela OpenGL necessita ser desenhada
function test_win:Display()
    -- limpa a tela e o z-buffer
    local i
    gl.Clear('COLOR_BUFFER_BIT,DEPTH_BUFFER_BIT')
    gl.PointSize(5.0)
    gl.Begin('POINTS')
    gl.Color(1,0,0)
    for i=1,#self.lmk_src do
        local x=self.lmk_src[i][1]
        local y=self.lmk_src[i][2]
        gl.Vertex(x,y)
    end
    gl.Color(0,0,1)
    for i=1,#self.lmk_dst do
        local x=self.lmk_dst[i][1]
        local y=self.lmk_dst[i][2]
        gl.Vertex(x,y)
    end
    gl.End()
    if self.drag=="new" then
        gl.Color(0,1,1)
        gl.Begin('LINES')
        gl.Vertex(self.origin_x, self.origin_y)
        gl.Vertex(self.target_x, self.target_y)
        gl.End()
    end
    gl.Color(1,1,0)
    gl.Begin('LINES')
    for i=1,#self.lmk_src do
        local xs=self.lmk_src[i][1]
        local ys=self.lmk_src[i][2]
        local xd=self.lmk_dst[i][1]
        local yd=self.lmk_dst[i][2]
        gl.Vertex(xs,ys)
        gl.Vertex(xd,yd)
    end
    gl.End()
    gl.Color(1,0,1)
    if self.data then
        local cq=self.data.cq
        for i=1,#self.lmk_src do
            local j
            gl.Begin('LINE_STRIP')
            for j=0,64 do
                local t=j/64
                local x=cubic.eval(cq:row(i-1,0),t)
                local y=cubic.eval(cq:row(i-1,1),t)
                gl.Vertex(x,y)
            end
            gl.End()
        end
    end
end

function test_win:new_line()
    self.lmk_src[#self.lmk_src+1]={self.origin_x,self.origin_y}
    self.lmk_dst[#self.lmk_dst+1]={self.target_x,self.target_y}
end

function test_win:find(x,y)
    local i
    for i=1,#self.lmk_src do
        local ctrl_x=self.lmk_src[i][1]
        local ctrl_y=self.lmk_src[i][2]
        if math.abs(ctrl_x-x)<3*self.px
            and math.abs(ctrl_y-y)<3*self.px then
            return self.lmk_src,i
        end
    end
    for i=1,#self.lmk_dst do
        local ctrl_x=self.lmk_dst[i][1]
        local ctrl_y=self.lmk_dst[i][2]
        if math.abs(ctrl_x-x)<3*self.px
            and math.abs(ctrl_y-y)<3*self.px then
            return self.lmk_dst,i
        end
    end
    return nil,0
end

function test_win:normalize(x,y)
    x=2*x/self.w-1
    y=1-2*y/self.h
    local norm=math.sqrt(x*x+y*y)
    if norm>0.95 then
        x=0.95*x/norm
        y=0.95*y/norm
    end
    return x,y
end

function test_win:Mouse(button,state,x,y)
    x,y=self:normalize(x,y)
    if button==glut.LEFT_BUTTON then
        if state==glut.DOWN then
             if glut.GetModifiers()==glut.ACTIVE_CTRL then
                self.target_x=x
                self.origin_x=x
                self.target_y=y
                self.origin_y=y
                self.drag="new"
            else
                local t,i=self:find(x,y)
                if i~=0 then
                    self.drag="ctrl"
                    self.ctrl_i=i
                    self.ctrl_t=t
                else
                    self.drag=nil
                end
            end
        elseif state==glut.UP then
            if self.drag=="new" and
                glut.GetModifiers()==glut.ACTIVE_CTRL then
                self:new_line()
            elseif self.drag=="ctrl" then
            end
            self.drag=nil
        end
    end
end

function test_win:Motion(x,y)
    x,y=self:normalize(x,y)
    if self.drag=="new" then
        self.target_x=x
        self.target_y=y
    elseif self.drag=="ctrl" then
        self.ctrl_t[self.ctrl_i][1]=x
        self.ctrl_t[self.ctrl_i][2]=y
    end
end

function test_win:PassiveMotion(x,y)
end

function test_win:Keyboard(key,x,y)
    if key==27 then
        os.exit()
    elseif key==32 then
        local m=50
        local n=2
        local N=#self.lmk_src
        self.data=alloc_data(n,N,m)
        init_data(self.data,self.lmk_src,self.lmk_dst)
        self.env=hyperbolic_heat_kernel(0.25,0.00,0.001,16536)
        --self.env=euclidean_heat_kernel_lut(0.25,0.0,n,0.001,16536)
        print(self.env.kernel_func(1))
        --self.env=euclidean_heat_kernel(0.25,0.00,n)
        print("BP")
        self.ws=alloc_workspace(N,n)
        print("BP")
        self.solver=alloc_solver(self.data,self.env,self.ws)
        print("BP")
        repeat
            self.solver:iterate()
        until self.solver.task=="conv"
        solve_alpha(self.data,self.env,self.ws)
    end
end

function test_win:Special(key,x,y)
end


-- chamada quando a janela OpenGL � criada
function test_win:Init()
    gl.ClearColor(1.0,1.0,1.0,0.5)                  -- cor de fundo preta
    gl.ClearDepth(1.0)                              -- valor do z-buffer
    gl.Enable('DEPTH_TEST')                         -- habilita teste z-buffer
    gl.Enable('CULL_FACE')
    gl.ShadeModel('FLAT')
    self.pars=bar.new("Parameters")
    self.pars.a={type=tw.TYPE_DOUBLE,properties="help='a'"}
end

win.Loop()
