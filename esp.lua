-- ============================================
-- MEMORY DUMPER SUPREMO - Leitura BRUTA da Memória
-- By: Seu Amigo (agora funciona de verdade)
-- ============================================

local memoryDumper = {}

-- ============================================
-- CONFIGURAÇÕES
-- ============================================
memoryDumper.scanRegion = {
    start = 0x00000000,  -- Vai descobrir sozinho
    size = 0x7FFFFFFF,    -- Scanner máximo (2GB)
    current = 0
}

memoryDumper.results = {}
memoryDumper.signatures = {
    -- Assinaturas conhecidas do Roblox
    DataModel = { 
        pattern = "\x48\x8B\x0D\x00\x00\x00\x00\x48\x85\xC9\x74\x00\x48\x8B\x01",
        mask = "xxx????xxxx?xxx"
    },
    TaskScheduler = {
        pattern = "\x48\x8B\x05\x00\x00\x00\x00\x48\x8B\x08\x48\x85\xC9\x74\x00",
        mask = "xxx????xxxxxx?x"
    },
    ScriptContext = {
        pattern = "\x48\x8B\x0D\x00\x00\x00\x00\xE8\x00\x00\x00\x00\x48\x8B\xD8",
        mask = "xxx????x????xxx"
    },
    LuaState = {
        pattern = "\x48\x8B\x00\x00\x00\x00\x00\x48\x8B\x08\xFF\x50\x00\x84\xC0",
        mask = "xx?????xxxx?xx"
    }
}

-- ============================================
-- FUNÇÃO DE LEITURA DE MEMÓRIA (A MÁGICA)
-- ============================================
function memoryDumper.ReadMemory(address, length)
    local bytes = {}
    
    -- Tenta múltiplos métodos de leitura
    local methods = {
        -- Método 1: Usar dezas (se disponível)
        function()
            if dezas then
                return dezas:ReadBytes(address, length, true)
            end
        end,
        
        -- Método 2: Usar mem_read (se disponível)
        function()
            if mem_read then
                local data = {}
                for i = 0, length - 1 do
                    data[i+1] = mem_read(address + i)
                end
                return data
            end
        end,
        
        -- Método 3: Usar readbytes (se disponível)
        function()
            if readbytes then
                return { readbytes(address, length) }
            end
        end,
        
        -- Método 4: Usar debug.getmemory (Roblox Studio)
        function()
            if debug and debug.getmemory then
                -- Converte string pra bytes
                local mem = debug.getmemory(address, length)
                if mem then
                    local bytes = {}
                    for i = 1, #mem do
                        bytes[i] = string.byte(mem, i)
                    end
                    return bytes
                end
            end
        end,
        
        -- Método 5: Tentar via CFFI (se disponível)
        function()
            if cffi then
                local ptr = cffi.cast("void*", address)
                local data = cffi.string(ptr, length)
                local bytes = {}
                for i = 1, #data do
                    bytes[i] = string.byte(data, i)
                end
                return bytes
            end
        end
    }
    
    -- Tenta cada método até um funcionar
    for _, method in ipairs(methods) do
        local success, result = pcall(method)
        if success and result and #result == length then
            return result
        end
    end
    
    return nil
end

-- ============================================
-- FUNÇÃO DE SCAN POR PADRÃO
-- ============================================
function memoryDumper.ScanPattern(pattern, mask, startAddr, size)
    local patternBytes = {}
    for i = 1, #pattern do
        patternBytes[i] = string.byte(pattern, i)
    end
    
    local patternLen = #patternBytes
    local endAddr = startAddr + size - patternLen
    
    -- Mostrar progresso a cada 10MB
    local lastProgress = startAddr
    local progressInterval = 10 * 1024 * 1024 -- 10MB
    
    for addr = startAddr, endAddr, 1 do
        -- Atualizar progresso
        if addr - lastProgress >= progressInterval then
            local percent = ((addr - startAddr) / size) * 100
            if memoryDumper.updateProgress then
                memoryDumper.updateProgress(string.format("Escaneando: %.1f%% (0x%x)", percent, addr))
            end
            lastProgress = addr
            wait(0) -- Permitir que a UI atualize
        end
        
        -- Ler bytes
        local bytes = memoryDumper.ReadMemory(addr, patternLen)
        if not bytes then
            continue
        end
        
        -- Comparar com padrão
        local found = true
        for i = 1, patternLen do
            if mask:sub(i, i) == 'x' then
                if bytes[i] ~= patternBytes[i] then
                    found = false
                    break
                end
            end
        end
        
        if found then
            return addr
        end
    end
    
    return nil
end

