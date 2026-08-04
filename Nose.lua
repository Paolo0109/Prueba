--==============================================================================
-- KILLER HUB UI - COMBINED MODULE (ROLE & DEAD DETECTION VIA PlayerDataChanged)
-- Creator: Killer Hub | By Paolo
--==============================================================================

local KillerHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/Salayer09/m.u.r.d.e.r.pzaoxl/refs/heads/main/Murder.lua"))()

if getgenv().__KillerHub_Combined_Loaded then
    KillerHub:NotifyWarn("Already Loaded", "The script is already running.", 3)
    return
end
getgenv().__KillerHub_Combined_Loaded = true

-- Services Caching
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local StatsService = game:GetService("Stats")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local VirtualUser = game:GetService("VirtualUser")

local LocalPlayer = Players.LocalPlayer

-- Fast Localizations
local os_clock = os.clock
local math_round = math.round
local math_clamp = math.clamp
local math_floor = math.floor
local string_format = string.format
local Vector3_zero = Vector3.zero

--------------------------------------------------------------------------------
-- 1. TAB CREATION
--------------------------------------------------------------------------------
local TabExtras = KillerHub:CreateTab("Extras", "Code")
local TabAutoFarm = KillerHub:CreateTab("Auto Farm", "Robot")

--------------------------------------------------------------------------------
-- EXTRAS MODULE STATE & LOGIC
--------------------------------------------------------------------------------
local function FormatTime(seconds)
    local mins = math_floor(seconds / 60)
    local secs = math_floor(seconds % 60)
    return string_format("%02d:%02d", math.max(0, mins), math.max(0, secs))
end

-- System Performance Overlay
local statsConnection = nil
local statsGui = nil
local statsFrame = nil
local statsBgTransparency = 0.25

local function CleanUpPerfOverlay()
    if statsConnection then
        statsConnection:Disconnect()
        statsConnection = nil
    end
    if statsGui then
        statsGui:Destroy()
        statsGui = nil
        statsFrame = nil
    end
end

-- Round Time UI
local RoundTimerGui = nil
local RoundTimerConnection = nil

local function CreateTimerUI()
    if RoundTimerGui then RoundTimerGui:Destroy() end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "KillerHub_RoundTimer"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local TimeLabel = Instance.new("TextLabel")
    TimeLabel.Name = "TimeText"
    TimeLabel.Size = UDim2.new(0, 250, 0, 40)
    TimeLabel.Position = UDim2.new(0.5, -125, 0, -5)
    TimeLabel.BackgroundTransparency = 1
    TimeLabel.Font = Enum.Font.SciFi
    TimeLabel.TextSize = 38
    TimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    TimeLabel.TextStrokeTransparency = 0.3
    TimeLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    TimeLabel.Text = ""
    TimeLabel.Visible = false
    TimeLabel.Parent = ScreenGui

    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = CoreGui
    elseif gethui then
        ScreenGui.Parent = gethui()
    else
        ScreenGui.Parent = CoreGui
    end

    RoundTimerGui = ScreenGui
    return TimeLabel
end

local function RemoveTimerUI()
    if RoundTimerGui then
        RoundTimerGui:Destroy()
        RoundTimerGui = nil
    end
end

-- Knife ESP Logic
local KnifeESP_Connection = nil
local KnifeWorkspaceConnection = nil
local ActiveKnifeAdornments = {}

local function ClearKnifeESP()
    for part, adornment in pairs(ActiveKnifeAdornments) do
        if adornment then adornment:Destroy() end
    end
    table.clear(ActiveKnifeAdornments)
end

