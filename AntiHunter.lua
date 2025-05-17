-- LocalScript: TeleportWithGUI (đặt trong StarterPlayerScripts)

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")
local UserInputService   = game:GetService("UserInputService")
local StarterPlayer      = game:GetService("StarterPlayer")

local LocalPlayer = Players.LocalPlayer
local Character   = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local HRP         = Character:WaitForChild("HumanoidRootPart")
local Humanoid    = Character:WaitForChild("Humanoid")

-- Tham số mặc định và giới hạn
local speed        = 300
local minSpeed     = 50
local maxSpeed     = 300
local threshold    = 10
local minThreshold = 10
local maxThreshold = 100
local areaRadius   = 50
local maxAttempts  = 20

-- Panic mode
local panicking        = false
local panicDuration    = 30    -- seconds (giảm xuống 30 giây)
local panicStartTime   = 0

local isTweening = false
local minimized = false

-- Tạo GUI điều chỉnh (giữ nguyên như trước)
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
local screenGui = Instance.new("ScreenGui") screenGui.Name="TeleportSettingsGUI" screenGui.ResetOnSpawn=false screenGui.Parent=playerGui
local frame = Instance.new("Frame") frame.Name="SettingsFrame" frame.Size=UDim2.new(0,200,0,170) frame.Position=UDim2.new(0,10,0,10) frame.BackgroundTransparency=0.3 frame.BackgroundColor3=Color3.fromRGB(0,0,0) frame.Parent=screenGui
local uiCorner = Instance.new("UICorner") uiCorner.CornerRadius=UDim.new(0,6) uiCorner.Parent=frame
local content = Instance.new("Frame") content.Name="Content" content.Size=UDim2.new(1,0,1,-24) content.Position=UDim2.new(0,0,0,24) content.BackgroundTransparency=1 content.Parent=frame
local titleBar = Instance.new("Frame") titleBar.Name="TitleBar" titleBar.Size=UDim2.new(1,0,0,24) titleBar.BackgroundTransparency=1 titleBar.Parent=frame
local titleLabel = Instance.new("TextLabel") titleLabel.Size=UDim2.new(1,-90,1,0) titleLabel.Position=UDim2.new(0,5,0,0) titleLabel.Text="Settings" titleLabel.TextColor3=Color3.new(1,1,1) titleLabel.BackgroundTransparency=1 titleLabel.Font=Enum.Font.SourceSansBold titleLabel.TextSize=16 titleLabel.Parent=titleBar
local btnMin = Instance.new("TextButton") btnMin.Name="MinimizeButton" btnMin.Size=UDim2.new(0,24,0,24) btnMin.Position=UDim2.new(1,-72,0,0) btnMin.Text="-" btnMin.TextColor3=Color3.new(1,1,1) btnMin.BackgroundTransparency=1 btnMin.Font=Enum.Font.SourceSansBold btnMin.TextSize=18 btnMin.Parent=titleBar
local btnReload = Instance.new("TextButton") btnReload.Name="ReloadButton" btnReload.Size=UDim2.new(0,24,0,24) btnReload.Position=UDim2.new(1,-48,0,0) btnReload.Text="R" btnReload.TextColor3=Color3.new(1,1,1) btnReload.BackgroundTransparency=1 btnReload.Font=Enum.Font.SourceSansBold btnReload.TextSize=18 btnReload.Parent=titleBar
local btnClose = Instance.new("TextButton") btnClose.Name="CloseButton" btnClose.Size=UDim2.new(0,24,0,24) btnClose.Position=UDim2.new(1,-24,0,0) btnClose.Text="X" btnClose.TextColor3=Color3.new(1,1,1) btnClose.BackgroundTransparency=1 btnClose.Font=Enum.Font.SourceSansBold btnClose.TextSize=18 btnClose.Parent=titleBar

-- Kéo thả
local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
frame.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 and input.Position.Y>frame.AbsolutePosition.Y and input.Position.Y<frame.AbsolutePosition.Y+24 then
        dragging=true; dragStart=input.Position; startPos=frame.Position
        input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
    end
end)
frame.InputChanged:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseMovement then dragInput=input end end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input==dragInput then
        local delta=input.Position-dragStart
        frame.Position=UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
    end
