-- Cactus Client - ESP Module v3
-- Bottom / Top / Middle tracers, team colors, neon dev style

local ESP = {}

function ESP.Init(Client)

    local Players     = Client.Services.Players
    local RunService  = Client.Services.RunService
    local LocalPlayer = Client.Player
    local Page        = Client.Pages.ESP
    local Theme       = Client.Theme
    local Camera      = workspace.CurrentCamera

    -- =========================
    -- State
    -- =========================

    local State = {
        Enabled        = false,

        BottomTracers  = true,
        TopTracers     = false,
        MiddleTracers  = false,

        Boxes          = true,
        Names          = true,
        Distance       = true,

        TeamColors     = true
    }

    local Objects = {}

    local COLORS = {
        Enemy   = Color3.fromRGB(255, 60, 60),
        Friendly= Color3.fromRGB(80, 140, 255),
        Neutral = Color3.fromRGB(0, 255, 140)
    }

    -- =========================
    -- Drawing factory
    -- =========================

    local function New(type, props)
        local obj = Drawing.new(type)
        for k,v in pairs(props) do
            obj[k] = v
        end
        return obj
    end

    local function CreateESP()
        return {
            BottomTracer = New("Line", {Thickness=1.5,Transparency=1,Visible=false}),
            TopTracer    = New("Line", {Thickness=1.5,Transparency=1,Visible=false}),
            MidTracer    = New("Line", {Thickness=1.5,Transparency=1,Visible=false}),

            Box = New("Square", {
                Thickness = 1.5,
                Transparency = 1,
                Filled = false,
                Visible = false
            }),

            Name = New("Text", {
                Size = 13,
                Center = true,
                Outline = true,
                Font = 2,
                Visible = false
            }),

            Dist = New("Text", {
                Size = 12,
                Center = true,
                Outline = true,
                Font = 2,
                Visible = false
            })
        }
    end

    local function Remove(plr)
        if Objects[plr] then
            for _,obj in pairs(Objects[plr]) do
                pcall(function() obj:Remove() end)
            end
            Objects[plr] = nil
        end
    end

    local function Setup(plr)
        if plr == LocalPlayer then return end
        Objects[plr] = CreateESP()
    end

    -- =========================
    -- Helpers
    -- =========================

    local function ResolveColor(plr)
        if not State.TeamColors then
            return COLORS.Neutral
        end

        if plr.Team == nil or LocalPlayer.Team == nil then
            return COLORS.Neutral
        end

        if plr.Team == LocalPlayer.Team then
            return COLORS.Friendly
        end

        return COLORS.Enemy
    end

    local function Hide(set)
        for _,obj in pairs(set) do
            obj.Visible = false
        end
    end

    local function GetBoxSize(cf, size)
        local corners = {
            cf * CFrame.new( size.X,  size.Y, 0),
            cf * CFrame.new(-size.X,  size.Y, 0),
            cf * CFrame.new( size.X, -size.Y, 0),
            cf * CFrame.new(-size.X, -size.Y, 0),
        }

        local minX, minY = math.huge, math.huge
        local maxX, maxY = -math.huge, -math.huge

        for _,corner in ipairs(corners) do
            local v, onScreen = Camera:WorldToViewportPoint(corner.Position)
            if onScreen then
                minX = math.min(minX, v.X)
                minY = math.min(minY, v.Y)
                maxX = math.max(maxX, v.X)
                maxY = math.max(maxY, v.Y)
            end
        end

        return Vector2.new(minX, minY), Vector2.new(maxX - minX, maxY - minY)
    end

    -- =========================
    -- Render loop
    -- =========================

    RunService.RenderStepped:Connect(function()

        if not State.Enabled then
            for _,set in pairs(Objects) do
                Hide(set)
            end
            return
        end

        local screenBottom = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
        local screenTop    = Vector2.new(Camera.ViewportSize.X/2, 0)
        local screenMid    = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

        for _,plr in ipairs(Players:GetPlayers()) do
            local set = Objects[plr]
            if set and plr.Character then

                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                local head = plr.Character:FindFirstChild("Head")
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")

                if hrp and hum and hum.Health > 0 then

                    local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if not onScreen then
                        Hide(set)
                        continue
                    end

                    local color = ResolveColor(plr)
                    local dist = (Camera.CFrame.Position - hrp.Position).Magnitude

                    -- apply color to all
                    for _,obj in pairs(set) do
                        if obj.Color ~= nil then
                            obj.Color = color
                        end
                    end

                    -- Bottom tracer
                    if State.BottomTracers then
                        set.BottomTracer.From = screenBottom
                        set.BottomTracer.To = Vector2.new(pos.X, pos.Y)
                        set.BottomTracer.Visible = true
                    else
                        set.BottomTracer.Visible = false
                    end

                    -- Top tracer
                    if State.TopTracers then
                        set.TopTracer.From = screenTop
                        set.TopTracer.To = Vector2.new(pos.X, pos.Y)
                        set.TopTracer.Visible = true
                    else
                        set.TopTracer.Visible = false
                    end

                    -- Middle tracer (from head)
                    if State.MiddleTracers and head then
                        local hpos, hon = Camera:WorldToViewportPoint(head.Position)
                        if hon then
                            set.MidTracer.From = screenMid
                            set.MidTracer.To = Vector2.new(hpos.X, hpos.Y)
                            set.MidTracer.Visible = true
                        else
                            set.MidTracer.Visible = false
                        end
                    else
                        set.MidTracer.Visible = false
                    end

                    -- Box
                    if State.Boxes then
                        local topLeft, size = GetBoxSize(hrp.CFrame, Vector3.new(2,3,0))
                        set.Box.Position = topLeft
                        set.Box.Size = size
                        set.Box.Visible = true
                    else
                        set.Box.Visible = false
                    end

                    -- Name
                    if State.Names then
                        set.Name.Text = plr.Name
                        set.Name.Position = Vector2.new(pos.X, pos.Y - 32)
                        set.Name.Visible = true
                    else
                        set.Name.Visible = false
                    end

                    -- Distance
                    if State.Distance then
                        set.Dist.Text = string.format("[%.0fm]", dist)
                        set.Dist.Position = Vector2.new(pos.X, pos.Y - 18)
                        set.Dist.Visible = true
                    else
                        set.Dist.Visible = false
                    end

                else
                    Hide(set)
                end
            end
        end
    end)

    -- =========================
    -- Player handling
    -- =========================

    for _,plr in ipairs(Players:GetPlayers()) do
        Setup(plr)
    end

    Players.PlayerAdded:Connect(Setup)
    Players.PlayerRemoving:Connect(Remove)

    -- =========================
    -- UI (Cactus style)
    -- =========================

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 240, 0, 360)
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

    local function Button(text, y)
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

    local espBtn    = Button("ESP: OFF", 40)
    local botBtn    = Button("Bottom Tracers: ON", 75)
    local topBtn    = Button("Top Tracers: OFF", 110)
    local midBtn    = Button("Middle Tracers: OFF", 145)
    local boxBtn    = Button("Boxes: ON", 180)
    local nameBtn   = Button("Names: ON", 215)
    local distBtn   = Button("Distance: ON", 250)
    local teamBtn   = Button("Team Colors: ON", 285)

    -- =========================
    -- UI logic
    -- =========================

    espBtn.MouseButton1Click:Connect(function()
        State.Enabled = not State.Enabled
        espBtn.Text = State.Enabled and "ESP: ON" or "ESP: OFF"
    end)

    botBtn.MouseButton1Click:Connect(function()
        State.BottomTracers = not State.BottomTracers
        botBtn.Text = State.BottomTracers and "Bottom Tracers: ON" or "Bottom Tracers: OFF"
    end)

    topBtn.MouseButton1Click:Connect(function()
        State.TopTracers = not State.TopTracers
        topBtn.Text = State.TopTracers and "Top Tracers: ON" or "Top Tracers: OFF"
    end)

    midBtn.MouseButton1Click:Connect(function()
        State.MiddleTracers = not State.MiddleTracers
        midBtn.Text = State.MiddleTracers and "Middle Tracers: ON" or "Middle Tracers: OFF"
    end)

    boxBtn.MouseButton1Click:Connect(function()
        State.Boxes = not State.Boxes
        boxBtn.Text = State.Boxes and "Boxes: ON" or "Boxes: OFF"
    end)

    nameBtn.MouseButton1Click:Connect(function()
        State.Names = not State.Names
        nameBtn.Text = State.Names and "Names: ON" or "Names: OFF"
    end)

    distBtn.MouseButton1Click:Connect(function()
        State.Distance = not State.Distance
        distBtn.Text = State.Distance and "Distance: ON" or "Distance: OFF"
    end)

    teamBtn.MouseButton1Click:Connect(function()
        State.TeamColors = not State.TeamColors
        teamBtn.Text = State.TeamColors and "Team Colors: ON" or "Team Colors: OFF"
    end)

end

return ESP

