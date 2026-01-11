local Fly = {}

function Fly.Init(Client)

	-- =========================
	-- Services / Core
	-- =========================

	local UIS = game:GetService("UserInputService")
	local RunService = Client.Services.RunService
	local LocalPlayer = Client.Player
	local Page = Client.Pages.Fly
	local Theme = Client.Theme

	-- =========================
	-- State
	-- =========================

	Fly.Enabled = false
	Fly.Mode = "normal"
	Fly.Speed = 60

	local humanoid
	local root
	local bv
	local bg
	local moveConn

	local saved = {}

	-- =========================
	-- Utilities (UNCHANGED)
	-- =========================

	local function getChar()
		local char = LocalPlayer.Character
		if not char then return end
		humanoid = char:FindFirstChildOfClass("Humanoid")
		root = char:FindFirstChild("HumanoidRootPart")
	end

	local function stopBot()
		if Client.Modules and Client.Modules.Bot and Client.Modules.Bot.Stop then
			Client.Modules.Bot:Stop()
		end
	end

	local function phaseOn()
		local Phase = Client.Modules and Client.Modules.Phase
		if Phase and Phase.SetMode then
			Phase.SetMode("normal", true)
		end
	end

	local function phaseOff()
		local Phase = Client.Modules and Client.Modules.Phase
		if Phase and Phase.Disable then
			Phase.Disable()
		end
	end

	-- =========================
	-- Fly Core (UNCHANGED)
	-- =========================

	local function startFly()
		if Fly.Enabled then return end
		getChar()
		if not humanoid or not root then return end

		stopBot()
		Fly.Enabled = true

		saved.AutoRotate = humanoid.AutoRotate
		saved.WalkSpeed = humanoid.WalkSpeed
		saved.JumpPower = humanoid.JumpPower

		humanoid.AutoRotate = false
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0

		bv = Instance.new("BodyVelocity")
		bv.MaxForce = Vector3.new(1e5,1e5,1e5)
		bv.Parent = root

		bg = Instance.new("BodyGyro")
		bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
		bg.CFrame = root.CFrame
		bg.Parent = root

		if Fly.Mode == "phase" then
			phaseOn()
		end

		moveConn = RunService.RenderStepped:Connect(function()
			if not Fly.Enabled then return end

			if Fly.Mode == "phase" then
				local Phase = Client.Modules and Client.Modules.Phase
				if Phase and Phase.SetMode then
					Phase.SetMode("normal", true)
				end
			end

			local cam = workspace.CurrentCamera
			if not cam then return end

			local dir = Vector3.zero
			if UIS:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
			if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
			if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end

			if dir.Magnitude > 0 then
				dir = dir.Unit * Fly.Speed
			end

			bv.Velocity = dir
			bg.CFrame = cam.CFrame
		end)
	end

	local function stopFly()
		if not Fly.Enabled then return end
		Fly.Enabled = false

		if moveConn then moveConn:Disconnect() moveConn = nil end
		if bv then bv:Destroy() bv = nil end
		if bg then bg:Destroy() bg = nil end

		phaseOff()

		if humanoid then
			humanoid.AutoRotate = saved.AutoRotate
			humanoid.WalkSpeed = saved.WalkSpeed
			humanoid.JumpPower = saved.JumpPower
		end
	end

	-- =========================
	-- GUI (REBUILT CLEANLY)
	-- =========================

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0,220,0,230)
	frame.Position = UDim2.new(0,10,0,10)
	frame.BackgroundColor3 = Color3.fromRGB(14,14,14)
	frame.BorderSizePixel = 0
	frame.Parent = Page
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)

	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Theme.STROKE
	stroke.Transparency = 0.4

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1,-12,0,26)
	title.Position = UDim2.new(0,10,0,4)
	title.BackgroundTransparency = 1
	title.Text = "Fly"
	title.Font = Enum.Font.Code
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Theme.TEXT
	title.Parent = frame

	-- holder uses layout (no overlap possible)
	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1,-20,1,-40)
	holder.Position = UDim2.new(0,10,0,36)
	holder.BackgroundTransparency = 1
	holder.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0,6)
	layout.Parent = holder

	local function makeButton(text)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1,0,0,30)
		b.BackgroundColor3 = Theme.BUTTON
		b.Text = text
		b.Font = Enum.Font.Code
		b.TextSize = 14
		b.TextColor3 = Theme.TEXT_DIM
		b.BorderSizePixel = 0
		b.Parent = holder
		Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
		return b
	end

	local normalBtn = makeButton("Normal Fly : OFF")

	local speedBlock = Instance.new("Frame")
	speedBlock.Size = UDim2.new(1,0,0,44)
	speedBlock.BackgroundTransparency = 1
	speedBlock.Visible = false
	speedBlock.Parent = holder

	local speedLabel = Instance.new("TextLabel")
	speedLabel.Size = UDim2.new(1,0,0,18)
	speedLabel.BackgroundTransparency = 1
	speedLabel.Text = "Speed: 60"
	speedLabel.Font = Enum.Font.Code
	speedLabel.TextSize = 13
	speedLabel.TextXAlignment = Enum.TextXAlignment.Left
	speedLabel.TextColor3 = Theme.TEXT_DIM
	speedLabel.Parent = speedBlock

	local slider = Instance.new("TextButton")
	slider.Size = UDim2.new(1,0,0,8)
	slider.Position = UDim2.new(0,0,0,24)
	slider.BackgroundColor3 = Theme.BUTTON
	slider.Text = ""
	slider.Parent = speedBlock
	Instance.new("UICorner", slider).CornerRadius = UDim.new(0,6)

	local stroke2 = Instance.new("UIStroke", slider)
	stroke2.Color = Theme.STROKE
	stroke2.Transparency = 0.7
	stroke2.Thickness = 1

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0.25,0,1,0)
	fill.BackgroundColor3 = Theme.TEXT
	fill.BorderSizePixel = 0
	fill.Parent = slider
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0,6)

	local phaseBtn = makeButton("Phase Fly : OFF")

	-- =========================
	-- Slider Input (UNCHANGED)
	-- =========================

	local dragging = false

	slider.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
	end)

	slider.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)

	UIS.InputChanged:Connect(function(i)
		if not dragging then return end
		if i.UserInputType ~= Enum.UserInputType.MouseMovement then return end

		local rel = math.clamp(
			(i.Position.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X,
			0,1
		)

		Fly.Speed = math.floor(20 + rel * 180)
		speedLabel.Text = "Speed: " .. Fly.Speed
		fill.Size = UDim2.new(rel,0,1,0)
	end)

	-- =========================
	-- Buttons (logic unchanged)
	-- =========================

	normalBtn.MouseButton1Click:Connect(function()
		if Fly.Enabled and Fly.Mode == "normal" then
			stopFly()
			speedBlock.Visible = false
			normalBtn.Text = "Normal Fly : OFF"
			normalBtn.TextColor3 = Theme.TEXT_DIM
			return
		end

		Fly.Mode = "normal"
		phaseBtn.Text = "Phase Fly : OFF"
		phaseBtn.TextColor3 = Theme.TEXT_DIM

		startFly()
		speedBlock.Visible = true

		normalBtn.Text = "Normal Fly : ON"
		normalBtn.TextColor3 = Theme.TEXT
	end)

	phaseBtn.MouseButton1Click:Connect(function()
		if Fly.Enabled and Fly.Mode == "phase" then
			stopFly()
			speedBlock.Visible = false
			phaseBtn.Text = "Phase Fly : OFF"
			phaseBtn.TextColor3 = Theme.TEXT_DIM
			return
		end

		Fly.Mode = "phase"
		normalBtn.Text = "Normal Fly : OFF"
		normalBtn.TextColor3 = Theme.TEXT_DIM

		startFly()
		speedBlock.Visible = true

		phaseBtn.Text = "Phase Fly : ON"
		phaseBtn.TextColor3 = Theme.TEXT
	end)
end

return Fly




