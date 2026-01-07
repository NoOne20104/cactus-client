-- Cactus Client - ESP Module (Fresh Build)
-- Clean overlay system, compact dev UI, modular core

local ESP = {}

function ESP.Init(Client)

    -- =========================
    -- Core
    -- =========================

    local Players     = Client.Services.Players
    local RunService  = Client.Services.RunService
    local LocalPlayer = Client.Player
    local Page        = Client.Pages.ESP
    local Theme       = Client.Theme
    local Camera      = workspace.CurrentCamera

    -- =========================
    -- Config / State
    -- =========================

    local Config = {
        Enabled = false,

        TracerBottom = true,
        TracerTop    = false,
        TracerMiddle = false,

        Boxes    = true,
        Names    = true,
        Distance = true,

        TeamColors = true
    }

    local Registry = {}

    local COLORS = {
        Enemy    = Color3.fromRGB(255, 80, 80),
        Friendly = Color3.fromRGB(90, 140, 255),
        Neutral  = Color3.fromRGB(0, 255, 140)
    }

    -- =========================
    -- Drawing layer
    -- =========================

    local function Draw(kind, props)
        local obj = Drawing.new(kind)
        for k,v in pairs(props) do
            obj[k] = v
        end
        return obj
    end

    local function NewBundle()
        return {
            TBottom = Draw("Line",{Thickness=1.2,Transparency=1,Visible=false}),
            TTop    = Draw("Line",{Thickness=1.2,Transparency=1,Visible=false}),
            TMid    = Draw("Line",{Thickness=1.2,Transparency=1,Visible=false}),
            Box     = Draw("Square",{Thickness=1.2,Transparency=1,Filled=false,Visible=false}),
            Name    = Draw("Text",{Size=12,Center=true,Outline=true,Font=2,Visible=false}),
            Dist    = Draw("Text",{Size=11,Center=true,Outline=true,Font=2,Visible=false})
        }
    end

    -- =========================
    -- Player registry
    -- =========================

    local function Register(plr)
        if plr ~= LocalPlayer then
            Registry[plr] = NewBundle()
        end
    end

    local function Unregister(plr)
        local set = Registry[plr]
        if set then
            for _,obj in pairs(set) do
                pcall(function() obj:Remove() end)
            end
            Registry[plr] = nil
        end
    end

    for _,p in ipairs(Players:GetPlayers()) do Register(p) end
    Players.PlayerAdded:Connect(Register)
    Players.PlayerRemoving:Connect(Unregister)

    -- =========================
    -- Helpers
    -- =========================

    local function GetColor(plr)
        if not Config.TeamColors then
            return COLORS.Neutral
        end
        if not plr.Team or not LocalPlayer.Team then
            return COLORS.Neutral
        end
        if plr.Team == LocalPlayer.Team then
            return COLORS.Friendly
        end
        return COLORS.Enemy
    end

    local function HideAll(set)
        for _,o in pairs(set) do
            o.Visible = false
        end
    end

    local function ComputeBox(cf)
        local size = Vector3.new(2,3,0)
        local points = {
            cf * CFrame.new( size.X,  size.Y,0),
            cf * CFrame.new(-size.X,  size.Y,0),
            cf * CFrame.new( size.X, -size.Y,0),
            cf * CFrame.new(-size.X, -size.Y,0)
        }

        local minX,minY,maxX,maxY = 9e9,9e9,-9e9,-9e9

        for _,p in ipairs(points) do
            local v,on = Camera:WorldToViewportPoint(p.Position)
            if on then
                minX = math.min(minX,v.X)
                minY = math.min(minY,v.Y)
                maxX = math.max(maxX,v.X)
                maxY = math.max(maxY,v.Y)
            end
        end

        return Vector2.new(minX,minY), Vector2.new(maxX-minX,maxY-minY)
    end

    -- =========================
    -- Render engine
    -- =========================

    RunService.RenderStepped:Connect(function()

        if not Config.Enabled then
            for _,set in pairs(Registry) do
                HideAll(set)
            end
            return
        end

        local screenBottom = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
        local screenTop    = Vector2.new(Camera.ViewportSize.X/2, 0)
        local screenMid    = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

        for _,plr in ipairs(Players:GetPlayers()) do
            local set = Registry[plr]
            if set and plr.Character then

                local hrp  = plr.Character:FindFirstChild("HumanoidRootPart")
                local head = plr.Character:FindFirstChild("Head")
                local hum  = plr.Character:FindFirstChildOfClass("Humanoid")

                if hrp and hum and hum.Health > 0 then

                    local pos,on = Camera:WorldToViewportPoint(hrp.Position)
                    if not on then HideAll(set) continue end

                    local col = GetColor(plr)
                    local dist = (Camera.CFrame.Position - hrp.Position).Magnitude

                    for _,o in pairs(set) do
                        if o.Color then o.Color = col end
                    end

                    -- tracers
                    if Config.TracerBottom then
                        set.TBottom.From = screenBottom
                        set.TBottom.To   = Vector2.new(pos.X,pos.Y)
                        set.TBottom.Visible = true
                    else set.TBottom.Visible=false end

                    if Config.TracerTop then
                        set.TTop.From = screenTop
                        set.TTop.To   = Vector2.new(pos.X,pos.Y)
                        set.TTop.Visible = true
                    else set.TTop.Visible=false end

                    if Config.TracerMiddle and head then
                        local hpos,hon = Camera:WorldToViewportPoint(head.Position)
                        if hon then
                            set.TMid.From = screenMid
                            set.TMid.To   = Vector2.new(hpos.X,hpos.Y)
                            set.TMid.Visible = true
                        else set.TMid.Visible=false end
                    else set.TMid.Visible=false end

                    -- box
                    if Config.Boxes then
                        local tl,sz = ComputeBox(hrp.CFrame)
                        set.Box.Position = tl
                        set.Box.Size = sz
                        set.Box.Visible = true
                    else set.Box.Visible=false end

                    -- name
                    if Config.Names then
                        set.Name.Text = plr.Name
                        set.Name.Position = Vector2.new(pos.X,pos.Y-28)
                        set.Name.Visible = true
                    else set.Name.Visible=false end

                    -- distance
                    if Config.Distance then
                        set.Dist.Text = string.format("[%.0fm]",dist)
                        set.Dist.Position = Vector2.new(pos.X,pos.Y-15)
                        set.Dist.Visible = true
                    else set.Dist.Visible=false end

                else
                    HideAll(set)
                end
            end
        end
    end)

    -- =========================
    -- UI (fresh compact panel)
    -- =========================

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0,180,0,200)
    frame.BackgroundColor3 = Color3.fromRGB(14,14,14)
    frame.BorderSizePixel = 0
    frame.Parent = Page
    Instance.new("UICorner",frame).CornerRadius = UDim.new(0,10)

    local stroke = Instance.new("UIStroke",frame)
    stroke.Color = Theme.STROKE
    stroke.Transparency = 0.4

    local title = Instance.new("TextLabel",frame)
    title.Size = UDim2.new(1,0,0,20)
    title.BackgroundTransparency = 1
    title.Text = "ESP"
    title.Font = Enum.Font.Code
    title.TextSize = 13
    title.TextColor3 = Theme.TEXT

    local scroll = Instance.new("ScrollingFrame",frame)
    scroll.Position = UDim2.new(0,5,0,24)
    scroll.Size = UDim2.new(1,-10,1,-28)
    scroll.CanvasSize = UDim2.new(0,0,0,0)
    scroll.ScrollBarThickness = 3
    scroll.ScrollingDirection = Enum.ScrollingDirection.Y
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel = 0

    local layout = Instance.new("UIListLayout",scroll)
    layout.Padding = UDim.new(0,5)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center

    local pad = Instance.new("UIPadding",scroll)
    pad.PaddingTop = UDim.new(0,4)
    pad.PaddingBottom = UDim.new(0,6)

    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 8)
    end)

    local function Button(text)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1,-6,0,22)
        b.BackgroundColor3 = Theme.BUTTON
        b.Text = text
        b.Font = Enum.Font.Code
        b.TextSize = 11
        b.TextColor3 = Theme.TEXT_DIM
        b.BorderSizePixel = 0
        b.Parent = scroll
        Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
        return b
    end

    local espBtn   = Button("ESP: OFF")
    local btmBtn   = Button("Bottom Tracer: ON")
    local topBtn   = Button("Top Tracer: OFF")
    local midBtn   = Button("Middle Tracer: OFF")
    local boxBtn   = Button("Boxes: ON")
    local nameBtn  = Button("Names: ON")
    local distBtn  = Button("Distance: ON")
    local teamBtn  = Button("Team Colors: ON")

    -- =========================
    -- UI logic
    -- =========================

    espBtn.MouseButton1Click:Connect(function()
        Config.Enabled = not Config.Enabled
        espBtn.Text = Config.Enabled and "ESP: ON" or "ESP: OFF"
    end)

    btmBtn.MouseButton1Click:Connect(function()
        Config.TracerBottom = not Config.TracerBottom
        btmBtn.Text = Config.TracerBottom and "Bottom Tracer: ON" or "Bottom Tracer: OFF"
    end)

    topBtn.MouseButton1Click:Connect(function()
        Config.TracerTop = not Config.TracerTop
        topBtn.Text = Config.TracerTop and "Top Tracer: ON" or "Top Tracer: OFF"
    end)

    midBtn.MouseButton1Click:Connect(function()
        Config.TracerMiddle = not Config.TracerMiddle
        midBtn.Text = Config.TracerMiddle and "Middle Tracer: ON" or "Middle Tracer: OFF"
    end)

    boxBtn.MouseButton1Click:Connect(function()
        Config.Boxes = not Config.Boxes
        boxBtn.Text = Config.Boxes and "Boxes: ON" or "Boxes: OFF"
    end)

    nameBtn.MouseButton1Click:Connect(function()
        Config.Names = not Config.Names
        nameBtn.Text = Config.Names and "Names: ON" or "Names: OFF"
    end)

    distBtn.MouseButton1Click:Connect(function()
        Config.Distance = not Config.Distance
        distBtn.Text = Config.Distance and "Distance: ON" or "Distance: OFF"
    end)

    teamBtn.MouseButton1Click:Connect(function()
        Config.TeamColors = not Config.TeamColors
        teamBtn.Text = Config.TeamColors and "Team Colors: ON" or "Team Colors: OFF"
    end)

end

return ESP

