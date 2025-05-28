-- Cảm hứng từ yee_kunkun(roblox name)
-- Tạo ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SimpleHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Thiết lập kích thước và vị trí của GUI
local initialSize = UDim2.new(0, 360, 0, 260)

-- Frame chính với bo tròn và bóng đổ
local Frame = Instance.new("Frame")
Frame.Name = "MainFrame"
Frame.Size = initialSize
Frame.Position = UDim2.new(0.5, -180, 0.5, -130)
Frame.AnchorPoint = Vector2.new(0.5, 0.5)
Frame.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
Frame.BorderSizePixel = 0
Frame.ClipsDescendants = true
Frame.Active = true
Frame.Parent = ScreenGui

-- Bo tròn góc cho Frame
local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 16)
frameCorner.Parent = Frame

-- Bóng đổ (UIShadow nếu khả dụng)
local success, Shadow = pcall(function()
    return Instance.new("UIShadow", Frame)
end)
if success then
    Shadow.Offset = Vector2.new(0, 4)
    Shadow.Color = Color3.fromRGB(0, 0, 0)
    Shadow.Transparency = 0.7
end

-- Kéo thả GUI
local function enableDragging(target)
    local uis = game:GetService("UserInputService")
    local dragInput, dragStart, startPos
    target.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragStart = input.Position
            startPos = target.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragStart = nil
                end
            end)
        end
    end)
    target.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    uis.InputChanged:Connect(function(input)
        if input == dragInput and dragStart then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

enableDragging(Frame)

-- Thanh tiêu đề với bo góc trên
local Title = Instance.new("Frame")
Title.Name = "TitleBar"
Title.Size = UDim2.new(1, 0, 0, 48)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundColor3 = Color3.fromRGB(44, 44, 46)
Title.Parent = Frame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 16)
titleCorner.Parent = Title

titleCorner = Instance.new("UICorner", Title)
titleCorner.CornerRadius = UDim.new(0, 16)

titleCorner.Name = "TopCorners"
titleCorner.CornerRadius = UDim.new(0, 16)

-- Gradient cho title
local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(70,70,72)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(44,44,46))
}
titleGradient.Rotation = 90
titleGradient.Parent = Title

-- Tiêu đề text
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleText"
TitleLabel.Text = "Simple Script Hub"
TitleLabel.Size = UDim2.new(1, -80, 1, 0)
TitleLabel.Position = UDim2.new(0, 16, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.Font = Enum.Font.GothamBlack
TitleLabel.TextSize = 22
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Title

-- Nút đóng
local CloseBtn = Instance.new("ImageButton")
CloseBtn.Name = "CloseButton"
CloseBtn.Size = UDim2.new(0, 32, 0, 32)
CloseBtn.Position = UDim2.new(1, -40, 0.5, -16)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Image = "rbxassetid://3926307971" -- icon đóng
CloseBtn.ImageColor3 = Color3.fromRGB(200, 200, 200)
CloseBtn.Parent = Title

CloseBtn.MouseEnter:Connect(function()
    CloseBtn.ImageColor3 = Color3.fromRGB(255, 100, 100)
end)
CloseBtn.MouseLeave:Connect(function()
    CloseBtn.ImageColor3 = Color3.fromRGB(200, 200, 200)
end)
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

enableDragging(Title)

-- Khung cuộn chứa nút
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name = "FunctionList"
ScrollFrame.Size = UDim2.new(1, -24, 1, -64)
ScrollFrame.Position = UDim2.new(0, 12, 0, 52)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.ScrollBarThickness = 6
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.Parent = Frame

-- Tự động dàn nút
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 12)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = ScrollFrame

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 12)
padding.PaddingBottom = UDim.new(0, 12)
padding.PaddingLeft = UDim.new(0, 8)
padding.PaddingRight = UDim.new(0, 8)
padding.Parent = ScrollFrame

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
end)

-- Hàm tạo nút với icon, sóng và bo góc
local function createButton(name, iconId, callback)
    local btn = Instance.new("TextButton")
    btn.Name = name:gsub("%s+", "")
    btn.Size = UDim2.new(1, 0, 0, 56)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 52)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 18
    btn.TextColor3 = Color3.fromRGB(255,255,255)
    btn.AutoButtonColor = false
    btn.Parent = ScrollFrame
    btn.Text = "  " .. name
    btn.TextXAlignment = Enum.TextXAlignment.Left

    -- Bo góc
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = btn

    -- Icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 24, 0, 24)
    icon.Position = UDim2.new(0, 12, 0.5, -12)
    icon.BackgroundTransparency = 1
    icon.Image = iconId or "rbxassetid://6031090991" -- default icon
    icon.Parent = btn

    -- Mouse hover
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 62)
    end)
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 52)
    end)

    -- Hiệu ứng sóng
    local ripple = Instance.new("ImageLabel")
    ripple.Name = "Ripple"
    ripple.Size = UDim2.new(2,0,2,0)
    ripple.Position = UDim2.new(-0.5,0,-0.5,0)
    ripple.BackgroundTransparency = 1
    ripple.Image = "rbxassetid://2708891599"
    ripple.ImageColor3 = Color3.fromRGB(255,255,255)
    ripple.Parent = btn
    ripple.ZIndex = 1

    btn.MouseButton1Click:Connect(function()
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = game:GetService("TweenService"):Create(ripple, tweenInfo, {Size = UDim2.new(5,0,5,0), ImageTransparency = 1})
        callback()
        tween:Play()
    end)
end

-- Các nút chức năng mới với icon minh họa
createButton("AntiAdmin", "rbxassetid://6035047360", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/HHuyer/NSoctript/refs/heads/main/AntiAdmin.lua"))()
end)
createButton("AntiHunter", "rbxassetid://6035047208", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/HHuyer/NSoctript/refs/heads/main/AntiHunter.lua"))()
end)
createButton("ObbyHelper", "rbxassetid://6035047071", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/HHuyer/NSoctript/refs/heads/main/ObbyHelper.lua"))()
end)
createButton("Aimbot NPC", "rbxassetid://6035046915", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/HHuyer/NSoctript/refs/heads/main/aimbotNPC.lua"))()
end)
