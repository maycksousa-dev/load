-- ============================================
-- AUTO-DUMPER SUPREMO - GUI EDITION
-- By: Seu Amigo (com ScrollingFrame)
-- ============================================

-- Services
local players = game:GetService("Players")
local tweenService = game:GetService("TweenService")
local userInputService = game:GetService("UserInputService")
local teleportService = game:GetService("TeleportService")
local coreGui = game:GetService("CoreGui")

-- Verificar se já existe pra não duplicar
if game:GetService("CoreGui"):FindFirstChild("DumperGUI") then
    game:GetService("CoreGui").DumperGUI:Destroy()
end

-- ============================================
-- CRIANDO A GUI PRINCIPAL
-- ============================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DumperGUI"
screenGui.Parent = coreGui
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- ============================================
-- MAIN FRAME (JANELA PRINCIPAL)
-- ============================================
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Parent = screenGui
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
mainFrame.Size = UDim2.new(0, 700, 0, 500)
mainFrame.Active = true
mainFrame.Draggable = true
mainFrame.ClipsDescendants = true

-- Arredondar cantos
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = mainFrame

-- Sombra
local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.Parent = mainFrame
shadow.BackgroundTransparency = 1
shadow.Position = UDim2.new(0, -10, 0, -10)
shadow.Size = UDim2.new(1, 20, 1, 20)
shadow.Image = "rbxassetid://6015897843"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.5
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10, 10, 118, 118)

-- ============================================
-- TOP BAR (BARRA DE TÍTULO)
-- ============================================
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Parent = mainFrame
topBar.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
topBar.BackgroundTransparency = 0.1
topBar.BorderSizePixel = 0
topBar.Size = UDim2.new(1, 0, 0, 40)

local topBarCorner = Instance.new("UICorner")
topBarCorner.CornerRadius = UDim.new(0, 10)
topBarCorner.Parent = topBar

-- Título
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Parent = topBar
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 15, 0, 0)
title.Text = "🔍 AUTO-DUMPER SUPREMO - ScrollingFrame Edition"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Font = Enum.Font.GothamBold
title.TextSize = 16

-- Botão fechar
local closeBtn = Instance.new("ImageButton")
closeBtn.Name = "CloseBtn"
closeBtn.Parent = topBar
closeBtn.BackgroundTransparency = 1
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0.5, -15)
closeBtn.Image = "rbxassetid://6031094678"
closeBtn.ImageColor3 = Color3.fromRGB(255, 100, 100)

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- ============================================
-- LEFT PANEL (CONTROLES)
-- ============================================
local leftPanel = Instance.new("Frame")
leftPanel.Name = "LeftPanel"
leftPanel.Parent = mainFrame
leftPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
leftPanel.BackgroundTransparency = 0.1
leftPanel.BorderSizePixel = 0
leftPanel.Position = UDim2.new(0, 10, 0, 50)
leftPanel.Size = UDim2.new(0, 200, 1, -60)

local leftCorner = Instance.new("UICorner")
leftCorner.CornerRadius = UDim.new(0, 8)
leftCorner.Parent = leftPanel

-- Título do painel esquerdo
local leftTitle = Instance.new("TextLabel")
leftTitle.Name = "LeftTitle"
leftTitle.Parent = leftPanel
leftTitle.BackgroundTransparency = 1
leftTitle.Size = UDim2.new(1, 0, 0, 35)
leftTitle.Text = "⚙️ CONTROLES"
leftTitle.TextColor3 = Color3.fromRGB(200, 200, 255)
leftTitle.Font = Enum.Font.GothamBold
leftTitle.TextSize = 14

-- Separador
local separator1 = Instance.new("Frame")
separator1.Name = "Separator1"
separator1.Parent = leftPanel
separator1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
separator1.BackgroundTransparency = 0.9
separator1.BorderSizePixel = 0
separator1.Position = UDim2.new(0, 10, 0, 35)
separator1.Size = UDim2.new(1, -20, 0, 1)

