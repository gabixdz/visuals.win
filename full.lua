-- [[ $arcanum.ven$ - full hvh suite ]]
-- merged mirage.lua logic + vense.lua interface

local repo = 'https://raw.githubusercontent.com/gabixdz/vense.lua/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = '$arcanum.ven$',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local Tabs = {
    Rage = Window:AddTab('rage'),
    AA = Window:AddTab('anti-aim'),
    Visuals = Window:AddTab('visuals'),
    Misc = Window:AddTab('misc'),
    Settings = Window:AddTab('settings'),
}

-- [[ UI SETUP ]]
local RageGroup = Tabs.Rage:AddLeftGroupbox('ragebot')
RageGroup:AddToggle('rage_enabled', { Text = 'enable ragebot', Default = false })
RageGroup:AddToggle('rage_silent', { Text = 'silent aim', Default = false })
RageGroup:AddSlider('rage_fov', { Text = 'aimbot fov', Default = 180, Min = 0, Max = 180, Rounding = 0 })
RageGroup:AddDropdown('rage_hitbox', { Text = 'target hitbox', Default = 1, Values = { 'Head', 'UpperTorso', 'HumanoidRootPart' } })

local ResolverGroup = Tabs.Rage:AddRightGroupbox('resolver')
ResolverGroup:AddToggle('res_enabled', { Text = 'enable resolver', Default = false })

local AAGroup = Tabs.AA:AddLeftGroupbox('anti-aim')
AAGroup:AddToggle('aa_enabled', { Text = 'enable anti-aim', Default = false })
AAGroup:AddDropdown('aa_yaw', { Text = 'yaw type', Default = 1, Values = { 'backward', 'spin', 'jitter' } })
AAGroup:AddSlider('aa_speed', { Text = 'spin speed', Default = 20, Min = 0, Max = 100 })

local VisualsGroup = Tabs.Visuals:AddLeftGroupbox('esp')
VisualsGroup:AddToggle('esp_enabled', { Text = 'enable visuals', Default = false })
VisualsGroup:AddToggle('esp_box', { Text = 'bounding box', Default = false })
VisualsGroup:AddLabel('color'):AddColorPicker('esp_color', { Default = Color3.fromRGB(255, 255, 255) })

local MiscGroup = Tabs.Misc:AddLeftGroupbox('movement')
MiscGroup:AddToggle('misc_bhop', { Text = 'bunnyhop', Default = false })
MiscGroup:AddSlider('misc_speed', { Text = 'speed walk', Default = 16, Min = 16, Max = 150 })

-- [[ CORE LOGIC ]]
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Targeted selection logic
local function get_target()
    local dist = Options.rage_fov.Value
    local target = nil
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local pos, vis = Camera:WorldToViewportPoint(v.Character.HumanoidRootPart.Position)
            local mag = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
            if vis and mag < dist then
                dist = mag
                target = v
            end
        end
    end
    return target
end

-- Silent Aim Hook
local old; old = hookmetamethod(game, "__index", function(self, idx)
    if self == Mouse and idx == "Hit" and Toggles.rage_enabled.Value and Toggles.rage_silent.Value then
        local t = get_target()
        if t then return t.Character[Options.rage_hitbox.Value].CFrame end
    end
    return old(self, idx)
end)

-- Main Loop
game:GetService("RunService").Heartbeat:Connect(function()
    -- Anti-Aim
    if Toggles.aa_enabled.Value and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = LocalPlayer.Character.HumanoidRootPart
        if Options.aa_yaw.Value == 'backward' then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(180), 0)
        elseif Options.aa_yaw.Value == 'spin' then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(tick() * (Options.aa_speed.Value * 10) % 360), 0)
        elseif Options.aa_yaw.Value == 'jitter' then
            hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(math.random(-45, 45)), 0)
        end
    end
    
    -- Movement
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        if Toggles.misc_bhop.Value and LocalPlayer.Character.Humanoid.FloorMaterial ~= Enum.Material.Air then
            LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
        LocalPlayer.Character.Humanoid.WalkSpeed = Options.misc_speed.Value
    end
end)

-- [[ FINALIZATION ]]
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
ThemeManager:SetFolder('arcanum_ven')
SaveManager:SetFolder('arcanum_ven/configs')
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

Library:Notify('$arcanum.ven$ initialized', 5)
