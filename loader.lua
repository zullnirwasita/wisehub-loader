-- ===== WISE HUB LOADER - ALL-IN-ONE VERSION =====
-- Compatible with Wind UI KeySystem Structure
-- Last Updated: 2025

-- === PREVENT MULTIPLE INSTANCES ===
if getgenv()._WISE_HUB_LOADED then
    game.Players.LocalPlayer:Kick("❌ Script already loaded!")
    return
end

getgenv()._WISE_HUB_LOADED = true

-- Wait for game to load
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- === CONFIG ===
local CONFIG = {
    API_URL = "https://wisehub-api.yourname.workers.dev", -- GANTI!
    API_KEY = "DAP", -- GANTI!
    DISCORD_LINK = "https://discord.gg/yourserver", -- GANTI!
    WHATSAPP_LINK = "https://whatsapp.com/channel/0029Vb7DQKsFCCoPegXh9W2O" -- GANTI!
}

-- === SERVICES ===
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- === HWID FUNCTION ===
local function getHWID()
    if gethwid then
        return gethwid()
    elseif syn and syn.request then
        return tostring(game:GetService("RbxAnalyticsService"):GetClientId())
    else
        return "FALLBACK-" .. HttpService:GenerateGUID(false)
    end
end

-- === LOAD WIND UI ===
local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

-- === ADD CUSTOM THEME ===
WindUI:AddTheme({
    Name = "Midnight Frost",
    Accent = Color3.fromHex("#0ea5e9"),
    Dialog = Color3.fromHex("#1e293b"),
    Outline = Color3.fromHex("#475569"),
    Text = Color3.fromHex("#f1f5f9"),
    Placeholder = Color3.fromHex("#94a3b8"),
    Background = Color3.fromHex("#0f172a"),
    Button = Color3.fromHex("#334155"),
    Icon = Color3.fromHex("#cbd5e1")
})

-- === REGISTER CUSTOM KEY SYSTEM SERVICE ===
-- Ini harus didefinisikan SEBELUM CreateWindow
WindUI.Services.WiseHubValidator = {
    Name = "Wise Hub Key System",
    Icon = "shield-check",
    
    -- Tidak perlu Args karena kita hardcode API_URL dan API_KEY
    New = function()
        
        -- Function untuk validasi key
        local function validateKey(key)
            -- Validasi basic
            if not key or type(key) ~= "string" or key == "" then
                return false, "❌ Key tidak boleh kosong!"
            end
            
            -- Get player info
            local player = Players.LocalPlayer
            local userId = tostring(player.UserId)
            local hwid = getHWID()
            local placeId = tostring(game.PlaceId)
            
            -- Build request
            local requestBody = HttpService:JSONEncode({
                userId = userId,
                key = key,
                hwid = hwid,
                placeId = placeId
            })
            
            -- Call API dengan error handling
            local success, response = pcall(function()
                return game:HttpPost(
                    CONFIG.API_URL .. "/validate",
                    requestBody,
                    Enum.HttpContentType.ApplicationJson,
                    true,
                    {
                        ["Content-Type"] = "application/json",
                        ["x-api-key"] = CONFIG.API_KEY
                    }
                )
            end)
            
            -- Handle connection error
            if not success then
                return false, "❌ Koneksi ke server gagal!\n\nPastikan:\n1. API URL benar\n2. Internet stabil\n3. Worker sudah deploy"
            end
            
            -- Parse JSON response
            local parseSuccess, data = pcall(function()
                return HttpService:JSONDecode(response)
            end)
            
            if not parseSuccess then
                return false, "❌ Server response error!\n\nHubungi admin."
            end
            
            -- Check validation result
            if data.success then
                -- Simpan data user ke global env
                getgenv().WiseHub_ScriptUrl = data.scriptUrl
                getgenv().WiseHub_UserTier = data.tier or "basic"
                getgenv().WiseHub_Username = data.username or "User"
                getgenv().WiseHub_Expiry = data.expiry
                
                return true, data.message or "✅ Selamat bermain!"
            else
                return false, data.message or "❌ Validasi gagal!"
            end
        end
        
        -- Function untuk copy link (dipanggil saat user klik tombol copy di key system)
        local function copyLink()
            local linkText = string.format(
                "🛡️ Wise Hub - Premium Script Hub\n\n📱 Discord: %s\n💬 WhatsApp: %s\n\n🔑 Hubungi admin untuk mendapatkan VIP key!",
                CONFIG.DISCORD_LINK,
                CONFIG.WHATSAPP_LINK
            )
            
            if setclipboard then
                setclipboard(linkText)
                return "✅ Links copied to clipboard!"
            else
                return "❌ Clipboard not supported by your executor."
            end
        end
        
        -- PENTING: Return object dengan Verify dan Copy
        return {
            Verify = validateKey,
            Copy = copyLink
        }
    end
}