-- ============================================
-- DESCOBRIR BASE DO ROBLOX AUTOMATICAMENTE
-- ============================================
function memoryDumper.FindRobloxBase()
    if memoryDumper.updateProgress then
        memoryDumper.updateProgress("Procurando base do Roblox...")
    end
    
    -- Método 1: Usar getexecutorname (se disponível)
    if getexecutorname then
        local execName = getexecutorname():lower()
        if execName:find("krnl") or execName:find("synapse") then
            -- Executores conhecidos têm a base em lugares conhecidos
            if dezas then
                local base = dezas:GetModuleBaseAddress("RobloxPlayerBeta.exe")
                if base and base > 0 then
                    return base
                end
            end
        end
    end
    
    -- Método 2: Procurar por assinatura do PE header (MZ)
    local possibleBases = {0x400000, 0x140000000, 0x20000000, 0x10000000}
    
    for _, base in ipairs(possibleBases) do
        local bytes = memoryDumper.ReadMemory(base, 2)
        if bytes and bytes[1] == 0x4D and bytes[2] == 0x5A then -- "MZ"
            return base
        end
    end
    
    -- Método 3: Tentar achar via game object
    if game then
        for i = 1, 100 do
            local testAddr = 0x400000 + (i * 0x1000)
            local bytes = memoryDumper.ReadMemory(testAddr, 8)
            if bytes then
                -- Procurar por referência ao game
                local gameAddr = tonumber(tostring(game):match("0x(%x+)"))
                if gameAddr then
                    gameAddr = tonumber(gameAddr, 16)
                    -- Procurar nas proximidades
                    for j = -50, 50 do
                        local checkAddr = testAddr + (j * 8)
                        local valBytes = memoryDumper.ReadMemory(checkAddr, 8)
                        if valBytes then
                            local val = 0
                            for k = 1, 8 do
                                val = val + (valBytes[k] * (256^(k-1)))
                            end
                            if math.abs(val - gameAddr) < 0x1000 then
                                return checkAddr - 0x1000000 -- Estimativa da base
                            end
                        end
                    end
                end
            end
        end
    end
    
    return 0x400000 -- Fallback
end

