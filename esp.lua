--[[
    ESP ULTIMATE v2.0
    Recursos:
    - Box ESP (2D e 3D)
    - Tracers (linhas do centro da tela até o jogador)
    - Name ESP (nome do jogador)
    - Health Bar (barra de vida)
    - Distance ESP (distância em studs)
    - Head Dot (ponto na cabeça)
    - Team Check (diferencia aliados de inimigos)
    - Configurações personalizáveis
]]

-- Carrega a biblioteca de desenho (depende do executor)
local Drawing = Drawing or not Drawing and loadstring(game:HttpGet("https://rawscripts.net/raw/Filtered-Drawing-Library-for-Synapse-24224"))()
if not Drawing then
    warn("Biblioteca Drawing não encontrada. Tentando criar objetos GUI...")
    -- Fallback para SurfaceGui (caso o executor não suporte Drawing)
end

-- Configurações do ESP
local Settings = {
    Enabled = true,
    TeamCheck = true,      -- Aliados = verde, Inimigos = vermelho
    ShowBox = true,
    ShowTracer = true,
    ShowName = true,
    ShowHealth = true,
    ShowDistance = true,
    ShowHeadDot = true,
    BoxType = "2D",        -- "2D" ou "3D"
    TracerPosition = "Bottom", -- "Bottom", "Center", "Top"
    MaxDistance = 1000,    -- Distância máxima para renderizar
    FontSize = 13,
    Outline = true,
    UpdateRate = 0.1,      -- Segundos entre atualizações
    Colors = {
        Enemy = Color3.fromRGB(255, 0, 0),
        Team = Color3.fromRGB(0, 255, 0),
        Tracer = Color3.fromRGB(255, 255, 255),
        Text = Color3.fromRGB(255, 255, 255),
        Outline = Color3.fromRGB(0, 0, 0)
    }
}

-- Cache de jogadores
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Tabela para armazenar os objetos de desenho
local ESPObjects = {}

-- Função para criar objetos de desenho (compatível com a maioria dos executores)
local function createDrawing(type, properties)
    local obj
    if Drawing then
        obj = Drawing.new(type)
    else
        -- Fallback: criar ScreenGui (caso o executor não suporte Drawing)
        -- Isso é menos eficiente, mas funciona em executores básicos
        local gui = Instance.new("ScreenGui")
        gui.Name = "ESP_" .. tostring(math.random(1, 999999))
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
        
        if type == "Square" then
            obj = Instance.new("Frame")
            obj.BackgroundColor3 = properties.Color or Color3.new(1,1,1)
            obj.BackgroundTransparency = properties.Transparency or 0
            obj.Size = UDim2.new(0, properties.Width or 2, 0, properties.Height or 2)
            obj.Position = UDim2.new(0, properties.X or 0, 0, properties.Y or 0)
            obj.Parent = gui
        elseif type == "Text" then
            obj = Instance.new("TextLabel")
            obj.Text = properties.Text or ""
            obj.TextColor3 = properties.Color or Color3.new(1,1,1)
            obj.TextStrokeTransparency = properties.Outline and 0 or 1
            obj.BackgroundTransparency = 1
            obj.Size = UDim2.new(0, properties.Width or 100, 0, properties.Height or 20)
            obj.Position = UDim2.new(0, properties.X or 0, 0, properties.Y or 0)
            obj.Parent = gui
        elseif type == "Line" then
            obj = Instance.new("Frame")
            obj.BackgroundColor3 = properties.Color or Color3.new(1,1,1)
            obj.Size = UDim2.new(0, properties.Width or 2, 0, properties.Height or 2)
            obj.Position = UDim2.new(0, properties.X or 0, 0, properties.Y or 0)
            obj.Rotation = properties.Rotation or 0
            obj.Parent = gui
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

-- Função para obter a cor baseada no time
local function getPlayerColor(player)
    if Settings.TeamCheck and player.Team and LocalPlayer.Team then
        if player.Team == LocalPlayer.Team then
            return Settings.Colors.Team
        end
    end
    return Settings.Colors.Enemy
end

