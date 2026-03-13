--[[
    ESP + AIMBOT + HUD ULTIMATE
    Recursos:
    - ESP completo (box, nome, vida, distância, tracer, head dot)
    - Aim Circle (FOV) e aimbot (opcional)
    - HUD com informações do jogador (saúde, armadura, etc.)
    - Menu de configuração interativo
    - Suporte a Drawing (Synapse, Krnl) e fallback para ScreenGui
]]

-- Configurações iniciais (podem ser alteradas pelo menu)
local Settings = {
    Enabled = true,
    TeamCheck = true,
    ShowBox = true,
    ShowName = true,
    ShowHealth = true,
    ShowDistance = true,
    ShowTracer = true,
    ShowHeadDot = true,
    ShowHUD = true,
    AimEnabled = false,
    AimCircle = true,
    AimCircleColor = Color3.fromRGB(255, 255, 255),
    AimCircleRadius = 150,
    AimSmoothness = 0.5,
    AimKey = "E",           -- Tecla para ativar aimbot (segurar)
    BoxType = "2D",
    TracerPosition = "Bottom",
    MaxDistance = 1000,
    FontSize = 13,
    Outline = true,
    Colors = {
        Enemy = Color3.fromRGB(255, 0, 0),
        Team = Color3.fromRGB(0, 255, 0),
        Tracer = Color3.fromRGB(255, 255, 255),
        Text = Color3.fromRGB(255, 255, 255),
        Outline = Color3.fromRGB(0, 0, 0),
        HUD = Color3.fromRGB(0, 150, 255)
    }
}

-- Serviços
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Mouse = LocalPlayer:GetMouse()

-- Cache
local ESPObjects = {}
local AimCircleObj = nil
local HUDElements = {}

-- Função para criar desenhos (compatível com Drawing ou ScreenGui)
local function createDrawing(type, properties)
    local obj
    if Drawing then
        obj = Drawing.new(type)
    else
        -- Fallback ScreenGui
        local gui = Instance.new("ScreenGui")
        gui.Name = "ESP_" .. tostring(math.random(1, 999999))
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        
        if type == "Square" then
            obj = Instance.new("Frame")
            obj.BackgroundColor3 = properties.Color or Color3.new(1,1,1)
            obj.BackgroundTransparency = properties.Transparency or 0
            obj.Size = UDim2.new(0, properties.Width or 2, 0, properties.Height or 2)
            obj.Position = UDim2.new(0, properties.X or 0, 0, properties.Y or 0)
            obj.BorderSizePixel = 0
            obj.Parent = gui
        elseif type == "Text" then
            obj = Instance.new("TextLabel")
            obj.Text = properties.Text or ""
            obj.TextColor3 = properties.Color or Color3.new(1,1,1)
            obj.TextStrokeTransparency = properties.Outline and 0 or 1
            obj.TextStrokeColor3 = properties.OutlineColor or Color3.new(0,0,0)
            obj.BackgroundTransparency = 1
            obj.Size = UDim2.new(0, properties.Width or 100, 0, properties.Height or 20)
            obj.Position = UDim2.new(0, properties.X or 0, 0, properties.Y or 0)
            obj.Font = Enum.Font.SourceSans
            obj.TextSize = properties.Size or 14
            obj.Parent = gui
        elseif type == "Line" then
            obj = Instance.new("Frame")
            obj.BackgroundColor3 = properties.Color or Color3.new(1,1,1)
            obj.Size = UDim2.new(0, properties.Width or 2, 0, properties.Height or 2)
            obj.Position = UDim2.new(0, properties.X or 0, 0, properties.Y or 0)
            obj.Rotation = properties.Rotation or 0
            obj.BorderSizePixel = 0
            obj.Parent = gui
        elseif type == "Circle" then
            -- Círculo via imagem ou frame arredondado
            obj = Instance.new("ImageLabel")
            obj.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
            obj.BackgroundTransparency = 1
            obj.Size = UDim2.new(0, properties.Radius*2 or 20, 0, properties.Radius*2 or 20)
            obj.Position = UDim2.new(0, properties.X - (properties.Radius or 10), 0, properties.Y - (properties.Radius or 10))
            obj.Parent = gui
            -- Infelizmente não há suporte nativo para círculo, mas podemos usar imagem
        end
    end
    
    if obj and properties then
        for k, v in pairs(properties) do
            pcall(function()
                obj[k] = v
            end)
        end
    end
    return obj
