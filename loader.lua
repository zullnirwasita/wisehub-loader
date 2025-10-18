local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- ===== CONFIG =====
local CONFIG = {
    API_URL = "https://wisehub-api.zullstore21.workers.dev",
    API_KEY = "DAP",
    TIMEOUT = 30
}

-- ===== VARIABLES =====
local LocalPlayer = Players.LocalPlayer
local ProfileUI = nil
local UserData = nil
local IsMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ===== TIER CONFIG =====
local TIER_INFO = {
    basic = {
        Name = "Basic",
        Color = Color3.fromRGB(100, 180, 255),
        GradientStart = Color3.fromRGB(70, 130, 220),
        GradientEnd = Color3.fromRGB(100, 180, 255),
        Icon = "👤",
        Description = "Access to basic features"
    },
    premium = {
        Name = "Premium",
        Color = Color3.fromRGB(255, 215, 0),
        GradientStart = Color3.fromRGB(255, 170, 0),
        GradientEnd = Color3.fromRGB(255, 215, 100),
        Icon = "⭐",
        Description = "Access to premium features"
    },
    vip = {
        Name = "VIP",
        Color = Color3.fromRGB(138, 43, 226),
        GradientStart = Color3.fromRGB(100, 20, 200),
        GradientEnd = Color3.fromRGB(180, 80, 255),
        Icon = "👑",
        Description = "Full access + priority support"
    }
}

-- ===== UTILITY FUNCTIONS =====
local function generateHWID()
    return game:GetService("RbxAnalyticsService"):GetClientId()
end

local function getCurrentPlaceId()
    return tostring(game.PlaceId)
end

local function getGameName()
    local success, info = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    end)
    
    if success and info then
        return info.Name
    end
    
    return "Unknown Game"
end

local function formatDate(dateString)
    if not dateString then return "N/A" end
    
    local year, month, day = dateString:match("(%d+)-(%d+)-(%d+)")
    if year and month and day then
        return string.format("%s/%s/%s", day, month, year)
    end
    
    return dateString:sub(1, 10)
end

local function getDaysRemaining(expiryDate)
    if not expiryDate then return 0 end
    
    local expiry = os.time({
        year = tonumber(expiryDate:sub(1, 4)),
        month = tonumber(expiryDate:sub(6, 7)),
        day = tonumber(expiryDate:sub(9, 10)),
        hour = 0, min = 0, sec = 0
    })
    
    local now = os.time()
    local diff = expiry - now
    local days = math.floor(diff / 86400)
    
    return days > 0 and days or 0
end

local function createNotification(title, message, duration)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = message,
            Duration = duration or 5
        })
    end)
end

-- ===== ANIMATION FUNCTIONS =====
local function fadeIn(obj, duration)
    if not obj then return end
    duration = duration or 0.3
    
    obj.BackgroundTransparency = 1
    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
        obj.TextTransparency = 1
    elseif obj:IsA("ImageLabel") then
        obj.ImageTransparency = 1
    end
    
    local tween = TweenService:Create(obj, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = obj:IsA("Frame") and 0 or (obj:IsA("TextLabel") or obj:IsA("TextButton")) and 1 or 0
    })
    
    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
        local textTween = TweenService:Create(obj, TweenInfo.new(duration), {TextTransparency = 0})
        textTween:Play()
    elseif obj:IsA("ImageLabel") then
        local imgTween = TweenService:Create(obj, TweenInfo.new(duration), {ImageTransparency = 0})
        imgTween:Play()
    end
    
    tween:Play()
end

local function slideIn(obj, fromPosition, duration)
    if not obj then return end
    duration = duration or 0.4
    
    obj.Position = fromPosition
    local targetPos = obj.Position
    
    local tween = TweenService:Create(obj, TweenInfo.new(duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = targetPos
    })
    tween:Play()
end

