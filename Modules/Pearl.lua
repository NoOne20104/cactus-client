-- Pearl.lua
-- Cactus Client – Ender Pearl Tool

local Pearl = {}

function Pearl.Init(Client)

	-- =========================
	-- Core
	-- =========================

	local RunService = Client.Services.RunService
	local UserInputService = Client.Services.UIS
	local Debris = game:GetService("Debris")

	local LocalPlayer = Client.Player
	local Theme = Client.Theme
	local Page = Client.Pages.Pearl

	if not Page then
		warn("[Pearl] Page not found")
		return
	end

	Page:ClearAllChildren()

	local mouse = LocalPlayer:GetMouse()
	local camera = workspace.CurrentCamera

	-- =========================
	-- Config
	-- =========================

	local MIN_THROW_SPEED = 50
	local MAX_THROW_SPEED = 700
	local DEFAULT_THROW_SPEED = 300

	-- =========================
	-- State
	-- =========================

	local State = {
		Enabled = false,
		ThrowSpeed = DEFAULT_THROW_SPEED,
		DraggingSlider = false,
	}

	-- =========================
	-- Utils
	-- =========================

	local function getCharacter()
		return LocalPlayer.Character
	end

	local function getHead()
		local character = getCharacter()
		return character and character:FindFirstChild("Head")
	end

	local function isMouseOverClientGui()
		local mousePosition = UserInputService:GetMouseLocation()

		local guiObjects =
			LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(
				mousePosition.X,
				mousePosition.Y
			)

		local cactusGui =
			LocalPlayer.PlayerGui:FindFirstChild("CactusClient")

		if not cactusGui then
			return false
		end

		for _, guiObject in ipairs(guiObjects) do
			if guiObject:IsDescendantOf(cactusGui) then
				return true
			end
		end

		return false
	end

	-- =========================
	-- Pearl logic
	-- =========================

	local function throwPearl()

		if not State.Enabled then
			return
		end

		local character = getCharacter()
		if not character then
			return
		end

		local head = getHead()
		if not head then
			return
		end

		camera = workspace.CurrentCamera

		if not camera then
			return
		end

		-- Create pearl
		local pearl = Instance.new("Part")

		pearl.Name = "GreenEnderPearl"
		pearl.Shape = Enum.PartType.Ball
		pearl.Size = Vector3.new(1.2, 1.2, 1.2)
		pearl.Material = Enum.Material.Neon
		pearl.Color = Color3.fromRGB(0, 255, 0)

		pearl.Anchored = false
		pearl.CanCollide = false
		pearl.CanTouch = false
		pearl.CastShadow = false

		-- Aim toward mouse
		local mouseRay =
			camera:ViewportPointToRay(
				mouse.X,
				mouse.Y
			)

		local direction =
			mouseRay.Direction.Unit

		-- Spawn slightly in front of player
		pearl.Position =
			head.Position
			+ direction * 3

		pearl.Parent = workspace

		-- Throw
		pearl.AssemblyLinearVelocity =
			direction * State.ThrowSpeed

		pearl.AssemblyAngularVelocity =
			Vector3.new(
				math.random(-10, 10),
				math.random(-10, 10),
				math.random(-10, 10)
			)

		-- =========================
		-- Collision raycast
		-- =========================

		local rayParams = RaycastParams.new()

		rayParams.FilterType =
			Enum.RaycastFilterType.Exclude

		rayParams.FilterDescendantsInstances = {
			character,
			pearl,
		}

		local previousPosition =
			pearl.Position

		local landed = false
		local connection

		connection =
			RunService.Heartbeat:Connect(function()

				if landed then
					return
				end

				if not pearl.Parent then
					if connection then
						connection:Disconnect()
					end
					return
				end

				local currentPosition =
					pearl.Position

				local movement =
					currentPosition
					- previousPosition

				if movement.Magnitude > 0.001 then

					local result =
						workspace:Raycast(
							previousPosition,
							movement,
							rayParams
						)

					if result then

						local hit =
							result.Instance

						local validHit =
							hit == workspace.Terrain
							or (
								hit:IsA("BasePart")
								and hit.CanCollide
							)

						if validHit then

							landed = true

							if connection then
								connection:Disconnect()
							end

							local impactPosition =
								result.Position

							pearl:Destroy()

							-- Teleport slightly above impact
							character:PivotTo(
								CFrame.new(
									impactPosition
									+ Vector3.new(0, 3, 0)
								)
							)

							return
						end
					end
				end

				previousPosition =
					currentPosition
			end)

		Debris:AddItem(pearl, 15)
	end

	-- =========================
	-- GUI
	-- =========================

	local Panel = Instance.new("Frame")

	Panel.Size =
		UDim2.new(0, 290, 1, -12)

	Panel.Position =
		UDim2.fromOffset(0, 0)

	Panel.BackgroundColor3 =
		Color3.fromRGB(14, 14, 14)

	Panel.BorderSizePixel = 0
	Panel.Parent = Page

	Instance.new(
		"UICorner",
		Panel
	).CornerRadius = UDim.new(0, 10)

	local stroke =
		Instance.new("UIStroke")

	stroke.Color = Theme.STROKE
	stroke.Thickness = 1
	stroke.Parent = Panel

	-- =========================
	-- Title
	-- =========================

	local title =
		Instance.new("TextLabel")

	title.Size =
		UDim2.new(1, 0, 0, 28)

	title.BackgroundTransparency = 1
	title.Text = "Ender Pearl"
	title.Font = Enum.Font.Code
	title.TextSize = 15
	title.TextColor3 = Theme.TEXT
	title.Parent = Panel

	-- =========================
	-- Scroll
	-- =========================

	local scroll =
		Instance.new("ScrollingFrame")

	scroll.Position =
		UDim2.new(0, 0, 0, 28)

	scroll.Size =
		UDim2.new(1, 0, 1, -28)

	scroll.CanvasSize =
		UDim2.new(0, 0, 0, 0)

	scroll.ScrollBarThickness = 4
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Parent = Panel

	local layout =
		Instance.new("UIListLayout")

	layout.Padding =
		UDim.new(0, 10)

	layout.Parent = scroll

	local pad =
		Instance.new("UIPadding")

	pad.PaddingTop = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 6)
	pad.PaddingRight = UDim.new(0, 6)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.Parent = scroll

	layout:GetPropertyChangedSignal(
		"AbsoluteContentSize"
	):Connect(function()

		scroll.CanvasSize =
			UDim2.new(
				0,
				0,
				0,
				layout.AbsoluteContentSize.Y + 10
			)
	end)

	-- =========================
	-- Enable toggle
	-- =========================

	local toggleButton =
		Instance.new("TextButton")

	toggleButton.Size =
		UDim2.new(1, 0, 0, 32)

	toggleButton.BackgroundColor3 =
		Theme.BUTTON

	toggleButton.Text =
		"Pearl Throwing : OFF"

	toggleButton.Font =
		Enum.Font.Code

	toggleButton.TextSize = 13

	toggleButton.TextColor3 =
		Theme.TEXT_DIM

	toggleButton.Parent =
		scroll

	Instance.new(
		"UICorner",
		toggleButton
	).CornerRadius = UDim.new(0, 6)

	toggleButton.MouseButton1Click:Connect(function()

		State.Enabled =
			not State.Enabled

		if State.Enabled then

			toggleButton.Text =
				"Pearl Throwing : ON"

			toggleButton.TextColor3 =
				Color3.fromRGB(0, 255, 120)

		else

			toggleButton.Text =
				"Pearl Throwing : OFF"

			toggleButton.TextColor3 =
				Theme.TEXT_DIM
		end
	end)

	-- =========================
	-- Speed slider
	-- =========================

	local sliderHolder =
		Instance.new("Frame")

	sliderHolder.Size =
		UDim2.new(1, 0, 0, 70)

	sliderHolder.BackgroundTransparency = 1
	sliderHolder.Parent = scroll

	local speedLabel =
		Instance.new("TextLabel")

	speedLabel.Size =
		UDim2.new(1, 0, 0, 22)

	speedLabel.BackgroundTransparency = 1
	speedLabel.Font = Enum.Font.Code
	speedLabel.TextSize = 12

	speedLabel.TextXAlignment =
		Enum.TextXAlignment.Left

	speedLabel.TextColor3 =
		Theme.TEXT

	speedLabel.Text =
		"Throw Speed : "
		.. tostring(State.ThrowSpeed)

	speedLabel.Parent =
		sliderHolder

	-- Slider bar
	local sliderBackground =
		Instance.new("Frame")

	sliderBackground.Position =
		UDim2.new(0, 4, 0, 32)

	sliderBackground.Size =
		UDim2.new(1, -8, 0, 8)

	sliderBackground.BackgroundColor3 =
		Color3.fromRGB(40, 40, 40)

	sliderBackground.BorderSizePixel = 0
	sliderBackground.Parent = sliderHolder

	Instance.new(
		"UICorner",
		sliderBackground
	).CornerRadius = UDim.new(1, 0)

	local startingPercent =
		(State.ThrowSpeed - MIN_THROW_SPEED)
		/
		(MAX_THROW_SPEED - MIN_THROW_SPEED)

	-- Slider fill
	local sliderFill =
		Instance.new("Frame")

	sliderFill.Size =
		UDim2.new(
			startingPercent,
			0,
			1,
			0
		)

	sliderFill.BackgroundColor3 =
		Color3.fromRGB(0, 255, 120)

	sliderFill.BorderSizePixel = 0
	sliderFill.Parent = sliderBackground

	Instance.new(
		"UICorner",
		sliderFill
	).CornerRadius = UDim.new(1, 0)

	-- Slider knob
	local sliderKnob =
		Instance.new("Frame")

	sliderKnob.AnchorPoint =
		Vector2.new(0.5, 0.5)

	sliderKnob.Position =
		UDim2.new(
			startingPercent,
			0,
			0.5,
			0
		)

	sliderKnob.Size =
		UDim2.fromOffset(16, 16)

	sliderKnob.BackgroundColor3 =
		Color3.fromRGB(230, 230, 230)

	sliderKnob.BorderSizePixel = 0
	sliderKnob.Parent = sliderBackground

	Instance.new(
		"UICorner",
		sliderKnob
	).CornerRadius = UDim.new(1, 0)

	-- Invisible slider input
	local sliderInput =
		Instance.new("TextButton")

	sliderInput.Size =
		UDim2.new(1, 0, 0, 32)

	sliderInput.Position =
		UDim2.new(0, 0, 0.5, -16)

	sliderInput.BackgroundTransparency = 1
	sliderInput.Text = ""
	sliderInput.AutoButtonColor = false
	sliderInput.Parent = sliderBackground

	-- =========================
	-- Slider update
	-- =========================

	local function updateSlider(inputX)

		local absolutePosition =
			sliderBackground.AbsolutePosition.X

		local absoluteSize =
			sliderBackground.AbsoluteSize.X

		if absoluteSize <= 0 then
			return
		end

		local percent =
			(inputX - absolutePosition)
			/
			absoluteSize

		percent =
			math.clamp(percent, 0, 1)

		local speed =
			MIN_THROW_SPEED
			+
			(MAX_THROW_SPEED - MIN_THROW_SPEED)
			* percent

		-- Snap to nearest 10
		speed =
			math.floor(
				speed / 10 + 0.5
			) * 10

		State.ThrowSpeed = speed

		local visualPercent =
			(State.ThrowSpeed - MIN_THROW_SPEED)
			/
			(MAX_THROW_SPEED - MIN_THROW_SPEED)

		sliderFill.Size =
			UDim2.new(
				visualPercent,
				0,
				1,
				0
			)

		sliderKnob.Position =
			UDim2.new(
				visualPercent,
				0,
				0.5,
				0
			)

		speedLabel.Text =
			"Throw Speed : "
			.. tostring(State.ThrowSpeed)
	end

	-- =========================
	-- Slider input
	-- =========================

	sliderInput.InputBegan:Connect(function(input)

		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then

			State.DraggingSlider = true

			updateSlider(
				input.Position.X
			)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)

		if not State.DraggingSlider then
			return
		end

		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then

			updateSlider(
				input.Position.X
			)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)

		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then

			State.DraggingSlider = false
		end
	end)

	-- =========================
	-- Speed range
	-- =========================

	local rangeLabel =
		Instance.new("TextLabel")

	rangeLabel.Position =
		UDim2.new(0, 2, 0, 46)

	rangeLabel.Size =
		UDim2.new(1, -4, 0, 18)

	rangeLabel.BackgroundTransparency = 1
	rangeLabel.Font = Enum.Font.Code
	rangeLabel.TextSize = 11

	rangeLabel.TextXAlignment =
		Enum.TextXAlignment.Left

	rangeLabel.TextColor3 =
		Theme.TEXT_DIM

	rangeLabel.Text =
		string.format(
			"%d  —  %d",
			MIN_THROW_SPEED,
			MAX_THROW_SPEED
		)

	rangeLabel.Parent =
		sliderHolder

	-- =========================
	-- Left click throwing
	-- =========================

	mouse.Button1Down:Connect(function()

		if not State.Enabled then
			return
		end

		if State.DraggingSlider then
			return
		end

		-- Clicking anywhere inside CactusClient
		-- will NOT throw a pearl
		if isMouseOverClientGui() then
			return
		end

		throwPearl()
	end)
end

return Pearl
