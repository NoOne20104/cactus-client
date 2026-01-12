local Freecam = {}

function Freecam.Init(Client)

	-- =========================
	-- Services / Core
	-- =========================

	local UIS = game:GetService("UserInputService")
	local RunService = Client.Services.RunService
	local LocalPlayer = Client.Player
	local Page = Client.Pages.Freecam
	local Theme = Client.Theme
	local Camera = workspace.CurrentCamera

	-- =========================
	-- State
	-- =========================

	Freecam.Enabled = false
	Freecam.Mode = "freecam" -- freecam | drone
	Freecam.Speed = 60
	Freecam.Sensitivity = 0.25

	local camConn
	local yaw = 0
	local pitch = 0
	local camDist = 0

	local saved = {}

	-- =========================
	-- Core Freecam
	-- =========================

	local function startFreecam()
		if Freecam.Enabled then return end
		if not Camera then return end

		Freecam.Enabled = true

		saved.Type = Camera.CameraType
		saved.Subject = Camera.CameraSubject
		saved.CFrame = Camera.CFrame
		saved.MouseBehavior = UIS.MouseBehavior
		saved.MouseIcon = UIS.MouseIconEnabled

		Camera.CameraType = Enum.CameraType.Scriptable

		if Freecam.Mode == "freecam" then
			UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
			UIS.MouseIconEnabled = false
		else
			UIS.MouseBehavior = Enum.MouseBehavior.Default
			UIS.MouseIconEnabled = true
		end

		local cf = Camera.CFrame
		local look = cf.LookVector
		yaw = math.atan2(-look.X, -look.Z)
		pitch = math.asin(look.Y)

		camConn = RunService.RenderStepped:Connect(function(dt)

			-- mouse look
			if Freecam.Mode == "freecam" then
				local delta = UIS:GetMouseDelta()
				yaw -= delta.X * Freecam.Sensitivity * 0.01
				pitch -= delta.Y * Freecam.Sensitivity * 0.01
				pitch = math.clamp(pitch, -1.5, 1.5)
			end

			local rot = CFrame.fromOrientation(pitch, yaw, 0)

			-- movement
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

			local basePos = Camera.CFrame.Position + dir
			local camCF = CFrame.new(basePos) * rot

			-- third person offset (Freecam only)
			if Freecam.Mode == "freecam" then
				camCF = camCF * CFrame.new(0, 0, camDist)
			end

			Camera.CFrame = camCF
		end)
	end

	local function stopFreecam()
		if not Freecam.Enabled then return end
		Freecam.Enabled = false

		if camConn then camConn:Disconnect() camConn = nil end

		if Camera then
			Camera.CameraType = saved.Type
			Camera.CameraSubject = saved.Subject
			Camera.CFrame = saved.CFrame
		end

		UIS.MouseBehavior = saved.MouseBehavior
		UIS.MouseIconEnabled = saved.MouseIcon
	end

	-- =========================
	-- Zoom controls (Freecam only)
	-- =========================

	UIS.InputChanged:Connect(function(input)
		if not Freecam.Enabled then return end
		if Freecam.Mode ~= "freecam" then return end

		if input.UserInputType == Enum.UserInputType.MouseWheel then
			camDist = math.clamp(camDist - input.Position.Z * 2, -100, 0)
		end
	end)

	-- =========================
	-- GUI
	-- =========================

	for _,child in ipairs(Page:GetChildren()) do
		if child:IsA("Frame") and child.Name == "CactusFreecamFrame" then
			child:Destroy()
		end
	end

	local frame = Instance.new("Frame")
	frame.Name = "CactusFreecamFrame"
	frame.Size = UDim2.new(0,220,0,210)
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
	title.Text = "Freecam"
	title.Font = Enum.Font.Code
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Theme.TEXT
	title.Parent = frame

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

	local freeBtn  = makeButton("Freecam : OFF")
	local droneBtn = makeButton("Drone Freecam : OFF")

	local speedLabel = Instance.new("TextLabel")
	speedLabel.Size = UDim2.new(1,0,0,18)
	speedLabel.BackgroundTransparency = 1
	speedLabel.Text = "Speed: 60"
	speedLabel.Font = Enum.Font.Code
	speedLabel.TextSize = 13
	speedLabel.TextXAlignment = Enum.TextXAlignment.Left
	speedLabel.TextColor3 = Theme.TEXT_DIM
	speedLabel.Parent = holder

	-- =========================
	-- Buttons
	-- =========================

	freeBtn.MouseButton1Click:Connect(function()
		if Freecam.Enabled and Freecam.Mode == "freecam" then
			stopFreecam()
			freeBtn.Text = "Freecam : OFF"
			freeBtn.TextColor3 = Theme.TEXT_DIM
			return
		end

		stopFreecam()
		Freecam.Mode = "freecam"
		startFreecam()

		freeBtn.Text = "Freecam : ON"
		freeBtn.TextColor3 = Theme.TEXT
		droneBtn.Text = "Drone Freecam : OFF"
		droneBtn.TextColor3 = Theme.TEXT_DIM
	end)

	droneBtn.MouseButton1Click:Connect(function()
		if Freecam.Enabled and Freecam.Mode == "drone" then
			stopFreecam()
			droneBtn.Text = "Drone Freecam : OFF"
			droneBtn.TextColor3 = Theme.TEXT_DIM
			return
		end

		stopFreecam()
		Freecam.Mode = "drone"
		startFreecam()

		droneBtn.Text = "Drone Freecam : ON"
		droneBtn.TextColor3 = Theme.TEXT
		freeBtn.Text = "Freecam : OFF"
		freeBtn.TextColor3 = Theme.TEXT_DIM
	end)

	-- safety reset
	LocalPlayer.CharacterAdded:Connect(function()
		if Freecam.Enabled then
			task.wait(0.2)
			stopFreecam()
			freeBtn.Text = "Freecam : OFF"
			freeBtn.TextColor3 = Theme.TEXT_DIM
			droneBtn.Text = "Drone Freecam : OFF"
			droneBtn.TextColor3 = Theme.TEXT_DIM
		end
	end)
end

return Freecam
