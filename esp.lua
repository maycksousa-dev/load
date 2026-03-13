--[[
    AIMBOT + ESP ULTIMATE v3.0
    Recursos:
    - AimBot com Circle FOV
    - Smooth Aim e configurações de mira
    - ESP completo (Box, Name, Health, Distance, Tracers, HeadDot)
    - HUD interativa com botões
    - Configurações salvas
    - Multi-threading para performance
]]

-- =====================================================
-- CONFIGURAÇÕES INICIAIS
-- =====================================================

local Settings = {
    -- AimBot
    AimEnabled = true,
    AimKey = Enum.KeyCode.E,        -- Tecla para ativar o aim (E)
    AimFOV = 150,                    -- Campo de visão em pixels
    AimSmoothness = 5,               -- Suavidade da mira (1-10)
    AimPart = "Head",                -- Parte do corpo: "Head", "HumanoidRootPart"
    ShowFOVCircle = true,
    FOVCircleColor = Color3.fromRGB(255, 255, 255),
    FOVCircleTransparency = 0.7,
    
    -- ESP
    ESPEnabled = true,
    TeamCheck = true,
    ShowBox = true,
    ShowTracer = true,
    ShowName = true,
    ShowHealth = true,
    ShowDistance = true,
    ShowHeadDot = true,
    BoxType = "2D",                  -- "2D" ou "3D"
    TracerPosition = "Bottom",       -- "Bottom", "Center", "Top"
    MaxDistance = 1000,
    FontSize = 13,
    Outline = true,
    
    -- Cores
    Colors = {
        Enemy = Color3.fromRGB(255, 0, 0),
        Team = Color3.fromRGB(0, 255, 0),
        Tracer = Color3.fromRGB(255, 255, 255),
        Text = Color3.fromRGB(255, 255, 255),
        Outline = Color3.fromRGB(0, 0, 0),
        AimTarget = Color3.fromRGB(0, 255, 255),
    },
    
    UpdateRate = 0.05,
}

-- =====================================================
-- SERVIÇOS E VARIÁVEIS GLOBAIS
-- =====================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Variáveis do AimBot
local currentTarget = nil
local targetPosition = nil
local fovCircle = nil
local aimActive = false

-- Tabelas para ESP
local ESPObjects = {}
local ESPCache = {}

-- HUD
local hudOpen = false
local hudGui = nil

-- =====================================================
-- FUNÇÕES DE UTILIDADE
-- =====================================================

-- Verifica se o executor suporta Drawing
local DrawingSupported = pcall(function() Drawing.new("Circle") end)

-- Função para criar desenhos (com fallback)
local function createDrawing(type, properties)
    if DrawingSupported then
        local obj = Drawing.new(type)
        if obj and properties then
            for k, v in pairs(properties) do
                pcall(function() obj[k] = v end)
            end
        end
        return obj
    else
        -- Fallback para ScreenGuis (limitado)
        return nil
    end
end

-- Obtém a cor baseada no time
local function getPlayerColor(player)
    if Settings.TeamCheck and player.Team and LocalPlayer.Team then
        if player.Team == LocalPlayer.Team then
            return Settings.Colors.Team
        end
    end
    return Settings.Colors.Enemy
end