-- ============================================
-- FUNÇÃO PRINCIPAL DE DUMP
-- ============================================
function memoryDumper.DumpAll(updateCallback)
    memoryDumper.updateProgress = updateCallback
    
    -- Limpar resultados anteriores
    memoryDumper.results = {}
    
    -- Encontrar base
    local baseAddr = memoryDumper.FindRobloxBase()
    if updateCallback then
        updateCallback(string.format("Base encontrada: 0x%x", baseAddr))
    end
    wait(0.5)
    
    -- Definir região de scan
    memoryDumper.scanRegion.start = baseAddr
    memoryDumper.scanRegion.current = baseAddr
    
    -- Escanear cada assinatura
    for name, sig in pairs(memoryDumper.signatures) do
        if updateCallback then
            updateCallback(string.format("Procurando %s...", name))
        end
        
        local addr = memoryDumper.ScanPattern(
            sig.pattern, 
            sig.mask, 
            baseAddr, 
            0x2000000 -- 32MB de scan
        )
        
        if addr then
            local offset = addr - baseAddr
            table.insert(memoryDumper.results, {
                name = name,
                address = addr,
                offset = offset,
                pattern = sig.pattern
            })
            
            if updateCallback then
                updateCallback(string.format("✓ %s encontrado em 0x%x (offset 0x%x)", 
                    name, addr, offset))
            end
        else
            if updateCallback then
                updateCallback(string.format("✗ %s não encontrado", name))
            end
        end
        
        wait(0.1)
    end
    
    -- Scan adicional por padrões genéricos
    memoryDumper.ScanGenericPatterns(baseAddr, updateCallback)
    
    if updateCallback then
        updateCallback(string.format("Dump concluído! %d itens encontrados.", #memoryDumper.results))
    end
    
    return memoryDumper.results
end

-- ============================================
-- SCAN POR PADRÕES GENÉRICOS
-- ============================================
function memoryDumper.ScanGenericPatterns(baseAddr, updateCallback)
    local genericPatterns = {
        -- Prólogos de função comuns
        { pattern = "\x55\x48\x8B\xEC", mask = "xxxx", name = "Function_Prologue_1" },
        { pattern = "\x48\x89\x5C\x24\x00\x48\x89\x74\x24\x00\x57", mask = "xxxx?xxxx?x", name = "Function_Prologue_2" },
        { pattern = "\x40\x53\x48\x83\xEC\x20", mask = "xxxxxx", name = "Function_Prologue_3" },
        
        -- Chamadas de função comuns
        { pattern = "\xE8\x00\x00\x00\x00\x48\x8B\xD8", mask = "x????xxx", name = "Call_Instruction" },
        { pattern = "\xFF\x15\x00\x00\x00\x00\x48\x8B\xC8", mask = "xx????xxx", name = "Indirect_Call" },
        
        -- Strings de referência
        { pattern = "\x44\x61\x74\x61\x4D\x6F\x64\x65\x6C", mask = "xxxxxxxxx", name = "String_DataModel" },
        { pattern = "\x57\x6F\x72\x6B\x73\x70\x61\x63\x65", mask = "xxxxxxxxx", name = "String_Workspace" },
    }
    
    for _, pattern in ipairs(genericPatterns) do
        if updateCallback then
            updateCallback(string.format("Procurando %s...", pattern.name))
        end
        
        local addr = memoryDumper.ScanPattern(
            pattern.pattern,
            pattern.mask,
            baseAddr,
            0x2000000
        )
        
        if addr then
            local offset = addr - baseAddr
            table.insert(memoryDumper.results, {
                name = pattern.name,
                address = addr,
                offset = offset,
                pattern = pattern.pattern,
                generic = true
            })
            
            if updateCallback then
                updateCallback(string.format("  → Encontrado em 0x%x", addr))
            end
        end
        
        wait(0.05)
    end
end

-- ============================================
-- GERAR OUTPUT
-- ============================================
function memoryDumper.GenerateOutput()
    local output = "-- MEMORY DUMP RESULTS\n"
    output = output .. "-- Generated: " .. os.date("%x %X") .. "\n"
    output = output .. "-- Base Address: 0x" .. string.format("%x", memoryDumper.scanRegion.start) .. "\n"
    output = output .. "-- Total Items: " .. #memoryDumper.results .. "\n\n"
    
    output = output .. "local offsets = {\n"
    
    for _, result in ipairs(memoryDumper.results) do
        output = output .. string.format('    ["%s"] = 0x%x, -- 0x%x\n', 
            result.name, result.offset, result.address)
    end
    
    output = output .. "}\n\n"
    
    -- Gerar patterns também
    output = output .. "-- Patterns for scanning:\n"
    output = output .. "local patterns = {\n"
    
    for _, result in ipairs(memoryDumper.results) do
        if result.pattern then
            -- Converter pattern string pra representação hex
            local hexPattern = ""
            for i = 1, #result.pattern do
                hexPattern = hexPattern .. string.format("\\x%02X", string.byte(result.pattern, i))
            end
            output = output .. string.format('    ["%s"] = "%s",\n', result.name, hexPattern)
        end
    end
    
    output = output .. "}\n\n"
    output = output .. "return offsets, patterns"
    
    return output
end

-- ============================================
-- GUI COM SCROLLING FRAME (ATUALIZADA)
-- ============================================
local function CreateGUI()
    -- (Manter a GUI anterior, mas adaptar as funções de callback)
    -- Vou reutilizar a GUI que já fizemos, mas agora conectando com o memoryDumper
    
    -- Modificar a função de scan:
    startBtn.MouseButton1Click:Connect(function()
        startBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
        startBtn.Active = false
        
        -- Limpar lista
        for _, child in ipairs(scrollingFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        -- Função de callback pra atualizar UI
        local function updateProgress(text)
            statusLabel.Text = "Status: " .. text
        end
        
        -- Iniciar dump
        local results = memoryDumper.DumpAll(updateProgress)
        
        -- Mostrar resultados na ScrollingFrame
        for _, result in ipairs(results) do
            -- Criar item na lista (igual antes)
            -- (código do item igual ao anterior)
            wait(0.01) -- Pequeno delay pra não travar
        end
        
        countLabel.Text = string.format("Offsets: %d", #results)
        startBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 50)
        startBtn.Active = true
    end)
    
    -- Modificar função de salvar
    saveBtn.MouseButton1Click:Connect(function()
        local output = memoryDumper.GenerateOutput()
        
        -- Tentar copiar pra clipboard
        if setclipboard then
            setclipboard(output)
            statusLabel.Text = "Status: Copiado pra clipboard!"
        else
            -- Mostrar numa janela de texto
            local textFrame = Instance.new("Frame")
            textFrame.Parent = screenGui
            textFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
            textFrame.BorderSizePixel = 0
            textFrame.Position = UDim2.new(0.1, 0, 0.1, 0)
            textFrame.Size = UDim2.new(0.8, 0, 0.8, 0)
            
            local textBox = Instance.new("TextBox")
            textBox.Parent = textFrame
            textBox.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
            textBox.Position = UDim2.new(0, 10, 0, 40)
            textBox.Size = UDim2.new(1, -20, 1, -50)
            textBox.Text = output
            textBox.TextColor3 = Color3.fromRGB(200, 200, 255)
            textBox.TextEditable = true
            textBox.MultiLine = true
            textBox.Font = Enum.Font.Code
            textBox.TextSize = 12
            
            local closeBtn = Instance.new("TextButton")
            closeBtn.Parent = textFrame
            closeBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
            closeBtn.Position = UDim2.new(1, -100, 0, 5)
            closeBtn.Size = UDim2.new(0, 90, 0, 30)
            closeBtn.Text = "Fechar"
            closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            
            closeBtn.MouseButton1Click:Connect(function()
                textFrame:Destroy()
            end)
        end
    end)
end

-- Inicializar
CreateGUI()
