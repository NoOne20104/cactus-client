-- NoClip Module (Cactus Client)
-- Testing-only, dev-friendly, observable

local NoClip = {}

function NoClip.Init(Client)

    local Players = Client.Services.Players
    local RunService = Client.Services.RunService
    local LocalPlayer = Client.Player
    local Page = Client.Pages.NoClip
    local Theme = Client.Theme
    local State = Client.State

    -- =========================
    -- State
    -- =========================

    State.NoClip = {
        Enabled = false,
        StartTime = 0,
        PartsAffected = 0,
        Blocked = false,
        BlockReason = nil
    }

    local conn = nil

    -- =========================
    -- Safety check (testing only)
    -- =========================

    local function canUse()
        if State.TestingOnly and not State.TestingOnly() then
            State.NoClip.Blocked = true
            State.NoClip.BlockReason = "Not in testing place"
            return false
        end
        State.NoClip.Blocked = false
        State.NoClip.BlockReason = nil
        return true
    end

    -- =========================
    -- Core logic
    -- =========================

    local function setCollisions(enabled)
        local char = LocalPlayer.Character
        if not char then return end

        local count = 0
        for _, v in ipairs(char:GetDescendants()) do
            if v:IsA("BasePart") then
                v.CanCollide = enabled
                count += 1
            end
        end

        State.NoClip.PartsAffected = count
    end

    local function enable()
        if State.NoClip.Enabled then return end
        if not canUse() then return end

        State.NoClip.Enabled = true
        State.NoClip.StartTime = os.clock()

        conn = RunService.Stepped:Connect(function()
            setCollisions(false)
        end)
    end

    local function disable()
        if not State.NoClip.Enabled then return end

        State.NoClip.Enabled = false
        setCollisions(true)

        if conn then
            conn:Disconnect()
            conn = nil
        end
    end

    -- =========================
    -- GUI (same style as others)
    -- =========================

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 140)
    frame.Position = UDim2.new(0, 10, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(14,14,14)
    frame.BorderSizePixel = 0
    frame.Parent = Page
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Theme.STROKE
    stroke.Transparency = 0.4

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,30)
    title.BackgroundTransparency = 1
    title.Text = "NoClip"
    title.Font = Enum.Font.Code
    title.TextSize = 16
    title.TextColor3 = Theme.TEXT
    title.Parent = frame

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1,-20,0,30)
    toggleBtn.Position = UDim2.new(0,10,0,40)
    toggleBtn.BackgroundColor3 = Theme.BUTTON
    toggleBtn.Text = "Enable"
    toggleBtn.Font = Enum.Font.Code
    toggleBtn.TextSize = 14
    toggleBtn.TextColor3 = Theme.TEXT_DIM
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Parent = frame
    Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,6)

    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1,-20,0,40)
    statusLabel.Position = UDim2.new(0,10,0,80)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Font = Enum.Font.Code
    statusLabel.TextSize = 13
    statusLabel.TextXAlignment = Enum.TextXAlignment.Left
    statusLabel.TextYAlignment = Enum.TextYAlignment.Top
    statusLabel.TextColor3 = Theme.TEXT_DIM
    statusLabel.Parent = frame

    -- =========================
    -- UI logic
    -- =========================

    toggleBtn.MouseButton1Click:Connect(function()
        if State.NoClip.Enabled then
            disable()
        else
            enable()
        end
    end)

    RunService.RenderStepped:Connect(function()
        if State.NoClip.Blocked then
            statusLabel.Text =
                "Status: BLOCKED\n" ..
                "Reason: " .. tostring(State.NoClip.BlockReason)
            toggleBtn.Text = "Unavailable"
            return
        end

        if State.NoClip.Enabled then
            toggleBtn.Text = "Disable"
            statusLabel.Text =
                "Status: ON\n" ..
                "Parts: " .. State.NoClip.PartsAffected .. "\n" ..
                "Time: " .. math.floor(os.clock() - State.NoClip.StartTime) .. "s"
        else
            toggleBtn.Text = "Enable"
            statusLabel.Text = "Status: OFF"
        end
    end)

end

return NoClip