-- Informações
local infoFrame = Instance.new("Frame")
infoFrame.Name = "InfoFrame"
infoFrame.Parent = leftPanel
infoFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
infoFrame.BackgroundTransparency = 0.3
infoFrame.BorderSizePixel = 0
infoFrame.Position = UDim2.new(0, 10, 0, 45)
infoFrame.Size = UDim2.new(1, -20, 0, 80)

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 5)
infoCorner.Parent = infoFrame

local robloxBaseLabel = Instance.new("TextLabel")
robloxBaseLabel.Name = "RobloxBaseLabel"
robloxBaseLabel.Parent = infoFrame
robloxBaseLabel.BackgroundTransparency = 1
robloxBaseLabel.Size = UDim2.new(1, -10, 0, 20)
robloxBaseLabel.Position = UDim2.new(0, 5, 0, 5)
robloxBaseLabel.Text = "Base: Escaneando..."
robloxBaseLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
robloxBaseLabel.TextXAlignment = Enum.TextXAlignment.Left
robloxBaseLabel.Font = Enum.Font.Code
robloxBaseLabel.TextSize = 12

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "StatusLabel"
statusLabel.Parent = infoFrame
statusLabel.BackgroundTransparency = 1
statusLabel.Size = UDim2.new(1, -10, 0, 20)
statusLabel.Position = UDim2.new(0, 5, 0, 30)
statusLabel.Text = "Status: Pronto"
statusLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 12

local countLabel = Instance.new("TextLabel")
countLabel.Name = "CountLabel"
countLabel.Parent = infoFrame
countLabel.BackgroundTransparency = 1
countLabel.Size = UDim2.new(1, -10, 0, 20)
countLabel.Position = UDim2.new(0, 5, 0, 55)
countLabel.Text = "Offsets: 0"
countLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
countLabel.TextXAlignment = Enum.TextXAlignment.Left
countLabel.Font = Enum.Font.Gotham
countLabel.TextSize = 12

-- Botões de ação
local startBtn = Instance.new("ImageButton")
startBtn.Name = "StartBtn"
startBtn.Parent = leftPanel
startBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
startBtn.BorderSizePixel = 0
startBtn.Position = UDim2.new(0, 10, 0, 140)
startBtn.Size = UDim2.new(1, -20, 0, 40)

local startCorner = Instance.new("UICorner")
startCorner.CornerRadius = UDim.new(0, 5)
startCorner.Parent = startBtn

local startIcon = Instance.new("ImageLabel")
startIcon.Name = "StartIcon"
startIcon.Parent = startBtn
startIcon.BackgroundTransparency = 1
startIcon.Size = UDim2.new(0, 25, 0, 25)
startIcon.Position = UDim2.new(0, 5, 0.5, -12)
startIcon.Image = "rbxassetid://6023426926"
startIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)

local startText = Instance.new("TextLabel")
startText.Name = "StartText"
startText.Parent = startBtn
startText.BackgroundTransparency = 1
startText.Size = UDim2.new(1, 0, 1, 0)
startText.Text = "▶ INICIAR DUMP"
startText.TextColor3 = Color3.fromRGB(255, 255, 255)
startText.Font = Enum.Font.GothamBold
startText.TextSize = 14

local saveBtn = Instance.new("ImageButton")
saveBtn.Name = "SaveBtn"
saveBtn.Parent = leftPanel
saveBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 150)
saveBtn.BorderSizePixel = 0
saveBtn.Position = UDim2.new(0, 10, 0, 190)
saveBtn.Size = UDim2.new(1, -20, 0, 40)

local saveCorner = Instance.new("UICorner")
saveCorner.CornerRadius = UDim.new(0, 5)
saveCorner.Parent = saveBtn