end

-- Função auxiliar para remover desenhos
local function removeDrawing(obj)
    if obj then
        pcall(function()
            if obj.Remove then
                obj:Remove()
            elseif obj.Destroy then
                obj:Destroy()
            end
        end)
    end
end

-- Função para obter cor baseada no time
local function getPlayerColor(player)
    if Settings.TeamCheck and player.Team and LocalPlayer.Team then
        if player.Team == LocalPlayer.Team then
            return Settings.Colors.Team
        end
    end
    return Settings.Colors.Enemy
end

-- Função para calcular distância
local function getDistance(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return math.huge
    end
    local root = player.Character.HumanoidRootPart
    return (Camera.CFrame.Position - root.Position).Magnitude
end

-- Função para verificar se o jogador é válido
local function isValidPlayer(player)
    if player == LocalPlayer then return false end
    if not player.Character then return false end
    local humanoid = player.Character:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    return true
end

-- Desenhar ESP para um jogador
local function drawESP(player, dist)
    if not isValidPlayer(player) then return end
    
    local color = getPlayerColor(player)
    local char = player.Character
    local humanoid = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then return end
    
    -- Inicializar ou limpar objetos antigos
    if not ESPObjects[player] then
        ESPObjects[player] = {}
    else
        for _, obj in pairs(ESPObjects[player]) do
            removeDrawing(obj)
        end
    end
    local objects = {}
    ESPObjects[player] = objects
    
    -- Posição e tamanho da caixa
    local size = humanoid.HipHeight * 2 + 3
    local topPos = root.Position + Vector3.new(0, size, 0)
    local bottomPos = root.Position - Vector3.new(0, size, 0)
    
    local top, visible = Camera:WorldToViewportPoint(topPos)
    local bottom = Camera:WorldToViewportPoint(bottomPos)
    
    if not visible then return end
    
    local width = (bottom.Y - top.Y) * 0.5
    local height = bottom.Y - top.Y
    local boxX = top.X - width * 0.5
    local boxY = top.Y
    
    -- Box
    if Settings.ShowBox then
        objects.Box = createDrawing("Square", {
            Color = color,
            Transparency = 0.7,
            Thickness = 2,
            Filled = false,
            Visible = true,
            ZIndex = 2,
            Size = Vector2.new(width, height),
            Position = Vector2.new(boxX, boxY)
        })
        if Settings.Outline then
            objects.BoxOutline = createDrawing("Square", {
                Color = Settings.Colors.Outline,
                Transparency = 0.5,
                Thickness = 1,
                Filled = false,
                Visible = true,
                ZIndex = 1,
                Size = Vector2.new(width + 2, height + 2),
                Position = Vector2.new(boxX - 1, boxY - 1)
            })
        end
    end
    
    -- Health Bar
    if Settings.ShowHealth then
        local healthPercent = humanoid.Health / humanoid.MaxHealth
        objects.HealthBg = createDrawing("Square", {
            Color = Color3.fromRGB(50, 50, 50),
            Transparency = 0.8,
            Filled = true,
            Visible = true,
            ZIndex = 3,
            Size = Vector2.new(5, height),
            Position = Vector2.new(boxX - 7, boxY)
        })
        objects.HealthBar = createDrawing("Square", {
            Color = Color3.fromRGB(255 - 255 * healthPercent, 255 * healthPercent, 0),
            Transparency = 0.2,
            Filled = true,
            Visible = true,
            ZIndex = 4,
            Size = Vector2.new(5, height * healthPercent),
            Position = Vector2.new(boxX - 7, boxY + (height - height * healthPercent))
        })
    end
    
    -- Name
    if Settings.ShowName then
        objects.Name = createDrawing("Text", {
            Text = player.Name,
            Color = Settings.Colors.Text,
            Outline = Settings.Outline,
            OutlineColor = Settings.Colors.Outline,
            Size = Settings.FontSize,
            Center = true,
            Position = Vector2.new(boxX + width/2, boxY - 20),
            Visible = true,
            ZIndex = 5
        })
        if Settings.ShowDistance then
            objects.Distance = createDrawing("Text", {
                Text = string.format("[%.0fm]", dist),
                Color = Settings.Colors.Text,
                Outline = Settings.Outline,
                OutlineColor = Settings.Colors.Outline,
                Size = Settings.FontSize - 2,
                Center = true,
                Position = Vector2.new(boxX + width/2, boxY - 35),
                Visible = true,
                ZIndex = 5
            })
        end
    end
    
    -- Tracer
    if Settings.ShowTracer then
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2,
            Settings.TracerPosition == "Bottom" and Camera.ViewportSize.Y or
            Settings.TracerPosition == "Top" and 0 or
            Camera.ViewportSize.Y / 2)
        objects.Tracer = createDrawing("Line", {
            Color = Settings.Colors.Tracer,
            Thickness = 2,
            Transparency = 0.8,
            Visible = true,
            From = screenCenter,
            To = Vector2.new(top.X, top.Y),
            ZIndex = 3
        })
    end
    
    -- Head Dot
    if Settings.ShowHeadDot then
        local head = char:FindFirstChild("Head")
        if head then
            local headPos, headVis = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
            if headVis then
                objects.HeadDot = createDrawing("Circle", {
                    Color = color,
                    Thickness = 2,
                    Filled = true,
                    Radius = 4,
                    NumSides = 12,
                    Position = Vector2.new(headPos.X, headPos.Y),
                    Visible = true,
                    ZIndex = 6
                })
            end
        end
    end
