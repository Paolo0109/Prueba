-- ============================================================================
-- 🔮 KILLER HUB - MÓDULO MMV (OPTIMIZADO v4.0 - SMART DRAG & CLICK)
-- ============================================================================

local success, KillerHub = pcall(function()
    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Salayer09/KillerHub1/refs/heads/main/MM2.lua"))()
end)

if not success or not KillerHub then
    warn("[KillerHub] Error al cargar la librería externa.")
    return
end

local MMVTab = KillerHub:CreateTab("Bomb Jump", "rbxassetid://14321074389")

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- 📊 CONFIGURACIÓN GLOBAL
local POTENCIA_SALTO = 55
local UMBRAL_ARRASTRE = 8 -- Píxeles de tolerancia para diferenciar Arrastre vs Clic

-- 📊 CONTROL TEMPORAL (TIMESTAMP BASE)
local CooldownNormalTime = 22.0
local CooldownFinNormal = 0
local NormalActivo = false
local AutoEquipNormalActivo = false
local LockNormal = false
local BotonSizeNormalActual = 100
local ARCHIVO_POS_NORMAL = "KillerHub_NormalPosConfig.json"

local CooldownGoldTime = 3.0
local CooldownFinGold = 0
local GoldActivo = false
local AutoEquipGoldActivo = false
local LockGold = false
local BotonSizeGoldActual = 100
local ARCHIVO_POS_GOLD = "KillerHub_GoldPosConfig.json"

local CooldownDiamondTime = 5.5
local CooldownFinDiamond = 0
local DiamondActivo = false
local AutoEquipDiamondActivo = false
local LockDiamond = false
local BotonSizeDiamondActual = 100
local ARCHIVO_POS_DIAMOND = "KillerHub_DiamondPosConfig.json"

-- UI Flotantes
local ScreenGuiNormal, BotonNormal
local ScreenGuiGold, BotonGold
local ScreenGuiDiamond, BotonDiamond

local ID_Generacion_Actual = 0

-- ============================================================================
-- 💾 SISTEMA DE CONFIGURACIÓN LOCAL
-- ============================================================================
local function guardarPosicionBoton(archivo, xScale, xOffset, yScale, yOffset)
    if not writefile then return end
    pcall(writefile, archivo, HttpService:JSONEncode({
        X_Scale = xScale, X_Offset = xOffset, Y_Scale = yScale, Y_Offset = yOffset
    }))
end

local function cargarPosicionBoton(archivo, defX, defY)
    local pos = {ScaleX = defX, OffsetX = -50, ScaleY = defY, OffsetY = -50}
    if readfile and isfile and isfile(archivo) then
        pcall(function()
            local decoded = HttpService:JSONDecode(readfile(archivo))
            if decoded then
                pos.ScaleX = decoded.X_Scale or pos.ScaleX
                pos.OffsetX = decoded.X_Offset or pos.OffsetX
                pos.ScaleY = decoded.Y_Scale or pos.ScaleY
                pos.OffsetY = decoded.Y_Offset or pos.OffsetY
            end
        end)
    end
    return pos
end

-- ============================================================================
-- 🎨 ESTILO Y SISTEMA INTELIGENTE DE ARRASTRE Y CLIC
-- ============================================================================
local function AplicarEstiloBoton(boton, colorTexto)
    boton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    boton.BackgroundTransparency = 0.5
    boton.Font = Enum.Font.GothamBold
    boton.TextSize = 11
    boton.TextColor3 = colorTexto
    boton.TextStrokeTransparency = 1
    boton.BorderSizePixel = 0
    boton.Active = true

    local corner = boton:FindFirstChildOfClass("UICorner") or Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 18)
    corner.Parent = boton

    local stroke = boton:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = Color3.fromRGB(0, 0, 0)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = boton
end

local function ConfigurarArrastreYClick(boton, archivoConfig, getLockState, accionClick)
    local dragging = false
    local wasDragged = false
    local dragInputObject = nil
    local dragStart = Vector3.zero
    local startPos = UDim2.new()

    boton.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = true
            wasDragged = false
            dragInputObject = input
            dragStart = input.Position
            startPos = boton.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInputObject then
            local delta = input.Position - dragStart
            -- Verificar si superó el umbral de movimiento en píxeles
            if delta.Magnitude > UMBRAL_ARRASTRE then
                if not (getLockState and getLockState()) then
                    wasDragged = true
                    boton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                end
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input == dragInputObject and dragging then
            dragging = false
            dragInputObject = nil

            if wasDragged then
                -- FUE ARRASTRE: Guarda posición y NO ejecuta la bomba
                guardarPosicionBoton(archivoConfig, boton.Position.X.Scale, boton.Position.X.Offset, boton.Position.Y.Scale, boton.Position.Y.Offset)
            else
                -- FUE CLIC LIMPIO: Ejecuta la acción del botón
                if accionClick then
                    accionClick()
                end
            end
        end
    end)
