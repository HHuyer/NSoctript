local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HRP = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid")

local enabled = true
local tweenSpeed = 300    -- studs per second
local threshold = 10
local maxAttempts = 20
local areaRadius = 50
local maxDistance = 50    -- khoảng cách tối đa mặc định
local isTweening = false

-- Vẽ vòng tròn minh họa khoảng cách tối đa
local function drawRangeCircle(radius)
    -- Xóa vòng cũ nếu có
    for _, v in pairs(workspace:GetChildren()) do
        if v.Name == "SafeTweenRangeCircle" then
            v:Destroy()
        end
    end

    local circle = Instance.new("Part")
    circle.Name = "SafeTweenRangeCircle"
    circle.Anchored = true
    circle.CanCollide = false
    circle.Transparency = 0.6
    circle.Material = Enum.Material.Neon
    circle.Color = Color3.fromRGB(0, 170, 255)
    circle.Shape = Enum.PartType.Cylinder
    circle.Size = Vector3.new(radius*2, 0.2, radius*2)
    circle.CFrame = HRP.CFrame * CFrame.new(0, -HRP.Size.Y/2, 0) * CFrame.Angles(math.rad(90), 0, 0)
    circle.Parent = workspace

    Debris:AddItem(circle, 1) -- tự động hủy sau 1 giây
end

-- Tạo GUI đơn giản
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AutoSafeTweenGUI"
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 260, 0, 150)
frame.Position = UDim2.new(0, 10, 0, 10)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BackgroundTransparency = 0.2
frame.Parent = screenGui

local uiCorner = Instance.new("UICorner")
uiCorner.CornerRadius = UDim.new(0, 8)
uiCorner.Parent = frame

local title = Instance.new("TextLabel")
title.Text = "Auto Safe Tween"
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1,1,1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 18
title.Parent = frame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Text = "Enabled"
toggleBtn.Size = UDim2.new(0, 80, 0, 30)
toggleBtn.Position = UDim2.new(0, 10, 0, 40)
toggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.TextSize = 16
toggleBtn.Parent = frame

local speedLabel = Instance.new("TextLabel")
speedLabel.Text = "Speed (studs/s):"
speedLabel.Size = UDim2.new(0, 100, 0, 25)
speedLabel.Position = UDim2.new(0, 100, 0, 40)
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = Color3.new(1,1,1)
speedLabel.Font = Enum.Font.SourceSans
speedLabel.TextSize = 14
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = frame

local speedBox = Instance.new("TextBox")
speedBox.Text = tostring(tweenSpeed)
speedBox.Size = UDim2.new(0, 70, 0, 25)
speedBox.Position = UDim2.new(0, 100, 0, 65)
speedBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
speedBox.TextColor3 = Color3.new(1,1,1)
speedBox.Font = Enum.Font.SourceSans
speedBox.TextSize = 14
speedBox.ClearTextOnFocus = false
speedBox.Parent = frame

local distLabel = Instance.new("TextLabel")
distLabel.Text = "Max Distance:"
distLabel.Size = UDim2.new(0, 100, 0, 25)
distLabel.Position = UDim2.new(0, 10, 0, 95)
distLabel.BackgroundTransparency = 1
distLabel.TextColor3 = Color3.new(1,1,1)
distLabel.Font = Enum.Font.SourceSans
distLabel.TextSize = 14
distLabel.TextXAlignment = Enum.TextXAlignment.Left
distLabel.Parent = frame

local distBox = Instance.new("TextBox")
distBox.Text = tostring(maxDistance)
distBox.Size = UDim2.new(0, 70, 0, 25)
distBox.Position = UDim2.new(0, 100, 0, 95)
distBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
distBox.TextColor3 = Color3.new(1,1,1)
distBox.Font = Enum.Font.SourceSans
distBox.TextSize = 14
distBox.ClearTextOnFocus = false
distBox.Parent = frame

toggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    toggleBtn.Text = enabled and "Enabled" or "Disabled"
    toggleBtn.BackgroundColor3 = enabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(170,0,0)
end)

speedBox.FocusLost:Connect(function()
    local val = tonumber(speedBox.Text)
    if val and val > 0 then
        tweenSpeed = val
    else
        speedBox.Text = tostring(tweenSpeed)
    end
end)

distBox.FocusLost:Connect(function()
    local val = tonumber(distBox.Text)
    if val and val > 0 then
        maxDistance = val
        drawRangeCircle(maxDistance)
    else
        distBox.Text = tostring(maxDistance)
    end
end)

local function isPositionSafe(p)
    local ray = workspace:Raycast(p + Vector3.new(0, 50, 0), Vector3.new(0, -100, 0))
    if not ray or not ray.Instance or not ray.Instance.CanCollide then return false end

    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LocalPlayer and pl.Character then
            local o = pl.Character:FindFirstChild("HumanoidRootPart")
            if o and (o.Position - p).Magnitude <= threshold then return false end
        end
    end

    local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true})
    path:ComputeAsync(HRP.Position, p)
    return path.Status == Enum.PathStatus.Success
end

local function findSafePosition()
    local lookVector = HRP.CFrame.LookVector
    for i = 1, maxAttempts do
        local forwardOffset = lookVector * math.random(10, maxDistance)
        local randomOffset = Vector3.new(math.random(-threshold, threshold), 0, math.random(-threshold, threshold))
        local candidatePos = HRP.Position + forwardOffset + randomOffset
        candidatePos = Vector3.new(candidatePos.X, HRP.Position.Y, candidatePos.Z)

        if isPositionSafe(candidatePos) then
            return candidatePos
        end
    end

    for i = 1, maxAttempts do
        local off = Vector3.new(math.random(-maxDistance, maxDistance), 0, math.random(-maxDistance, maxDistance))
        local c = HRP.Position + Vector3.new(off.X, 0, off.Z)
        if isPositionSafe(c) then return c end
    end

    return nil
end

local function tweenToPosition(pos)
    if isTweening then return end
    isTweening = true

    local distance = (HRP.Position - pos).Magnitude
    local time = distance / tweenSpeed

    local tweenInfo = TweenInfo.new(time, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(HRP, tweenInfo, {CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)})

    tween:Play()
    tween.Completed:Wait()

    isTweening = false
end

-- Detect khi người chơi bắt đầu nhảy
Humanoid.StateChanged:Connect(function(old, new)
    if new == Enum.HumanoidStateType.Jumping and enabled and not isTweening then
        local safePos = findSafePosition()
        if safePos then
            tweenToPosition(safePos)
        end
    end
end)
