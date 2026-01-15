local Freecam = {}

function Freecam.Init(Client)

	-- =========================
	-- Services / Core
	-- =========================

	local UIS = game:GetService("UserInputService")
	local RunService = Client.Services.RunService
	local Players = Client.Services.Players
	local LocalPlayer = Client.Player
	local Page = Client.Pages.Freecam
	local Theme = Client.Theme
	local Camera = workspace.CurrentCamera

	-- =========================
	-- State
	-- =========================

	Freecam.Enabled = false
	Freecam.Speed = 60
	Freecam.Sensitivity = 0.25

	local yaw = 0
	local pitch = 0
	local looking = false

	local saved = {}

	-- =========================
	-- Core Drone Freecam
	-- =========================

	local function startFreecam()
		if Freecam.Enabled then return end
		if not Camera then return end

		Freecam.Enabled = true

		saved.Type = Camera.CameraType
		saved.Subject = Camera.CameraSubject
		saved.MouseBehavior = UIS.MouseBehavior
		saved.MouseIcon = UIS.MouseIconEnabled

		Camera.CameraType = Enum.CameraType.Scriptable
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		UIS.MouseIconEnabled = true

		local look = Camera.CFrame.LookVector
		yaw = math.atan2(-look.X, -look.Z)
		pitch = math.asin(look.Y)

		RunService:BindToRenderStep(
			"CactusDroneFreecam",
			Enum.RenderPriority.Camera.Value,
			function(dt)

				if looking then
					local delta = UIS:GetMouseDelta()
					yaw -= delta.X * Freecam.Sensitivity * 0.01
					pitch -= delta.Y * Freecam.Sensitivity * 0.01
					pitch = math.clamp(pitch, -1.5, 1.5)
				end

				local rot = CFrame.fromOrientation(pitch, yaw, 0)

				local dir = Vector3.zero
				if UIS:IsKeyDown(Enum.KeyCode.W) then dir += rot.LookVector end
				if UIS:IsKeyDown(Enum.KeyCode.S) then dir -= rot.LookVector end
				if UIS:IsKeyDown(Enum.KeyCode.A) then dir -= rot.RightVector end
				if UIS:IsKeyDown(Enum.KeyCode.D) then dir += rot.RightVector end
				if UIS:IsKeyDown(Enum.KeyCode.Space) then dir += Vector3.new(0,1,0) end
				if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0,1,0) end

				if dir.Magnitude > 0 then
					dir = dir.Unit * Freecam.Speed * dt
				end

				Camera.CFrame = CFrame.new(Camera.CFrame.Position + dir) * rot
			end
		)
	end

	local function stopFreecam()
		if not Freecam.Enabled then return end
		Freecam.Enabled = false

		RunService:UnbindFromRenderStep("CactusDroneFreecam")

		if Camera then
			Camera.CameraType = saved.Type
			Camera.CameraSubject = saved.Subject
		end

		UIS.MouseBehavior = saved.MouseBehavior
		UIS.MouseIconEnabled = saved.MouseIcon
	end

	-- =========================
	-- Right click look
	-- =========================

	UIS.InputBegan:Connect(function(input)
		if not Freecam.Enabled then return end
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			looking = true
			UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
			UIS.MouseIconEnabled = false
		end
	end)

	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			looking = false
			if Freecam.Enabled then
				UIS.MouseBehavior = Enum.MouseBehavior.Default
				UIS.MouseIconEnabled = true
			end
		end
	end)

	-- =========================
	-- HARD SAFETY (death fix + UI sync)
	-- =========================

	local uiReset -- assigned after UI is built

	LocalPlayer.CharacterAdded:Connect(function()
		if Freecam.Enabled then
			task.wait()
			stopFreecam()
			if uiReset then
				uiReset()
			end
		end
	end)

	-- =========================
	-- GUI
	-- =========================

	for _,child in ipairs(Page:GetChildren()) do
		if child:IsA("Frame") and child.Name == "CactusDroneFreecamFrame" then
			child:Destroy()
		end
	end

	local frame = Instance.new("Frame")
	frame.Name = "CactusDroneFreecamFrame"
	frame.Size = UDim2.new(0,220,0,200)
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
	title.Text = "Drone Freecam"
	title.Font = Enum.Font.Code
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Theme.TEXT
	title.Parent = frame

	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1,-20,1,-44)
	holder.Position = UDim2.new(0,10,0,24)
	holder.BackgroundTransparency = 1
	holder.Parent = frame

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0,8)
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

	local toggleBtn = makeButton("Drone Freecam : OFF")

	local spacer = Instance.new("Frame")
	spacer.Size = UDim2.new(1,0,0,10)
	spacer.BackgroundTransparency = 1
	spacer.Parent = holder

	local speedLabel = Instance.new("TextLabel")
	speedLabel.Size = UDim2.new(1,0,0,18)
	speedLabel.BackgroundTransparency = 1
	speedLabel.Text = "Speed: 60"
	speedLabel.Font = Enum.Font.Code
	speedLabel.TextSize = 13
	speedLabel.TextXAlignment = Enum.TextXAlignment.Left
	speedLabel.TextColor3 = Theme.TEXT_DIM
	speedLabel.Visible = false
	speedLabel.Parent = holder

	local slider = Instance.new("TextButton")
	slider.Size = UDim2.new(1,0,0,8)
	slider.BackgroundColor3 = Theme.BUTTON
	slider.Text = ""
	slider.Visible = false
	slider.Parent = holder
	Instance.new("UICorner", slider).CornerRadius = UDim.new(0,6)

	local stroke2 = Instance.new("UIStroke", slider)
	stroke2.Color = Theme.STROKE
	stroke2.Transparency = 0.7
	stroke2.Thickness = 1

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0.2,0,1,0)
	fill.BackgroundColor3 = Theme.TEXT
	fill.BorderSizePixel = 0
	fill.Parent = slider
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0,6)

	-- =========================
	-- Slider
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

		Freecam.Speed = math.floor(5 + rel * 295)
		speedLabel.Text = "Speed: " .. Freecam.Speed
		fill.Size = UDim2.new(rel,0,1,0)
	end)

	-- =========================
	-- UI state helpers
	-- =========================

	uiReset = function()
		speedLabel.Visible = false
		slider.Visible = false
		toggleBtn.Text = "Drone Freecam : OFF"
		toggleBtn.TextColor3 = Theme.TEXT_DIM
	end

	-- =========================
	-- Button
	-- =========================

	toggleBtn.MouseButton1Click:Connect(function()
		if Freecam.Enabled then
			stopFreecam()
			uiReset()
		else
			startFreecam()
			speedLabel.Visible = true
			slider.Visible = true
			toggleBtn.Text = "Drone Freecam : ON"
			toggleBtn.TextColor3 = Theme.TEXT
		end
	end)

end

return Freecam