end

-- ============================================================================
-- ⚡ BUCLE DE ACTUALIZACIÓN VISUAL DE COOLDOWNS
-- ============================================================================
local function IniciarLoopCooldown(boton, tiempoFin, textoBase, colorBase, idGen)
    task.spawn(function()
        while os.clock() < tiempoFin and idGen == ID_Generacion_Actual do
            if boton and boton.Parent then
                local restante = tiempoFin - os.clock()
                boton.Text = string.format("%.1fs", math.max(0, restante))
                boton.TextColor3 = Color3.fromRGB(150, 150, 150)
                boton.Active = false
            else
                break
            end
            task.wait(0.1)
        end
        if boton and boton.Parent and idGen == ID_Generacion_Actual then
            boton.Text = textoBase
            boton.TextColor3 = colorBase
            boton.Active = true
        end
    end)
end

-- ============================================================================
-- ⚡ LÓGICAS DE EJECUCIÓN (BOMB JUMPS)
-- ============================================================================
local function EjecutarNormalBombJump()
    if os.clock() < CooldownFinNormal or not NormalActivo then return end
    
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    
    local tieneBomba = (char and char:FindFirstChild("FakeBomb")) or (backpack and backpack:FindFirstChild("FakeBomb"))
    if not tieneBomba then return end
    
    if hum and root and hum.Health > 0 then
        if AutoEquipNormalActivo and backpack then
            local bombTool = backpack:FindFirstChild("FakeBomb")
            if bombTool then hum:EquipTool(bombTool); task.wait(0.05) end
        end
        
        local fakeBomb = char and char:FindFirstChild("FakeBomb")
        local remote = fakeBomb and fakeBomb:FindFirstChild("Remote")
        if fakeBomb and remote then
            CooldownFinNormal = os.clock() + CooldownNormalTime
            hum.Jump = true
            task.wait(0.12)
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, POTENCIA_SALTO, root.AssemblyLinearVelocity.Z)
            pcall(function() remote:FireServer(CFrame.new(root.Position - Vector3.new(0, 3, 0)), 50) end)
            
            IniciarLoopCooldown(BotonNormal, CooldownFinNormal, "BOMB JUMP", Color3.fromRGB(255, 255, 255), ID_Generacion_Actual)
        end
    end
end

local function EjecutarGoldBombJump()
    if os.clock() < CooldownFinGold or not GoldActivo then return end
    
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    
    local tieneBomba = (char and char:FindFirstChild("GoldBomb")) or (backpack and backpack:FindFirstChild("GoldBomb"))
    if not tieneBomba then return end
    
    if hum and root and hum.Health > 0 then
        if AutoEquipGoldActivo and backpack then
            local goldTool = backpack:FindFirstChild("GoldBomb")
            if goldTool then hum:EquipTool(goldTool); task.wait(0.05) end
        end
        
        local goldBomb = char and char:FindFirstChild("GoldBomb")
        local remote = goldBomb and goldBomb:FindFirstChild("Remote")
        if goldBomb and remote then
            CooldownFinGold = os.clock() + CooldownGoldTime
            hum.Jump = true
            task.wait(0.12)
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, POTENCIA_SALTO, root.AssemblyLinearVelocity.Z)
            pcall(function() remote:FireServer(CFrame.new(root.Position - Vector3.new(0, 3, 0)), 50) end)
            
            IniciarLoopCooldown(BotonGold, CooldownFinGold, "GOLD JUMP", Color3.fromRGB(255, 215, 0), ID_Generacion_Actual)
        end
    end
end

local function EjecutarDiamondBombJump()
    if os.clock() < CooldownFinDiamond or not DiamondActivo then return end
    
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    
    local tieneBomba = (char and char:FindFirstChild("DiamondBomb")) or (backpack and backpack:FindFirstChild("DiamondBomb"))
    if not tieneBomba then return end
    
    if hum and root and hum.Health > 0 then
        if AutoEquipDiamondActivo and backpack then
            local diamondTool = backpack:FindFirstChild("DiamondBomb")
            if diamondTool then hum:EquipTool(diamondTool); task.wait(0.05) end
        end
        
        local diamondBomb = char and char:FindFirstChild("DiamondBomb")
        local remote = diamondBomb and diamondBomb:FindFirstChild("Remote")
        if diamondBomb and remote then
            CooldownFinDiamond = os.clock() + CooldownFinDiamondTime
            hum.Jump = true
            task.wait(0.12)
            root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, POTENCIA_SALTO, root.AssemblyLinearVelocity.Z)
            pcall(function() remote:FireServer(CFrame.new(root.Position - Vector3.new(0, 3, 0)), 50) end)
            
            IniciarLoopCooldown(BotonDiamond, CooldownFinDiamond, "DIAMOND JUMP", Color3.fromRGB(0, 191, 255), ID_Generacion_Actual)
        end
    end
