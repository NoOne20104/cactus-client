-- Fullbright.lua
-- Cactus Client – Environment / Visibility Tool
-- Adjustable Fullbright + Gamma + Auto Mode
-- Safe state caching & restore

local Fullbright = {}

function Fullbright.Init(Client)

	-- =========================
	-- Services / Core
	-- =========================

	local Lighting = game:GetService("Lighting")
	local RunService = game:GetService("RunService")
	local UserInputService = game:GetService("UserInputService")

	local Page = Client.Pages.Fullbright
	local Theme = Client.Theme

	if not Page then
		warn("[Fullbright] Page not found")
		return
	end

	Page:ClearAllChildren()

	-- =========================
	-- State
	-- =========================

	local Enabled = false
	local AutoMode = false

	local Brightness = 2
	local Gamma = 1

	local Cached = {}
	local Loop

	-- =========================
	-- Cache & Restore
	-- =========================

	local function CacheLighting()
		Cached = {
			Brightness = Lighting.Brightness,
			Ambient = Lighting.Ambient,
			OutdoorAmbient = Lighting.OutdoorAmbient,
			GlobalShadows = Lighting.GlobalShadows,
			FogEnd = Lighting.FogEnd,
			Exposure = Lighting.ExposureCompensation,
		}
	end

	local function RestoreLighting()
		for prop,val in pairs(Cached) do
			pcall(function()
				Lighting[prop] = val
			end)
		end
	end

	-- =========================
	-- Auto Brightness (FIXED)
	-- =========================

	local function GetAutoBrightness()
		local t = Lighting.ClockTime
		local dist = math.abs(t - 12)
		local darkness = math.clamp(dist / 12, 0, 1)

		-- reacts to time of day
		local auto = 1.8 + (darkness * 2)

		-- also reacts if the game is set very dark
		if Lighting.Brightness < 2 then
			auto += (2 - Lighting.Brightness)
		end

		return auto
	end

	-- =========================
	-- Apply Fullbright
	-- =========================

	local function Apply()
		if not Enabled then return end

		local finalBrightness = Brightness

		if AutoMode then
			finalBrightness = GetAutoBrightness()
		end

		Lighting.GlobalShadows = false
		Lighting.Ambient = Color3.fromRGB(255,255,255)
		Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
		Lighting.FogEnd = 1e6
		Lighting.Brightness = finalBrightness
		Lighting.ExposureCompensation = Gamma
	end

	-- =========================
	-- Enable / Disable
	-- =========================

	local function Enable()
		if Enabled then return end
		Enabled = true

		CacheLighting()
		Apply()

		Loop = RunService.Heartbeat:Connect(function()
			if Enabled then
				Apply()
			end
		end)
	end

	local function Disable()
		if not Enabled then return end
		Enabled = false

		if Loop then
			Loop:Disconnect()
			Loop = nil
		end

		RestoreLighting()
	end

	-- =========================
	-- GUI
	-- =========================

	local Panel = Instance.new("Frame")
	Panel.Size = UDim2.new(0,260,0,205)
	Panel.BackgroundColor3 = Color3.fromRGB(14,14,14)
	Panel.BorderSizePixel = 0
	Panel.Parent = Page
	Instance.new("UICorner", Panel).CornerRadius = UDim.new(0,10)

	local stroke = Instance.new("UIStroke", Panel)
	stroke.Color = Theme.STROKE
	stroke.Thickness = 1

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1,0,0,26)
	title.BackgroundTransparency = 1
	title.Text = "Fullbright"
	title.Font = Enum.Font.Code
	title.TextSize = 15
	title.TextColor3 = Theme.TEXT
	title.Parent = Panel

	-- =========================
	-- Toggle
	-- =========================

	local toggle = Instance.new("TextButton")
	toggle.Position = UDim2.new(0,8,0,34)
	toggle.Size = UDim2.new(1,-16,0,26)
	toggle.BackgroundColor3 = Theme.BUTTON
	toggle.Text = "Fullbright : OFF"
	toggle.Font = Enum.Font.Code
	toggle.TextSize = 13
	toggle.TextColor3 = Theme.TEXT_DIM
	toggle.Parent = Panel
	Instance.new("UICorner", toggle).CornerRadius = UDim.new(0,6)

	toggle.MouseButton1Click:Connect(function()
		if not Enabled then
			Enable()
			toggle.Text = "Fullbright : ON"
			toggle.TextColor3 = Theme.TEXT
		else
			Disable()
			toggle.Text = "Fullbright : OFF"
			toggle.TextColor3 = Theme.TEXT_DIM
		end
	end)

	-- =========================
	-- Auto Mode Button
	-- =========================

	local autoBtn = Instance.new("TextButton")
	autoBtn.Position = UDim2.new(0,8,0,66)
	autoBtn.Size = UDim2.new(1,-16,0,24)
	autoBtn.BackgroundColor3 = Theme.BUTTON
	autoBtn.Text = "Auto Mode : OFF"
	autoBtn.Font = Enum.Font.Code
	autoBtn.TextSize = 12
	autoBtn.TextColor3 = Theme.TEXT_DIM
	autoBtn.Parent = Panel
	Instance.new("UICorner", autoBtn).CornerRadius = UDim.new(0,6)

	autoBtn.MouseButton1Click:Connect(function()
		AutoMode = not AutoMode

		if AutoMode then
			autoBtn.Text = "Auto Mode : ON"
			autoBtn.TextColor3 = Theme.TEXT
		else
			autoBtn.Text = "Auto Mode : OFF"
			autoBtn.TextColor3 = Theme.TEXT_DIM
		end
	end)

	-- =========================
	-- Slider helper
	-- =========================

	local function MakeSlider(labelText, y, min, max, default, onChange)

		local label = Instance.new("TextLabel")
		label.Position = UDim2.new(0,8,0,y)
		label.Size = UDim2.new(1,-16,0,18)
		label.BackgroundTransparency = 1
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.Text = labelText .. ": " .. default
		label.Font = Enum.Font.Code
		label.TextSize = 12
		label.TextColor3 = Theme.TEXT_DIM
		label.Parent = Panel

		local bar = Instance.new("Frame")
		bar.Position = UDim2.new(0,8,0,y+20)
		bar.Size = UDim2.new(1,-16,0,6)
		bar.BackgroundColor3 = Color3.fromRGB(30,30,30)
		bar.BorderSizePixel = 0
		bar.Parent = Panel
		Instance.new("UICorner", bar).CornerRadius = UDim.new(0,3)

		local fill = Instance.new("Frame")
		fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
		fill.BackgroundColor3 = Theme.STROKE
		fill.BorderSizePixel = 0
		fill.Parent = bar
		Instance.new("UICorner", fill).CornerRadius = UDim.new(0,3)

		local dragging = false

		bar.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
			end
		end)

		bar.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = false
			end
		end)

		RunService.RenderStepped:Connect(function()
			if dragging then
				local mouseX = UserInputService:GetMouseLocation().X
				local rel = math.clamp((mouseX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
				fill.Size = UDim2.new(rel,0,1,0)

				local value = min + (max-min)*rel
				value = math.floor(value*100)/100

				label.Text = labelText .. ": " .. value
				onChange(value)
			end
		end)
	end

	-- =========================
	-- Sliders
	-- =========================

	MakeSlider("Brightness", 98, 0.5, 5, Brightness, function(v)
		Brightness = v
	end)

	MakeSlider("Gamma", 140, 0, 3, Gamma, function(v)
		Gamma = v
	end)
end

return Fullbright