end

-- Função para desenhar o círculo do aimbot
local function drawAimCircle()
    if not Settings.AimCircle then
        if AimCircleObj then
            removeDrawing(AimCircleObj)
            AimCircleObj = nil
        end
        return
    end
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    if not AimCircleObj then
        AimCircleObj = createDrawing("Circle", {
            Color = Settings.AimCircleColor,
            Thickness = 2,
            Filled = false,
            Radius = Settings.AimCircleRadius,
            NumSides = 60,
            Position = center,
            Visible = true,
            ZIndex = 10
        })
    else
        AimCircleObj.Color = Settings.AimCircleColor
        AimCircleObj.Radius = Settings.AimCircleRadius
        AimCircleObj.Position = center
        AimCircleObj.Visible = true
    end
end

-- Função para encontrar o alvo mais próximo dentro do círculo
local function getClosestTarget()
    local closest = nil
    local closestDist = math.huge
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if isValidPlayer(player) then
            local root = player.Character.HumanoidRootPart
            local pos, visible = Camera:WorldToViewportPoint(root.Position)
            if visible then
                local screenPos = Vector2.new(pos.X, pos.Y)
                local dist = (screenPos - center).Magnitude
                if dist < Settings.AimCircleRadius and dist < closestDist then
                    closest = player
                    closestDist = dist
                end
            end
        end
    end
    return closest
end

-- Função do aimbot (mira suave)
local function doAimbot(target)
    if not target or not target.Character then return end
    local root = target.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local targetPos = root.Position
    local cameraPos = Camera.CFrame.Position
    local direction = (targetPos - cameraPos).Unit
    local newCFrame = CFrame.lookAt(cameraPos, cameraPos + direction)
    
    -- Suavização
    local currentCF = Camera.CFrame
    local smoothCF = currentCF:Lerp(newCFrame, Settings.AimSmoothness)
    Camera.CFrame = smoothCF
end

