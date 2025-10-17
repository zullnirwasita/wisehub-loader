-- ===== WISEHUB UNIVERSAL LOADER V2 =====
-- Loader dengan Profile UI dan Auto Game Detection

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ThumbnailService = game:GetService("Players")

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

-- ===== TIER CONFIG =====
local TIER_INFO = {
    basic = {
        Name = "Basic VIP",
        Color = Color3.fromRGB(100, 180, 255),
        Icon = "👤",
        Description = "Access to basic features"
    },
    premium = {
        Name = "Premium VIP",
        Color = Color3.fromRGB(255, 215, 0),
        Icon = "⭐",
        Description = "Access to premium features"
    },
    vip = {
        Name = "Elite VIP",
        Color = Color3.fromRGB(138, 43, 226),
        Icon = "👑",
        Description = "Full access + priority support"
    }
}

-- ===== UTILITY FUNCTIONS =====
local function generateHWID()
    local hwid = game:GetService("RbxAnalyticsService"):GetClientId()
    return hwid
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

local function createNotification(title, message, duration, type)
    duration = duration or 5
    type = type or "info"
    
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = message,
        Duration = duration
    })
end

-- ===== UI FUNCTIONS =====
local function createProfileUI(userData)
    -- Get user thumbnail
    local thumbnailUrl = ""
    pcall(function()
        thumbnailUrl = ThumbnailService:GetUserThumbnailAsync(
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
    
    -- Main Frame
    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 450, 0, 550)
    Frame.Position = UDim2.new(0.5, -225, 0.5, -275)
    Frame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    Frame.BorderSizePixel = 0
    Frame.Parent = ScreenGui
    
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 16)
    UICorner.Parent = Frame
    
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = tierInfo.Color
    UIStroke.Thickness = 3
    UIStroke.Parent = Frame
    
    -- Header with gradient
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 80)
    Header.BackgroundColor3 = tierInfo.Color
    Header.BorderSizePixel = 0
    Header.Parent = Frame
    
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 16)
    HeaderCorner.Parent = Header
    
    local HeaderCover = Instance.new("Frame")
    HeaderCover.Size = UDim2.new(1, 0, 0, 40)
    HeaderCover.Position = UDim2.new(0, 0, 1, -40)
    HeaderCover.BackgroundColor3 = tierInfo.Color
    HeaderCover.BorderSizePixel = 0
    HeaderCover.Parent = Header
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -40, 1, 0)
    Title.Position = UDim2.new(0, 20, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🛡️ WISE HUB"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 28
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Header
    
    -- Profile Section
    local ProfileSection = Instance.new("Frame")
    ProfileSection.Size = UDim2.new(1, -40, 0, 160)
    ProfileSection.Position = UDim2.new(0, 20, 0, 100)
    ProfileSection.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    ProfileSection.BorderSizePixel = 0
    ProfileSection.Parent = Frame
    
    local ProfileCorner = Instance.new("UICorner")
    ProfileCorner.CornerRadius = UDim.new(0, 12)
    ProfileCorner.Parent = ProfileSection
    
    -- Avatar Image
    local AvatarFrame = Instance.new("Frame")
    AvatarFrame.Size = UDim2.new(0, 100, 0, 100)
    AvatarFrame.Position = UDim2.new(0, 20, 0, 30)
    AvatarFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    AvatarFrame.BorderSizePixel = 0
    AvatarFrame.Parent = ProfileSection
    
    local AvatarCorner = Instance.new("UICorner")
    AvatarCorner.CornerRadius = UDim.new(0, 12)
    AvatarCorner.Parent = AvatarFrame
    
    local Avatar = Instance.new("ImageLabel")
    Avatar.Size = UDim2.new(1, -4, 1, -4)
    Avatar.Position = UDim2.new(0, 2, 0, 2)
    Avatar.BackgroundTransparency = 1
    Avatar.Image = thumbnailUrl
    Avatar.Parent = AvatarFrame
    
    local AvatarImgCorner = Instance.new("UICorner")
    AvatarImgCorner.CornerRadius = UDim.new(0, 10)
    AvatarImgCorner.Parent = Avatar
    
    -- Username
    local Username = Instance.new("TextLabel")
    Username.Size = UDim2.new(0, 270, 0, 30)
    Username.Position = UDim2.new(0, 135, 0, 30)
    Username.BackgroundTransparency = 1
    Username.Text = userData.username or LocalPlayer.Name
    Username.TextColor3 = Color3.fromRGB(255, 255, 255)
    Username.TextSize = 22
    Username.Font = Enum.Font.GothamBold
    Username.TextXAlignment = Enum.TextXAlignment.Left
    Username.TextTruncate = Enum.TextTruncate.AtEnd
    Username.Parent = ProfileSection
    
    -- User ID
    local UserId = Instance.new("TextLabel")
    UserId.Size = UDim2.new(0, 270, 0, 20)
    UserId.Position = UDim2.new(0, 135, 0, 60)
    UserId.BackgroundTransparency = 1
    UserId.Text = "ID: " .. LocalPlayer.UserId
    UserId.TextColor3 = Color3.fromRGB(150, 150, 150)
    UserId.TextSize = 14
    UserId.Font = Enum.Font.Gotham
    UserId.TextXAlignment = Enum.TextXAlignment.Left
    UserId.Parent = ProfileSection
    
    -- Tier Badge
    local TierBadge = Instance.new("Frame")
    TierBadge.Size = UDim2.new(0, 250, 0, 40)
    TierBadge.Position = UDim2.new(0, 135, 0, 85)
    TierBadge.BackgroundColor3 = tierInfo.Color
    TierBadge.BorderSizePixel = 0
    TierBadge.Parent = ProfileSection
    
    local TierCorner = Instance.new("UICorner")
    TierCorner.CornerRadius = UDim.new(0, 8)
    TierCorner.Parent = TierBadge
    
    local TierIcon = Instance.new("TextLabel")
    TierIcon.Size = UDim2.new(0, 30, 1, 0)
    TierIcon.Position = UDim2.new(0, 10, 0, 0)
    TierIcon.BackgroundTransparency = 1
    TierIcon.Text = tierInfo.Icon
    TierIcon.TextColor3 = Color3.fromRGB(255, 255, 255)
    TierIcon.TextSize = 20
    TierIcon.Font = Enum.Font.GothamBold
    TierIcon.Parent = TierBadge
    
    local TierText = Instance.new("TextLabel")
    TierText.Size = UDim2.new(1, -50, 1, 0)
    TierText.Position = UDim2.new(0, 40, 0, 0)
    TierText.BackgroundTransparency = 1
    TierText.Text = tierInfo.Name
    TierText.TextColor3 = Color3.fromRGB(255, 255, 255)
    TierText.TextSize = 16
    TierText.Font = Enum.Font.GothamBold
    TierText.TextXAlignment = Enum.TextXAlignment.Left
    TierText.Parent = TierBadge
    
    -- Info Section
    local InfoSection = Instance.new("Frame")
    InfoSection.Size = UDim2.new(1, -40, 0, 120)
    InfoSection.Position = UDim2.new(0, 20, 0, 280)
    InfoSection.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    InfoSection.BorderSizePixel = 0
    InfoSection.Parent = Frame
    
    local InfoCorner = Instance.new("UICorner")
    InfoCorner.CornerRadius = UDim.new(0, 12)
    InfoCorner.Parent = InfoSection
    
    -- Expiry Info
    local ExpiryLabel = Instance.new("TextLabel")
    ExpiryLabel.Size = UDim2.new(1, -30, 0, 25)
    ExpiryLabel.Position = UDim2.new(0, 15, 0, 15)
    ExpiryLabel.BackgroundTransparency = 1
    ExpiryLabel.Text = "⏰ Expires: " .. formatDate(userData.expiry)
    ExpiryLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    ExpiryLabel.TextSize = 15
    ExpiryLabel.Font = Enum.Font.Gotham
    ExpiryLabel.TextXAlignment = Enum.TextXAlignment.Left
    ExpiryLabel.Parent = InfoSection
    
    -- Days Remaining
    local DaysLabel = Instance.new("TextLabel")
    DaysLabel.Size = UDim2.new(1, -30, 0, 25)
    DaysLabel.Position = UDim2.new(0, 15, 0, 45)
    DaysLabel.BackgroundTransparency = 1
    DaysLabel.Text = string.format("📅 Days Remaining: %d days", daysLeft)
    DaysLabel.TextColor3 = daysLeft < 7 and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(100, 255, 150)
    DaysLabel.TextSize = 15
    DaysLabel.Font = Enum.Font.GothamBold
    DaysLabel.TextXAlignment = Enum.TextXAlignment.Left
    DaysLabel.Parent = InfoSection
    
    -- Login Count
    local LoginLabel = Instance.new("TextLabel")
    LoginLabel.Size = UDim2.new(1, -30, 0, 25)
    LoginLabel.Position = UDim2.new(0, 15, 0, 75)
    LoginLabel.BackgroundTransparency = 1
    LoginLabel.Text = "🔐 Total Logins: " .. (userData.login_count or 0)
    LoginLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    LoginLabel.TextSize = 15
    LoginLabel.Font = Enum.Font.Gotham
    LoginLabel.TextXAlignment = Enum.TextXAlignment.Left
    LoginLabel.Parent = InfoSection
    
    -- Status Label
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Name = "StatusLabel"
    StatusLabel.Size = UDim2.new(1, -40, 0, 30)
    StatusLabel.Position = UDim2.new(0, 20, 0, 420)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "🎮 Loading game script..."
    StatusLabel.TextColor3 = Color3.fromRGB(150, 200, 255)
    StatusLabel.TextSize = 16
    StatusLabel.Font = Enum.Font.GothamBold
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Center
    StatusLabel.Parent = Frame
    
    -- Progress Bar
    local ProgressBar = Instance.new("Frame")
    ProgressBar.Name = "ProgressBar"
    ProgressBar.Size = UDim2.new(1, -40, 0, 8)
    ProgressBar.Position = UDim2.new(0, 20, 0, 460)
    ProgressBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    ProgressBar.BorderSizePixel = 0
    ProgressBar.Parent = Frame
    
    local ProgressCorner = Instance.new("UICorner")
    ProgressCorner.CornerRadius = UDim.new(0, 4)
    ProgressCorner.Parent = ProgressBar
    
    local ProgressFill = Instance.new("Frame")
    ProgressFill.Name = "Fill"
    ProgressFill.Size = UDim2.new(0, 0, 1, 0)
    ProgressFill.BackgroundColor3 = tierInfo.Color
    ProgressFill.BorderSizePixel = 0
    ProgressFill.Parent = ProgressBar
    
    local FillCorner = Instance.new("UICorner")
    FillCorner.CornerRadius = UDim.new(0, 4)
    FillCorner.Parent = ProgressFill
    
    -- Game Info
    local GameLabel = Instance.new("TextLabel")
    GameLabel.Size = UDim2.new(1, -40, 0, 25)
    GameLabel.Position = UDim2.new(0, 20, 0, 480)
    GameLabel.BackgroundTransparency = 1
    GameLabel.Text = "📍 " .. getGameName()
    GameLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
    GameLabel.TextSize = 13
    GameLabel.Font = Enum.Font.Gotham
    GameLabel.TextXAlignment = Enum.TextXAlignment.Center
    GameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    GameLabel.Parent = Frame
    
    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 35, 0, 35)
    CloseBtn.Position = UDim2.new(1, -50, 0, 22)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = 20
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Parent = Header
    
    local CloseCorner = Instance.new("UICorner")
    CloseCorner.CornerRadius = UDim.new(0, 8)
    CloseCorner.Parent = CloseBtn
    
    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
    
    ScreenGui.Parent = game:GetService("CoreGui")
    
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
                0.4,
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

