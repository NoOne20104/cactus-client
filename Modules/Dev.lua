-- Dev Menu Module (Cactus Client)

local Dev = {}

function Dev.Init(Client)

    local Players = Client.Services.Players
    local RunService = Client.Services.RunService
    local LocalPlayer = Client.Player
    local Page = Client.Pages.Dev
    local Theme = Client.Theme

    local startTime = os.clock()
    local fps = 0
    local frames = 0
    local lastFpsUpdate = os.clock()

    -- =========================
    -- UI
    -- =========================

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 200)
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
    title.Text = "Dev"
    title.Font = Enum.Font.Code
    title.TextSize = 16
    title.TextColor3 = Theme.TEXT
    title.Parent = frame

    local clientLabel = Instance.new("TextLabel")
    clientLabel.Size = UDim2.new(1,-20,0,50)
    clientLabel.Position = UDim2.new(0,10,0,34)
    clientLabel.BackgroundTransparency = 1
    clientLabel.Font = Enum.Font.Code
    clientLabel.TextSize = 13
    clientLabel.TextXAlignment = Enum.TextXAlignment.Left
    clientLabel.TextYAlignment = Enum.TextYAlignment.Top
    clientLabel.TextColor3 = Theme.TEXT_DIM
    clientLabel.Text = ""
    clientLabel.Parent = frame

    local playerLabel = Instance.new("TextLabel")
    playerLabel.Size = UDim2.new(1,-20,0,70)
    playerLabel.Position = UDim2.new(0,10,0,86)
    playerLabel.BackgroundTransparency = 1
    playerLabel.Font = Enum.Font.Code
    playerLabel.TextSize = 13
    playerLabel.TextXAlignment = Enum.TextXAlignment.Left
    playerLabel.TextYAlignment = Enum.TextYAlignment.Top
    playerLabel.TextColor3 = Theme.TEXT_DIM
    playerLabel.Text = ""
    playerLabel.Parent = frame

    local worldLabel = Instance.new("TextLabel")
    worldLabel.Size = UDim2.new(1,-20,0,40)
    worldLabel.Position = UDim2.new(0,10,0,158)
    worldLabel.BackgroundTransparency = 1
    worldLabel.Font = Enum.Font.Code
    worldLabel.TextSize = 13
    worldLabel.TextXAlignment = Enum.TextXAlignment.Left
    worldLabel.TextYAlignment = Enum.TextYAlignment.Top
    worldLabel.TextColor3 = Theme.TEXT_DIM
    worldLabel.Text = ""
    worldLabel.Parent = frame

    -- =========================
    -- Update loop
    -- =========================

    RunService.RenderStepped:Connect(function()
        frames += 1

        if os.clock() - lastFpsUpdate >= 1 then
            fps = frames
            frames = 0
            lastFpsUpdate = os.clock()
        end

        local uptime = os.clock() - startTime

        -- client
        clientLabel.Text =
            "Client\n" ..
            "FPS: " .. fps .. "\n" ..
            "Uptime: " .. string.format("%02d:%02d",
                math.floor(uptime/60),
                math.floor(uptime%60)
            )

        -- player
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local hrp = char and char:FindFirstChild("HumanoidRootPart")

        if hum and hrp then
            local pos = hrp.Position
            playerLabel.Text =
                "Player\n" ..
                string.format("Pos: %.1f, %.1f, %.1f\n", pos.X, pos.Y, pos.Z) ..
                "Health: " .. math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth) .. "\n" ..
                "Speed: " .. hum.WalkSpeed .. "\n" ..
                "State: " .. hum:GetState().Name
        else
            playerLabel.Text = "Player\nNo character"
        end

        -- world
worldLabel.Text =
    "World\n" ..
    "Players: " .. #Players:GetPlayers() .. "\n" ..
    "Gravity: " .. workspace.Gravity

--  NoClip telemetry (added)
local nc = Client.State.NoClip
if nc then
    worldLabel.Text = worldLabel.Text ..
        "\n\nNoClip\n" ..
        "Enabled: " .. tostring(nc.Enabled) .. "\n" ..
        "Parts: " .. tostring(nc.PartsAffected)
end
end)