local function CreateKnifeBox(targetPart)
    if not targetPart or ActiveKnifeAdornments[targetPart] then return end

    local box = Instance.new("BoxHandleAdornment")
    box.Name = "KillerHub_CleanKnifeBox"
    box.Color3 = Color3.fromRGB(0, 255, 100)
    box.Transparency = 0.3
    box.AlwaysOnTop = true
    box.ZIndex = 5

    if targetPart:IsA("BasePart") then
        box.Size = targetPart.Size + Vector3.new(0.3, 0.3, 0.3)
    else
        box.Size = Vector3.new(1.2, 2.5, 1.2)
    end

    box.Adornee = targetPart

    if syn and syn.protect_gui then
        syn.protect_gui(box)
        box.Parent = CoreGui
    elseif gethui then
        box.Parent = gethui()
    else
        box.Parent = CoreGui
    end

    ActiveKnifeAdornments[targetPart] = box
end

local function ProcessPartOrModel(obj)
    if not obj then return nil end
    if obj:IsA("BasePart") then
        return obj
    elseif obj:IsA("Model") or obj:IsA("Tool") then
        local handle = obj:FindFirstChild("Handle") or obj.PrimaryPart
        if handle and handle:IsA("BasePart") then
            return handle
        end
        for _, child in ipairs(obj:GetChildren()) do
            if child:IsA("BasePart") then
                return child
            end
        end
    end
    return nil
end

local function IsPartEquippedOrInWorkspace(part)
    if not part or not part.Parent then return false end
    local tool = part:FindFirstAncestorOfClass("Tool")
    if tool then
        local character = tool.Parent
        if character and character:FindFirstChildOfClass("Humanoid") then
            return true
        end
        return false
    end
    return part:IsDescendantOf(Workspace)
end

-- Traps ESP Logic
local TrapsESP_Connection = nil
local TrapsWorkspaceConnection = nil
local ActiveTrapAdornments = {}

local function ClearTrapsESP()
    for part, adornment in pairs(ActiveTrapAdornments) do
        if adornment then adornment:Destroy() end
    end
    table.clear(ActiveTrapAdornments)
end

local function CreateTrapBox(targetPart)
    if not targetPart or ActiveTrapAdornments[targetPart] then return end

    local box = Instance.new("BoxHandleAdornment")
    box.Name = "KillerHub_TrapBox"
    box.Color3 = Color3.fromRGB(255, 30, 30)
    box.Transparency = 0.3
    box.AlwaysOnTop = true
    box.ZIndex = 5

    if targetPart:IsA("BasePart") then
        box.Size = targetPart.Size + Vector3.new(0.4, 0.4, 0.4)
    else
        box.Size = Vector3.new(2, 2, 2)
    end

    box.Adornee = targetPart

    if syn and syn.protect_gui then
        syn.protect_gui(box)
        box.Parent = CoreGui
    elseif gethui then
        box.Parent = gethui()
    else
        box.Parent = CoreGui
    end

    ActiveTrapAdornments[targetPart] = box
end

-- No Lights Logic
local NoLightsConnection = nil
local OriginalMaterials = {}
local OriginalLightProps = {}
local OriginalLightingProps = {}

local function RemoveBrightGlaring(inst)
    if inst:IsA("BasePart") and inst.Material == Enum.Material.Neon then
        if not OriginalMaterials[inst] then
            OriginalMaterials[inst] = inst.Material
        end
        inst.Material = Enum.Material.SmoothPlastic
    elseif inst:IsA("Light") then
        if not OriginalLightProps[inst] then
            OriginalLightProps[inst] = inst.Brightness
        end
        if inst.Brightness > 1.2 then
            inst.Brightness = 0.8
        end
    end
end

local function ApplyNoLightsSettings()
    OriginalLightingProps.OutdoorAmbient = Lighting.OutdoorAmbient
    OriginalLightingProps.Brightness = Lighting.Brightness

    local curOutdoor = Lighting.OutdoorAmbient
    Lighting.OutdoorAmbient = Color3.fromRGB(
        math_clamp(math_floor(curOutdoor.R * 255 * 0.55), 70, 255),
        math_clamp(math_floor(curOutdoor.G * 255 * 0.55), 70, 255),
        math_clamp(math_floor(curOutdoor.B * 255 * 0.55), 70, 255)
    )
    
    if Lighting.Brightness > 1.0 then
        Lighting.Brightness = 1.0
    end