local function pulse(obj)
    if not obj then return end
    
    spawn(function()
        while obj and obj.Parent do
            local tween = TweenService:Create(obj, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Size = obj.Size + UDim2.new(0, 5, 0, 5)
            })
            tween:Play()
            tween.Completed:Wait()
            
            local tween2 = TweenService:Create(obj, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                Size = obj.Size - UDim2.new(0, 5, 0, 5)
            })
            tween2:Play()
            tween2.Completed:Wait()
        end
    end)
end

-- ===== ERROR UI =====
local function showErrorUI(errorType, errorMessage)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "WiseHubError"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Blur Background
    local Blur = Instance.new("Frame")
    Blur.Size = UDim2.new(1, 0, 1, 0)
    Blur.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Blur.BackgroundTransparency = 0.5
    Blur.BorderSizePixel = 0
    Blur.Parent = ScreenGui
    
    -- Error Frame
    local scale = IsMobile and 0.9 or 0.7
    local ErrorFrame = Instance.new("Frame")
    ErrorFrame.Size = UDim2.new(scale, 0, 0, IsMobile and 350 or 300)
    ErrorFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
    ErrorFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    ErrorFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    ErrorFrame.BorderSizePixel = 0
    ErrorFrame.Parent = ScreenGui
    
    local ErrorCorner = Instance.new("UICorner")
    ErrorCorner.CornerRadius = UDim.new(0, 20)
    ErrorCorner.Parent = ErrorFrame
    
    local ErrorStroke = Instance.new("UIStroke")
    ErrorStroke.Color = Color3.fromRGB(255, 80, 80)
    ErrorStroke.Thickness = 3
    ErrorStroke.Parent = ErrorFrame
    
    -- Error Icon
    local ErrorIcon = Instance.new("TextLabel")
    ErrorIcon.Size = UDim2.new(0, 80, 0, 80)
    ErrorIcon.Position = UDim2.new(0.5, 0, 0, 30)
    ErrorIcon.AnchorPoint = Vector2.new(0.5, 0)
    ErrorIcon.BackgroundTransparency = 1
    ErrorIcon.Text = "❌"
    ErrorIcon.TextColor3 = Color3.fromRGB(255, 80, 80)
    ErrorIcon.TextSize = 60
    ErrorIcon.Font = Enum.Font.GothamBold
    ErrorIcon.Parent = ErrorFrame
    
    -- Error Title
    local ErrorTitle = Instance.new("TextLabel")
    ErrorTitle.Size = UDim2.new(1, -40, 0, 40)
    ErrorTitle.Position = UDim2.new(0, 20, 0, 120)
    ErrorTitle.BackgroundTransparency = 1
    ErrorTitle.Text = errorType == "game_not_found" and "🎮 Game Tidak Terdaftar" or "⚠️ Script Error"
    ErrorTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    ErrorTitle.TextSize = IsMobile and 20 or 24
    ErrorTitle.Font = Enum.Font.GothamBold
    ErrorTitle.TextWrapped = true
    ErrorTitle.Parent = ErrorFrame
    
    -- Error Message
    local ErrorMsg = Instance.new("TextLabel")
    ErrorMsg.Size = UDim2.new(1, -40, 0, IsMobile and 100 : 80)
    ErrorMsg.Position = UDim2.new(0, 20, 0, 170)
    ErrorMsg.BackgroundTransparency = 1
    ErrorMsg.Text = errorMessage
    ErrorMsg.TextColor3 = Color3.fromRGB(200, 200, 200)
    ErrorMsg.TextSize = IsMobile and 14 or 16
    ErrorMsg.Font = Enum.Font.Gotham
    ErrorMsg.TextWrapped = true
    ErrorMsg.TextYAlignment = Enum.TextYAlignment.Top
    ErrorMsg.Parent = ErrorFrame
    
    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, IsMobile and 120 : 150, 0, IsMobile and 45 : 50)
    CloseBtn.Position = UDim2.new(0.5, 0, 1, -70)
    CloseBtn.AnchorPoint = Vector2.new(0.5, 0)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Text = "Close"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = IsMobile and 16 : 18
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Parent = ErrorFrame
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 12)
    CloseCorner.Parent = CloseBtn
    
    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
    
    -- Animations
    ErrorFrame.Size = UDim2.new(0, 0, 0, 0)
    local openTween = TweenService:Create(ErrorFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(scale, 0, 0, IsMobile and 350 or 300)
    })
    openTween:Play()
    
    pulse(ErrorIcon)
    
    ScreenGui.Parent = game:GetService("CoreGui")
    
    return ScreenGui