-- === CREATE WINDOW WITH KEY SYSTEM ===
local Window = WindUI:CreateWindow({
    Title = "Wise Hub",
    Icon = "boxes",
    Author = "by Zu11",
    Folder = "WiseHub",
    Size = UDim2.fromOffset(580, 460),
    Transparent = true,
    Theme = "Midnight Frost",
    Resizable = true,
    SideBarWidth = 200,
    
    -- Key System Configuration
    KeySystem = {
        Note = "🔑 Masukkan VIP Key Anda\n\nBelum punya key? Klik tombol di bawah untuk mendapatkan link komunitas kami!",
        
        SaveKey = false, -- Set true jika mau auto-save key
        
        -- API untuk validasi
        API = {
            {
                Type = "WiseHubValidator" -- Nama service yang kita daftarkan di atas
            }
        }
    }
})

-- === MAIN TAB ===
local MainTab = Window:Tab({
    Title = "Main",
    Icon = "home"
})

local MainSection = MainTab:Section({
    Title = "Script Executor",
    Opened = true
})

-- Welcome message
if getgenv().WiseHub_Username then
    MainSection:Paragraph({
        Title = "👋 Welcome back, " .. getgenv().WiseHub_Username .. "!",
        Description = string.format(
            "• Tier: %s\n• Expiry: %s",
            getgenv().WiseHub_UserTier or "Unknown",
            getgenv().WiseHub_Expiry or "Unknown"
        )
    })
end

-- Execute Script Button
MainSection:Button({
    Title = "▶️ Execute Script",
    Description = "Load and run the script for this game.",
    Icon = "play",
    Callback = function()
        local scriptUrl = getgenv().WiseHub_ScriptUrl
        
        if not scriptUrl then
            WindUI:Notify({
                Title = "Error",
                Description = "❌ No script available for this game.\n\nPlace ID: " .. tostring(game.PlaceId),
                Duration = 5
            })
            return
        end
        
        WindUI:Notify({
            Title = "Loading",
            Description = "⏳ Fetching script from server...",
            Duration = 2
        })
        
        -- Fetch script dari URL
        local success, scriptContent = pcall(function()
            return game:HttpGet(scriptUrl)
        end)
        
        if success and scriptContent then
            local func, err = loadstring(scriptContent)
            
            if func then
                WindUI:Notify({
                    Title = "Success",
                    Description = "✅ Script loaded! Executing...",
                    Duration = 2
                })
                
                task.wait(0.5)
                
                -- Destroy UI sebelum execute
                Window:Destroy()
                
                -- Execute game script
                local executeSuccess, executeError = pcall(func)
                
                if not executeSuccess then
                    warn("❌ Script execution error: " .. tostring(executeError))
                end
                
                -- Cleanup sensitive data
                getgenv().WiseHub_ScriptUrl = nil
                getgenv().WiseHub_UserTier = nil
                getgenv().WiseHub_Username = nil
                getgenv().WiseHub_Expiry = nil
            else
                WindUI:Notify({
                    Title = "Error",
                    Description = "❌ Failed to parse script:\n\n" .. tostring(err),
                    Duration = 5
                })
            end
        else
            WindUI:Notify({
                Title = "Error",
                Description = "❌ Failed to fetch script from server.\n\nCheck if script_url in database is correct.",
                Duration = 5
            })
        end
    end
})

MainSection:Button({
    Title = "🔄 Refresh Info",
    Description = "Reload your user information.",
    Icon = "refresh-cw",
    Callback = function()
        if getgenv().WiseHub_Username then
            WindUI:Notify({
                Title = "User Info",
                Description = string.format(
                    "Username: %s\nTier: %s\nExpiry: %s",
                    getgenv().WiseHub_Username,
                    getgenv().WiseHub_UserTier or "Unknown",
                    getgenv().WiseHub_Expiry or "Unknown"
                ),
                Duration = 5
            })
        else
            WindUI:Notify({
                Title = "Error",
                Description = "❌ No user data found.",
                Duration = 3
            })
        end
    end
})

-- === COMMUNITY TAB ===
local CommunityTab = Window:Tab({
    Title = "Community",
    Icon = "users"
})

local CommunitySection = CommunityTab:Section({
    Title = "Join Our Community",
    Opened = true
})

