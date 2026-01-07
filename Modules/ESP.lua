-- Cactus Client - ESP Module (Compact UI Rewrite)
-- Multi-tracer ESP with team colors and compact scroll UI

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
	-- State
	-- =========================

	local State = {
		Enabled = false,

		BottomTracers = true,
		TopTracers    = false,
		MiddleTracers = false,

		Boxes    = true,
		Names    = true,
		Distance = true,

		TeamColors = true
	}

	local Objects = {}

	local COLORS = {
		Enemy    = Color3.fromRGB(255, 70, 70),
		Friendly = Color3.fromRGB(80, 140, 255),
		Neutral  = Color3.fromRGB(0, 255, 140)
	}

	-- =========================
	-- Drawing factory
	-- =========================

	local function New(t, props)
		local o = Drawing.new(t)
		for k,v in pairs(props) do
			o[k] = v
		end
		return o
	end

	local function NewSet()
		return {
			Bottom = New("Line",   {Thickness=1.2,Transparency=1,Visible=false}),
			Top    = New("Line",   {Thickness=1.2,Transparency=1,Visible=false}),
			Middle = New("Line",   {Thickness=1.2,Transparency=1,Visible=false}),
			Box    = New("Square",{Thickness=1.2,Transparency=1,Filled=false,Visible=false}),
			Name   = New("Text",  {Size=12,Center=true,Outline=true,Font=2,Visible=false}),
			Dist   = New("Text",  {Size=11,Center=true,Outline=true,Font=2,Visible=false})
		}
	end

	-- =========================
	-- Player lifecycle
	-- =========================

	local function Remove(plr)
		if Objects[plr] then
			for _,o in pairs(Objects[plr]) do
				pcall(function() o:Remove() end)
			end
			Objects[plr] = nil
		end
	end

	local function Setup(plr)
		if plr ~= LocalPlayer then
			Objects[plr] = NewSet()
		end
	end

	for _,p in ipairs(Players:GetPlayers()) do Setup(p) end
	Players.PlayerAdded:Connect(Setup)
	Players.PlayerRemoving:Connect(Remove)

	-- =========================
	-- Helpers
	-- =========================

	local function ColorFor(plr)
		if not State.TeamColors then
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

	local function Hide(set)
		for _,o in pairs(set) do o.Visible = false end
	end

	local function GetBox(cf)
		local size = Vector3.new(2,3,0)
		local corners = {
			cf * CFrame.new( size.X,  size.Y,0),
			cf * CFrame.new(-size.X,  size.Y,0),
			cf * CFrame.new( size.X, -size.Y,0),
			cf * CFrame.new(-size.X, -size.Y,0)
		}

		local minX,minY,maxX,maxY = 9e9,9e9,-9e9,-9e9

		for _,c in ipairs(corners) do
			local v,on = Camera:WorldToViewportPoint(c.Position)
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
	-- Render
	-- =========================

	RunService.RenderStepped:Connect(function()

		if not State.Enabled then
			for _,s in pairs(Objects) do Hide(s) end
			return
		end

		local bottom = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
		local top    = Vector2.new(Camera.ViewportSize.X/2, 0)
		local mid    = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

		for _,plr in ipairs(Players:GetPlayers()) do
			local set = Objects[plr]
			if set and plr.Character then

				local hrp  = plr.Character:FindFirstChild("HumanoidRootPart")
				local head = plr.Character:FindFirstChild("Head")
				local hum  = plr.Character:FindFirstChildOfClass("Humanoid")

				if hrp and hum and hum.Health > 0 then
					local pos,on = Camera:WorldToViewportPoint(hrp.Position)
					if not on then Hide(set) continue end

					local col = ColorFor(plr)
					local dist = (Camera.CFrame.Position - hrp.Position).Magnitude

					for _,o in pairs(set) do if o.Color then o.Color = col end end

					if State.BottomTracers then
						set.Bottom.From = bottom
						set.Bottom.To   = Vector2.new(pos.X,pos.Y)
						set.Bottom.Visible = true
					else set.Bottom.Visible=false end

					if State.TopTracers then
						set.Top.From = top
						set.Top.To   = Vector2.new(pos.X,pos.Y)
						set.Top.Visible = true
					else set.Top.Visible=false end

					if State.MiddleTracers and head then
						local hpos,hon = Camera:WorldToViewportPoint(head.Position)
						if hon then
							set.Middle.From = mid
							set.Middle.To   = Vector2.new(hpos.X,hpos.Y)
							set.Middle.Visible = true
						else set.Middle.Visible=false end
					else set.Middle.Visible=false end

					if State.Boxes then
						local tl,sz = GetBox(hrp.CFrame)
						set.Box.Position = tl
						set.Box.Size = sz
						set.Box.Visible = true
					else set.Box.Visible=false end

					if State.Names then
						set.Name.Text = plr.Name
						set.Name.Position = Vector2.new(pos.X,pos.Y-30)
						set.Name.Visible = true
					else set.Name.Visible=false end

					if State.Distance then
						set.Dist.Text = string.format("[%.0fm]",dist)
						set.Dist.Position = Vector2.new(pos.X,pos.Y-16)
						set.Dist.Visible = true
					else set.Dist.Visible=false end

				else Hide(set) end
			end
		end
	end)

	-- =========================
	-- UI (compact cactus panel)
	-- =========================

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0,190,0,210)
	frame.BackgroundColor3 = Color3.fromRGB(14,14,14)
	frame.BorderSizePixel = 0
	frame.Parent = Page
	Instance.new("UICorner",frame).CornerRadius = UDim.new(0,10)

	local stroke = Instance.new("UIStroke",frame)
	stroke.Color = Theme.STROKE
	stroke.Transparency = 0.4

	local title = Instance.new("TextLabel",frame)
	title.Size = UDim2.new(1,0,0,22)
	title.BackgroundTransparency = 1
	title.Text = "ESP"
	title.Font = Enum.Font.Code
	title.TextSize = 13
	title.TextColor3 = Theme.TEXT

	local scroll = Instance.new("ScrollingFrame",frame)
	scroll.Position = UDim2.new(0,5,0,26)
	scroll.Size = UDim2.new(1,-10,1,-30)
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

	local function Button(txt)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1,-6,0,22)
		b.BackgroundColor3 = Theme.BUTTON
		b.Text = txt
		b.Font = Enum.Font.Code
		b.TextSize = 11
		b.TextColor3 = Theme.TEXT_DIM
		b.BorderSizePixel = 0
		b.Parent = scroll
		Instance.new("UICorner",b).CornerRadius = UDim.new(0,6)
		return b
	end

	local espBtn  = Button("ESP: OFF")
	local bBtn    = Button("Bottom Tracers: ON")
	local tBtn    = Button("Top Tracers: OFF")
	local mBtn    = Button("Middle Tracers: OFF")
	local boxBtn  = Button("Boxes: ON")
	local nBtn    = Button("Names: ON")
	local dBtn    = Button("Distance: ON")
	local teamBtn = Button("Team Colors: ON")

	-- =========================
	-- UI logic
	-- =========================

	espBtn.MouseButton1Click:Connect(function()
		State.Enabled = not State.Enabled
		espBtn.Text = State.Enabled and "ESP: ON" or "ESP: OFF"
	end)

	bBtn.MouseButton1Click:Connect(function()
		State.BottomTracers = not State.BottomTracers
		bBtn.Text = State.BottomTracers and "Bottom Tracers: ON" or "Bottom Tracers: OFF"
	end)

	tBtn.MouseButton1Click:Connect(function()
		State.TopTracers = not State.TopTracers
		tBtn.Text = State.TopTracers and "Top Tracers: ON" or "Top Tracers: OFF"
	end)

	mBtn.MouseButton1Click:Connect(function()
		State.MiddleTracers = not State.MiddleTracers
		mBtn.Text = State.MiddleTracers and "Middle Tracers: ON" or "Middle Tracers: OFF"
	end)

	boxBtn.MouseButton1Click:Connect(function()
		State.Boxes = not State.Boxes
		boxBtn.Text = State.Boxes and "Boxes: ON" or "Boxes: OFF"
	end)

	nBtn.MouseButton1Click:Connect(function()
		State.Names = not State.Names
		nBtn.Text = State.Names and "Names: ON" or "Names: OFF"
	end)

	dBtn.MouseButton1Click:Connect(function()
		State.Distance = not State.Distance
		dBtn.Text = State.Distance and "Distance: ON" or "Distance: OFF"
	end)

	teamBtn.MouseButton1Click:Connect(function()
		State.TeamColors = not State.TeamColors
		teamBtn.Text = State.TeamColors and "Team Colors: ON" or "Team Colors: OFF"
	end)

end

return ESP
