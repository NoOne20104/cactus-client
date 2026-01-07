-- Player Teleport Module (Cactus Client)

local PlayerTP = {}

function PlayerTP.Init(Client)

    local Players = Client.Services.Players
    local LocalPlayer = Client.Player
    local Page = Client.Pages.Teleport
    local Theme = Client.Theme

    local selectedPlayer = nil

    -- =========================
    -- UI
    -- =========================

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 220, 0, 220)
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
    title.Text = "Player Teleport"
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

    local selectBtn = makeButton("Select Player", 40)
    local tpBtn     = makeButton("Teleport", 75)

    local selectedLabel = Instance.new("TextLabel")
    selectedLabel.Size = UDim2.new(1,-20,0,22)
    selectedLabel.Position = UDim2.new(0,10,0,110)
    selectedLabel.BackgroundTransparency = 1
    selectedLabel.Text = "Target: none"
    selectedLabel.Font = Enum.Font.Code
    selectedLabel.TextSize = 13
    selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
    selectedLabel.TextColor3 = Theme.TEXT_DIM
    selectedLabel.Parent = frame

    -- =========================
    -- Dropdown (attached to panel)
    -- =========================

    local dropdown = Instance.new("Frame")
    dropdown.Visible = false
    dropdown.Size = UDim2.new(1,-20,0,140)
    dropdown.Position = UDim2.new(0,10,0,138)
    dropdown.BackgroundColor3 = Color3.fromRGB(14,14,14)
    dropdown.BorderSizePixel = 0
    dropdown.Parent = frame
    Instance.new("UICorner", dropdown).CornerRadius = UDim.new(0,8)

    local dStroke = Instance.new("UIStroke", dropdown)
    dStroke.Color = Theme.STROKE
    dStroke.Transparency = 0.4

    local list = Instance.new("ScrollingFrame")
    list.Size = UDim2.new(1,-10,1,-10)
    list.Position = UDim2.new(0,5,0,5)
    list.CanvasSize = UDim2.new(0,0,0,0)
    list.ScrollBarImageTransparency = 0.3
    list.BackgroundTransparency = 1
    list.Parent = dropdown

    local layout = Instance.new("UIListLayout", list)
    layout.Padding = UDim.new(0,6)

    local function rebuildList()
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end

        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1,0,0,30)
                btn.Text = plr.Name
                btn.Font = Enum.Font.Code
                btn.TextSize = 14
                btn.TextColor3 = Theme.TEXT_DIM
                btn.BackgroundColor3 = Theme.BUTTON
                btn.BorderSizePixel = 0
                btn.Parent = list
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0,6)

                btn.MouseButton1Click:Connect(function()
                    selectedPlayer = plr
                    selectedLabel.Text = "Target: " .. plr.Name
                    dropdown.Visible = false
                end)
            end
        end

        task.wait()
        list.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 6)
    end

    -- =========================
    -- Logic
    -- =========================

    selectBtn.MouseButton1Click:Connect(function()
        dropdown.Visible = not dropdown.Visible
        rebuildList()
    end)

    tpBtn.MouseButton1Click:Connect(function()
        if not selectedPlayer then return end
        local char = selectedPlayer.Character
        local myChar = LocalPlayer.Character
        if not char or not myChar then return end

        local hrp = char:FindFirstChild("HumanoidRootPart")
        local myHrp = myChar:FindFirstChild("HumanoidRootPart")
        if not hrp or not myHrp then return end

        myHrp.CFrame = hrp.CFrame * CFrame.new(0,0,-3)
    end)

end

return PlayerTP