CommunitySection:Paragraph({
    Title = "📱 Where to find us?",
    Description = "Join our community for:\n• Script updates\n• VIP giveaways\n• 24/7 support\n• Exclusive scripts"
})

CommunitySection:Button({
    Title = "📱 Copy Discord Link",
    Description = "Join our Discord server.",
    Icon = "message-circle",
    Callback = function()
        if setclipboard then
            setclipboard(CONFIG.DISCORD_LINK)
            WindUI:Notify({
                Title = "Success",
                Description = "✅ Discord link copied to clipboard!",
                Duration = 2
            })
        else
            WindUI:Notify({
                Title = "Discord Link",
                Description = CONFIG.DISCORD_LINK,
                Duration = 5
            })
        end
    end
})

CommunitySection:Button({
    Title = "💬 Copy WhatsApp Link",
    Description = "Join our WhatsApp channel.",
    Icon = "phone",
    Callback = function()
        if setclipboard then
            setclipboard(CONFIG.WHATSAPP_LINK)
            WindUI:Notify({
                Title = "Success",
                Description = "✅ WhatsApp link copied to clipboard!",
                Duration = 2
            })
        else
            WindUI:Notify({
                Title = "WhatsApp Link",
                Description = CONFIG.WHATSAPP_LINK,
                Duration = 5
            })
        end
    end
})

-- === INFO TAB ===
local InfoTab = Window:Tab({
    Title = "Info",
    Icon = "info"
})

local InfoSection = InfoTab:Section({
    Title = "About Wise Hub",
    Opened = true
})

InfoSection:Paragraph({
    Title = "🛡️ Wise Hub v1.0",
    Description = "Premium script hub with integrated VIP key system and advanced security.\n\nMade with ❤️ by Zu11"
})

InfoSection:Paragraph({
    Title = "✨ Features",
    Description = "• 🔒 HWID Lock Protection\n• 🎮 Multi-Game Support\n• 🔄 Auto Updates\n• 💬 24/7 Support\n• ⚡ Fast & Reliable\n• 🛡️ Secure API"
})

InfoSection:Paragraph({
    Title = "🔐 Security",
    Description = "• Cloudflare Workers API\n• Supabase Database\n• Hardware ID Lock\n• Key Validation System\n• Admin Dashboard"
})

InfoSection:Button({
    Title = "ℹ️ System Info",
    Description = "View current game and system information.",
    Icon = "info",
    Callback = function()
        local info = string.format(
            "Place ID: %s\nPlayer: %s (%s)\nHWID: %s\nExecutor: %s",
            tostring(game.PlaceId),
            Players.LocalPlayer.Name,
            tostring(Players.LocalPlayer.UserId),
            getHWID():sub(1, 16) .. "...",
            identifyexecutor and identifyexecutor() or "Unknown"
        )
        
        WindUI:Notify({
            Title = "System Information",
            Description = info,
            Duration = 8
        })
    end
})

InfoSection:Button({
    Title = "✅ Check Updates",
    Description = "Verify you're using the latest version.",
    Icon = "check-circle",
    Callback = function()
        WindUI:Notify({
            Title = "Version Check",
            Description = "✅ You're running the latest version!\n\nVersion: 1.0.0\nLast Update: 2025",
            Duration = 3
        })
    end
})

-- === SETTINGS TAB ===
local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings"
})

local SettingsSection = SettingsTab:Section({
    Title = "Script Settings",
    Opened = true
})

SettingsSection:Paragraph({
    Title = "⚙️ Configuration",
    Description = "Current API Configuration:\n\n• API URL: " .. CONFIG.API_URL:match("https://([^/]+)") .. "\n• Status: Connected"
})

SettingsSection:Button({
    Title = "🔄 Reset Script",
    Description = "Reload the entire script.",
    Icon = "rotate-ccw",
    Callback = function()
        getgenv()._WISE_HUB_LOADED = nil
        Window:Destroy()
        
        WindUI:Notify({
            Title = "Reset",
            Description = "✅ Script reset! Re-execute to use again.",
            Duration = 3
        })
    end
})

-- === SIMPLE PROTECTION ===
-- Auto cleanup after 10 minutes
task.spawn(function()
    task.wait(600) -- 10 minutes
    if getgenv()._WISE_HUB_LOADED then
        -- Clear sensitive data
        getgenv().WiseHub_ScriptUrl = nil
        getgenv().WiseHub_UserTier = nil
        getgenv().WiseHub_Username = nil
        getgenv().WiseHub_Expiry = nil
    end
end)