end

local function RestoreOriginalLights()
    for part, mat in pairs(OriginalMaterials) do
        if part and part.Parent then
            part.Material = mat
        end
    end
    table.clear(OriginalMaterials)

    for light, brightness in pairs(OriginalLightProps) do
        if light and light.Parent then
            light.Brightness = brightness
        end
    end
    table.clear(OriginalLightProps)

    if OriginalLightingProps.OutdoorAmbient then
        Lighting.OutdoorAmbient = OriginalLightingProps.OutdoorAmbient
    end
    if OriginalLightingProps.Brightness then
        Lighting.Brightness = OriginalLightingProps.Brightness
    end
    table.clear(OriginalLightingProps)
end

--------------------------------------------------------------------------------
-- EXTRAS CONTROLS
--------------------------------------------------------------------------------
TabExtras:CreateSection("Performance")

TabExtras:CreateToggle("Extras_PerformanceStats", "Show Stats", function(estado)
    CleanUpPerfOverlay()
    
    if estado then
        statsGui = Instance.new("ScreenGui")
        statsGui.Name = "KillerHub_PerformanceOverlay"
        statsGui.ResetOnSpawn = false

        statsFrame = Instance.new("Frame")
        statsFrame.Size = UDim2.new(0, 155, 0, 72)
        statsFrame.Position = UDim2.new(1, -162, 0, 2)
        statsFrame.BackgroundColor3 = Color3.fromRGB(12, 4, 22)
        statsFrame.BackgroundTransparency = statsBgTransparency
        statsFrame.BorderSizePixel = 0

        local Corner = Instance.new("UICorner")
        Corner.CornerRadius = UDim.new(0, 8)
        Corner.Parent = statsFrame

        local Stroke = Instance.new("UIStroke")
        Stroke.Thickness = 1.2
        Stroke.Color = Color3.fromRGB(40, 15, 65)
        Stroke.Parent = statsFrame

        local TextLabel = Instance.new("TextLabel")
        TextLabel.Size = UDim2.new(1, -10, 1, -6)
        TextLabel.Position = UDim2.new(0, 8, 0, 3)
        TextLabel.BackgroundTransparency = 1
        TextLabel.TextXAlignment = Enum.TextXAlignment.Left
        TextLabel.Font = Enum.Font.GothamBold
        TextLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
        TextLabel.TextSize = 12
        TextLabel.LineHeight = 1.25
        TextLabel.RichText = true
        TextLabel.Text = "Loading..."
        TextLabel.Parent = statsFrame

        statsFrame.Parent = statsGui

        if syn and syn.protect_gui then
            syn.protect_gui(statsGui)
            statsGui.Parent = CoreGui
        elseif gethui then
            statsGui.Parent = gethui()
        else
            statsGui.Parent = CoreGui
        end

        local lastTime = os_clock()
        local frameCount = 0
        local currentFps = 60
        local pingObject = nil
        pcall(function() pingObject = StatsService.Network.ServerStatsItem["Data Ping"] end)

        statsConnection = RunService.Heartbeat:Connect(function()
            frameCount = frameCount + 1
            local currentTime = os_clock()
            
            if currentTime - lastTime >= 0.4 then
                currentFps = math_round(frameCount / (currentTime - lastTime))
                frameCount = 0
                lastTime = currentTime
                
                local ping = 0
                if pingObject then
                    pcall(function() ping = math_round(pingObject:GetValue()) end)
                elseif LocalPlayer then
                    pcall(function() ping = math_round(LocalPlayer:GetNetworkPing() * 1000) end)
                end
                
                local memoria = math_round(StatsService:GetTotalMemoryUsageMb())
                
                TextLabel.Text = string_format(
                    "FPS: <font color=\"rgb(160,60,255)\">%d</font>\nPING: <font color=\"rgb(0,255,120)\">%d ms</font>\nRAM: <font color=\"rgb(240,240,240)\">%d MB</font>",
                    currentFps,
                    ping,
                    memoria
                )
            end
        end)
    end
end)