end

-- ===== PROFILE UI =====
local function createProfileUI(userData)
    local thumbnailUrl = ""
    pcall(function()
        thumbnailUrl = Players:GetUserThumbnailAsync(
            LocalPlayer.UserId,
            Enum.ThumbnailType.HeadShot,
            Enum.ThumbnailSize.Size420x420
        )
    end)
    
    local tierInfo = TIER_INFO[userData.tier] or TIER_INFO.basic
    local daysLeft = getDaysRemaining(userData.expiry)
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "WiseHubProfile"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    
    -- Background Blur
    local BgBlur = Instance.new("Frame")
    BgBlur.Size = UDim2.new(1, 0, 1, 0)
    BgBlur.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    BgBlur.BackgroundTransparency = 0.3
    BgBlur.BorderSizePixel = 0
    BgBlur.Parent = ScreenGui
    
    -- Main Frame (Responsive)
    local frameWidth = IsMobile and 0.95 or 0
    local frameHeight = IsMobile and 0 or 0
    local frameWidthOffset = IsMobile and 0 or 480
    local frameHeightOffset = IsMobile and 620 or 600
    
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(frameWidth, frameWidthOffset, frameHeight, frameHeightOffset)
    Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
    Frame.AnchorPoint = Vector2.new(0.5, 0.5)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    Frame.BackgroundTransparency = 0.1
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 20)
    UICorner.Parent = Frame
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = tierInfo.Color
    UIStroke.Thickness = 3
    UIStroke.Transparency = 0.3
    UIStroke.Parent = Frame
    
    -- Header with Gradient
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, IsMobile and 100 or 90)
    Header.BackgroundColor3 = tierInfo.Color
    Header.BorderSizePixel = 0
    Header.Parent = Frame
    
    local HeaderGradient = Instance.new("UIGradient")
    HeaderGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, tierInfo.GradientStart),
        ColorSequenceKeypoint.new(1, tierInfo.GradientEnd)
    })
    HeaderGradient.Rotation = 45
    HeaderGradient.Parent = Header
    
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 20)
    HeaderCorner.Parent = Header
    
    local HeaderCover = Instance.new("Frame")
    HeaderCover.Size = UDim2.new(1, 0, 0, 50)
    HeaderCover.Position = UDim2.new(0, 0, 1, -50)
    HeaderCover.BackgroundColor3 = tierInfo.Color
    HeaderCover.BorderSizePixel = 0
    HeaderCover.Parent = Header
    
    local HeaderCoverGradient = Instance.new("UIGradient")
    HeaderCoverGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, tierInfo.GradientStart),
        ColorSequenceKeypoint.new(1, tierInfo.GradientEnd)
    })
    HeaderCoverGradient.Rotation = 45
    HeaderCoverGradient.Parent = HeaderCover
    
    -- Animated particles (optional decoration)
    for i = 1, 5 do
        local Particle = Instance.new("Frame")
        Particle.Size = UDim2.new(0, math.random(3, 8), 0, math.random(3, 8))
        Particle.Position = UDim2.new(math.random(0, 100) / 100, 0, math.random(0, 100) / 100, 0)
        Particle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Particle.BackgroundTransparency = 0.7
        Particle.BorderSizePixel = 0
        Particle.Parent = Header
        
        local ParticleCorner = Instance.new("UICorner")
        ParticleCorner.CornerRadius = UDim.new(1, 0)
        ParticleCorner.Parent = Particle
        
        spawn(function()
            while Particle.Parent do
                local randomY = math.random(-50, 50)
                local tween = TweenService:Create(Particle, TweenInfo.new(math.random(2, 4), Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Position = Particle.Position + UDim2.new(0, 0, 0, randomY)
                })
                tween:Play()
                tween.Completed:Wait()
                wait(0.5)
            end
        end)
    end
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -100, 1, 0)
    Title.Position = UDim2.new(0, 20, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🛡️ WISE HUB"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = IsMobile and 26 or 32
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.TextStrokeTransparency = 0.8
    Title.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    Title.Parent = Header
    
    -- Profile Section
    local profileTop = IsMobile and 115 or 105
    local ProfileSection = Instance.new("Frame")
    ProfileSection.Size = UDim2.new(1, -30, 0, IsMobile and 180 or 170)
    ProfileSection.Position = UDim2.new(0, 15, 0, profileTop)
    ProfileSection.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    ProfileSection.BackgroundTransparency = 0.3
    ProfileSection.BorderSizePixel = 0
    ProfileSection.Parent = Frame
    
    local ProfileGradient = Instance.new("UIGradient")
    ProfileGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 45)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 35))
    })
    ProfileGradient.Rotation = 90
    ProfileGradient.Parent = ProfileSection
    
    local ProfileCorner = Instance.new("UICorner")
    ProfileCorner.CornerRadius = UDim.new(0, 15)
    ProfileCorner.Parent = ProfileSection
    
    -- Avatar
    local avatarSize = IsMobile and 110 or 100
    local AvatarFrame = Instance.new("Frame")
    AvatarFrame.Size = UDim2.new(0, avatarSize, 0, avatarSize)
    AvatarFrame.Position = UDim2.new(0, 20, 0, IsMobile and 35 or 35)
    AvatarFrame.BackgroundColor3 = tierInfo.Color
    AvatarFrame.BorderSizePixel = 0
    AvatarFrame.Parent = ProfileSection
    
    local AvatarGradient = Instance.new("UIGradient")
    AvatarGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, tierInfo.GradientStart),
        ColorSequenceKeypoint.new(1, tierInfo.GradientEnd)
    })
    AvatarGradient.Rotation = 45
    AvatarGradient.Parent = AvatarFrame
    
    local AvatarCorner = Instance.new("UICorner")
    AvatarCorner.CornerRadius = UDim.new(0, 15)
    AvatarCorner.Parent = AvatarFrame
    
    local Avatar = Instance.new("ImageLabel")
    Avatar.Size = UDim2.new(1, -6, 1, -6)
    Avatar.Position = UDim2.new(0, 3, 0, 3)
    Avatar.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    Avatar.Image = thumbnailUrl
    Avatar.Parent = AvatarFrame
    
    local AvatarImgCorner = Instance.new("UICorner")
    AvatarImgCorner.CornerRadius = UDim.new(0, 12)
    AvatarImgCorner.Parent = Avatar
    
    -- Username
    local usernameX = IsMobile and 145 or 135
    local Username = Instance.new("TextLabel")
    Username.Size = UDim2.new(1, -usernameX - 20, 0, 35)
    Username.Position = UDim2.new(0, usernameX, 0, 35)
    Username.BackgroundTransparency = 1
    Username.Text = userData.username or LocalPlayer.Name
    Username.TextColor3 = Color3.fromRGB(255, 255, 255)
    Username.TextSize = IsMobile and 20 or 22
    Username.Font = Enum.Font.GothamBold
    Username.TextXAlignment = Enum.TextXAlignment.Left
    Username.TextTruncate = Enum.TextTruncate.AtEnd
    Username.Parent = ProfileSection
    
    -- User ID
    local UserId = Instance.new("TextLabel")
    UserId.Size = UDim2.new(1, -usernameX - 20, 0, 20)
    UserId.Position = UDim2.new(0, usernameX, 0, 70)
    UserId.BackgroundTransparency = 1
    UserId.Text = "ID: " .. LocalPlayer.UserId
    UserId.TextColor3 = Color3.fromRGB(150, 150, 150)
    UserId.TextSize = IsMobile and 13 or 14
    UserId.Font = Enum.Font.Gotham
    UserId.TextXAlignment = Enum.TextXAlignment.Left
    UserId.Parent = ProfileSection
    
    -- Tier Badge
    local badgeWidth = IsMobile and 1 or 0
    local badgeWidthOffset = IsMobile and -usernameX - 25 or 230
    local TierBadge = Instance.new("Frame")
    TierBadge.Size = UDim2.new(badgeWidth, badgeWidthOffset, 0, 45)
    TierBadge.Position = UDim2.new(0, usernameX, 0, 100)
    TierBadge.BackgroundColor3 = tierInfo.Color
    TierBadge.BorderSizePixel = 0
    TierBadge.Parent = ProfileSection
    
    local TierGradient = Instance.new("UIGradient")
    TierGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, tierInfo.GradientStart),
        ColorSequenceKeypoint.new(1, tierInfo.GradientEnd)
    })
    TierGradient.Rotation = 45
    TierGradient.Parent = TierBadge
    
    local TierCorner = Instance.new("UICorner")
    TierCorner.CornerRadius = UDim.new(0, 10)
    TierCorner.Parent = TierBadge
    
    local TierIcon = Instance.new("TextLabel")
    TierIcon.Size = UDim2.new(0, 35, 1, 0)
    TierIcon.Position = UDim2.new(0, 10, 0, 0)
    TierIcon.BackgroundTransparency = 1
    TierIcon.Text = tierInfo.Icon
    TierIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    TierIcon.TextSize = IsMobile and 22 : 24
    TierIcon.Font = Enum.Font.GothamBold
    TierIcon.Parent = TierBadge
    
    local TierText = Instance.new("TextLabel")
    TierText.Size = UDim2.new(1, -55, 1, 0)
    TierText.Position = UDim2.new(0, 45, 0, 0)
    TierText.BackgroundTransparency = 1
    TierText.Text = tierInfo.Name
    TierText.TextColor3 = Color3.fromRGB(255, 255, 255)
    TierText.TextSize = IsMobile and 16 : 18
    TierText.Font = Enum.Font.GothamBold
    TierText.TextXAlignment = Enum.TextXAlignment.Left
    TierText.Parent = TierBadge
    
    -- Info Section
    local infoTop = profileTop + (IsMobile and 200 or 190)
    local InfoSection = Instance.new("Frame")
    InfoSection.Size = UDim2.new(1, -30, 0, IsMobile and 140 : 130)
    InfoSection.Position = UDim2.new(0, 15, 0, infoTop)
    InfoSection.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    InfoSection.BackgroundTransparency = 0.3
    InfoSection.BorderSizePixel = 0
    InfoSection.Parent = Frame
    
    local InfoGradient = Instance.new("UIGradient")
    InfoGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 35, 45)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(25, 25, 35))
    })
    InfoGradient.Rotation = 90
    InfoGradient.Parent = InfoSection
    
    local InfoCorner = Instance.new("UICorner")
    InfoCorner.CornerRadius = UDim.new(0, 15)
    InfoCorner.Parent = InfoSection
    
    -- Info Items
    local ExpiryLabel = Instance.new("TextLabel")
    ExpiryLabel.Size = UDim2.new(1, -30, 0, 30)
    ExpiryLabel.Position = UDim2.new(0, 15, 0, 15)
    ExpiryLabel.BackgroundTransparency = 1
    ExpiryLabel.Text = "⏰ Expires: " .. formatDate(userData.expiry)
    ExpiryLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    ExpiryLabel.TextSize = IsMobile and 14 : 16
    ExpiryLabel.Font = Enum.Font.Gotham
    ExpiryLabel.TextXAlignment = Enum.TextXAlignment.Left
    ExpiryLabel.Parent = InfoSection
    
    local DaysLabel = Instance.new("TextLabel")
    DaysLabel.Size = UDim2.new(1, -30, 0, 30)
    DaysLabel.Position = UDim2.new(0, 15, 0, 50)
    DaysLabel.BackgroundTransparency = 1
    DaysLabel.Text = string.format("📅 Days Remaining: %d days", daysLeft)
    DaysLabel.TextColor3 = daysLeft < 7 and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 150)
    DaysLabel.TextSize = IsMobile and 14 : 16
    DaysLabel.Font = Enum.Font.GothamBold
    DaysLabel.TextXAlignment = Enum.TextXAlignment.Left
    DaysLabel.Parent = InfoSection
    
    local LoginLabel = Instance.new("TextLabel")
    LoginLabel.Size = UDim2.new(1, -30, 0, 30)
    LoginLabel.Position = UDim2.new(0, 15, 0, 85)
    LoginLabel.BackgroundTransparency = 1
    LoginLabel.Text = "🔐 Total Logins: " .. (userData.login_count or 0)
    LoginLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    LoginLabel.TextSize = IsMobile and 14 : 16
    LoginLabel.Font = Enum.Font.Gotham
    LoginLabel.TextXAlignment = Enum.TextXAlignment.Left
    LoginLabel.Parent = InfoSection
    
    -- Status Section
    local statusTop = infoTop + (IsMobile and 160 : 150)
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Name = "StatusLabel"
    StatusLabel.Size = UDim2.new(1, -30, 0, 35)
    StatusLabel.Position = UDim2.new(0, 15, 0, statusTop)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "🎮 Loading game script..."
    StatusLabel.TextColor3 = tierInfo.Color
    StatusLabel.TextSize = IsMobile and 15 : 18
    StatusLabel.Font = Enum.Font.GothamBold
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
    StatusLabel.Parent = Frame
    
    -- Progress Bar
    local progressTop = statusTop + 45
    local ProgressBar = Instance.new("Frame")
    ProgressBar.Name = "ProgressBar"
    ProgressBar.Size = UDim2.new(1, -30, 0, 10)
    ProgressBar.Position = UDim2.new(0, 15, 0, progressTop)
    ProgressBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    ProgressBar.BackgroundTransparency = 0.3
    ProgressBar.BorderSizePixel = 0
    ProgressBar.Parent = Frame
    
    local ProgressCorner = Instance.new("UICorner")
    ProgressCorner.CornerRadius = UDim.new(0, 5)
    ProgressCorner.Parent = ProgressBar
    
    local ProgressFill = Instance.new("Frame")
    ProgressFill.Name = "Fill"
    ProgressFill.Size = UDim2.new(0, 0, 1, 0)
    ProgressFill.BackgroundColor3 = tierInfo.Color
    ProgressFill.BorderSizePixel = 0
    ProgressFill.Parent = ProgressBar
    
    local FillGradient = Instance.new("UIGradient")
    FillGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, tierInfo.GradientStart),
        ColorSequenceKeypoint.new(1, tierInfo.GradientEnd)
    })
    FillGradient.Rotation = 0
    FillGradient.Parent = ProgressFill
    
    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(0, 5)
    FillCorner.Parent = ProgressFill
    
    -- Game Info
    local gameTop = progressTop + 20
    local GameLabel = Instance.new("TextLabel")
    GameLabel.Size = UDim2.new(1, -30, 0, 30)
    GameLabel.Position = UDim2.new(0, 15, 0, gameTop)
    GameLabel.BackgroundTransparency = 1
    GameLabel.Text = "📍 " .. getGameName()
    GameLabel.TextColor3 = Color3.fromRGB(140, 140, 140)
    GameLabel.TextSize = IsMobile and 13 : 14
    GameLabel.Font = Enum.Font.Gotham
    GameLabel.TextXAlignment = Enum.TextXAlignment.Center
    GameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    GameLabel.Parent = Frame
    
    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, IsMobile and 40 : 40, 0, IsMobile and 40 : 40)
    CloseBtn.Position = UDim2.new(1, IsMobile and -55 : -55, 0, IsMobile and 30 : 25)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    CloseBtn.BackgroundTransparency = 0.2
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = IsMobile and 22 : 24
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Parent = Header
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 10)
    CloseCorner.Parent = CloseBtn
    
    CloseBtn.MouseButton1Click:Connect(function()
        local closeTween = TweenService:Create(Frame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        })
        closeTween:Play()
        closeTween.Completed:Wait()
        ScreenGui:Destroy()
    end)
    
    CloseBtn.MouseEnter:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 40, 40)}):Play()
    end)
    
    CloseBtn.MouseLeave:Connect(function()
        TweenService:Create(CloseBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(255, 60, 60)}):Play()
    end)
    
    ScreenGui.Parent = game:GetService("CoreGui")
    
    -- Entry Animation
    Frame.Size = UDim2.new(0, 0, 0, 0)
    local openTween = TweenService:Create(Frame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(frameWidth, frameWidthOffset, frameHeight, frameHeightOffset)
    })
    openTween:Play()
    
    wait(0.3)
    fadeIn(ProfileSection, 0.4)
    wait(0.2)
    fadeIn(InfoSection, 0.4)
    
    return ScreenGui
