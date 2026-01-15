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
	Freecam.Mode = "drone" -- "drone" or "freecam"
	Freecam.Speed = 60
	Freecam.Sensitivity = 0.25

	local yaw = 0
	local pitch = 0
	local looking = false
	local camPos

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

		freezeCharacter()

		Camera.CameraType = Enum.CameraType.Scriptable
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		UIS.MouseIconEnabled = true

		local cf = Camera.CFrame
		local look = cf.LookVector
		yaw = math.atan2(-look.X, -look.Z)
		pitch = math.asin(look.Y)
		camPos = cf.Position

		RunService:BindToRenderStep("CactusFreecam", Enum.RenderPriority.Camera.Value, function(dt)

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

			camPos = camPos + dir

			-- =========================
			-- CAMERA BUILD (FIXED)
			-- =========================

			if Freecam.Mode == "freecam" then
				-- TRUE third person orbit cam
				local distance = 10
				local height = 2

				local offset =
					(rot.LookVector * -distance) +
					Vector3.new(0, height, 0)

				local camWorld = camPos + offset
				Camera.CFrame = CFrame.lookAt(camWorld, camPos)
			else
				-- Drone cam (true first person)
				Camera.CFrame = CFrame.new(camPos) * rot
			end
		end)
	end

	local function stopFreecam()
		if not Freecam.Enabled then return end
		Freecam.Enabled = false

		RunService:UnbindFromRenderStep("CactusFreecam")

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
	-- GUI
	-- =========================

	for _,child in ipairs(Page:GetChildren()) do
		if child:IsA("Frame") and child.Name == "CactusFreecamFrame" then
			child:Destroy()
		end
	end

	local frame = Instance.new("Frame")
	frame.Name = "CactusFreecamFrame"
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

	local droneBtn = makeButton("Drone Freecam : OFF")
	local freeBtn  = makeButton("Freecam : OFF")

	-- =========================
	-- Buttons
	-- =========================

	droneBtn.MouseButton1Click:Connect(function()
		if Freecam.Enabled and Freecam.Mode == "drone" then
			stopFreecam()
			droneBtn.Text = "Drone Freecam : OFF"
			droneBtn.TextColor3 = Theme.TEXT_DIM
			return
		end

		Freecam.Mode = "drone"
		freeBtn.Text = "Freecam : OFF"
		freeBtn.TextColor3 = Theme.TEXT_DIM

		startFreecam()
		droneBtn.Text = "Drone Freecam : ON"
		droneBtn.TextColor3 = Theme.TEXT
	end)

	freeBtn.MouseButton1Click:Connect(function()
		if Freecam.Enabled and Freecam.Mode == "freecam" then
			stopFreecam()
			freeBtn.Text = "Freecam : OFF"
			freeBtn.TextColor3 = Theme.TEXT_DIM
			return
		end

		Freecam.Mode = "freecam"
		droneBtn.Text = "Drone Freecam : OFF"
		droneBtn.TextColor3 = Theme.TEXT_DIM

		startFreecam()
		freeBtn.Text = "Freecam : ON"
		freeBtn.TextColor3 = Theme.TEXT
	end)

	LocalPlayer.CharacterAdded:Connect(function()
		if Freecam.Enabled then
			task.wait(0.2)
			stopFreecam()
			droneBtn.Text = "Drone Freecam : OFF"
			freeBtn.Text = "Freecam : OFF"
			droneBtn.TextColor3 = Theme.TEXT_DIM
			freeBtn.TextColor3 = Theme.TEXT_DIM
		end
	end)
end

return Freecam