local saveIcon = Instance.new("ImageLabel")
saveIcon.Name = "SaveIcon"
saveIcon.Parent = saveBtn
saveIcon.BackgroundTransparency = 1
saveIcon.Size = UDim2.new(0, 25, 0, 25)
saveIcon.Position = UDim2.new(0, 5, 0.5, -12)
saveIcon.Image = "rbxassetid://6026569649"
saveIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)

local saveText = Instance.new("TextLabel")
saveText.Name = "SaveText"
saveText.Parent = saveBtn
saveText.BackgroundTransparency = 1
saveText.Size = UDim2.new(1, 0, 1, 0)
saveText.Text = "💾 SALVAR OFFSETS"
saveText.TextColor3 = Color3.fromRGB(255, 255, 255)
saveText.Font = Enum.Font.GothamBold
saveText.TextSize = 14

-- ============================================
-- RIGHT PANEL (SCROLLING FRAME - LISTA DE OFFSETS)
-- ============================================
local rightPanel = Instance.new("Frame")
rightPanel.Name = "RightPanel"
rightPanel.Parent = mainFrame
rightPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
rightPanel.BackgroundTransparency = 0.1
rightPanel.BorderSizePixel = 0
rightPanel.Position = UDim2.new(0, 220, 0, 50)
rightPanel.Size = UDim2.new(1, -230, 1, -60)

local rightCorner = Instance.new("UICorner")
rightCorner.CornerRadius = UDim.new(0, 8)
rightCorner.Parent = rightPanel

-- Título do painel direito
local rightTitle = Instance.new("TextLabel")
rightTitle.Name = "RightTitle"
rightTitle.Parent = rightPanel
rightTitle.BackgroundTransparency = 1
rightTitle.Size = UDim2.new(1, 0, 0, 35)
rightTitle.Text = "📋 OFFSETS ENCONTRADOS (ScrollingFrame)"
rightTitle.TextColor3 = Color3.fromRGB(200, 200, 255)
rightTitle.Font = Enum.Font.GothamBold
rightTitle.TextSize = 14

-- Separador
local separator2 = Instance.new("Frame")
separator2.Name = "Separator2"
separator2.Parent = rightPanel
separator2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
separator2.BackgroundTransparency = 0.9
separator2.BorderSizePixel = 0
separator2.Position = UDim2.new(0, 10, 0, 35)
separator2.Size = UDim2.new(1, -20, 0, 1)

-- ============================================
-- SCROLLING FRAME (ONDE VÃO APARECER OS OFFSETS)
-- ============================================
local scrollingFrame = Instance.new("ScrollingFrame")
scrollingFrame.Name = "OffsetsList"
scrollingFrame.Parent = rightPanel
scrollingFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
scrollingFrame.BackgroundTransparency = 0.3
scrollingFrame.BorderSizePixel = 0
scrollingFrame.Position = UDim2.new(0, 10, 0, 45)
scrollingFrame.Size = UDim2.new(1, -20, 1, -55)
scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollingFrame.ScrollBarThickness = 6
scrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 150)
scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

local listLayout = Instance.new("UIListLayout")
listLayout.Parent = scrollingFrame
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 4)

local listPadding = Instance.new("UIPadding")
listPadding.Parent = scrollingFrame
listPadding.PaddingTop = UDim.new(0, 2)
listPadding.PaddingBottom = UDim.new(0, 2)
listPadding.PaddingLeft = UDim.new(0, 2)
listPadding.PaddingRight = UDim.new(0, 2)

-- ============================================
-- FUNÇÕES DO DUMPER
-- ============================================
local dumper = {
    results = {},
    robloxBase = 0,
    executorFunctions = {}
}

