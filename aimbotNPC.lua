-- Dual-Mode Aimbot GUI with Drag-and-Drop, Rounded Corners, Click/TP Aim, Collapsible & Scrollable Menu
-- Paste this as a LocalScript under StarterGui

local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer
local Camera           = workspace.CurrentCamera

-- ===== SETTINGS =====
local SETTINGS = {
    SimpleEnabled  = false,
    StickyEnabled  = false,
    SmartAim       = false,
    ClickAim       = false,
    TPAim          = false,
    UpdateInterval = 0.5,
    StickTime      = 0.5,
    MoveThreshold  = 1,
    ClickSmooth    = 0.9,
}

-- Tracking state
local isClicking = false
local collapsed  = false

-- NPC storage
local validNPCs      = {}
local lastUpdate     = 0
local currentTarget  = nil
local lastSwitchTime = 0

-- Mouse tracking
UserInputService.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then isClicking=true end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then isClicking=false end end)

-- ===== GUI =====
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AimbotMenu"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main Frame
local frame = Instance.new("Frame", screenGui)
frame.Name = "MainFrame"
frame.Size = UDim2.new(0,260,0,340)
frame.Position = UDim2.new(0,10,0,10)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)

-- Title Bar
local titleBar = Instance.new("Frame", frame)
titleBar.Size = UDim2.new(1,0,0,30)
titleBar.BackgroundTransparency = 1

local title = Instance.new("TextLabel", titleBar)
title.Size = UDim2.new(1,-60,1,0)
title.Position = UDim2.new(0,10,0,0)
title.BackgroundTransparency=1
title.Font=Enum.Font.SourceSansBold
title.TextSize=16
title.TextColor3=Color3.new(1,1,1)
title.Text="Aimbot Menu"

local collapseBtn = Instance.new("TextButton", titleBar)
collapseBtn.Size=UDim2.new(0,30,1,0)
collapseBtn.Position=UDim2.new(1,-35,0,0)
collapseBtn.BackgroundTransparency=1
collapseBtn.Font=Enum.Font.SourceSansBold
collapseBtn.TextSize=20
collapseBtn.TextColor3=Color3.new(1,1,1)
collapseBtn.Text="-"

-- Drag
local dragging, dragInput, dragStart, startPos
frame.InputBegan:Connect(function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 then
        dragging=true; dragStart=input.Position; startPos=frame.Position
        input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
    end
end)
frame.InputChanged:Connect(function(input) if input.UserInputType==Enum.UserInputType.MouseMovement then dragInput=input end end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input==dragInput then
        local d = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
    end
end)

-- Scrollable Content
local scroll = Instance.new("ScrollingFrame", frame)
scroll.Name="Scroll"
scroll.Size=UDim2.new(1,-0,1,-30)
scroll.Position=UDim2.new(0,0,0,30)
scroll.CanvasSize=UDim2.new(0,0,0,0)
scroll.ScrollBarThickness=6
scroll.BackgroundTransparency=1

local layout = Instance.new("UIListLayout", scroll)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0,8)
layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0,0,0, layout.AbsoluteContentSize.Y + 10)
end)

-- Collapse logic
collapseBtn.MouseButton1Click:Connect(function()
    collapsed = not collapsed
    collapseBtn.Text = collapsed and "+" or "-"
    scroll.Visible = not collapsed
    frame.Size = collapsed and UDim2.new(0,260,0,30) or UDim2.new(0,260,0,340)
end)