TabExtras:CreateSlider("Extras_StatsOpacity", "BG Opacity (%)", 0, 100, function(valor)
    statsBgTransparency = valor / 100
    if statsFrame then
        statsFrame.BackgroundTransparency = statsBgTransparency
    end
end)

TabExtras:CreateSection("Round Info")

TabExtras:CreateToggle("Extras_ShowRoundTime", "Round Time", function(enabled)
    if enabled then
        local label = CreateTimerUI()
        local zeroTime = nil
        local lastCheck = 0

        RoundTimerConnection = RunService.Heartbeat:Connect(function()
            if os_clock() - lastCheck < 0.25 then return end
            lastCheck = os_clock()

            local timerPart = Workspace:FindFirstChild("RoundTimerPart")
            if timerPart then
                local secondsRemaining = timerPart:GetAttribute("Time")
                if secondsRemaining and tonumber(secondsRemaining) and secondsRemaining > 0 then
                    zeroTime = nil
                    label.Visible = true
                    label.Text = FormatTime(secondsRemaining)
                    label.TextColor3 = Color3.fromRGB(255, 255, 255)
                    return
                end
            end

            if not zeroTime then
                zeroTime = tick()
            end

            if tick() - zeroTime <= 10 then
                label.Visible = true
                label.Text = "00:00"
                label.TextColor3 = Color3.fromRGB(255, 40, 40)
            else
                label.Visible = false
            end
        end)
    else
        if RoundTimerConnection then
            RoundTimerConnection:Disconnect()
            RoundTimerConnection = nil
        end
        RemoveTimerUI()
    end
end)

TabExtras:CreateSection("Visuals")

TabExtras:CreateToggle("Extras_NoLights", "No lights", function(enabled)
    if enabled then
        ApplyNoLightsSettings()
        
        task.spawn(function()
            local descendants = Workspace:GetDescendants()
            for i = 1, #descendants do
                RemoveBrightGlaring(descendants[i])
                if i % 400 == 0 then
                    task.wait()
                end
            end
        end)

        NoLightsConnection = Workspace.DescendantAdded:Connect(function(desc)
            task.spawn(function()
                RemoveBrightGlaring(desc)
            end)
        end)
    else
        if NoLightsConnection then
            NoLightsConnection:Disconnect()
            NoLightsConnection = nil
        end
        RestoreOriginalLights()
    end
end)