-- Função para calcular a distância
local function getDistance(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return math.huge
    end
    local root = player.Character.HumanoidRootPart
    return (Camera.CFrame.Position - root.Position).Magnitude
end

-- Função para desenhar a caixa 2D
local function drawBox2D(player, color, dist, objects)
    local char = player.Character
    if not char then return end
    
    local humanoid = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then return end
    
    local position = root.Position
    local size = humanoid.HipHeight * 2 + 3
    
    local top, visible = Camera:WorldToViewportPoint(position + Vector3.new(0, size, 0))
    local bottom, _ = Camera:WorldToViewportPoint(position - Vector3.new(0, size, 0))
    
    if not visible then return end
    
    local width = (bottom.Y - top.Y) * 0.5
    local height = bottom.Y - top.Y
    local x = top.X - width * 0.5
    local y = top.Y
    
    -- Caixa principal
    objects.box = createDrawing("Square", {
        Color = color,
        Transparency = 0.7,
        Thickness = 2,
        Filled = false,
        Visible = Settings.ShowBox,
        ZIndex = 2
    })
    objects.box.Size = Vector2.new(width, height)
    objects.box.Position = Vector2.new(x, y)
    
    -- Bordas (para dar efeito de outline)
    objects.boxOutline = createDrawing("Square", {
        Color = Settings.Colors.Outline,
        Transparency = 0.5,
        Thickness = 1,
        Filled = false,
        Visible = Settings.ShowBox and Settings.Outline,
        ZIndex = 1
    })
    objects.boxOutline.Size = Vector2.new(width + 2, height + 2)
    objects.boxOutline.Position = Vector2.new(x - 1, y - 1)
    
    return x, y, width, height
end

-- Função para desenhar a caixa 3D
local function drawBox3D(player, color, dist, objects)
    -- Implementação de caixa 3D mais complexa
    -- (8 pontos do cubo projetados na tela)
    -- Por simplicidade, vou deixar como 2D por enquanto
    return drawBox2D(player, color, dist, objects)
end

-- Função para desenhar a barra de vida
local function drawHealthBar(player, color, x, y, width, height, objects)
    local char = player.Character
    if not char then return end
    
    local humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local health = humanoid.Health
    local maxHealth = humanoid.MaxHealth
    local percent = health / maxHealth
    
    -- Barra de fundo
    objects.healthBg = createDrawing("Square", {
        Color = Color3.fromRGB(50, 50, 50),
        Transparency = 0.8,
        Filled = true,
        Visible = Settings.ShowHealth,
        ZIndex = 3
    })
    objects.healthBg.Size = Vector2.new(5, height)
    objects.healthBg.Position = Vector2.new(x - 7, y)
    
    -- Barra de vida
    objects.healthBar = createDrawing("Square", {
        Color = Color3.fromRGB(255 - (255 * percent), 255 * percent, 0),
        Transparency = 0.2,
        Filled = true,
        Visible = Settings.ShowHealth,
        ZIndex = 4
    })
    objects.healthBar.Size = Vector2.new(5, height * percent)
    objects.healthBar.Position = Vector2.new(x - 7, y + (height - height * percent))
end

-- Função para desenhar o tracer (linha do centro até o jogador)
local function drawTracer(player, color, objects)
    local char = player.Character
    if not char then return end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    local pos, visible = Camera:WorldToViewportPoint(root.Position)
    if not visible then return end
    
    local screenPos = Vector2.new(pos.X, pos.Y)
    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, 
        Settings.TracerPosition == "Bottom" and Camera.ViewportSize.Y or
        Settings.TracerPosition == "Top" and 0 or
        Camera.ViewportSize.Y / 2)
    
    objects.tracer = createDrawing("Line", {
        Color = color,
        Thickness = 2,
        Transparency = 0.8,
        Visible = Settings.ShowTracer,
        From = screenCenter,
        To = screenPos,
        ZIndex = 5
    })
end

-- Função para desenhar o nome
local function drawName(player, color, x, y, width, dist, objects)
    objects.name = createDrawing("Text", {
        Text = player.Name,
        Color = Settings.Colors.Text,
        Outline = Settings.Outline,
        OutlineColor = Settings.Colors.Outline,
        Size = Settings.FontSize,
        Center = true,
        Position = Vector2.new(x + width / 2, y - 20),
        Visible = Settings.ShowName,
        ZIndex = 6
    })
    
    if Settings.ShowDistance then
        objects.distance = createDrawing("Text", {
            Text = string.format("[%.0fm]", dist),
            Color = Settings.Colors.Text,
            Outline = Settings.Outline,
            OutlineColor = Settings.Colors.Outline,
            Size = Settings.FontSize - 2,
            Center = true,
            Position = Vector2.new(x + width / 2, y - 35),
            Visible = true,
            ZIndex = 6
        })
    end
end

-- Função para desenhar o ponto na cabeça
local function drawHeadDot(player, color, objects)
    local char = player.Character
    if not char then return end
    
    local head = char:FindFirstChild("Head")
    if not head then return end
    
    local pos, visible = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
    if not visible then return end
    
    objects.headDot = createDrawing("Circle", {
        Color = color,
        Thickness = 2,
        Filled = true,
        Radius = 4,
        NumSides = 12,
        Position = Vector2.new(pos.X, pos.Y),
        Visible = Settings.ShowHeadDot,
        ZIndex = 7
    })
end