-- HUD com informações do jogador
local function drawHUD()
    if not Settings.ShowHUD then
        if HUDElements.Container then
            for _, obj in pairs(HUDElements) do
                removeDrawing(obj)
            end
            HUDElements = {}
        end
        return
    end
    
    -- Se não existir, criar elementos
    if not HUDElements.Container then
        local x, y = 10, 10
        local bg = createDrawing("Square", {
            Color = Color3.fromRGB(0, 0, 0),
            Transparency = 0.5,
            Filled = true,
            Size = Vector2.new(200, 100),
            Position = Vector2.new(x, y),
            ZIndex = 100
        })
        HUDElements.Container = bg
        
        HUDElements.Title = createDrawing("Text", {
            Text = "ESP ULTIMATE",
            Color = Settings.Colors.HUD,
            Size = 16,
            Outline = true,
            OutlineColor = Color3.new(0,0,0),
            Position = Vector2.new(x + 10, y + 5),
            ZIndex = 101
        })
        
        HUDElements.Status = createDrawing("Text", {
            Text = "Status: " .. (Settings.Enabled and "ON" or "OFF"),
            Color = Settings.Enabled and Color3.new(0,1,0) or Color3.new(1,0,0),
            Size = 14,
            Position = Vector2.new(x + 10, y + 25),
            ZIndex = 101
        })
        
        HUDElements.Players = createDrawing("Text", {
            Text = "Players: " .. #Players:GetPlayers(),
            Color = Color3.new(1,1,1),
            Size = 14,
            Position = Vector2.new(x + 10, y + 45),
            ZIndex = 101
        })
        
        HUDElements.Aimbot = createDrawing("Text", {
            Text = "Aimbot: " .. (Settings.AimEnabled and "ON" or "OFF"),
            Color = Settings.AimEnabled and Color3.new(0,1,0) or Color3.new(1,0,0),
            Size = 14,
            Position = Vector2.new(x + 10, y + 65),
            ZIndex = 101
        })
        
        HUDElements.FPS = createDrawing("Text", {
            Text = "FPS: 60",
            Color = Color3.new(1,1,1),
            Size = 14,
            Position = Vector2.new(x + 10, y + 85),
            ZIndex = 101
        })
    else
        -- Atualizar textos
        HUDElements.Status.Text = "Status: " .. (Settings.Enabled and "ON" or "OFF")
        HUDElements.Status.Color = Settings.Enabled and Color3.new(0,1,0) or Color3.new(1,0,0)
        HUDElements.Players.Text = "Players: " .. #Players:GetPlayers()
        HUDElements.Aimbot.Text = "Aimbot: " .. (Settings.AimEnabled and "ON" or "OFF")
        HUDElements.Aimbot.Color = Settings.AimEnabled and Color3.new(0,1,0) or Color3.new(1,0,0)
        HUDElements.FPS.Text = string.format("FPS: %.0f", 1 / RunService.RenderStepped:Wait())
    end
end

-- Loop principal de renderização
RunService.RenderStepped:Connect(function()
    if not Settings.Enabled then
        -- Limpar todos os ESP
        for player, objects in pairs(ESPObjects) do
            for _, obj in pairs(objects) do
                removeDrawing(obj)
            end
        end
        ESPObjects = {}
        if AimCircleObj then
            removeDrawing(AimCircleObj)
            AimCircleObj = nil
        end
        drawHUD()
        return
    end
    
    -- Desenhar círculo do aimbot
    drawAimCircle()
    
    -- ESP para cada jogador
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local dist = getDistance(player)
            if dist < Settings.MaxDistance then
                drawESP(player, dist)
            else
                -- Remover ESP se existir
                if ESPObjects[player] then
                    for _, obj in pairs(ESPObjects[player]) do
                        removeDrawing(obj)
                    end
                    ESPObjects[player] = nil
                end
            end
        end
    end
    
    -- Aimbot (se ativado e tecla pressionada)
    if Settings.AimEnabled and UserInputService:IsKeyDown(Enum.KeyCode[Settings.AimKey]) then
        local target = getClosestTarget()
        doAimbot(target)
    end
    
    -- Atualizar HUD
    drawHUD()
end)