-- Detectar funções do executor
function dumper.DetectExecutorFunctions()
    statusLabel.Text = "Status: Detectando funções..."
    
    local possibleFunctions = {
        getaddress = {"getaddress", "get_address", "getInstanceAddress", "getinstaddress"},
        readbyte = {"readbyte", "read_byte", "mem_read_byte"},
        scanpattern = {"scanpattern", "pattern_scan", "find_pattern", "scan_memory"},
        gettaskscheduler = {"gettaskscheduler", "get_task_scheduler", "task_scheduler"},
        getdatamodel = {"getdatamodel", "get_data_model", "datamodel"},
        getfunctionaddress = {"getfunctionaddress", "get_function_address"}
    }
    
    for funcName, variations in pairs(possibleFunctions) do
        for _, var in ipairs(variations) do
            if getgenv()[var] then
                dumper.executorFunctions[funcName] = getgenv()[var]
                break
            end
        end
    end
    
    -- Tentar pegar base do Roblox
    if dumper.executorFunctions.getaddress and game then
        local success, addr = pcall(dumper.executorFunctions.getaddress, game)
        if success and addr then
            dumper.robloxBase = addr - 0x5000000 -- Estimativa
            robloxBaseLabel.Text = string.format("Base: 0x%x", dumper.robloxBase)
        end
    end
    
    statusLabel.Text = "Status: Funções detectadas"
end