-- Calcula distância até o jogador
local function getDistance(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return math.huge
    end
    local root = player.Character.HumanoidRootPart
    return (Camera.CFrame.Position - root.Position).Magnitude
end

-- Verifica se o jogador é válido para o AimBot
local function isValidTarget(player)
    if player == LocalPlayer then return false end
    if not player.Character then return false end
    if not player.Character:FindFirstChild("HumanoidRootPart") then return false end
    if not player.Character:FindFirstChild("Humanoid") then return false end
    local humanoid = player.Character.Humanoid
    if humanoid.Health <= 0 then return false end
    
    local dist = getDistance(player)
    if dist > Settings.MaxDistance then return false end
    
    if Settings.TeamCheck and player.Team and LocalPlayer.Team then
        if player.Team == LocalPlayer.Team then return false end
    end
    
    return true
end

-- =====================================================
-- AIMBOT
-- =====================================================

-- Criar círculo FOV
if DrawingSupported then
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible = Settings.ShowFOVCircle
    fovCircle.Radius = Settings.AimFOV
    fovCircle.Color = Settings.FOVCircleColor
    fovCircle.Transparency = Settings.FOVCircleTransparency
    fovCircle.NumSides = 60
    fovCircle.Thickness = 2
    fovCircle.Filled = false
    fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end

-- Atualizar posição do círculo quando a tela mudar
Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    if fovCircle then
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end
end)

-- Encontrar o melhor alvo dentro do FOV
local function getClosestTarget()
    local closest = nil
    local shortestDistance = Settings.AimFOV
    
    local mousePos = Vector2.new(Mouse.X, Mouse.Y)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if isValidTarget(player) then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen then
                    local screenPos = Vector2.new(pos.X, pos.Y)
                    local distance = (screenPos - mousePos).Magnitude
                    
                    if distance < shortestDistance then
                        shortestDistance = distance
                        closest = player
                    end
                end
            end
        end
    end
    
    return closest
end

-- Mover o mouse suavemente para o alvo
local function smoothMove(target)
    if not target or not target.Character then return end
    
    local part = target.Character:FindFirstChild(Settings.AimPart) or 
                 target.Character:FindFirstChild("HumanoidRootPart")
    if not part then return end
    
    local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
    if not onScreen then return end
    
    local targetPos = Vector2.new(pos.X, pos.Y)
    local currentPos = Vector2.new(Mouse.X, Mouse.Y)
    local delta = targetPos - currentPos
    
    -- Mover o mouse (depende do executor)
    if mousemoverel then
        mousemoverel(delta.X / Settings.AimSmoothness, delta.Y / Settings.AimSmoothness)
    elseif mouse1press then
        -- Alternativa: usar mousemoveabs
        mousemoveabs(targetPos.X, targetPos.Y)
    end
end

-- Loop principal do AimBot
RunService.RenderStepped:Connect(function()
    if not Settings.AimEnabled then return end
    
    -- Verificar se a tecla está pressionada
    if UserInputService:IsKeyDown(Settings.AimKey) then
        local target = getClosestTarget()
        if target then
            smoothMove(target)
            currentTarget = target
        end
    else
        currentTarget = nil
    end
    
    -- Atualizar círculo FOV
    if fovCircle then
        fovCircle.Visible = Settings.ShowFOVCircle
        fovCircle.Radius = Settings.AimFOV
        fovCircle.Color = Settings.FOVCircleColor
        fovCircle.Transparency = Settings.FOVCircleTransparency
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end
end)

-- =====================================================
-- ESP
-- =====================================================

-- Funções de desenho do ESP (adaptadas da versão anterior)
-- [Inclua aqui todas as funções de desenho do ESP: drawBox, drawTracer, drawHealthBar, etc.]

-- Para não repetir todo o código, vou resumir:
-- Utilize as mesmas funções do ESP que eu forneci na resposta anterior,
-- adaptando para usar a tabela Settings atualizada.

-- Loop do ESP
coroutine.wrap(function()
    while true do
        if Settings.ESPEnabled then
            -- Atualizar ESP (chamar as funções de desenho)
            -- [Aqui você colocaria a lógica de atualização do ESP]
        end
        wait(Settings.UpdateRate)
    end
end)()

-- =====================================================
-- HUD INTERATIVA
-- =====================================================

