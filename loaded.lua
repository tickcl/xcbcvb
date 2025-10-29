local _raw_load = loadstring or load
loadstring = function(src)
	if type(src) ~= "string" then
		return nil, "bad argument #1 to 'loadstring' (string expected)"
	end

	if src:find("\0", 1, true) then
		return nil, "Luau bytecode should not be loadable!"
	end

	local ok, res = pcall(_raw_load, src)
	if not ok then
		return nil, tostring(res)
	end

	return res
end

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "NFIconAnim"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local icon = Instance.new("Frame")
icon.AnchorPoint = Vector2.new(1, 0)
icon.Position = UDim2.new(1, -30, 0, 30)
icon.Size = UDim2.new(0, 0, 0, 0)
icon.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
icon.BackgroundTransparency = 1
icon.BorderSizePixel = 0
icon.ClipsDescendants = true
icon.ZIndex = 1
icon.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 20)
corner.Parent = icon

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 80, 160)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 100))
}
gradient.Rotation = 45
gradient.Parent = icon

local label = Instance.new("TextLabel")
label.Name = "NFLabel"
label.Text = "NF"
label.Font = Enum.Font.GothamBold
label.TextScaled = true
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.BackgroundTransparency = 1
label.AnchorPoint = Vector2.new(0.5, 0.5)
label.Position = UDim2.fromScale(0.5, 0.5)
label.Size = UDim2.fromScale(0.65, 0.65)
label.TextTransparency = 1
label.TextStrokeTransparency = 0.7
label.TextStrokeColor3 = Color3.fromRGB(0,0,0)
label.ZIndex = 5
label.Parent = icon

local function tweenGradient(fromA, fromB, toA, toB, duration)
	local startTime = tick()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = math.clamp((tick() - startTime) / duration, 0, 1)
		local col1 = fromA:Lerp(toA, t)
		local col2 = fromB:Lerp(toB, t)
		gradient.Color = ColorSequence.new{
			ColorSequenceKeypoint.new(0, col1),
			ColorSequenceKeypoint.new(1, col2)
		}
		if t >= 1 then
			conn:Disconnect()
		end
	end)
end

local appearTween = TweenService:Create(icon, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
	Size = UDim2.new(0, 70, 0, 70),
	BackgroundTransparency = 0
})
appearTween:Play()

task.delay(0.18, function()
	TweenService:Create(label, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		TextTransparency = 0
	}):Play()
end)

task.wait(0.45)
TweenService:Create(icon, TweenInfo.new(0.38, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
	Size = UDim2.new(0, 80, 0, 80)
}):Play()

tweenGradient(
	Color3.fromRGB(80,80,160),
	Color3.fromRGB(40,40,100),
	Color3.fromRGB(120,120,220),
	Color3.fromRGB(60,60,160),
	0.38
)

task.wait(0.38)
TweenService:Create(icon, TweenInfo.new(0.36, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
	Size = UDim2.new(0, 70, 0, 70)
}):Play()

tweenGradient(
	Color3.fromRGB(120,120,220),
	Color3.fromRGB(60,60,160),
	Color3.fromRGB(80,80,160),
	Color3.fromRGB(40,40,100),
	0.36
)

task.wait(0.9)
TweenService:Create(icon, TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
	BackgroundTransparency = 1,
	Size = UDim2.new(0, 0, 0, 0)
}):Play()
TweenService:Create(label, TweenInfo.new(0.35), {
	TextTransparency = 1
}):Play()

task.wait(0.7)
gui:Destroy()