end

local function updateStatus(text, progress)
    if not ProfileUI then return end
    
    local frame = ProfileUI:FindFirstChild("Frame")
    if not frame then return end
    
    local statusLabel = frame:FindFirstChild("StatusLabel")
    local progressBar = frame:FindFirstChild("ProgressBar")
    
    if statusLabel then
        statusLabel.Text = text
    end
    
    if progressBar and progress then
        local fill = progressBar:FindFirstChild("Fill")
        if fill then
            fill:TweenSize(
                UDim2.new(progress, 0, 1, 0),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.5,
                true
            )
        end
    end
end

-- ===== API FUNCTIONS =====
local function makeRequest(endpoint, method, data)
    method = method or "GET"
    
    local url = CONFIG.API_URL .. endpoint
    local options = {
        Url = url,
        Method = method,
        Headers = {
            ["x-api-key"] = CONFIG.API_KEY,
            ["Content-Type"] = "application/json"
        }
    }
    
    if data and method ~= "GET" then
        options.Body = HttpService:JSONEncode(data)
    end
    
    local success, response = pcall(function()
        return request(options)
    end)
    
    if not success then
        return nil, "Connection failed: " .. tostring(response)
    end
    
    if not response.Success then
        return nil, "HTTP Error " .. response.StatusCode .. ": " .. response.StatusMessage
    end
    
    local decodeSuccess, decoded = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)
    
    if not decodeSuccess then
        return nil, "Failed to parse response"
    end
    
    return decoded, nil