-- Helper to create switch row
local function createSwitch(text)
    local container = Instance.new("Frame", scroll)
    container.Size = UDim2.new(1,-20,0,24)
    container.BackgroundTransparency=1
    
    local lbl = Instance.new("TextLabel", container)
    lbl.Size=UDim2.new(0.65,0,1,0)
    lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.SourceSans; lbl.TextSize=14; lbl.TextColor3=Color3.new(1,1,1)
    lbl.Text=text
    
    local bg = Instance.new("TextButton", container)
    bg.Size=UDim2.new(0,40,0,20)
    bg.Position=UDim2.new(1,-50,0,2)
    bg.BackgroundColor3=Color3.fromRGB(100,100,100)
    bg.BorderSizePixel=0; bg.AutoButtonColor=false
    Instance.new("UICorner", bg)
    
    local knob = Instance.new("Frame", bg)
    knob.Size=UDim2.new(0,18,0,18)
    knob.Position=UDim2.new(0,1,0,1)
    Instance.new("UICorner", knob)
    knob.BackgroundColor3=Color3.new(1,1,1)
    
    return container, bg, knob
end

-- Create Switches
local entries = {
    {"NPC Aim (Non-Human)", "SimpleEnabled"},
    {"NPC Aim (Human)",    "StickyEnabled"},
    {"Smart Aim",         "SmartAim"},
    {"Click Aim",         "ClickAim"},
    {"TP Aim",            "TPAim"},
}
for i,info in ipairs(entries) do
    local container, bg, knob = createSwitch(info[1])
    local key = info[2]
    bg.MouseButton1Click:Connect(function()
        SETTINGS[key] = not SETTINGS[key]
        local on = SETTINGS[key]
        TweenService:Create(knob, TweenInfo.new(0.2),{Position = on and UDim2.new(1,-19,0,1) or UDim2.new(0,1,0,1)}):Play()
        TweenService:Create(bg, TweenInfo.new(0.2),{BackgroundColor3 = on and Color3.fromRGB(0,170,0) or Color3.fromRGB(100,100,100)}):Play()
    end)
end

-- Helper to create label+textbox row
local function createSetting(name, key)
    local container = Instance.new("Frame", scroll)
    container.Size = UDim2.new(1,-20,0,28)
    container.BackgroundTransparency=1
    
    local lbl = Instance.new("TextLabel", container)
    lbl.Size=UDim2.new(0.6,0,1,0)
    lbl.Position=UDim2.new(0,10,0,0)
    lbl.BackgroundTransparency=1; lbl.Font=Enum.Font.SourceSans; lbl.TextSize=14; lbl.TextColor3=Color3.new(1,1,1)
    lbl.Text = name
    
    local tb = Instance.new("TextBox", container)
    tb.Size=UDim2.new(0.3,0,1,0)
    tb.Position=UDim2.new(0.65,0,0,0)
    tb.BackgroundColor3=Color3.fromRGB(40,40,40)
    tb.BorderSizePixel=0; tb.Font=Enum.Font.SourceSans; tb.TextSize=14; tb.TextColor3=Color3.new(1,1,1)
    tb.Text = tostring(SETTINGS[key])
    tb.ClearTextOnFocus=false
    tb.FocusLost:Connect(function()
        local v = tonumber(tb.Text)
        if v and v>0 then SETTINGS[key] = v else tb.Text = tostring(SETTINGS[key]) end
    end)
end

-- Create setting inputs
createSetting("Update Interval", "UpdateInterval")
createSetting("Stick Time",      "StickTime")
createSetting("Move Threshold",  "MoveThreshold")
createSetting("Click Smooth",    "ClickSmooth")

-- NPC detection
local function isNPC(ch)
    if not ch:IsA("Model") then return false end
    local h,chd = ch:FindFirstChild("Humanoid"), ch:FindFirstChild("Head")
    return h and h.Health>0 and chd and not Players:GetPlayerFromCharacter(ch)
end

-- Teleport functions
local originalCFrame
local function teleportTo(pos)
    local c = LocalPlayer.Character
    if c and c:FindFirstChild("HumanoidRootPart") then
        originalCFrame = c.HumanoidRootPart.CFrame
        c.HumanoidRootPart.CFrame = CFrame.new(pos)
    end
end
local function teleportBack()
    local c = LocalPlayer.Character
    if c and c:FindFirstChild("HumanoidRootPart") and originalCFrame then
        c.HumanoidRootPart.CFrame = originalCFrame
    end
end

