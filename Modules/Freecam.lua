local Freecam = {}

function Freecam.Init(Client)

	-- =========================
	-- Services
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
	Freecam.Mode = "drone" -- "drone" | "freecam"
	Freecam.Speed = 60
	Freecam.Sensitivity = 0.25

	local yaw = 0
	local pitch = 0
	local looking = false

	local camPos
	local focusPos
	local camConn

	local saved = {}

	-- =========================
	-- Character freeze
	-- =========================

	local function freezeCharacter()
		local char = LocalPlayer.Character
		if not char then return end

		local hum = char:FindFirstChildOfClass("Humanoid")
		local root = char:FindFirstChild("HumanoidRootPart")

		if hum then
			saved.WalkSpeed = hum.WalkSpeed
			saved.JumpPower = hum.JumpPower
			hum.WalkSpeed = 0
			hum.JumpPower = 0
		end

		if root then
			root.Anchored = true
		end
	end

	local function unfreezeCharacter()
		local char = LocalPlayer.Character
		if not char then return end

		local hum = char:FindFirstChildOfClass("Humanoid")
		local root = char:FindFirstChild("HumanoidRootPart")

		if hum then
			hum.WalkSpeed = saved.WalkSpeed or 16
			hum.JumpPower = saved.JumpPower or 50
		end

		if root then
			root.Anchored = false
		end
	end

	-- =========================
	-- Core
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

		freezeCharacter()

		Camera.CameraType = Enum.CameraType.Scriptable
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		UIS.MouseIconEnabled = true

		local look = Camera.CFrame.LookVector
		yaw = math.atan2(-look.X, -look.Z)
		pitch = math.asin(look.Y)

		camPos = Camera.CFrame.Position
		focusPos = Camera.CFrame.Position + look * 12

		camConn = RunService.RenderStepped:Connect(function(dt)

			if looking then
				local delta = UIS:GetMouseDelta()
				yaw -= delta.X * Freecam.Sensitivity * 0.01
				pitch -= delta.Y * Freecam.Sensitivity * 0.01
				pitch = math.clamp(pitch, -1.4, 1.4)
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

			if Freecam.Mode == "drone" then
				camPos += dir
				Camera.CFrame = CFrame.new(camPos) * rot
			else
				focusPos += dir
				local distance = 12
				local camWorld = focusPos - rot.LookVector * distance
				Camera.CFrame = CFrame.lookAt(camWorld, focusPos)
			end
		end)
	end

	local function stopFreecam()
		if not Freecam.Enabled then return end
		Freecam.Enabled = false

		if camConn then camConn:Disconnect() camConn = nil end

		unfreezeCharacter()

		if Camera then
			Camera.CameraType = saved.Type
			Camera.CameraSubject = saved.Subject
			Camera.CFrame = saved.CFrame
		end

		UIS.MouseBehavior = saved.MouseBehavior
		UIS.MouseIconEnabled = saved.MouseIcon
	end

	-- =========================
	-- Right click look
	-- =========================

	UIS.InputBegan:Connect(function(i)
		if not Freecam.Enabled then return end
		if i.UserInputType == Enum.UserInputType.MouseButton2 then
			looking = true
			UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
			UIS.MouseIconEnabled = false
		end
	end)

	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton2 then
			looking = false
			if Freecam.Enabled then
				UIS.MouseBehavior = Enum.MouseBehavior.Default
				UIS.MouseIconEnabled = true
			end
		end
	end)

	-- =========================
	-- GUI
	-- =========================

	for _,v in ipairs(Page:GetChildren()) do
		if v:IsA("Frame") then v:Destroy() end
	end

	local frame = Instance.new("Frame", Page)
	frame.Size = UDim2.new(0,220,0,170)
	frame.Position = UDim2.new(0,10,0,10)
	frame.BackgroundColor3 = Color3.fromRGB(14,14,14)
	frame.BorderSizePixel = 0
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)

	local stroke = Instance.new("UIStroke", frame)
	stroke.Color = Theme.STROKE
	stroke.Transparency = 0.4

	local holder = Instance.new("Frame", frame)
	holder.Size = UDim2.new(1,-20,1,-20)
	holder.Position = UDim2.new(0,10,0,10)
	holder.BackgroundTransparency = 1

	local layout = Instance.new("UIListLayout", holder)
	layout.Padding = UDim.new(0,6)

	local function makeButton(txt)
		local b = Instance.new("TextButton", holder)
		b.Size = UDim2.new(1,0,0,30)
		b.BackgroundColor3 = Theme.BUTTON
		b.Text = txt
		b.Font = Enum.Font.Code
		b.TextSize = 14
		b.TextColor3 = Theme.TEXT_DIM
		b.BorderSizePixel = 0
		Instance.new("UICorner", b).CornerRadius = UDim.new(0,6)
		return b
	end

	local droneBtn = makeButton("Drone Freecam : OFF")
	local freeBtn = makeButton("Freecam : OFF")

	droneBtn.MouseButton1Click:Connect(function()
		if Freecam.Enabled and Freecam.Mode == "drone" then
			stopFreecam()
			droneBtn.Text = "Drone Freecam : OFF"
			return
		end
		stopFreecam()
		Freecam.Mode = "drone"
		startFreecam()
		droneBtn.Text = "Drone Freecam : ON"
		freeBtn.Text = "Freecam : OFF"
	end)

	freeBtn.MouseButton1Click:Connect(function()
		if Freecam.Enabled and Freecam.Mode == "freecam" then
			stopFreecam()
			freeBtn.Text = "Freecam : OFF"
			return
		end
		stopFreecam()
		Freecam.Mode = "freecam"
		startFreecam()
		freeBtn.Text = "Freecam : ON"
		droneBtn.Text = "Drone Freecam : OFF"
	end)
end

return Freecam