end

local function validateUser(userId, key, hwid, placeId)
    local data = {
        userId = userId,
        key = key,
        hwid = hwid,
        placeId = placeId
    }
    
    local response, err = makeRequest("/validate", "POST", data)
    
    if not response then
        return false, "❌ Connection failed: " .. tostring(err), nil
    end
    
    return response.success, response.message, response
end

-- ===== SCRIPT LOADER WITH ERROR HANDLING =====
local function loadScript(scriptUrl)
    updateStatus("📥 Downloading script...", 0.7)
    wait(0.5)
    
    -- Check if scriptUrl is valid
    if not scriptUrl or scriptUrl == "" or scriptUrl == "null" then
        return false, "game_not_found", "Game ini belum terdaftar di sistem kami.\n\nSilakan hubungi admin untuk menambahkan support game ini."
    end
    
    -- Try to download script
    local success, response = pcall(function()
        return request({
            Url = scriptUrl,
            Method = "GET"
        })
    end)
    
    if not success then
        return false, "script_error", "Gagal mengunduh script game.\n\nKemungkinan:\n• Link script rusak atau tidak valid\n• Server script sedang down\n\n💡 Hubungi admin untuk memperbaiki!"
    end
    
    if not response.Success then
        return false, "script_error", "Script game error! (HTTP " .. response.StatusCode .. ")\n\nLink script mungkin rusak atau sudah tidak aktif.\n\n💡 Hubungi admin segera!"
    end
    
    local script = response.Body
    
    if not script or script == "" or script == "404: Not Found" or script:find("404") then
        return false, "script_error", "Script game tidak ditemukan!\n\nLink script di database rusak atau file sudah dihapus.\n\n💡 Hubungi admin untuk update link script!"
    end
    
    updateStatus("⚡ Executing script...", 0.9)
    wait(0.3)
    
    local executeSuccess, executeErr = pcall(function()
        loadstring(script)()
    end)
    
    if not executeSuccess then
        return false, "script_error", "Error saat menjalankan script!\n\n" .. tostring(executeErr) .. "\n\n💡 Script mungkin rusak, hubungi admin!"
    end
    
    return true, "success", "✅ Script loaded!"