-- Simple Aim
local function simpleAim(dt)
    if SETTINGS.ClickAim and not isClicking then return end
    local folder = workspace:FindFirstChild("NPCs")
    if not folder then return end
    local nearest,d = nil,math.huge
    for _,npc in ipairs(folder:GetChildren()) do
        if npc:FindFirstChild("HumanoidRootPart") then
            local hrp = npc.HumanoidRootPart
            local dist = (hrp.Position - Camera.CFrame.Position).Magnitude
            if dist < d then d,nearest = dist,hrp end
        end
    end
    if nearest then
        if SETTINGS.TPAim and isClicking then
            teleportTo(nearest.Position)
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, nearest.Position)
            teleportBack()
        else
            if not SETTINGS.SmartAim or nearest.Velocity.Magnitude > SETTINGS.MoveThreshold then
                local dir = (nearest.Position - Camera.CFrame.Position).Unit
                local cur = Camera.CFrame
                local factor = SETTINGS.ClickAim and SETTINGS.ClickSmooth or 1
                local look = cur.LookVector:Lerp(dir, factor)
                Camera.CFrame = CFrame.new(cur.Position, cur.Position + look)
            end
        end
    end
end

-- Sticky Aim setup
workspace.DescendantAdded:Connect(function(ch) if isNPC(ch) then validNPCs[ch]=true; local h=ch:FindFirstChild("Humanoid"); if h then h.Died:Connect(function() validNPCs[ch]=nil end) end end end)
workspace.DescendantRemoving:Connect(function(ch) if validNPCs[ch] then validNPCs[ch]=nil; if currentTarget==ch then currentTarget=nil end end end)
for _,ch in ipairs(workspace:GetDescendants()) do if isNPC(ch) then validNPCs[ch]=true end end

local function getNearestStickyPos()
    local best,d = nil,math.huge
    local cam = Camera.CFrame.Position
    for npc in pairs(validNPCs) do if npc:FindFirstChild("Head") then local dist=(npc.Head.Position-cam).Magnitude; if dist<d then d,best=dist,npc.Head.Position end end end
    return best
end

-- Sticky Aim
local function stickyAim(dt)
    if SETTINGS.ClickAim and not isClicking then return end
    lastUpdate = lastUpdate + dt
    if lastUpdate >= SETTINGS.UpdateInterval then
        for npc in pairs(validNPCs) do if not isNPC(npc) then validNPCs[npc]=nil; if currentTarget==npc then currentTarget=nil end end end
        lastUpdate = 0
    end
    local now = tick()
    if not currentTarget or now - lastSwitchTime >= SETTINGS.StickTime then
        local pos = getNearestStickyPos()
        if pos then
            for npc in pairs(validNPCs) do
                if npc:FindFirstChild("Head") and npc.Head.Position == pos and npc~=currentTarget then
                    currentTarget, lastSwitchTime = npc, now
                    break
                end
            end
        end
    end
    if currentTarget and currentTarget:FindFirstChild("Head") then
        if SETTINGS.TPAim and isClicking then
            teleportTo(currentTarget.Head.Position)
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, currentTarget.Head.Position)
            teleportBack()
        else
            local hrp = currentTarget:FindFirstChild("HumanoidRootPart")
            local moving = hrp and hrp.Velocity.Magnitude > SETTINGS.MoveThreshold
            if not SETTINGS.SmartAim or moving then
                local dir = (currentTarget.Head.Position - Camera.CFrame.Position).Unit
                local cur = Camera.CFrame
                local factor = SETTINGS.ClickAim and SETTINGS.ClickSmooth or 1
                local look = cur.LookVector:Lerp(dir, factor)
                Camera.CFrame = CFrame.new(cur.Position, cur.Position + look)
            end
        end
    end
end

-- Main Loop
RunService.Heartbeat:Connect(function(dt)
    if SETTINGS.SimpleEnabled then simpleAim(dt) end
    if SETTINGS.StickyEnabled then stickyAim(dt) end
end)