-- ===== SCRIPT LOADER =====
local function loadScript(scriptUrl)
    updateStatus("📥 Downloading script...", 0.7)
    wait(0.5)
    
    local success, response = pcall(function()
        return request({
            Url = scriptUrl,
            Method = "GET"
        })
    end)
    
    if not success or not response.Success then
        return false, "❌ Failed to download script"
    end
    
    local script = response.Body
    
    if not script or script == "" then
        return false, "❌ Script is empty"
    end
    
    updateStatus("⚡ Executing script...", 0.9)
    wait(0.3)
    
    local executeSuccess, executeErr = pcall(function()
        loadstring(script)()
    end)
    
    if not executeSuccess then
        return false, "❌ Execution error: " .. tostring(executeErr)
    end
    
    return true, "✅ Script loaded!"
end

-- ===== MAIN LOADER =====
local function startLoader(userKey)
    -- Get info
    local userId = tostring(LocalPlayer.UserId)
    local hwid = generateHWID()
    local placeId = getCurrentPlaceId()
    
    -- Create notification
    createNotification("WiseHub", "🔐 Authenticating...", 3)
    
    -- Validate
    local success, message, data = validateUser(userId, userKey, hwid, placeId)
    
    if not success then
        createNotification("WiseHub", message, 7)
        return false
    end
    
    -- Store user data
    UserData = data
    
    -- Create Profile UI
    ProfileUI = createProfileUI(data)
    
    createNotification("WiseHub", "✅ Welcome, " .. (data.username or LocalPlayer.Name) .. "!", 5)
    
    wait(1)
    
    -- Auto detect & load game script
    updateStatus("🔍 Detecting game...", 0.3)
    wait(0.5)
    
    updateStatus("🎮 Game detected: " .. getGameName(), 0.5)
    wait(0.5)
    
    -- Load script
    local scriptSuccess, scriptMsg = loadScript(data.scriptUrl)
    
    if not scriptSuccess then
        updateStatus(scriptMsg, 1)
        createNotification("WiseHub", scriptMsg, 7)
        wait(3)
        return false
    end
    
    updateStatus("✅ Script loaded successfully!", 1)
    createNotification("WiseHub", "🎉 Enjoy your game!", 5)
    
    wait(2)
    if ProfileUI then
        ProfileUI:Destroy()
    end
    
    return true
end

-- ===== PUBLIC API =====
local WiseHub = {}

function WiseHub:Load(key)
    if not key or key == "" then
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

return WiseHub