-- Phase.lua (Cactus Client Module)
-- Normal / Smart / Subtle phase movement system
-- + Visual on/off state

local Phase = {}

function Phase.Init(Client)

    local Players = Client.Services.Players
    local RunService = Client.Services.RunService
    local LocalPlayer = Client.Player
    local Page = Client.Pages.Phase
    local Theme = Client.Theme

    local humanoid
    local rootPart
    local character

    local enabled = false
    local currentMode = "off"
    local smartConn

    local cachedParts = {}

    print("[Cactus Phase] Loaded")

    -- =========================
    -- Character handling
    -- =========================

    local function cacheParts()
        cachedParts = {}
        if not character then return end
        for _,v in ipairs(character:GetDescendants()) do
            if v:IsA("BasePart") then
                cachedParts[v] = v.CanCollide
            end
        end
    end

    local function restoreCollision()
        for part,canCollide in pairs(cachedParts) do
            if part and part.Parent then
                part.CanCollide = canCollide
            end
        end
    end

    local function setAllCollision(state)
        if not character then return end
        for _,v in ipairs(character:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = state
            end
        end
    end

    local function setSubtleCollision()
        if not character then return end
        for _,v in ipairs(character:GetDescendants()) do
            if v:IsA("BasePart") then
                if v.Name == "HumanoidRootPart" or v.Name:lower():find("leg") then
                    v.CanCollide = true
                else
                    v.CanCollide = false
                end
            end
        end
    end

    local function getCharacter()
        character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        humanoid = character:WaitForChild("Humanoid")
        rootPart = character:WaitForChild("HumanoidRootPart")

        cacheParts()

        if enabled and currentMode ~= "off" then
            Phase.SetMode(currentMode, true)
        end
    end

    -- =========================
    -- Smart phase detection
    -- =========================

    local function startSmartPhase()
        if smartConn then smartConn:Disconnect() end

        smartConn = RunService.Heartbeat:Connect(function()
            if not rootPart then return end
            if not enabled or currentMode ~= "smart" then return end

            local params = RaycastParams.new()
            params.FilterDescendantsInstances = {character}
            params.FilterType = Enum.RaycastFilterType.Blacklist

            local forward = rootPart.CFrame.LookVector * 2
            local result = workspace:Raycast(rootPart.Position, forward, params)

            if result then
                setAllCollision(false)
            else
                restoreCollision()
            end
        end)
    end

    local function stopSmartPhase()
        if smartConn then
            smartConn:Disconnect()
            smartConn = nil
        end
    end

    -- =========================
    -- Core control
    -- =========================

    local function disablePhase()
        enabled = false
        currentMode = "off"
        stopSmartPhase()
        restoreCollision()
        if refreshUI then refreshUI() end
        print("[Cactus Phase] Disabled")
    end

    function Phase.SetMode(mode, force)
        if not force then
            if enabled and currentMode == mode then
                disablePhase()
                return
            end
        end

        enabled = true
        currentMode = mode

        stopSmartPhase()
        restoreCollision()

        if mode == "normal" then
            setAllCollision(false)
        elseif mode == "smart" then
            startSmartPhase()
        elseif mode == "subtle" then
            setSubtleCollision()
        end

        if refreshUI then refreshUI() end
        print("[Cactus Phase] Mode:", mode)
    end

    function Phase.Disable()
        disablePhase()
    end

    -- =========================
    -- GUI
    -- =========================

    local normalBtn, smartBtn, subtleBtn, offBtn

    function refreshUI()
        normalBtn.Text = "Normal Phase"
        smartBtn.Text  = "Smart Phase"
        subtleBtn.Text = "Subtle Phase"
        offBtn.Text    = "Disable Phase"

        if not enabled then
            offBtn.Text = "Phase: OFF"
            return
        end

        if currentMode == "normal" then
            normalBtn.Text = "Normal Phase  [ON]"
        elseif currentMode == "smart" then
            smartBtn.Text = "Smart Phase  [ON]"
        elseif currentMode == "subtle" then
            subtleBtn.Text = "Subtle Phase  [ON]"
        end
    end

    local function createGUI()

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 220, 0, 210)
        frame.Position = UDim2.new(0, 10, 0, 10)
        frame.BackgroundColor3 = Color3.fromRGB(14,14,14)
        frame.BorderSizePixel = 0
        frame.Parent = Page
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

        local stroke = Instance.new("UIStroke", frame)
        stroke.Color = Theme.STROKE
        stroke.Transparency = 0.4

        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, -10, 0, 28)
        title.Position = UDim2.new(0, 10, 0, 4)
        title.BackgroundTransparency = 1
        title.Text = "Phase"
        title.Font = Enum.Font.Code
        title.TextSize = 16
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.TextColor3 = Theme.TEXT
        title.Parent = frame

        local function makeButton(text, y)
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, -20, 0, 32)
            b.Position = UDim2.new(0, 10, 0, y)
            b.BackgroundColor3 = Theme.BUTTON
            b.Text = text
            b.Font = Enum.Font.Code
            b.TextSize = 14
            b.TextColor3 = Theme.TEXT_DIM
            b.BorderSizePixel = 0
            b.Parent = frame
            Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
            return b
        end

        normalBtn = makeButton("Normal Phase", 36)
        smartBtn  = makeButton("Smart Phase", 76)
        subtleBtn = makeButton("Subtle Phase", 116)
        offBtn    = makeButton("Disable Phase", 156)

        normalBtn.MouseButton1Click:Connect(function()
            Phase.SetMode("normal")
        end)

        smartBtn.MouseButton1Click:Connect(function()
            Phase.SetMode("smart")
        end)

        subtleBtn.MouseButton1Click:Connect(function()
            Phase.SetMode("subtle")
        end)

        offBtn.MouseButton1Click:Connect(function()
            Phase.Disable()
        end)

        refreshUI()
    end

    -- =========================
    -- Boot
    -- =========================

    getCharacter()
    createGUI()

    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(1)
        getCharacter()
        refreshUI()
    end)
end

return Phase