-- Adicionar offset à lista
function dumper.AddOffsetToList(name, address, offset, pattern)
    local itemFrame = Instance.new("Frame")
    itemFrame.Name = "OffsetItem"
    itemFrame.Parent = scrollingFrame
    itemFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    itemFrame.BackgroundTransparency = 0.2
    itemFrame.BorderSizePixel = 0
    itemFrame.Size = UDim2.new(1, -5, 0, 45)
    itemFrame.LayoutOrder = #dumper.results + 1
    
    local itemCorner = Instance.new("UICorner")
    itemCorner.CornerRadius = UDim.new(0, 4)
    itemCorner.Parent = itemFrame
    
    -- Nome do offset
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Parent = itemFrame
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(1, -10, 0, 20)
    nameLabel.Position = UDim2.new(0, 5, 0, 2)
    nameLabel.Text = name
    nameLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 12
    
    -- Endereço e offset
    local addrLabel = Instance.new("TextLabel")
    addrLabel.Parent = itemFrame
    addrLabel.BackgroundTransparency = 1
    addrLabel.Size = UDim2.new(1, -10, 0, 16)
    addrLabel.Position = UDim2.new(0, 5, 0, 22)
    addrLabel.Text = string.format("Addr: 0x%x | Offset: 0x%x", address, offset)
    addrLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
    addrLabel.TextXAlignment = Enum.TextXAlignment.Left
    addrLabel.Font = Enum.Font.Code
    addrLabel.TextSize = 10
    
    -- Badge do tipo
    local typeBadge = Instance.new("Frame")
    typeBadge.Parent = itemFrame
    typeBadge.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    typeBadge.BorderSizePixel = 0
    typeBadge.Position = UDim2.new(1, -65, 0, 2)
    typeBadge.Size = UDim2.new(0, 60, 0, 18)
    
    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(0, 4)
    badgeCorner.Parent = typeBadge
    
    local badgeText = Instance.new("TextLabel")
    badgeText.Parent = typeBadge
    badgeText.BackgroundTransparency = 1
    badgeText.Size = UDim2.new(1, 0, 1, 0)
    badgeText.Text = pattern and "Pattern" or "Offset"
    badgeText.TextColor3 = Color3.fromRGB(255, 255, 255)
    badgeText.Font = Enum.Font.Gotham
    badgeText.TextSize = 9
    
    table.insert(dumper.results, {
        name = name,
        address = address,
        offset = offset,
        pattern = pattern
    })
    
    countLabel.Text = string.format("Offsets: %d", #dumper.results)
end

-- ============================================
-- FUNÇÕES DE SCAN
-- ============================================
function dumper.ScanAll()
    statusLabel.Text = "Status: Escaneando..."
    startBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    startBtn.Active = false
    
    -- Limpar lista atual
    for _, child in ipairs(scrollingFrame:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end
    dumper.results = {}
    
    -- Scan DataModel
    if dumper.executorFunctions.getdatamodel then
        local dm = dumper.executorFunctions.getdatamodel()
        if dm then
            local addr = dumper.executorFunctions.getaddress(dm)
            dumper.AddOffsetToList("DataModel", addr, addr - dumper.robloxBase)
            wait(0.1)
        end
    end
    
    -- Scan TaskScheduler
    if dumper.executorFunctions.gettaskscheduler then
        local ts = dumper.executorFunctions.gettaskscheduler()
        if ts then
            local addr = dumper.executorFunctions.getaddress(ts)
            dumper.AddOffsetToList("TaskScheduler", addr, addr - dumper.robloxBase)
            wait(0.1)
        end
    end
    
    -- Scan serviços
    local services = {
        "Workspace", "Players", "Lighting", "ReplicatedStorage",
        "ServerStorage", "ServerScriptService"
    }
    
    for _, serviceName in ipairs(services) do
        local service = game:GetService(serviceName)
        if service then
            local addr = dumper.executorFunctions.getaddress(service)
            dumper.AddOffsetToList("Service_" .. serviceName, addr, addr - dumper.robloxBase)
            wait(0.05)
        end
    end
    
    statusLabel.Text = "Status: Scan concluído!"
    startBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
    startBtn.Active = true
end

-- ============================================
-- FUNÇÃO DE SALVAR
-- ============================================
function dumper.SaveOffsets()
    statusLabel.Text = "Status: Salvando..."
    
    local output = "-- AUTO-DUMPER OFFSETS\n"
    output = output .. "-- Data: " .. os.date("%x %X") .. "\n"
    output = output .. "-- Roblox Base: 0x" .. string.format("%x", dumper.robloxBase) .. "\n\n"
    
    output = output .. "local offsets = {\n"
    
    for _, result in ipairs(dumper.results) do
        output = output .. string.format('    ["%s"] = { offset = 0x%x },\n', 
            result.name, result.offset)
    end
    
    output = output .. "}\n\nreturn offsets"
    
    -- Criar GUI de notificação
    local notif = Instance.new("Frame")
    notif.Parent = screenGui
    notif.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    notif.BorderSizePixel = 0
    notif.Position = UDim2.new(0.5, -150, 0, 50)
    notif.Size = UDim2.new(0, 300, 0, 50)
    
    local notifCorner = Instance.new("UICorner")
    notifCorner.CornerRadius = UDim.new(0, 8)
    notifCorner.Parent = notif
    
    local notifText = Instance.new("TextLabel")
    notifText.Parent = notif
    notifText.BackgroundTransparency = 1
    notifText.Size = UDim2.new(1, 0, 1, 0)
    notifText.Text = "✅ Offsets salvos!\n" .. #dumper.results .. " encontrados"
    notifText.TextColor3 = Color3.fromRGB(255, 255, 255)
    notifText.Font = Enum.Font.Gotham
    notifText.TextSize = 14
    
    -- Animação de fade
    for i = 1, 10 do
        wait(0.3)
    end
    notif:Destroy()
    
    -- Copiar pra clipboard (se possível)
    if setclipboard then
        setclipboard(output)
        statusLabel.Text = "Status: Copiado pra clipboard!"
    else
        statusLabel.Text = "Status: Não foi possível copiar"
    end
end

-- ============================================
-- CONECTAR BOTÕES
-- ============================================
startBtn.MouseButton1Click:Connect(function()
    dumper.ScanAll()
end)

saveBtn.MouseButton1Click:Connect(function()
    dumper.SaveOffsets()
end)

-- ============================================
-- INICIALIZAR
-- ============================================
dumper.DetectExecutorFunctions()

-- ============================================
-- DRAG FUNCTION (se quiser mover de outro lugar)
-- ============================================
local dragging = false
local dragInput, dragStart, startPos

topBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)

topBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

userInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, 
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

userInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)