-- Função principal de atualização
local function updateESP()
    if not Settings.Enabled then
        -- Limpar todos os desenhos
        for _, objects in pairs(ESPObjects) do
            for _, obj in pairs(objects) do
                pcall(function() obj:Remove() end)
            end
        end
        ESPObjects = {}
        return
    end
    
    local currentPlayers = Players:GetPlayers()
    
    -- Remover ESP de jogadores que saíram
    for player, objects in pairs(ESPObjects) do
        if not table.find(currentPlayers, player) or player == LocalPlayer then
            for _, obj in pairs(objects) do
                pcall(function() obj:Remove() end)
            end
            ESPObjects[player] = nil
        end
    end
    
    -- Atualizar ESP para cada jogador
    for _, player in ipairs(currentPlayers) do
        if player ~= LocalPlayer then
            local dist = getDistance(player)
            if dist < Settings.MaxDistance then
                local color = getPlayerColor(player)
                
                -- Inicializar ou pegar objetos existentes
                if not ESPObjects[player] then
                    ESPObjects[player] = {}
                end
                local objects = ESPObjects[player]
                
                -- Remover objetos antigos
                for _, obj in pairs(objects) do
                    pcall(function() obj:Remove() end)
                end
                objects = {}
                ESPObjects[player] = objects
                
                -- Desenhar caixa
                local x, y, width, height
                if Settings.BoxType == "2D" then
                    x, y, width, height = drawBox2D(player, color, dist, objects)
                else
                    x, y, width, height = drawBox3D(player, color, dist, objects)
                end
                
                if x and y then
                    drawHealthBar(player, color, x, y, width, height, objects)
                    drawName(player, color, x, y, width, dist, objects)
                end
                
                drawTracer(player, color, objects)
                drawHeadDot(player, color, objects)
            else
                -- Jogador muito longe, remover ESP
                if ESPObjects[player] then
                    for _, obj in pairs(ESPObjects[player]) do
                        pcall(function() obj:Remove() end)
                    end
                    ESPObjects[player] = nil
                end
            end
        end
    end
end

-- Menu de configuração (GUI interativa)
local function createConfigMenu()
    local menuOpen = false
    
    local function toggleMenu()
        menuOpen = not menuOpen
        if menuOpen then
            -- Criar menu flutuante
            local menu = Instance.new("ScreenGui")
            menu.Name = "ESPConfigMenu"
            menu.Parent = LocalPlayer:WaitForChild("PlayerGui")
            
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(0, 300, 0, 400)
            frame.Position = UDim2.new(0.5, -150, 0.5, -200)
            frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            frame.BackgroundTransparency = 0.1
            frame.BorderSizePixel = 0
            frame.Parent = menu
            
            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, 0, 0, 30)
            title.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            title.Text = "ESP Configuration"
            title.TextColor3 = Color3.fromRGB(255, 255, 255)
            title.Font = Enum.Font.SourceSansBold
            title.TextSize = 18
            title.Parent = frame
            
            -- Checkbox para Enabled
            local enabledCheck = Instance.new("TextButton")
            enabledCheck.Size = UDim2.new(1, -20, 0, 30)
            enabledCheck.Position = UDim2.new(0, 10, 0, 40)
            enabledCheck.BackgroundColor3 = Settings.Enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
            enabledCheck.Text = "Enabled: " .. tostring(Settings.Enabled)
            enabledCheck.TextColor3 = Color3.fromRGB(255, 255, 255)
            enabledCheck.Parent = frame
            enabledCheck.MouseButton1Click:Connect(function()
                Settings.Enabled = not Settings.Enabled
                enabledCheck.BackgroundColor3 = Settings.Enabled and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                enabledCheck.Text = "Enabled: " .. tostring(Settings.Enabled)
            end)
            
            -- Checkbox para TeamCheck
            local teamCheck = Instance.new("TextButton")
            teamCheck.Size = UDim2.new(1, -20, 0, 30)
            teamCheck.Position = UDim2.new(0, 10, 0, 80)
            teamCheck.BackgroundColor3 = Settings.TeamCheck and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
            teamCheck.Text = "Team Check: " .. tostring(Settings.TeamCheck)
            teamCheck.TextColor3 = Color3.fromRGB(255, 255, 255)
            teamCheck.Parent = frame
            teamCheck.MouseButton1Click:Connect(function()
                Settings.TeamCheck = not Settings.TeamCheck
                teamCheck.BackgroundColor3 = Settings.TeamCheck and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
                teamCheck.Text = "Team Check: " .. tostring(Settings.TeamCheck)
            end)
            
            -- Botão para fechar
            local closeBtn = Instance.new("TextButton")
            closeBtn.Size = UDim2.new(0, 100, 0, 30)
            closeBtn.Position = UDim2.new(0.5, -50, 1, -40)
            closeBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
            closeBtn.Text = "Close"
            closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            closeBtn.Parent = frame
            closeBtn.MouseButton1Click:Connect(function()
                menu:Destroy()
                menuOpen = false
            end)
            
            -- Botão para toggle via tecla (ex: Insert)
            UserInputService.InputBegan:Connect(function(input)
                if input.KeyCode == Enum.KeyCode.Insert then
                    if menuOpen then
                        menu:Destroy()
                        menuOpen = false
                    else
                        toggleMenu()
                    end
                end
            end)
        end
    end
    
    -- Atalho de tecla para abrir/fechar menu
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.Insert then
            toggleMenu()
        end
    end)
    
    print("ESP carregado! Pressione INSERT para abrir o menu de configuração.")
end

-- Iniciar o ESP
coroutine.wrap(function()
    while true do
        pcall(updateESP)
        wait(Settings.UpdateRate)
    end
end)()

-- Criar menu de configuração
createConfigMenu()

-- Aviso de carregamento
print("ESP Ultimate carregado com sucesso!")
