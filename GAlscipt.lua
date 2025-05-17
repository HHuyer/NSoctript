-- Tạo ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SimpleHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")

-- Thiết lập kích thước và vị trí ban đầu của GUI
local initialSize = UDim2.new(0, 300, 0, 200)
local dragStart = nil
local dragStartOffset = nil

-- Tạo Frame chính
local Frame = Instance.new("Frame")
Frame.Size = initialSize
Frame.Position = UDim2.new(0.5, -150, 0.5, -100)
Frame.AnchorPoint = Vector2.new(0.5, 0.5)
Frame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
Frame.BorderSizePixel = 0
Frame.ClipsDescendants = true
Frame.Active = true
Frame.Parent = ScreenGui
Frame.ClipsDescendants = true
Frame.BackgroundTransparency = 0
Frame.ZIndex = 2

-- Function để cho phép kéo thả GUI
local function enableDragging()
    local uis = game:GetService("UserInputService")
    local dragInput, dragStart, startPos
    
    Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragStart = input.Position
            startPos = Frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragStart = nil
                end
            end)
        end
    end)
    
    Frame.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    uis.InputChanged:Connect(function(input)
        if input == dragInput and dragStart then
            local delta = input.Position - dragStart
            Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Kích hoạt kéo thả
enableDragging()

-- Tiêu đề
local Title = Instance.new("TextLabel")
Title.Text = "Simple Script Hub"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 20
Title.Parent = Frame

-- Scroll Frame để chứa các chức năng
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, 0, 0.85, -50)
ScrollFrame.Position = UDim2.new(0, 0, 0, 50)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 300)
ScrollFrame.ScrollBarThickness = 8
ScrollFrame.Parent = Frame

-- Hàm tạo nút với hiệu ứng sóng và góc bo tròn
local function createButton(name, posY, callback)
    local btn = Instance.new("TextButton")
    btn.Text = name
    btn.Size = UDim2.new(0.9, 0, 0, 50)
    btn.Position = UDim2.new(0.05, 0, 0, posY)
    btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    btn.BorderSizePixel = 0
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 16
    btn.Parent = ScrollFrame
    btn.AutoButtonColor = false
    btn.ZIndex = 2
    
    -- Hiệu ứng sóng khi click
    local ripple = Instance.new("ImageLabel")
    ripple.Size = UDim2.new(2, 0, 2, 0)
    ripple.Position = UDim2.new(-0.5, 0, -0.5, 0)
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.BackgroundTransparency = 1
    ripple.Image = "rbxassetid://2708891599"
    ripple.ImageColor3 = Color3.fromRGB(255, 255, 255)
    ripple.Parent = btn
    ripple.ZIndex = 1
    
    btn.MouseEnter:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    end)
    
    btn.MouseLeave:Connect(function()
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    end)
    
    btn.MouseButton1Click:Connect(function()
        -- Tween hiệu ứng sóng
        local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        local tween = game:GetService("TweenService"):Create(ripple, tweenInfo, {Size = UDim2.new(5, 0, 5, 0), ImageTransparency = 1})
        
        -- Callback function
        callback()
        
        -- Bắt đầu tween khi click
        tween:Play()
    end)
    
    -- Góc bo tròn
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = btn
end

-- Nút: ESP Script
createButton("ESP Script", 0, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUsername/esp-script/main/esp.lua"))()
end)

-- Nút: Fly Script
createButton("Fly Script", 60, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUsername/fly-script/main/fly.lua"))()
end)

-- Nút: Infinite Yield
createButton("Infinite Yield", 120, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end)

-- Nút: Speed Hack
createButton("Speed Hack", 180, function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/YourUsername/speed-hack/main/speed.lua"))()
end)

-- Đề xuất thêm: Thêm biểu tượng hoặc màu sắc khác cho từng nút để dễ dàng nhận diện chức năng.
-- Đề xuất thêm: Thêm hiệu ứng hover (di chuột qua) cho các nút để người dùng biết được khi nào nút sẽ được click.

