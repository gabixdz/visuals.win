-- [[ $arcanum.ven$ - section 1: core initialization ]]
local repo = 'https://raw.githubusercontent.com/gabixdz/vense.lua/main/'
local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

-- Initialize rebranded window
local Window = Library:CreateWindow({
    Title = '$arcanum.ven$',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

-- Lowercase Tab Setup (Vense Framework)
local Tabs = {
    Rage = Window:AddTab('rage'),
    AntiAim = Window:AddTab('anti-aim'),
    Visuals = Window:AddTab('visuals'),
    Misc = Window:AddTab('misc'),
    Settings = Window:AddTab('settings'),
}

-- Global logic table for $arcanum.ven$
local arcanum_globals = {
    version = "v1.0",
    is_running = true,
    scripts_merged = true
}

-- Confirmation notification
Library:Notify('successfully loaded $arcanum.ven$', 5)-- [[ $arcanum.ven$ - section 2: rage & aa interface ]]

-- Ragebot Groupbox
local RageGroup = Tabs.Rage:AddLeftGroupbox('ragebot logic')
RageGroup:AddToggle('rage_active', { Text = 'enable ragebot', Default = false })
RageGroup:AddToggle('rage_silent', { Text = 'silent aim', Default = false })
RageGroup:AddDropdown('rage_target', { Text = 'target priority', Default = 1, Values = { 'distance', 'health', 'fov' } })
RageGroup:AddSlider('rage_fov', { Text = 'aimbot fov', Default = 180, Min = 0, Max = 180, Rounding = 0 })

-- Mirage Resolver Port
local ResolverGroup = Tabs.Rage:AddRightGroupbox('resolver')
ResolverGroup:AddToggle('res_enabled', { Text = 'enable resolver', Default = false })
ResolverGroup:AddDropdown('res_mode', { Text = 'resolver mode', Default = 1, Values = { 'automatic', 'bruteforce', 'inverse' } })

-- Anti-Aim Groupbox
local AAGroup = Tabs.AntiAim:AddLeftGroupbox('anti-aim')
AAGroup:AddToggle('aa_active', { Text = 'enable anti-aim', Default = false })
AAGroup:AddDropdown('aa_yaw', { Text = 'yaw base', Default = 1, Values = { 'backward', 'spin', 'jitter', 'arcanum custom' } })
AAGroup:AddSlider('aa_yaw_offset', { Text = 'yaw offset', Default = 0, Min = -180, Max = 180, Rounding = 0 })
AAGroup:AddSlider('aa_jitter_range', { Text = 'jitter range', Default = 0, Min = 0, Max = 90, Rounding = 0 })

local PitchGroup = Tabs.AntiAim:AddRightGroupbox('pitch & modifier')
PitchGroup:AddDropdown('aa_pitch', { Text = 'pitch mode', Default = 1, Values = { 'none', 'down', 'up', 'jitter' } })
PitchGroup:AddToggle('aa_desync', { Text = 'enable desync', Default = false })-- [[ $arcanum.ven$ - section 3: core math & combat loop ]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

-- Mirage Math Tables Ported to Arcanum
local arcanum_math = {
    last_tick = 0,
    angle_offset = 0,
    target = nil,
    hitbox_list = {"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm", "LeftUpperLeg", "RightUpperLeg"}
}

-- Target Selection Logic (Mirage Logic)
local function get_best_target()
    local max_dist = Options.rage_fov.Value
    local best_ply = nil
    
    for _, ply in pairs(Players:GetPlayers()) do
        if ply ~= LocalPlayer and ply.Character and ply.Character:FindFirstChild("HumanoidRootPart") and ply.Character:FindFirstChild("Humanoid") then
            if ply.Character.Humanoid.Health > 0 then
                local screen_pos, on_screen = Camera:WorldToViewportPoint(ply.Character.HumanoidRootPart.Position)
                if on_screen then
                    local mouse_dist = (Vector2.new(screen_pos.X, screen_pos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                    if mouse_dist < max_dist then
                        max_dist = mouse_dist
                        best_ply = ply
                    end
                end
            end
        end
    end
    return best_ply
end

-- Mirage Anti-Aim Rotation Matrix
local function run_arcanum_aa()
    if not Toggles.aa_active.Value then return end
    
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    arcanum_math.angle_offset = (arcanum_math.angle_offset + Options.aa_yaw_offset.Value) % 360
    local yaw_logic = Options.aa_yaw.Value
    local final_cframe = root.CFrame
    
    if yaw_logic == 'backward' then
        final_cframe = final_cframe * CFrame.Angles(0, math.rad(180), 0)
    elseif yaw_logic == 'spin' then
        final_cframe = final_cframe * CFrame.Angles(0, math.rad(tick() * (Options.aa_yaw_offset.Value * 10) % 360), 0)
    elseif yaw_logic == 'jitter' then
        local jitter = math.random(-Options.aa_jitter_range.Value, Options.aa_jitter_range.Value)
        final_cframe = final_cframe * CFrame.Angles(0, math.rad(180 + jitter), 0)
    elseif yaw_logic == 'arcanum custom' then
        -- Ported Mirage Custom Desync Math
        final_cframe = final_cframe * CFrame.Angles(0, math.rad(math.sin(tick() * 15) * 45), 0)
    end
    
    -- Pitch Logic
    local pitch_logic = Options.aa_pitch.Value
    if pitch_logic == 'down' then
        final_cframe = final_cframe * CFrame.Angles(math.rad(-89), 0, 0)
    elseif pitch_logic == 'up' then
        final_cframe = final_cframe * CFrame.Angles(math.rad(89), 0, 0)
    end
    
    root.CFrame = final_cframe
end

-- Main Execution Heartbeat
RunService.Heartbeat:Connect(function()
    if Toggles.rage_active.Value then
        arcanum_math.target = get_best_target()
        -- Silent Aim / Rage Logic from Mirage Crack
        if arcanum_math.target and Toggles.rage_silent.Value then
            local aim_part = arcanum_math.target.Character[Options.rage_target_part.Value or "Head"]
            -- This hook simulates the Mirage Silent Aim manipulation
            local old_index
            old_index = hookmetamethod(game, "__index", function(self, index)
                if self == Mouse and index == "Hit" and Toggles.rage_active.Value then
                    return aim_part.CFrame
                end
                return old_index(self, index)
            end)
        end
    end
    
    run_arcanum_aa()
end)-- [[ $arcanum.ven$ - section 4: visual engine ]]

local VisualsMain = Tabs.Visuals:AddLeftGroupbox('esp main')
local VisualsMisc = Tabs.Visuals:AddRightGroupbox('world & fov')

VisualsMain:AddToggle('esp_enabled', { Text = 'enable esp', Default = false })
VisualsMain:AddToggle('esp_boxes', { Text = 'bounding box', Default = false })
VisualsMain:AddToggle('esp_names', { Text = 'player labels', Default = false })
VisualsMain:AddLabel('box color'):AddColorPicker('esp_color', { Default = Color3.fromRGB(255, 255, 255) })

VisualsMisc:AddSlider('field_of_view', { Text = 'custom fov', Default = 90, Min = 70, Max = 130, Rounding = 0 })
VisualsMisc:AddToggle('no_recoil', { Text = 'remove camera shake', Default = false })

-- ESP Rendering Engine (Ported Mirage Drawing API)
local function create_esp_elements(player)
    local box = Drawing.new("Square")
    box.Visible = false
    box.Thickness = 1
    box.Color = Color3.new(1,1,1)
    
    local name = Drawing.new("Text")
    name.Visible = false
    name.Center = true
    name.Outline = true
    name.Size = 13
    
    RunService.RenderStepped:Connect(function()
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and Toggles.esp_enabled.Value then
            local rootPos, onScreen = Camera:WorldToViewportPoint(player.Character.HumanoidRootPart.Position)
            if onScreen then
                if Toggles.esp_boxes.Value then
                    box.Size = Vector2.new(2000 / rootPos.Z, 2500 / rootPos.Z)
                    box.Position = Vector2.new(rootPos.X - box.Size.X / 2, rootPos.Y - box.Size.Y / 2)
                    box.Color = Options.esp_color.Value
                    box.Visible = true
                else box.Visible = false end
                
                if Toggles.esp_names.Value then
                    name.Text = string.lower(player.Name .. " [$arcanum.ven$]") -- Custom Rebrand
                    name.Position = Vector2.new(rootPos.X, rootPos.Y - (box.Size.Y / 2) - 15)
                    name.Visible = true
                else name.Visible = false end
            else
                box.Visible = false
                name.Visible = false
            end
        else
            box.Visible = false
            name.Visible = false
        end
    end)
end

-- Initialize ESP for all current and new players
for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then create_esp_elements(p) end end
Players.PlayerAdded:Connect(create_esp_elements)

-- World Modifiers
Options.field_of_view:OnChanged(function()
    Camera.FieldOfView = Options.field_of_view.Value
end)-- [[ $arcanum.ven$ - section 5: misc & finalization ]]

local MiscGroup = Tabs.Misc:AddLeftGroupbox('movement & utility')
local CreditGroup = Tabs.Misc:AddRightGroupbox('arcanum info')

-- Movement Features (Ported Mirage logic)
MiscGroup:AddToggle('misc_bhop', { Text = 'bunnyhop', Default = false })
MiscGroup:AddToggle('misc_walkspeed', { Text = 'speed hack', Default = false })
MiscGroup:AddSlider('misc_ws_value', { Text = 'speed amount', Default = 16, Min = 16, Max = 200, Rounding = 0 })

-- Branding/Credits (All lowercase as requested)
CreditGroup:AddLabel('script: $arcanum.ven$')
CreditGroup:AddLabel('status: operational')
CreditGroup:AddButton('copy discord', function()
    setclipboard("https://discord.gg/arcanum-ven")
    Library:Notify('discord link copied to clipboard', 3)
end)

-- Movement Logic Execution
RunService.Stepped:Connect(function()
    if Toggles.misc_bhop and Toggles.misc_bhop.Value then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            if LocalPlayer.Character.Humanoid.FloorMaterial ~= Enum.Material.Air then
                LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end
    end
    
    if Toggles.misc_walkspeed and Toggles.misc_walkspeed.Value then
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
            LocalPlayer.Character.Humanoid.WalkSpeed = Options.misc_ws_value.Value
        end
    end
end)

-- [[ THEME & CONFIGURATION SYSTEM ]]

-- Set up the library for managers
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

-- Ignore theme settings in config saves
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

-- Set folders (Lowercase rebranding)
ThemeManager:SetFolder('arcanum_ven')
SaveManager:SetFolder('arcanum_ven/configs')

-- Build the Settings Tab
SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)

-- Default UI Setup
Window:SelectTab(1)
Library:Notify('$arcanum.ven$ initialized successfully', 5)

-- Final Mirage Logic Hook: Keybind to toggle menu
Library.Keybind = Enum.KeyCode.RightShift -- Default Mirage/Vense toggle key

-- Handle Auto-Load
SaveManager:LoadAutoloadConfig()