TabExtras:CreateToggle("Extras_SeeKnifeESP", "Knife ESP", function(enabled)
    if enabled then
        local lastScan = 0
        KnifeESP_Connection = RunService.Heartbeat:Connect(function()
            if os_clock() - lastScan < 0.2 then return end
            lastScan = os_clock()

            local currentTargets = {}

            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local char = player.Character
                    if char then
                        local knifeTool = char:FindFirstChild("Knife")
                        if knifeTool then
                            local validPart = ProcessPartOrModel(knifeTool)
                            if validPart then
                                currentTargets[validPart] = true
                            end
                        end
                    end
                end
            end

            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj.Name == "Knife" or obj.Name == "FlyingKnife" or obj:GetAttribute("ThrowSpeed") or obj:FindFirstChild("KnifeClient") then
                    local validPart = ProcessPartOrModel(obj)
                    if validPart then
                        currentTargets[validPart] = true
                    end
                end
            end

            for part, adornment in pairs(ActiveKnifeAdornments) do
                if not currentTargets[part] or not IsPartEquippedOrInWorkspace(part) then
                    adornment:Destroy()
                    ActiveKnifeAdornments[part] = nil
                end
            end

            for part in pairs(currentTargets) do
                if not ActiveKnifeAdornments[part] and IsPartEquippedOrInWorkspace(part) then
                    CreateKnifeBox(part)
                end
            end
        end)

        KnifeWorkspaceConnection = Workspace.ChildAdded:Connect(function(child)
            task.spawn(function()
                if child.Name == "Knife" or child.Name == "FlyingKnife" or child:GetAttribute("ThrowSpeed") or child:FindFirstChild("KnifeClient") then
                    local validPart = ProcessPartOrModel(child)
                    local attempts = 0
                    while not validPart and attempts < 8 do
                        task.wait(0.05)
                        attempts = attempts + 1
                        validPart = ProcessPartOrModel(child)
                    end
                    if validPart and IsPartEquippedOrInWorkspace(validPart) then
                        CreateKnifeBox(validPart)
                    end
                end
            end)
        end)
    else
        if KnifeESP_Connection then
            KnifeESP_Connection:Disconnect()
            KnifeESP_Connection = nil
        end
        if KnifeWorkspaceConnection then
            KnifeWorkspaceConnection:Disconnect()
            KnifeWorkspaceConnection = nil
        end
        ClearKnifeESP()
    end
end)

TabExtras:CreateToggle("Extras_SeeTraps", "Traps ESP", function(enabled)
    if enabled then
        local lastScan = 0
        TrapsESP_Connection = RunService.Heartbeat:Connect(function()
            if os_clock() - lastScan < 0.5 then return end
            lastScan = os_clock()

            local currentTraps = {}
            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj.Name == "Trap" and (obj:IsA("Model") or obj:IsA("BasePart")) then
                    local validPart = ProcessPartOrModel(obj)
                    if validPart then
                        currentTraps[validPart] = true
                    end
                end
            end

            for part, adornment in pairs(ActiveTrapAdornments) do
                if not currentTraps[part] or not part.Parent then
                    adornment:Destroy()
                    ActiveTrapAdornments[part] = nil
                end
            end

            for part in pairs(currentTraps) do
                if not ActiveTrapAdornments[part] then
                    CreateTrapBox(part)
                end
            end
        end)

        TrapsWorkspaceConnection = Workspace.ChildAdded:Connect(function(child)
            if child.Name == "Trap" then
                task.spawn(function()
                    local validPart = ProcessPartOrModel(child)
                    local attempts = 0
                    while not validPart and attempts < 8 do
                        task.wait(0.05)
                        attempts = attempts + 1
                        validPart = ProcessPartOrModel(child)
                    end
                    if validPart and validPart:IsDescendantOf(Workspace) then
                        CreateTrapBox(part)
                    end
                end)
            end
        end)
    else
        if TrapsESP_Connection then
            TrapsESP_Connection:Disconnect()
            TrapsESP_Connection = nil
        end
        if TrapsWorkspaceConnection then
            TrapsWorkspaceConnection:Disconnect()
            TrapsWorkspaceConnection = nil
        end
        ClearTrapsESP()
    end
end)

--------------------------------------------------------------------------------
-- AUTOFARM MODULE STATE & LOGIC (ACCURATE PLAYER DATA DETECTION)
--------------------------------------------------------------------------------
local autoFarmEnabled = false
local autoResetEnabled = false
local antiAfkEnabled = false
local farmSpeed = 28.05

local roundInService = false
local resetting = false
local isBagFullState = false
local farmThread = nil
local activeTween = nil

-- ESTADOS EXTRAÍDOS DE PlayerDataChanged
local myRole = nil
local myDeadState = false

local connections = {}
local idledConnection = nil
local noclipConnection = nil

local function getHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function isPlayerAlive()
    local hum = getHumanoid()
    local hrp = getHRP()
    return hum and hum.Health > 0 and hrp and hrp.Parent ~= nil