end)
-- Thu gọn/Đóng
btnMin.MouseButton1Click:Connect(function() minimized = not minimized; content.Visible = not minimized; frame.Size = minimized and UDim2.new(0,200,0,24) or UDim2.new(0,200,0,170) end)
btnClose.MouseButton1Click:Connect(function() screenGui:Destroy() end)
btnReload.MouseButton1Click:Connect(function()
    local current = script:Clone()
    current.Parent = script.Parent
    script:Destroy()
end)
-- Label & Input
local function createLabel(txt,y) local lbl=Instance.new("TextLabel"); lbl.Size=UDim2.new(1,-10,0,24); lbl.Position=UDim2.new(0,5,0,y); lbl.Text=txt; lbl.TextColor3=Color3.new(1,1,1); lbl.BackgroundTransparency=1; lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Font=Enum.Font.SourceSans; lbl.TextSize=14; lbl.Parent=content; return lbl end
local function createInput(def,y) local box=Instance.new("TextBox"); box.Size=UDim2.new(1,-10,0,24); box.Position=UDim2.new(0,5,0,y); box.Text=def; box.ClearTextOnFocus=false; box.TextColor3=Color3.new(1,1,1); box.BackgroundColor3=Color3.fromRGB(40,40,40); box.BackgroundTransparency=0.2; box.Font=Enum.Font.SourceSans; box.TextSize=14; box.TextXAlignment=Enum.TextXAlignment.Center; box.Parent=content; local cr=Instance.new("UICorner"); cr.CornerRadius=UDim.new(0,4); cr.Parent=box; return box end
createLabel("Speed (50-300):",5); local speedBox=createInput(tostring(speed),30)
createLabel("Threshold (10-100):",60); local thresholdBox=createInput(tostring(threshold),85)
speedBox.FocusLost:Connect(function() local v=tonumber(speedBox.Text); if v then speed=math.clamp(v,minSpeed,maxSpeed) end; speedBox.Text=tostring(speed) end)
thresholdBox.FocusLost:Connect(function() local v=tonumber(thresholdBox.Text); if v then threshold=math.clamp(v,minThreshold,maxThreshold) end; thresholdBox.Text=tostring(threshold) end)

-- Kiểm tra an toàn
local function isPositionSafe(p)
    local ray=workspace:Raycast(p+Vector3.new(0,50,0),Vector3.new(0,-100,0))
    if not ray or not ray.Instance or not ray.Instance.CanCollide then return false end
    for _,pl in ipairs(Players:GetPlayers()) do
        if pl~=LocalPlayer and pl.Character then local o=pl.Character:FindFirstChild("HumanoidRootPart"); if o and (o.Position-p).Magnitude<=threshold then return false end end
    end
    local path=PathfindingService:CreatePath({AgentRadius=2,AgentHeight=5,AgentCanJump=true})
    path:ComputeAsync(HRP.Position,p)
    return path.Status==Enum.PathStatus.Success
end
local function findSafePosition()
    for i=1,maxAttempts do
        local off=Vector3.new(math.random(-areaRadius,areaRadius),0,math.random(-areaRadius,areaRadius))
        local c=HRP.Position+Vector3.new(off.X,0,off.Z)
        if isPositionSafe(c) then return c end
    end
end

-- Panic tween ngẫu nhiên
local function startPanic()
    panicking=true
    panicStartTime=os.clock()
    threshold=100
    local function nextTween()
        if not panicking then return end
        local elapsed=os.clock()-panicStartTime
        if elapsed>=panicDuration then panicking=false; isTweening=false; return end
        -- vị trí random: xz random, y random giữa HRP+0 đến HRP+skinHeight
        local height=math.random(50, 500)
        local off=Vector3.new(math.random(-areaRadius,areaRadius),height,math.random(-areaRadius,areaRadius))
        local target=HRP.Position+off
        local time=(off.Magnitude)/speed
        local tween=TweenService:Create(HRP, TweenInfo.new(time,Enum.EasingStyle.Linear), {CFrame=CFrame.new(target)})
        isTweening=true; tween:Play()
        tween.Completed:Connect(function()
            isTweening=false; nextTween()
        end)
    end
    nextTween()
end

-- Vòng lặp chính
RunService.Heartbeat:Connect(function()
    if isTweening then return end
    -- tìm nearest
    local nearest,dist=nil,math.huge
    for _,pl in ipairs(Players:GetPlayers()) do if pl~=LocalPlayer and pl.Character then local o=pl.Character:FindFirstChild("HumanoidRootPart"); if o then local d=(HRP.Position-o.Position).Magnitude; if d<dist then dist,nearest=d,pl end end end end
    -- nếu đang panic skip
    if panicking then return end
    -- điều kiện panic
    if Humanoid.Health/Humanoid.MaxHealth<=0.6 and nearest and dist<=threshold then
        startPanic()
        return
    end
    -- tween an toàn bình thường
    if nearest and dist<=threshold then
        local safe=findSafePosition()
        if safe then
            isTweening=true
            local d=(safe-HRP.Position).Magnitude; local t=d/speed
            local tween=TweenService:Create(HRP, TweenInfo.new(t,Enum.EasingStyle.Linear), {CFrame=CFrame.new(safe)})
            tween:Play()
            tween.Completed:Connect(function() isTweening=false end)
        end
    end
end)