end

-- ============================================================================
-- 🔄 RESET DETECTOR
-- ============================================================================
local function AlReaparecerPersonaje()
    ID_Generacion_Actual = ID_Generacion_Actual + 1
    CooldownFinNormal = 0
    CooldownFinGold = 0
    CooldownFinDiamond = 0
    
    if BotonNormal and NormalActivo then
        BotonNormal.Text = "BOMB JUMP"
        BotonNormal.TextColor3 = Color3.fromRGB(255, 255, 255)
        BotonNormal.Active = true
    end
    if BotonGold and GoldActivo then
        BotonGold.Text = "GOLD JUMP"
        BotonGold.TextColor3 = Color3.fromRGB(255, 215, 0)
        BotonGold.Active = true
    end
    if BotonDiamond and DiamondActivo then
        BotonDiamond.Text = "DIAMOND JUMP"
        BotonDiamond.TextColor3 = Color3.fromRGB(0, 191, 255)
        BotonDiamond.Active = true
    end
end

LocalPlayer.CharacterAdded:Connect(AlReaparecerPersonaje)

-- ============================================================================
-- 🔳 CREACIÓN DE BOTONES FLOTANTES
-- ============================================================================
local function CrearBotonNormal()
    if CoreGui:FindFirstChild("KillerHub_NormalJump") then CoreGui.KillerHub_NormalJump:Destroy() end
    ScreenGuiNormal = Instance.new("ScreenGui", CoreGui)
    ScreenGuiNormal.Name = "KillerHub_NormalJump"
    ScreenGuiNormal.ResetOnSpawn = false
    
    local pos = cargarPosicionBoton(ARCHIVO_POS_NORMAL, 0.6, 0.7)
    BotonNormal = Instance.new("TextButton", ScreenGuiNormal)
    BotonNormal.Name = "NormalJumpButton"
    BotonNormal.Size = UDim2.new(0, BotonSizeNormalActual, 0, BotonSizeNormalActual)
    BotonNormal.Position = UDim2.new(pos.ScaleX, pos.OffsetX, pos.ScaleY, pos.OffsetY)
    
    AplicarEstiloBoton(BotonNormal, Color3.fromRGB(255, 255, 255))
    
    if os.clock() < CooldownFinNormal then
        IniciarLoopCooldown(BotonNormal, CooldownFinNormal, "BOMB JUMP", Color3.fromRGB(255, 255, 255), ID_Generacion_Actual)
    else
        BotonNormal.Text = "BOMB JUMP"
    end
    
    ConfigurarArrastreYClick(BotonNormal, ARCHIVO_POS_NORMAL, function() return LockNormal end, EjecutarNormalBombJump)
end

local function CrearBotonGold()
    if CoreGui:FindFirstChild("KillerHub_GoldJump") then CoreGui.KillerHub_GoldJump:Destroy() end
    ScreenGuiGold = Instance.new("ScreenGui", CoreGui)
    ScreenGuiGold.Name = "KillerHub_GoldJump"
    ScreenGuiGold.ResetOnSpawn = false
    
    local pos = cargarPosicionBoton(ARCHIVO_POS_GOLD, 0.4, 0.7)
    BotonGold = Instance.new("TextButton", ScreenGuiGold)
    BotonGold.Name = "GoldJumpButton"
    BotonGold.Size = UDim2.new(0, BotonSizeGoldActual, 0, BotonSizeGoldActual)
    BotonGold.Position = UDim2.new(pos.ScaleX, pos.OffsetX, pos.ScaleY, pos.OffsetY)
    
    AplicarEstiloBoton(BotonGold, Color3.fromRGB(255, 215, 0))
    
    if os.clock() < CooldownFinGold then
        IniciarLoopCooldown(BotonGold, CooldownFinGold, "GOLD JUMP", Color3.fromRGB(255, 215, 0), ID_Generacion_Actual)
    else
        BotonGold.Text = "GOLD JUMP"
    end
    
    ConfigurarArrastreYClick(BotonGold, ARCHIVO_POS_GOLD, function() return LockGold end, EjecutarGoldBombJump)
end

