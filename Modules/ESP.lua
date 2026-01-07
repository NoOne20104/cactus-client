-- Cactus ESP Module
-- Bottom screen tracers, neon green, dev-style

local ESP = {}

function ESP.Init(Client)

    local Players = Client.Services.Players
    local RunService = Client.Services.RunService
    local LocalPlayer = Client.Player
    local Page = Client.Pages.ESP
    local Theme = Client.Theme
    local Camera = workspace.CurrentCamera

    -- =========================
    -- State
    -- =========================

    local ESPState = {
        Enabled = false,
        Tracers = true,
        TeamCheck = false,
    }

    local drawings = {}

    -- =========================
    -- Drawing helpers
    -- =========================

    local function newTracer()
        local line = Drawing.new("Line")
        line.Visible = false
        line.Thickness = 1.5
        line.Transparency = 1
        line.Color = Color3.fromRGB(0, 255, 140) -- neon cactus green
        return line
    end

    local function removePlayer(plr)
        if drawings[plr] then
            for _, obj in pairs(drawings[plr]) do
                pcall(function() obj:Remove() end)
            end
            drawings[plr] = nil
        end
    end

    local function setupPlayer(plr)
        if plr == LocalPlayer then return end
        drawings[plr] = {
            Tracer = newTracer()
        }
    end

    -- =========================
    -- ESP update loop
    -- =========================

    RunService.RenderStepped:Connect(function()

        if not ESPState.Enabled then
            for _, data in pairs(drawings) do
                data.Tracer.Visible = false
            end
            return
        end

        local screenBottom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and drawings[plr] then

                local char = plr.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                local tracer = drawings[plr].Tracer

                if hrp then
                    local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)

                    if onScreen then
                        tracer.From = screenBottom
                        tracer.To = Vector2.new(pos.X, pos.Y)
                        tracer.Visible = ESPState.Tracers
                    else
                        tracer.Visible = false
                    end
                else
                    tracer.Visible = false
                end
            end
        end
    end)

    -- =========================
    -- Player handling
    -- =========================

    for _, plr in ipairs(Players:GetPlayers()) do
        setupPlayer(plr)
    end

    Players.PlayerAdded:Connect(setupPlayer)
    Players.PlayerRemoving:Connect(removePlayer)

    -- =========================
    -- UI
    -- =========================

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 170)
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
    title.Text = "ESP"
    title.Font = Enum.Font.Code
    title.TextSize = 16
    title.TextColor3 = Theme.TEXT
    title.Parent = frame

    local function makeButton(text, y)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1,-20,0,30)
        b.Position = UDim2.new(0,10,0,y)
        b.BackgroundColor3 = Theme.BUTTON
        b.Text = text
        b.Font = Enum.Font.Code
        b.TextSize = 14
        b.TextColor3 = Theme.TEXT_DIM
        b.BorderSizePixel = 0
        b.Parent = frame
        Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
        return b
    end

    local espBtn     = makeButton("ESP: OFF", 40)
    local tracerBtn  = makeButton("Tracers: ON", 75)

    -- =========================
    -- UI logic
    -- =========================

    espBtn.MouseButton1Click:Connect(function()
        ESPState.Enabled = not ESPState.Enabled
        espBtn.Text = ESPState.Enabled and "ESP: ON" or "ESP: OFF"
    end)

    tracerBtn.MouseButton1Click:Connect(function()
        ESPState.Tracers = not ESPState.Tracers
        tracerBtn.Text = ESPState.Tracers and "Tracers: ON" or "Tracers: OFF"
    end)

end

return ESP