end

-- VERIFICACIÓN ESTRICTA DE ROL Y ESTADO MUERTO
local function hasValidActiveRole()
    if myDeadState == true then return false end
    if not myRole or myRole == "" or myRole == "None" or myRole == "Spectator" then
        return false
    end
    -- Roles permitidos en partida
    return myRole == "Innocent" or myRole == "Sheriff" or myRole == "Hero" or myRole == "Murderer"
end

local function getCoinContainer()
    local container = Workspace:FindFirstChild("CoinContainer")
    if container then return container end

    for _, obj in ipairs(Workspace:GetChildren()) do
        if obj.Name == "Coins" or obj:FindFirstChild("CoinContainer") then
            return obj.Name == "CoinContainer" and obj or (obj:FindFirstChild("CoinContainer") or obj)
        end
    end
    return nil
end

local function isPlayerInLobby()
    local hrp = getHRP()
    if not hrp then return true end

    local lobby = Workspace:FindFirstChild("Lobby") or Workspace:FindFirstChild("LobbyMap")
    if lobby then
        local lobbyPart = lobby:FindFirstChildOfClass("BasePart") or lobby.PrimaryPart
        if lobbyPart then
            return (hrp.Position - lobbyPart.Position).Magnitude < 180
        end
    end

    local container = getCoinContainer()
    return container == nil or #container:GetChildren() == 0
end

local function canFarmRightNow()
    return isPlayerAlive() and hasValidActiveRole() and not isPlayerInLobby()
end

