-- Cactus Client - ESP Module
-- Neon green, dev-style, modular, performance-safe

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
        Enabled  = false,
        Tracers  = true,
        Boxes    = true,
        Names    = true,
        Distance = true,
        TeamCheck = false
    }

    local Objects = {}

    local GREEN = Color3.fromRGB(0, 255, 140)

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
            Tracer = New("Line", {
                Thickness = 1.5,
                Transparency = 1,
                Color = GREEN,
                Visible = false
            }),

            Box = New("Square", {
                Thickness = 1.5,
                Transparency = 1,
                Color = GREEN,
                Filled = false,
                Visible = false
            }),

            Name = New("Text", {
                Size = 13,
                Center = true,
                Outline = true,
                Color = GREEN,
                Font = 2,
                Visible = false
            }),

            Dist = New("Text", {
                Size = 12,
                Center = true,
                Outline = true,
                Color = GREEN,
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
    -- Math helpers
    -- =========================

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

    local function Hide(set)
        for _,obj in pairs(set) do
            obj.Visible = false
        end
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

        local screenBottom = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)

        for _,plr in ipairs(Players:GetPlayers()) do
            local set = Objects[plr]
            if set and plr.Character then

                local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")

                if hrp and hum and hum.Health > 0 then

                    if State.TeamCheck and plr.Team == LocalPlayer.Team then
                        Hide(set)
                        continue
                    end

                    local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                    if not onScreen then
                        Hide(set)
                        continue
                    end

                    local dist = (Camera.CFrame.Position - hrp.Position).Magnitude

                    -- Tracer
                    if State.Tracers then
                        set.Tracer.From = screenBottom
                        set.Tracer.To = Vector2.new(pos.X, pos.Y)
                        set.Tracer.Visible = true
                    else
                        set.Tracer.Visible = false
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
                        set.Name.Position = Vector2.new(pos.X, pos.Y - 30)
                        set.Name.Visible = true
                    else
                        set.Name.Visible = false
                    end

                    -- Distance
                    if State.Distance then
                        set.Dist.Text = string.format("[%.0fm]", dist)
                        set.Dist.Position = Vector2.new(pos.X, pos.Y - 16)
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
    -- UI (Waypoints-style)
    -- =========================

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 230, 0, 260)
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

    local espBtn     = Button("ESP: OFF", 40)
    local tracerBtn  = Button("Tracers: ON", 75)
    local boxBtn     = Button("Boxes: ON", 110)
    local nameBtn    = Button("Names: ON", 145)
    local distBtn    = Button("Distance: ON", 180)

    -- =========================
    -- UI logic
    -- =========================

    espBtn.MouseButton1Click:Connect(function()
        State.Enabled = not State.Enabled
        espBtn.Text = State.Enabled and "ESP: ON" or "ESP: OFF"
    end)

    tracerBtn.MouseButton1Click:Connect(function()
        State.Tracers = not State.Tracers
        tracerBtn.Text = State.Tracers and "Tracers: ON" or "Tracers: OFF"
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

end

return ESP