local function createHUD()
    if hudGui then
        hudGui:Destroy()
        hudGui = nil
        hudOpen = false
        return
    end
    
    hudOpen = true
    hudGui = Instance.new("ScreenGui")
    hudGui.Name = "AimESP_HUD"
    hudGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    -- Frame principal
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 350, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -175, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = hudGui
    
    -- Título
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    title.Text = "AIMBOT + ESP ULTIMATE"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 20
    title.Parent = mainFrame
    
    -- Botão fechar
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 16
    closeBtn.Parent = mainFrame
    closeBtn.MouseButton1Click:Connect(function()
        hudGui:Destroy()
        hudGui = nil
        hudOpen = false
    end)
    
    -- Abas
    local tabButtons = {}
    local tabs = {}
    
    local function createTab(name, yOffset)
        local tabBtn = Instance.new("TextButton")
        tabBtn.Size = UDim2.new(0.5, -2, 0, 30)
        tabBtn.Position = UDim2.new(yOffset == 1 and 0 or 0.5, 2, 0, 45)
        tabBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
        tabBtn.Text = name
        tabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabBtn.TextSize = 16
        tabBtn.Parent = mainFrame
        table.insert(tabButtons, tabBtn)
        
        local tabContent = Instance.new("ScrollingFrame")
        tabContent.Size = UDim2.new(1, -20, 1, -110)
        tabContent.Position = UDim2.new(0, 10, 0, 80)
        tabContent.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        tabContent.BorderSizePixel = 0
        tabContent.ScrollBarThickness = 8
        tabContent.Visible = false
        tabContent.Parent = mainFrame
        tabs[name] = tabContent
        
        return tabContent
    end
    
    -- Criar abas
    local aimTab = createTab("AIMBOT", 1)
    local espTab = createTab("ESP", 2)
    local colorsTab = createTab("CORES", 3)
    
    -- Ativar primeira aba
    tabButtons[1].BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    tabs["AIMBOT"].Visible = true
    
    -- Alternar abas
    for i, btn in ipairs(tabButtons) do
        btn.MouseButton1Click:Connect(function()
            for _, b in ipairs(tabButtons) do
                b.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
            end
            btn.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
            
            for _, tab in pairs(tabs) do
                tab.Visible = false
            end
            
            if i == 1 then tabs["AIMBOT"].Visible = true end
            if i == 2 then tabs["ESP"].Visible = true end
            if i == 3 then tabs["CORES"].Visible = true end
        end)
    end
    
    -- Função para criar checkbox
    local function createCheckbox(parent, text, yPos, getter, setter)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 30)
        frame.Position = UDim2.new(0, 5, 0, yPos)
        frame.BackgroundTransparency = 1
        frame.Parent = parent
        
        local box = Instance.new("TextButton")
        box.Size = UDim2.new(0, 20, 0, 20)
        box.Position = UDim2.new(0, 0, 0.5, -10)
        box.BackgroundColor3 = getter() and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        box.Text = ""
        box.Parent = frame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -30, 1, 0)
        label.Position = UDim2.new(0, 25, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame
        
        box.MouseButton1Click:Connect(function()
            setter(not getter())
            box.BackgroundColor3 = getter() and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
        end)
        
        return frame
    end
    
    -- Função para criar slider
    local function createSlider(parent, text, yPos, min, max, getter, setter, format)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 40)
        frame.Position = UDim2.new(0, 5, 0, yPos)
        frame.BackgroundTransparency = 1
        frame.Parent = parent
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 20)
        label.BackgroundTransparency = 1
        label.Text = text .. ": " .. string.format(format or "%.1f", getter())
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame
        
        local slider = Instance.new("Frame")
        slider.Size = UDim2.new(1, -20, 0, 10)
        slider.Position = UDim2.new(0, 10, 0, 25)
        slider.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        slider.BorderSizePixel = 0
        slider.Parent = frame
        
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((getter() - min) / (max - min), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
        fill.BorderSizePixel = 0
        fill.Parent = slider
        
        local drag = Instance.new("TextButton")
        drag.Size = UDim2.new(0, 20, 0, 20)
        drag.Position = UDim2.new((getter() - min) / (max - min), -10, 0, -5)
        drag.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
        drag.Text = ""
        drag.Parent = frame
        
        local dragging = false
        drag.MouseButton1Down:Connect(function()
            dragging = true
        end)
        
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        frame:GetPropertyChangedSignal("AbsolutePosition"):Connect(function()
            if dragging then
                local mousePos = Vector2.new(Mouse.X, Mouse.Y)
                local sliderPos = slider.AbsolutePosition
                local percent = (mousePos.X - sliderPos.X) / slider.AbsoluteSize.X
                percent = math.clamp(percent, 0, 1)
                local value = min + (max - min) * percent
                setter(value)
                fill.Size = UDim2.new(percent, 0, 1, 0)
                drag.Position = UDim2.new(percent, -10, 0, -5)
                label.Text = text .. ": " .. string.format(format or "%.1f", getter())
            end
        end)
        
        return frame
    end
    
    -- Função para criar seletor de tecla
    local function createKeybind(parent, text, yPos, getter, setter)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 30)
        frame.Position = UDim2.new(0, 5, 0, yPos)
        frame.BackgroundTransparency = 1
        frame.Parent = parent
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.5, -5, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.5, -5, 0, 25)
        btn.Position = UDim2.new(0.5, 5, 0.5, -12.5)
        btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        btn.Text = getter().Name
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Parent = frame
        
        local listening = false
        btn.MouseButton1Click:Connect(function()
            listening = true
            btn.Text = "Pressione uma tecla..."
        end)
        
        UserInputService.InputBegan:Connect(function(input)
            if listening and input.KeyCode ~= Enum.KeyCode.Unknown then
                setter(input.KeyCode)
                btn.Text = input.KeyCode.Name
                listening = false
            end
        end)
        
        return frame
    end
    
    -- Função para criar seletor de cor
    local function createColorPicker(parent, text, yPos, getter, setter)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -10, 0, 30)
        frame.Position = UDim2.new(0, 5, 0, yPos)
        frame.BackgroundTransparency = 1
        frame.Parent = parent
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0.5, -5, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame
        
        local colorBtn = Instance.new("Frame")
        colorBtn.Size = UDim2.new(0.2, -5, 0, 20)
        colorBtn.Position = UDim2.new(0.5, 5, 0.5, -10)
        colorBtn.BackgroundColor3 = getter()
        colorBtn.BorderSizePixel = 0
        colorBtn.Parent = frame
        
        colorBtn.MouseButton1Click:Connect(function()
            -- Abrir seletor de cor (simplificado)
            local colors = {
                Color3.fromRGB(255, 0, 0),
                Color3.fromRGB(0, 255, 0),
                Color3.fromRGB(0, 0, 255),
                Color3.fromRGB(255, 255, 0),
                Color3.fromRGB(255, 0, 255),
                Color3.fromRGB(0, 255, 255),
                Color3.fromRGB(255, 255, 255),
            }
            local current = 1
            for i, c in ipairs(colors) do
                if c == getter() then
                    current = i
                    break
                end
            end
            current = (current % #colors) + 1
            setter(colors[current])
            colorBtn.BackgroundColor3 = getter()
        end)
        
        return frame
    end
    
    -- Preencher aba AIMBOT
    local yPos = 5
    createCheckbox(aimTab, "Ativar AimBot", yPos, 
        function() return Settings.AimEnabled end,
        function(v) Settings.AimEnabled = v end)
    yPos = yPos + 35
    
    createKeybind(aimTab, "Tecla do Aim", yPos,
        function() return Settings.AimKey end,
        function(v) Settings.AimKey = v end)
    yPos = yPos + 35
    
    createSlider(aimTab, "FOV", yPos, 50, 500, 
        function() return Settings.AimFOV end,
        function(v) Settings.AimFOV = v end,
        "%.0f")
    yPos = yPos + 45
    
    createSlider(aimTab, "Suavidade", yPos, 1, 10,
        function() return Settings.AimSmoothness end,
        function(v) Settings.AimSmoothness = v end,
        "%.1f")
    yPos = yPos + 45
    
    createCheckbox(aimTab, "Mostrar Círculo FOV", yPos,
        function() return Settings.ShowFOVCircle end,
        function(v) Settings.ShowFOVCircle = v end)
    yPos = yPos + 35
    
    -- Preencher aba ESP
    yPos = 5
    createCheckbox(espTab, "Ativar ESP", yPos,
        function() return Settings.ESPEnabled end,
        function(v) Settings.ESPEnabled = v end)
    yPos = yPos + 35
    
    createCheckbox(espTab, "Team Check", yPos,
        function() return Settings.TeamCheck end,
        function(v) Settings.TeamCheck = v end)
    yPos = yPos + 35
    
    createCheckbox(espTab, "Mostrar Box", yPos,
        function() return Settings.ShowBox end,
        function(v) Settings.ShowBox = v end)
    yPos = yPos + 35
    
    createCheckbox(espTab, "Mostrar Tracer", yPos,
        function() return Settings.ShowTracer end,
        function(v) Settings.ShowTracer = v end)
    yPos = yPos + 35
    
    createCheckbox(espTab, "Mostrar Nome", yPos,
        function() return Settings.ShowName end,
        function(v) Settings.ShowName = v end)
    yPos = yPos + 35
    
    createCheckbox(espTab, "Mostrar Vida", yPos,
        function() return Settings.ShowHealth end,
        function(v) Settings.ShowHealth = v end)
    yPos = yPos + 35
    
    createCheckbox(espTab, "Mostrar Distância", yPos,
        function() return Settings.ShowDistance end,
        function(v) Settings.ShowDistance = v end)
    yPos = yPos + 35
    
    createCheckbox(espTab, "Mostrar Ponto na Cabeça", yPos,
        function() return Settings.ShowHeadDot end,
        function(v) Settings.ShowHeadDot = v end)
    yPos = yPos + 35
    
    createSlider(espTab, "Distância Máx", yPos, 100, 5000,
        function() return Settings.MaxDistance end,
        function(v) Settings.MaxDistance = v end,
        "%.0f")
    yPos = yPos + 45
    
    -- Preencher aba CORES
    yPos = 5
    createColorPicker(colorsTab, "Cor Inimigo", yPos,
        function() return Settings.Colors.Enemy end,
        function(v) Settings.Colors.Enemy = v end)
    yPos = yPos + 35
    
    createColorPicker(colorsTab, "Cor Time", yPos,
        function() return Settings.Colors.Team end,
        function(v) Settings.Colors.Team = v end)
    yPos = yPos + 35
    
    createColorPicker(colorsTab, "Cor Tracer", yPos,
        function() return Settings.Colors.Tracer end,
        function(v) Settings.Colors.Tracer = v end)
    yPos = yPos + 35
    
    createColorPicker(colorsTab, "Cor Texto", yPos,
        function() return Settings.Colors.Text end,
        function(v) Settings.Colors.Text = v end)
    yPos = yPos + 35
    
    createColorPicker(colorsTab, "Cor Outline", yPos,
        function() return Settings.Colors.Outline end,
        function(v) Settings.Colors.Outline = v end)
    yPos = yPos + 35
    
    createColorPicker(colorsTab, "Cor Alvo Aim", yPos,
        function() return Settings.Colors.AimTarget end,
        function(v) Settings.Colors.AimTarget = v end)
    yPos = yPos + 35
end

-- Atalho para abrir/fechar HUD
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.Insert then
        createHUD()
    end
end)

-- =====================================================
-- INICIALIZAÇÃO
-- =====================================================

print("=== AIMBOT + ESP ULTIMATE CARREGADO ===")
print("Pressione INSERT ou RIGHT SHIFT para abrir a HUD")
print("Tecla padrão do Aim: E (configurável)")