local function CrearBotonDiamond()
    if CoreGui:FindFirstChild("KillerHub_DiamondJump") then CoreGui.KillerHub_DiamondJump:Destroy() end
    ScreenGuiDiamond = Instance.new("ScreenGui", CoreGui)
    ScreenGuiDiamond.Name = "KillerHub_DiamondJump"
    ScreenGuiDiamond.ResetOnSpawn = false
    
    local pos = cargarPosicionBoton(ARCHIVO_POS_DIAMOND, 0.5, 0.7)
    BotonDiamond = Instance.new("TextButton", ScreenGuiDiamond)
    BotonDiamond.Name = "DiamondJumpButton"
    BotonDiamond.Size = UDim2.new(0, BotonSizeDiamondActual, 0, BotonSizeDiamondActual)
    BotonDiamond.Position = UDim2.new(pos.ScaleX, pos.OffsetX, pos.ScaleY, pos.OffsetY)
    
    AplicarEstiloBoton(BotonDiamond, Color3.fromRGB(0, 191, 255))
    
    if os.clock() < CooldownFinDiamond then
        IniciarLoopCooldown(BotonDiamond, CooldownFinDiamond, "DIAMOND JUMP", Color3.fromRGB(0, 191, 255), ID_Generacion_Actual)
    else
        BotonDiamond.Text = "DIAMOND JUMP"
    end
    
    ConfigurarArrastreYClick(BotonDiamond, ARCHIVO_POS_DIAMOND, function() return LockDiamond end, EjecutarDiamondBombJump)
end

local function DestruirBotonNormal() if ScreenGuiNormal then ScreenGuiNormal:Destroy() ScreenGuiNormal = nil BotonNormal = nil end end
local function DestruirBotonGold() if ScreenGuiGold then ScreenGuiGold:Destroy() ScreenGuiGold = nil BotonGold = nil end end
local function DestruirBotonDiamond() if ScreenGuiDiamond then ScreenGuiDiamond:Destroy() ScreenGuiDiamond = nil BotonDiamond = nil end end

-- ============================================================================
-- 🛠️ INTERFAZ DE USUARIO
-- ============================================================================

-- 1️⃣ NORMAL BOMB JUMP
MMVTab:CreateSection("Bomb Jump")

MMVTab:CreateToggle("NormalBomb_Enable", "Bomb Jump", function(estado)
    NormalActivo = estado
    if estado then CrearBotonNormal() else DestruirBotonNormal() end
end)

MMVTab:CreateSlider("NormalBomb_Size", "Button Size", 60, 200, function(valor)
    BotonSizeNormalActual = math.floor(valor)
    if BotonNormal and NormalActivo then
        BotonNormal.Size = UDim2.new(0, BotonSizeNormalActual, 0, BotonSizeNormalActual)
    end
end)

MMVTab:CreateToggle("NormalBomb_Lock", "Lock Position", function(estado)
    LockNormal = estado
end)

MMVTab:CreateToggle("NormalBomb_AutoEquip", "Auto Equip", function(estado)
    AutoEquipNormalActivo = estado
end)


-- 2️⃣ GOLD BOMB JUMP
MMVTab:CreateSection("Gold Bomb Jump")

MMVTab:CreateToggle("GoldBomb_Enable", "Gold Bomb Jump", function(estado)
    GoldActivo = estado
    if estado then CrearBotonGold() else DestruirBotonGold() end
end)

MMVTab:CreateSlider("GoldBomb_Size", "Button Size", 60, 200, function(valor)
    BotonSizeGoldActual = math.floor(valor)
    if BotonGold and GoldActivo then
        BotonGold.Size = UDim2.new(0, BotonSizeGoldActual, 0, BotonSizeGoldActual)
    end
end)

MMVTab:CreateToggle("GoldBomb_Lock", "Lock Position", function(estado)
    LockGold = estado
end)

MMVTab:CreateToggle("GoldBomb_AutoEquip", "Auto Equip", function(estado)
    AutoEquipGoldActivo = estado
end)


-- 3️⃣ DIAMOND BOMB JUMP
MMVTab:CreateSection("Diamond Bomb Jump")

MMVTab:CreateToggle("DiamondBomb_Enable", "Diamond Bomb Jump", function(estado)
    DiamondActivo = estado
    if estado then CrearBotonDiamond() else DestruirBotonDiamond() end
end)

MMVTab:CreateSlider("DiamondBomb_Size", "Button Size", 60, 200, function(valor)
    BotonSizeDiamondActual = math.floor(valor)
    if BotonDiamond and DiamondActivo then
        BotonDiamond.Size = UDim2.new(0, BotonSizeDiamondActual, 0, BotonSizeDiamondActual)
    end
end)

MMVTab:CreateToggle("DiamondBomb_Lock", "Lock Position", function(estado)
    LockDiamond = estado
end)

MMVTab:CreateToggle("DiamondBomb_AutoEquip", "Auto Equip", function(estado)
    AutoEquipDiamondActivo = estado
end)

return KillerHub