end

-- ===== MAIN LOADER =====
local function startLoader(userKey)
    local userId = tostring(LocalPlayer.UserId)
    local hwid = generateHWID()
    local placeId = getCurrentPlaceId()
    
    createNotification("WiseHub", "🔐 Authenticating...", 3)
    
    local success, message, data = validateUser(userId, userKey, hwid, placeId)
    
    if not success then
        showErrorUI("auth_failed", message)
        createNotification("WiseHub", message, 7)
        return false
    end
    
    UserData = data
    
    ProfileUI = createProfileUI(data)
    
    createNotification("WiseHub", "✅ Welcome, " .. (data.username or LocalPlayer.Name) .. "!", 5)
    
    wait(1)
    
    updateStatus("🔍 Detecting game...", 0.3)
    wait(0.5)
    
    updateStatus("🎮 Game detected: " .. getGameName(), 0.5)
    wait(0.5)
    
    -- Check if scriptUrl exists
    if not data.scriptUrl or data.scriptUrl == "" then
        updateStatus("❌ Game not registered", 1)
        wait(1)
        
        if ProfileUI then
            ProfileUI:Destroy()
        end
        
        showErrorUI("game_not_found", "Game ini belum terdaftar di sistem!\n\nPlaceID: " .. placeId .. "\nGame: " .. getGameName() .. "\n\n💡 Silakan hubungi admin untuk menambahkan support game ini.")
        createNotification("WiseHub", "❌ Game tidak terdaftar!", 7)
        return false
    end
    
    local scriptSuccess, errorType, scriptMsg = loadScript(data.scriptUrl)
    
    if not scriptSuccess then
        updateStatus("❌ " .. (errorType == "game_not_found" and "Game Not Found" or "Script Error"), 1)
        wait(1)
        
        if ProfileUI then
            ProfileUI:Destroy()
        end
        
        showErrorUI(errorType, scriptMsg)
        createNotification("WiseHub", errorType == "game_not_found" and "❌ Game tidak terdaftar!" or "❌ Script error!", 7)
        return false
    end
    
    updateStatus("✅ Script loaded successfully!", 1)
    createNotification("WiseHub", "🎉 Enjoy your game!", 5)
    
    wait(2)
    if ProfileUI then
        local frame = ProfileUI:FindFirstChild("Frame")
        if frame then
            local closeTween = TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
                Size = UDim2.new(0, 0, 0, 0)
            })
            closeTween:Play()
            closeTween.Completed:Wait()
        end
        ProfileUI:Destroy()
    end
    
    return true
end

-- ===== PUBLIC API =====
local WiseHub = {}

function WiseHub:Load(key)
    if not key or key == "" then
        showErrorUI("invalid_key", "Key tidak boleh kosong!\n\nFormat penggunaan:\nloadstring(...)():Load(\"YOUR-KEY-HERE\")\n\n💡 Dapatkan key dari admin.")
        createNotification("WiseHub", "❌ Please provide a valid key!", 5)
        return false
    end
    
    return startLoader(key)
end

function WiseHub:GetHWID()
    return generateHWID()
end

function WiseHub:GetUserData()
    return UserData
end

function WiseHub:GetVersion()
    return "3.0.0-Premium"
end

return WiseHub