local function toggleNoclip(state)
    if state then
        if not noclipConnection then
            noclipConnection = RunService.Stepped:Connect(function()
                if autoFarmEnabled and canFarmRightNow() and not isBagFullState and not resetting then
                    local char = LocalPlayer.Character
                    if char then
                        for _, part in ipairs(char:GetChildren()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end
                end
            end)
        end
    else
        if noclipConnection then
            noclipConnection:Disconnect()
            noclipConnection = nil
        end
    end
end

local function getNearestCoin()
    local hrp = getHRP()
    if not hrp then return nil, math.huge end

    local container = getCoinContainer()
    if not container then return nil, math.huge end

    local closest, minDist = nil, math.huge
    local coins = container:GetChildren()
    for i = 1, #coins do
        local coin = coins[i]
        if coin:IsA("BasePart") and coin.Parent and coin:FindFirstChild("TouchInterest") then
            local dist = (hrp.Position - coin.Position).Magnitude
            if dist < minDist then
                closest = coin
                minDist = dist
            end
        end
    end
    return closest, minDist
end

local function doAutoReset()
    if resetting then return end
    resetting = true
    roundInService = false
    isBagFullState = false
    toggleNoclip(false)
    
    if activeTween then
        activeTween:Cancel()
        activeTween = nil
    end

    task.wait(0.1)
    local char = LocalPlayer.Character
    if char then
        char:BreakJoints()
    end
    
    task.wait(1.2)
    resetting = false
end

-- ESCUCHA DE EVENTOS REMOTOS Y PlayerDataChanged
pcall(function()
    local gameplayRemotes = ReplicatedStorage:WaitForChild("Remotes", 3):WaitForChild("Gameplay", 3)
    local PlayerDataChanged = gameplayRemotes and gameplayRemotes:FindFirstChild("PlayerDataChanged")
    local RoundStart = gameplayRemotes and gameplayRemotes:FindFirstChild("RoundStart")
    local RoundEnd = gameplayRemotes and (gameplayRemotes:FindFirstChild("RoundEndFade") or gameplayRemotes:FindFirstChild("RoundEnd"))
    local CoinCollected = gameplayRemotes and gameplayRemotes:FindFirstChild("CoinCollected")

    -- ESCUCHA DE ROLES EN PlayerDataChanged
    if PlayerDataChanged then
        table.insert(connections, PlayerDataChanged.OnClientEvent:Connect(function(dataData)
            if typeof(dataData) == "table" and LocalPlayer then
                local myData = dataData[LocalPlayer.Name]
                if myData then
                    if myData["Role"] ~= nil then
                        myRole = myData["Role"]
                    end
                    if myData["Dead"] ~= nil then
                        myDeadState = myData["Dead"]
                    end

                    -- Si acabamos de morir según el servidor, congelar inmediatamente el farm
                    if myDeadState == true then
                        roundInService = false
                        toggleNoclip(false)
                        if activeTween then
                            activeTween:Cancel()
                            activeTween = nil
                        end
                    end
                end
            end
        end))
    end
    
    if RoundStart then
        table.insert(connections, RoundStart.OnClientEvent:Connect(function()
            task.wait(0.5)
            if canFarmRightNow() then
                roundInService = true
                resetting = false
                isBagFullState = false
                if autoFarmEnabled then
                    toggleNoclip(true)
                end
            else
                roundInService = false
            end
        end))
    end

    if RoundEnd then
        table.insert(connections, RoundEnd.OnClientEvent:Connect(function()
            roundInService = false
            isBagFullState = false
            myRole = nil
            myDeadState = true
            toggleNoclip(false)
            if activeTween then activeTween:Cancel() end
        end))
    end

    if CoinCollected then
        table.insert(connections, CoinCollected.OnClientEvent:Connect(function(_, currentCoins, maxCoins)
            if typeof(currentCoins) == "number" and typeof(maxCoins) == "number" then
                if currentCoins >= maxCoins and maxCoins > 0 then
                    isBagFullState = true
                    toggleNoclip(false)
                end
            end
        end))
    end
end)

local function setupCharacter(char)
    local hum = char:WaitForChild("Humanoid", 3)
    if hum then
        hum.Died:Connect(function()
            myDeadState = true
            roundInService = false
            isBagFullState = false
            toggleNoclip(false)
            if activeTween then 
                activeTween:Cancel()
                activeTween = nil 
            end
        end)
    end
end

if LocalPlayer.Character then setupCharacter(LocalPlayer.Character) end
table.insert(connections, LocalPlayer.CharacterAdded:Connect(setupCharacter))

-- LOOP PRINCIPAL DE AUTO FARM (PERFECTAMENTE CONTROLADO POR ROL)
local function startFarmLoop()
    if farmThread then return end
    
    farmThread = task.spawn(function()
        while autoFarmEnabled do
            if not resetting then
                if autoResetEnabled and isBagFullState then
                    doAutoReset()
                elseif canFarmRightNow() and not isBagFullState then
                    roundInService = true
                    toggleNoclip(true)

                    local coin, dist = getNearestCoin()
                    local hrp = getHRP()

                    if coin and canFarmRightNow() and hrp then
                        local timeToReach = math_clamp(dist / math_clamp(farmSpeed, 15, 35), 0.05, 2.5)
                        local tweenInfo = TweenInfo.new(timeToReach, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
                        local targetCFrame = coin.CFrame * CFrame.new(0, 1.2, 0)
                        
                        activeTween = TweenService:Create(hrp, tweenInfo, {CFrame = targetCFrame})
                        activeTween:Play()

                        local startTime = os_clock()
                        local coinTimeout = math.min(timeToReach + 0.3, 1.5)

                        repeat
                            local touch = coin:FindFirstChild("TouchInterest")
                            if touch and (hrp.Position - coin.Position).Magnitude < 4.5 then
                                if firetouchinterest then
                                    pcall(function()
                                        firetouchinterest(hrp, coin, 0)
                                        task.wait(0.01)
                                        firetouchinterest(hrp, coin, 1)
                                    end)
                                end
                            end

                            task.wait(0.03)
                        until not coin 
                           or not coin.Parent 
                           or not coin:FindFirstChild("TouchInterest") 
                           or not autoFarmEnabled 
                           or not canFarmRightNow()
                           or resetting 
                           or isBagFullState
                           or (os_clock() - startTime) >= coinTimeout
                        
                        if activeTween then
                            activeTween:Cancel()
                            activeTween = nil
                        end

                        if hrp then
                            hrp.AssemblyLinearVelocity = Vector3_zero
                            hrp.AssemblyAngularVelocity = Vector3_zero
                        end
                    else
                        task.wait(0.2)
                    end
                else
                    roundInService = false
                    toggleNoclip(false)
                    if activeTween then
                        activeTween:Cancel()
                        activeTween = nil
                    end
                end
            else
                if activeTween then
                    activeTween:Cancel()
                    activeTween = nil
                end
            end
            
            task.wait(0.05)
        end
        
        roundInService = false
        toggleNoclip(false)
        if activeTween then activeTween:Cancel() end
        farmThread = nil
    end)
end

--------------------------------------------------------------------------------
-- AUTOFARM CONTROLS
--------------------------------------------------------------------------------
TabAutoFarm:CreateSection("Coin Farming")

TabAutoFarm:CreateToggle("Farm_Coins", "Auto Farm", function(state)
    autoFarmEnabled = state
    if state then
        startFarmLoop()
    else
        roundInService = false
        isBagFullState = false
        toggleNoclip(false)
        if activeTween then 
            activeTween:Cancel()
            activeTween = nil
        end
    end
end)

TabAutoFarm:CreateToggle("Farm_ResetFull", "Auto Reset", function(state)
    autoResetEnabled = state
end)

TabAutoFarm:CreateParagraph("⚠️ WARNING", "It is recommended to keep the farm speed at default or slightly lower. Going too fast will trigger invalid position detection and disconnect you frequently.")

TabAutoFarm:CreateSlider("Farm_Speed", "Farm Speed", 15, 35, function(value)
    farmSpeed = value
end)

TabAutoFarm:CreateSection("Utilities")

TabAutoFarm:CreateToggle("Farm_AntiAFK", "Anti-AFK", function(state)
    antiAfkEnabled = state
    if state then
        if not idledConnection then
            idledConnection = LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
    else
        if idledConnection then
            idledConnection:Disconnect()
            idledConnection = nil
        end
    end
end)

--------------------------------------------------------------------------------
-- CLEANUP TASK
--------------------------------------------------------------------------------
KillerHub:AddTask(function()
    CleanUpPerfOverlay()
    if RoundTimerConnection then RoundTimerConnection:Disconnect() RoundTimerConnection = nil end
    if KnifeESP_Connection then KnifeESP_Connection:Disconnect() KnifeESP_Connection = nil end
    if KnifeWorkspaceConnection then KnifeWorkspaceConnection:Disconnect() KnifeWorkspaceConnection = nil end
    if TrapsESP_Connection then TrapsESP_Connection:Disconnect() TrapsESP_Connection = nil end
    if TrapsWorkspaceConnection then TrapsWorkspaceConnection:Disconnect() TrapsWorkspaceConnection = nil end
    if NoLightsConnection then NoLightsConnection:Disconnect() NoLightsConnection = nil end
    RestoreOriginalLights()
    RemoveTimerUI()
    ClearKnifeESP()
    ClearTrapsESP()

    autoFarmEnabled = false
    roundInService = false
    isBagFullState = false
    myRole = nil
    myDeadState = true
    if activeTween then activeTween:Cancel() end
    toggleNoclip(false)
    if idledConnection then
        idledConnection:Disconnect()
        idledConnection = nil
    end
    for _, conn in ipairs(connections) do
        if conn then conn:Disconnect() end
    end
    table.clear(connections)

    getgenv().__KillerHub_Combined_Loaded = nil
end)

-- Notification
KillerHub:NotifySuccess("Killer Hub", "script working correctly", 3)

return KillerHub