-- Menu de configuração (GUI)
local function createMenu()
    local menuOpen = false
    local menuGui
    
    local function toggleMenu()
        if menuOpen then
            if menuGui then
                menuGui:Destroy()
                menuGui = nil
            end
            menuOpen = false
        else
            menuGui = Instance.new("ScreenGui")
            menuGui.Name = "ESPMenu"
            menuGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
            
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(0, 400, 0, 500)
            frame.Position = UDim2.new(0.5, -200, 0.5, -250)
            frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            frame.BackgroundTransparency = 0.2
            frame.BorderSizePixel = 0
            frame.Active = true
            frame.Draggable = true
            frame.Parent = menuGui
            
            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, 0, 0, 30)
            title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            title.Text = "ESP ULTIMATE - CONFIGURAÇÃO"
            title.TextColor3 = Color3.fromRGB(255, 255, 255)
            title.Font = Enum.Font.SourceSansBold
            title.TextSize = 18
            title.Parent = frame
            
            local yOffset = 40
            
            -- Função para criar checkbox
            local function createCheckbox(name, setting, y)
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, -20, 0, 30)
                btn.Position = UDim2.new(0, 10, 0, y)
                btn.BackgroundColor3 = Settings[setting] and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                btn.Text = name .. ": " .. tostring(Settings[setting])
                btn.TextColor3 = Color3.fromRGB(255, 255, 255)
                btn.Parent = frame
                btn.MouseButton1Click:Connect(function()
                    Settings[setting] = not Settings[setting]
                    btn.BackgroundColor3 = Settings[setting] and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                    btn.Text = name .. ": " .. tostring(Settings[setting])
                end)
            end
            
            createCheckbox("Enabled", "Enabled", yOffset); yOffset = yOffset + 35
            createCheckbox("Team Check", "TeamCheck", yOffset); yOffset = yOffset + 35
            createCheckbox("Show Box", "ShowBox", yOffset); yOffset = yOffset + 35
            createCheckbox("Show Name", "ShowName", yOffset); yOffset = yOffset + 35
            createCheckbox("Show Health", "ShowHealth", yOffset); yOffset = yOffset + 35
            createCheckbox("Show Distance", "ShowDistance", yOffset); yOffset = yOffset + 35
            createCheckbox("Show Tracer", "ShowTracer", yOffset); yOffset = yOffset + 35
            createCheckbox("Show Head Dot", "ShowHeadDot", yOffset); yOffset = yOffset + 35
            createCheckbox("Show HUD", "ShowHUD", yOffset); yOffset = yOffset + 35
            createCheckbox("Aimbot Enabled", "AimEnabled", yOffset); yOffset = yOffset + 35
            createCheckbox("Aim Circle", "AimCircle", yOffset); yOffset = yOffset + 35
            
            -- Slider para raio do círculo
            local radiusLabel = Instance.new("TextLabel")
            radiusLabel.Size = UDim2.new(0.5, -10, 0, 30)
            radiusLabel.Position = UDim2.new(0, 10, 0, yOffset)
            radiusLabel.BackgroundTransparency = 1
            radiusLabel.Text = "Circle Radius: " .. Settings.AimCircleRadius
            radiusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            radiusLabel.Parent = frame
            
            local radiusSlider = Instance.new("TextBox")
            radiusSlider.Size = UDim2.new(0.3, 0, 0, 30)
            radiusSlider.Position = UDim2.new(0.6, 0, 0, yOffset)
            radiusSlider.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            radiusSlider.Text = tostring(Settings.AimCircleRadius)
            radiusSlider.TextColor3 = Color3.fromRGB(255, 255, 255)
            radiusSlider.Parent = frame
            radiusSlider.FocusLost:Connect(function()
                local val = tonumber(radiusSlider.Text)
                if val and val > 0 then
                    Settings.AimCircleRadius = val
                    radiusLabel.Text = "Circle Radius: " .. val
                end
            end)
            yOffset = yOffset + 35
            
            -- Tecla do aimbot
            local keyLabel = Instance.new("TextLabel")
            keyLabel.Size = UDim2.new(0.5, -10, 0, 30)
            keyLabel.Position = UDim2.new(0, 10, 0, yOffset)
            keyLabel.BackgroundTransparency = 1
            keyLabel.Text = "Aimbot Key: " .. Settings.AimKey
            keyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            keyLabel.Parent = frame
            
            local keyBox = Instance.new("TextBox")
            keyBox.Size = UDim2.new(0.3, 0, 0, 30)
            keyBox.Position = UDim2.new(0.6, 0, 0, yOffset)
            keyBox.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            keyBox.Text = Settings.AimKey
            keyBox.TextColor3 = Color3.fromRGB(255, 255, 255)
            keyBox.Parent = frame
            keyBox.FocusLost:Connect(function()
                local key = keyBox.Text:upper()
                if #key == 1 and key:match("%a") then
                    Settings.AimKey = key
                    keyLabel.Text = "Aimbot Key: " .. key
                end
            end)
            yOffset = yOffset + 35
            
            -- Botão fechar
            local closeBtn = Instance.new("TextButton")
            closeBtn.Size = UDim2.new(0, 100, 0, 30)
            closeBtn.Position = UDim2.new(0.5, -50, 1, -40)
            closeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            closeBtn.Text = "Fechar"
            closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            closeBtn.Parent = frame
            closeBtn.MouseButton1Click:Connect(function()
                toggleMenu()
            end)
            
            menuOpen = true
        end
    end
    
    -- Atalho: Insert para abrir/fechar menu
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Insert then
            toggleMenu()
        end
    end)
    
    print("Pressione INSERT para abrir o menu de configuração.")
end

-- Iniciar menu
createMenu()
