--[[ $visuals.win$ — Ultimate Visual Effects Script ]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ── Config ────────────────────────────────────────────────────────────────────
local Config = {
    BG         = Color3.fromRGB(8,   8,  12),
    Panel      = Color3.fromRGB(14, 14,  20),
    Card       = Color3.fromRGB(20, 20,  30),
    Border     = Color3.fromRGB(40, 40,  60),
    Accent     = Color3.fromRGB(120, 80, 255),
    AccentB    = Color3.fromRGB(0,  200, 255),
    Text       = Color3.fromRGB(240, 240, 255),
    SubText    = Color3.fromRGB(140, 140, 170),
    On         = Color3.fromRGB(80,  220, 120),
    Off        = Color3.fromRGB(220,  60,  60),
}

-- ── State ─────────────────────────────────────────────────────────────────────
local Enabled    = {}   -- [key] = bool
local Settings   = {}   -- [key] = { color, rainbow, neon, size, speed, ... }
local Conns      = {}   -- [key] = connection or {connections}
local Objects    = {}   -- [key] = {parts/instances to clean}
local RainbowC   = {}   -- [key] = heartbeat conn for rainbow

local function getChar()  return player.Character end
local function getHRP()
    local c = getChar(); if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart")
end
local function getHum()
    local c = getChar(); if not c then return nil end
    return c:FindFirstChild("Humanoid")
end

-- ── Helpers ───────────────────────────────────────────────────────────────────
local function corner(p, r) local c=Instance.new("UICorner"); c.CornerRadius=UDim.new(0,r or 8); c.Parent=p end
local function stroke(p, t, c) local s=Instance.new("UIStroke"); s.Thickness=t or 1; s.Color=c or Config.Border; s.Parent=p end
local function tween(obj, t, props, style, dir)
    return TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
end
local function lerp(a,b,t) return a+(b-a)*t end
local function rainbowColor(offset)
    return Color3.fromHSV(((tick()*0.4)+(offset or 0))%1, 1, 1)
end
local function stopRainbow(key)
    if RainbowC[key] then RainbowC[key]:Disconnect(); RainbowC[key]=nil end
end
local function cleanObjects(key)
    if Objects[key] then
        for _, obj in pairs(Objects[key]) do
            if typeof(obj)=="Instance" and obj.Parent then obj:Destroy() end
        end
        Objects[key] = {}
    end
end
local function disconnectConn(key)
    if Conns[key] then
        if typeof(Conns[key])=="RBXScriptConnection" then
            Conns[key]:Disconnect()
        elseif type(Conns[key])=="table" then
            for _, c in pairs(Conns[key]) do if typeof(c)=="RBXScriptConnection" then c:Disconnect() end end
        end
        Conns[key]=nil
    end
end
local function makePart(size, color, mat, parent)
    local p=Instance.new("Part")
    p.Size=size or Vector3.new(1,1,1)
    p.Color=color or Color3.fromRGB(255,255,255)
    p.Material=mat or Enum.Material.Neon
    p.CanCollide=false; p.Anchored=true; p.CastShadow=false
    p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
    p.Parent=parent or workspace
    return p
end
local function makeBillboard(adornee, size)
    local bb=Instance.new("BillboardGui")
    bb.Size=UDim2.new(0,size or 40,0,size or 40)
    bb.AlwaysOnTop=false; bb.Adornee=adornee; bb.Parent=adornee
    return bb
end
local function makeGlow(parent, color, size)
    local img=Instance.new("ImageLabel")
    img.Size=UDim2.new(1,0,1,0); img.BackgroundTransparency=1
    img.Image="rbxassetid://6407871923"
    img.ImageColor3=color or Color3.fromRGB(255,255,255)
    img.ImageTransparency=0.3; img.Parent=parent
    return img
end

-- Default settings per visual
local DEFAULTS = {
    color   = Color3.fromRGB(120, 80, 255),
    rainbow = false,
    neon    = true,
    size    = 1.0,
    speed   = 1.0,
    opacity = 0.7,
    count   = 6,
}
local function getSetting(key, prop)
    if Settings[key] and Settings[key][prop] ~= nil then return Settings[key][prop] end
    return DEFAULTS[prop]
end
local function getColor(key, offset)
    if getSetting(key,"rainbow") then return rainbowColor(offset or 0) end
    return getSetting(key,"color")
end

-- ════════════════════════════════════════════════════════════════════════════
-- ── VISUAL DEFINITIONS (30+) ─────────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════════════════

local Visuals = {}

-- ── 1. BODY TRAIL ────────────────────────────────────────────────────────────
Visuals["trail"] = {
    name = "body trail",
    desc = "glowing trail follows your movement",
    settings = {"color","rainbow","size","opacity"},
    start = function(key)
        local char = getChar(); if not char then return end
        local hrp = getHRP(); if not hrp then return end
        local att0 = Instance.new("Attachment"); att0.Position=Vector3.new(0,1,0); att0.Parent=hrp
        local att1 = Instance.new("Attachment"); att1.Position=Vector3.new(0,-1,0); att1.Parent=hrp
        local trail = Instance.new("Trail")
        trail.Attachment0=att0; trail.Attachment1=att1
        trail.Lifetime=0.6; trail.MinLength=0
        trail.Color=ColorSequence.new(getSetting(key,"color"))
        trail.Transparency=NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1-getSetting(key,"opacity")),
            NumberSequenceKeypoint.new(1, 1)
        })
        trail.WidthScale=NumberSequence.new(getSetting(key,"size")*1.5)
        trail.LightEmission=1; trail.FaceCamera=true
        trail.Parent=hrp
        Objects[key]={att0,att1,trail}
        if getSetting(key,"rainbow") then
            RainbowC[key]=RunService.Heartbeat:Connect(function()
                if not Enabled[key] then stopRainbow(key) return end
                trail.Color=ColorSequence.new(rainbowColor())
            end)
        end
    end,
    stop = function(key) stopRainbow(key); cleanObjects(key) end,
}

-- ── 2. JUMP CIRCLE ───────────────────────────────────────────────────────────
Visuals["jumpcircle"] = {
    name = "jump circle",
    desc = "ring expands when you jump",
    settings = {"color","rainbow","size"},
    start = function(key)
        local char = getChar(); if not char then return end
        local hum = getHum(); if not hum then return end
        Conns[key] = hum.Jumping:Connect(function(active)
            if not active then return end
            local hrp = getHRP(); if not hrp then return end
            local ring = makePart(Vector3.new(getSetting(key,"size")*4,0.1,getSetting(key,"size")*4), getColor(key), Enum.Material.Neon)
            ring.CFrame=CFrame.new(hrp.Position-Vector3.new(0,3,0))
            local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Cylinder
            mesh.Scale=Vector3.new(0.05,1,1); mesh.Parent=ring
            tween(ring, 0.5, {Size=Vector3.new(getSetting(key,"size")*12,0.05,getSetting(key,"size")*12), CFrame=CFrame.new(hrp.Position-Vector3.new(0,3,0))}, Enum.EasingStyle.Quad):Play()
            tween(ring, 0.5, {Transparency=1}):Play()
            game:GetService("Debris"):AddItem(ring, 0.6)
        end)
    end,
    stop = function(key) disconnectConn(key) end,
}

-- ── 3. LANDING SHOCKWAVE ─────────────────────────────────────────────────────
Visuals["shockwave"] = {
    name = "landing shockwave",
    desc = "shockwave explodes when you land",
    settings = {"color","rainbow","size","opacity"},
    start = function(key)
        local char = getChar(); if not char then return end
        local hum = getHum(); if not hum then return end
        local wasInAir = false
        Conns[key] = RunService.Heartbeat:Connect(function()
            if not Enabled[key] then return end
            local h = getHum(); if not h then return end
            local inAir = h:GetState()==Enum.HumanoidStateType.Freefall or h:GetState()==Enum.HumanoidStateType.Jumping
            if wasInAir and not inAir then
                local hrp=getHRP(); if not hrp then return end
                local col = getColor(key)
                for i=1,3 do
                    local ring=makePart(Vector3.new(1,0.1,1), col, Enum.Material.Neon)
                    ring.CFrame=CFrame.new(hrp.Position-Vector3.new(0,2.8,0))
                    ring.Transparency=1-getSetting(key,"opacity")
                    local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Cylinder
                    mesh.Scale=Vector3.new(0.05*i,1,1); mesh.Parent=ring
                    local sz=getSetting(key,"size")*(6+i*3)
                    local delay=i*0.06
                    coroutine.wrap(function()
                        wait(delay)
                        tween(ring, 0.5, {Size=Vector3.new(sz,0.05,sz)}, Enum.EasingStyle.Quart):Play()
                        tween(ring, 0.5, {Transparency=1}):Play()
                        game:GetService("Debris"):AddItem(ring, 0.6)
                    end)()
                end
            end
            wasInAir = inAir
        end)
    end,
    stop = function(key) disconnectConn(key) end,
}

-- ── 4. ORBIT PARTICLES ───────────────────────────────────────────────────────
Visuals["orbit"] = {
    name = "orbit particles",
    desc = "glowing orbs orbit around you",
    settings = {"color","rainbow","size","count","speed"},
    start = function(key)
        local char=getChar(); if not char then return end
        local hrp=getHRP(); if not hrp then return end
        local n=math.floor(getSetting(key,"count")); local orbs={}
        for i=1,n do
            local orb=makePart(Vector3.new(0.3,0.3,0.3)*getSetting(key,"size"), getColor(key))
            local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Sphere; mesh.Parent=orb
            local bb=makeBillboard(orb,24); makeGlow(bb, getSetting(key,"color"), 24)
            table.insert(orbs,orb)
        end
        Objects[key]=orbs
        local t0=tick()
        Conns[key]=RunService.Heartbeat:Connect(function()
            local hrp2=getHRP(); if not hrp2 then return end
            local t=tick()-t0; local spd=getSetting(key,"speed")
            for i,orb in ipairs(orbs) do
                if not orb.Parent then continue end
                local ao=(i-1)/n*math.pi*2
                local angle=t*spd*math.pi*2+ao
                local bob=math.sin(t*1.5+ao)*1.2
                local radius=3.5*getSetting(key,"size")
                orb.CFrame=CFrame.new(hrp2.Position+Vector3.new(math.cos(angle)*radius,bob,math.sin(angle)*radius))
                local sz=0.3*getSetting(key,"size")*(1+math.sin(t*3+ao)*0.15)
                orb.Size=Vector3.new(sz,sz,sz)
                if getSetting(key,"rainbow") then
                    local c=rainbowColor((i-1)/n)
                    orb.Color=c
                    local bb2=orb:FindFirstChildOfClass("BillboardGui")
                    if bb2 then local img=bb2:FindFirstChildOfClass("ImageLabel"); if img then img.ImageColor3=c end end
                end
            end
        end)
    end,
    stop = function(key) disconnectConn(key); cleanObjects(key) end,
}

-- ── 5. WINGS ─────────────────────────────────────────────────────────────────
Visuals["wings"] = {
    name = "wings",
    desc = "glowing wings on your back",
    settings = {"color","rainbow","size","opacity"},
    start = function(key)
        local char=getChar(); if not char then return end
        local hrp=getHRP(); if not hrp then return end
        local wings={}
        for side=-1,1,2 do
            for seg=1,4 do
                local w=makePart(Vector3.new(0.15,0.8+seg*0.2,1.2+seg*0.3)*getSetting(key,"size"), getColor(key))
                w.Transparency=1-getSetting(key,"opacity")
                w.Parent=workspace
                local att=Instance.new("AlignPosition"); att.Parent=w
                table.insert(wings,w)
            end
        end
        Objects[key]=wings
        local t0=tick()
        Conns[key]=RunService.Heartbeat:Connect(function()
            local hrp2=getHRP(); if not hrp2 then return end
            local t=tick()-t0; local flap=math.sin(t*3)*0.3
            local idx=0
            for side=-1,1,2 do
                for seg=1,4 do
                    idx=idx+1
                    local w=wings[idx]; if not w or not w.Parent then continue end
                    local spread=(side*(1+seg*0.7+flap*seg*0.2))*getSetting(key,"size")
                    local rise=(seg*0.5+math.sin(t*3+seg)*0.2)*getSetting(key,"size")
                    local back=(-seg*0.3)*getSetting(key,"size")
                    w.CFrame=hrp2.CFrame*CFrame.new(spread,rise,back)*CFrame.Angles(0,0,side*math.rad(30+seg*10+flap*20))
                    if getSetting(key,"rainbow") then w.Color=rainbowColor(idx/8) end
                end
            end
        end)
    end,
    stop = function(key) disconnectConn(key); cleanObjects(key) end,
}

-- ── 6. GROUND GLOW ───────────────────────────────────────────────────────────
Visuals["groundglow"] = {
    name = "ground glow",
    desc = "glowing circle beneath your feet",
    settings = {"color","rainbow","size","opacity"},
    start = function(key)
        local glow=makePart(Vector3.new(6,0.05,6)*getSetting(key,"size"), getColor(key))
        glow.Transparency=1-getSetting(key,"opacity")*0.6
        local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Cylinder
        mesh.Scale=Vector3.new(0.03,1,1); mesh.Parent=glow
        Objects[key]={glow}
        local t0=tick()
        Conns[key]=RunService.Heartbeat:Connect(function()
            local hrp=getHRP(); if not hrp then return end
            local t=tick()-t0
            local pulse=1+math.sin(t*2)*0.12
            local sz=6*getSetting(key,"size")*pulse
            glow.Size=Vector3.new(sz,0.05,sz)
            glow.CFrame=CFrame.new(hrp.Position-Vector3.new(0,3,0))
            if getSetting(key,"rainbow") then glow.Color=rainbowColor() end
        end)
    end,
    stop = function(key) disconnectConn(key); cleanObjects(key) end,
}

-- ── 7. SPEED LINES ───────────────────────────────────────────────────────────
Visuals["speedlines"] = {
    name = "speed lines",
    desc = "lines shoot past you when moving fast",
    settings = {"color","rainbow","size","speed"},
    start = function(key)
        local t0=tick(); local lastPos=nil
        Conns[key]=RunService.Heartbeat:Connect(function()
            local hrp=getHRP(); if not hrp then return end
            if lastPos then
                local vel=(hrp.Position-lastPos).Magnitude/0.016
                if vel > 15 then
                    local col=getColor(key)
                    for _=1,2 do
                        local line=makePart(Vector3.new(0.05,0.05,math.random(3,8)*getSetting(key,"size")), col)
                        local offset=Vector3.new(math.random(-4,4),math.random(-2,2),math.random(-4,4))
                        line.CFrame=CFrame.new(hrp.Position+offset, hrp.Position+offset+hrp.CFrame.LookVector*10)
                        line.Transparency=0.2
                        tween(line,0.2,{Transparency=1,CFrame=line.CFrame*CFrame.new(0,0,-5)}):Play()
                        game:GetService("Debris"):AddItem(line,0.25)
                    end
                end
            end
            lastPos=hrp.Position
        end)
    end,
    stop = function(key) disconnectConn(key) end,
}

-- ── 8. HEAD AURA ─────────────────────────────────────────────────────────────
Visuals["headaura"] = {
    name = "head aura",
    desc = "glowing aura around your head",
    settings = {"color","rainbow","size","opacity"},
    start = function(key)
        local char=getChar(); if not char then return end
        local head=char:FindFirstChild("Head"); if not head then return end
        local aura=makePart(Vector3.new(3,3,3)*getSetting(key,"size"), getColor(key))
        aura.Transparency=1-getSetting(key,"opacity")*0.5
        local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Sphere; mesh.Parent=aura
        Objects[key]={aura}
        local t0=tick()
        Conns[key]=RunService.Heartbeat:Connect(function()
            local char2=getChar(); if not char2 then return end
            local head2=char2:FindFirstChild("Head"); if not head2 then return end
            local t=tick()-t0
            local pulse=1+math.sin(t*2.5)*0.08
            local sz=3*getSetting(key,"size")*pulse
            aura.Size=Vector3.new(sz,sz,sz)
            aura.CFrame=CFrame.new(head2.Position)
            if getSetting(key,"rainbow") then aura.Color=rainbowColor() end
        end)
    end,
    stop = function(key) disconnectConn(key); cleanObjects(key) end,
}

-- ── 9. FOOTSTEP SPARKS ───────────────────────────────────────────────────────
Visuals["footsparks"] = {
    name = "footstep sparks",
    desc = "sparks pop under your feet as you walk",
    settings = {"color","rainbow","size"},
    start = function(key)
        local lastPos=nil; local stepTimer=0
        Conns[key]=RunService.Heartbeat:Connect(function(dt)
            local hrp=getHRP(); if not hrp then return end
            stepTimer=stepTimer+dt
            if lastPos and (hrp.Position-lastPos).Magnitude>1.5 and stepTimer>0.15 then
                stepTimer=0
                local col=getColor(key)
                for _=1,5 do
                    local spark=makePart(Vector3.new(0.08,0.08,0.08)*getSetting(key,"size"), col)
                    spark.CFrame=CFrame.new(hrp.Position-Vector3.new(0,3,0)+Vector3.new(math.random(-1,1)*0.5,0,math.random(-1,1)*0.5))
                    local vel=Vector3.new(math.random(-4,4),math.random(3,7),math.random(-4,4))
                    tween(spark,0.4,{CFrame=CFrame.new(spark.Position+vel), Transparency=1, Size=Vector3.new(0.01,0.01,0.01)}):Play()
                    game:GetService("Debris"):AddItem(spark,0.5)
                end
            end
            lastPos=hrp.Position
        end)
    end,
    stop = function(key) disconnectConn(key) end,
}

-- ── 10. NAME TAG GLOW ────────────────────────────────────────────────────────
Visuals["nametag"] = {
    name = "nametag glow",
    desc = "glowing custom name tag above head",
    settings = {"color","rainbow","size"},
    start = function(key)
        local char=getChar(); if not char then return end
        local head=char:FindFirstChild("Head"); if not head then return end
        local sg=Instance.new("BillboardGui")
        sg.Size=UDim2.new(0,200*getSetting(key,"size"),0,40)
        sg.StudsOffset=Vector3.new(0,3.5,0); sg.Adornee=head
        sg.AlwaysOnTop=true; sg.Parent=head
        local lbl=Instance.new("TextLabel")
        lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
        lbl.Text="✦ "..player.Name.." ✦"
        lbl.Font=Enum.Font.GothamBold; lbl.TextSize=16*getSetting(key,"size")
        lbl.TextColor3=getSetting(key,"color"); lbl.TextStrokeTransparency=0.3
        lbl.Parent=sg
        Objects[key]={sg}
        if getSetting(key,"rainbow") then
            RainbowC[key]=RunService.Heartbeat:Connect(function()
                if not Enabled[key] then stopRainbow(key) return end
                local c=rainbowColor(); lbl.TextColor3=c
            end)
        end
    end,
    stop = function(key) stopRainbow(key); cleanObjects(key) end,
}

-- ── 11. BODY OUTLINE (CHAMS) ─────────────────────────────────────────────────
Visuals["chams"] = {
    name = "body outline",
    desc = "neon outline around your entire body",
    settings = {"color","rainbow","size","opacity"},
    start = function(key)
        local char=getChar(); if not char then return end
        local parts={}
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") and part.Name~="HumanoidRootPart" then
                local clone=part:Clone()
                clone.Anchored=false; clone.CanCollide=false; clone.CastShadow=false
                clone.Material=Enum.Material.Neon
                clone.Color=getSetting(key,"color")
                clone.Transparency=1-getSetting(key,"opacity")*0.6
                clone.Size=part.Size+Vector3.new(1,1,1)*0.15*getSetting(key,"size")
                for _, v in pairs(clone:GetChildren()) do
                    if not v:IsA("SpecialMesh") then v:Destroy() end
                end
                local weld=Instance.new("WeldConstraint")
                weld.Part0=part; weld.Part1=clone; weld.Parent=clone
                clone.Parent=char; table.insert(parts,clone)
            end
        end
        Objects[key]=parts
        if getSetting(key,"rainbow") then
            RainbowC[key]=RunService.Heartbeat:Connect(function()
                if not Enabled[key] then stopRainbow(key) return end
                local c=rainbowColor()
                for _, p in pairs(parts) do if p.Parent then p.Color=c end end
            end)
        end
    end,
    stop = function(key) stopRainbow(key); cleanObjects(key) end,
}

-- ── 12. FLOATING RUNES ───────────────────────────────────────────────────────
Visuals["runes"] = {
    name = "floating runes",
    desc = "mystical rune symbols float around you",
    settings = {"color","rainbow","size","count"},
    start = function(key)
        local runeChars={"ᚠ","ᚢ","ᚦ","ᚨ","ᚱ","ᚲ","ᚷ","ᚹ","ᚺ","ᚾ","ᛁ","ᛃ","ᛇ","ᛈ","ᛉ","ᛊ","ᛏ","ᛒ","ᛖ","ᛗ","ᛚ","ᛜ","ᛞ","ᛟ"}
        local n=math.floor(getSetting(key,"count")); local runes={}
        for i=1,n do
            local part=makePart(Vector3.new(0.1,0.1,0.1), Color3.fromRGB(1,1,1))
            part.Transparency=1
            local bb=Instance.new("BillboardGui")
            bb.Size=UDim2.new(0,40*getSetting(key,"size"),0,40*getSetting(key,"size"))
            bb.AlwaysOnTop=false; bb.Adornee=part; bb.Parent=part
            local lbl=Instance.new("TextLabel")
            lbl.Size=UDim2.new(1,0,1,0); lbl.BackgroundTransparency=1
            lbl.Text=runeChars[math.random(#runeChars)]
            lbl.Font=Enum.Font.GothamBold; lbl.TextSize=28*getSetting(key,"size")
            lbl.TextColor3=getSetting(key,"color"); lbl.TextStrokeTransparency=0.2
            lbl.Parent=bb
            table.insert(runes,{part=part,lbl=lbl})
        end
        Objects[key]=#runes>0 and (function() local t={} for _,r in ipairs(runes) do table.insert(t,r.part) end return t end)() or {}
        local t0=tick()
        Conns[key]=RunService.Heartbeat:Connect(function()
            local hrp=getHRP(); if not hrp then return end
            local t=tick()-t0
            for i,r in ipairs(runes) do
                if not r.part.Parent then continue end
                local ao=(i-1)/n*math.pi*2
                local angle=t*0.5+ao
                local yBob=math.sin(t*1.2+ao)*1.5+1
                local radius=4*getSetting(key,"size")
                r.part.CFrame=CFrame.new(hrp.Position+Vector3.new(math.cos(angle)*radius,yBob,math.sin(angle)*radius))
                if getSetting(key,"rainbow") then r.lbl.TextColor3=rainbowColor((i-1)/n) end
            end
        end)
    end,
    stop = function(key) disconnectConn(key); cleanObjects(key) end,
}

-- ── 13. LIGHTNING BOLTS ──────────────────────────────────────────────────────
Visuals["lightning"] = {
    name = "lightning bolts",
    desc = "lightning crackles around you",
    settings = {"color","rainbow","size","speed"},
    start = function(key)
        local timer=0
        Conns[key]=RunService.Heartbeat:Connect(function(dt)
            local hrp=getHRP(); if not hrp then return end
            timer=timer+dt
            if timer<0.08/getSetting(key,"speed") then return end
            timer=0
            local col=getColor(key)
            local segments=math.random(4,8)
            local startPos=hrp.Position+Vector3.new(math.random(-2,2),math.random(-1,2),math.random(-2,2))
            local pos=startPos
            for _=1,segments do
                local nextPos=pos+Vector3.new(math.random(-2,2),math.random(-2,2),math.random(-2,2))*getSetting(key,"size")
                local mid=(pos+nextPos)/2
                local len=(nextPos-pos).Magnitude
                local bolt=makePart(Vector3.new(0.05,0.05,len), col)
                bolt.CFrame=CFrame.new(mid, nextPos)
                bolt.Transparency=0.1
                tween(bolt,0.1,{Transparency=1}):Play()
                game:GetService("Debris"):AddItem(bolt,0.12)
                pos=nextPos
            end
        end)
    end,
    stop = function(key) disconnectConn(key) end,
}

-- ── 14. SMOKE TRAIL ──────────────────────────────────────────────────────────
Visuals["smoke"] = {
    name = "smoke trail",
    desc = "dreamy smoke follows your movement",
    settings = {"color","rainbow","size","opacity","speed"},
    start = function(key)
        local timer=0
        Conns[key]=RunService.Heartbeat:Connect(function(dt)
            local hrp=getHRP(); if not hrp then return end
            timer=timer+dt
            if timer<0.05/getSetting(key,"speed") then return end
            timer=0
            local col=getColor(key)
            local puff=makePart(Vector3.new(1,1,1)*getSetting(key,"size")*0.8, col)
            puff.Transparency=1-getSetting(key,"opacity")*0.5
            local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Sphere; mesh.Parent=puff
            puff.CFrame=CFrame.new(hrp.Position+Vector3.new(math.random(-1,1)*0.3,math.random(-1,0),math.random(-1,1)*0.3))
            local sz=getSetting(key,"size")*(2+math.random()*2)
            tween(puff,0.8,{Size=Vector3.new(sz,sz,sz), Transparency=1, CFrame=CFrame.new(puff.Position+Vector3.new(math.random(-1,1),2,math.random(-1,1)))}):Play()
            game:GetService("Debris"):AddItem(puff,0.9)
        end)
    end,
    stop = function(key) disconnectConn(key) end,
}

-- ── 15. PETAL RAIN ───────────────────────────────────────────────────────────
Visuals["petals"] = {
    name = "petal rain",
    desc = "flower petals drift around you",
    settings = {"color","rainbow","size","count"},
    start = function(key)
        local n=math.floor(getSetting(key,"count")); local petals={}
        for i=1,n do
            local p=makePart(Vector3.new(0.2,0.05,0.3)*getSetting(key,"size"), getColor(key))
            p.Transparency=0.2; table.insert(petals,p)
        end
        Objects[key]=petals
        local offsets={}
        for i=1,n do offsets[i]={x=math.random(-5,5),y=math.random(-4,6),z=math.random(-5,5),t=math.random()*10} end
        local t0=tick()
        Conns[key]=RunService.Heartbeat:Connect(function()
            local hrp=getHRP(); if not hrp then return end
            local t=tick()-t0
            for i,p in ipairs(petals) do
                if not p.Parent then continue end
                local o=offsets[i]
                local x=o.x+math.sin(t*0.7+o.t)*1.5
                local y=o.y-((t*0.5+o.t)%8)-2
                local z=o.z+math.cos(t*0.5+o.t)*1.5
                p.CFrame=CFrame.new(hrp.Position+Vector3.new(x,y,z))*CFrame.Angles(t*0.5+o.t,t*0.3,t*0.7)
                if getSetting(key,"rainbow") then p.Color=rainbowColor(i/n) end
            end
        end)
    end,
    stop = function(key) disconnectConn(key); cleanObjects(key) end,
}

-- ── 16. STAR BURST ───────────────────────────────────────────────────────────
Visuals["starburst"] = {
    name = "star burst",
    desc = "stars explode outward periodically",
    settings = {"color","rainbow","size","speed"},
    start = function(key)
        local timer=0
        Conns[key]=RunService.Heartbeat:Connect(function(dt)
            local hrp=getHRP(); if not hrp then return end
            timer=timer+dt
            if timer<1.5/getSetting(key,"speed") then return end
            timer=0
            local col=getColor(key)
            for i=1,12 do
                local star=makePart(Vector3.new(0.12,0.12,0.5)*getSetting(key,"size"), col)
                local angle=(i-1)/12*math.pi*2
                local dir=Vector3.new(math.cos(angle),math.random(-1,1)*0.3,math.sin(angle))
                star.CFrame=CFrame.new(hrp.Position,hrp.Position+dir)
                tween(star,0.5,{CFrame=CFrame.new(hrp.Position+dir*8*getSetting(key,"size")), Transparency=1, Size=Vector3.new(0.05,0.05,0.1)}):Play()
                game:GetService("Debris"):AddItem(star,0.55)
            end
        end)
    end,
    stop = function(key) disconnectConn(key) end,
}

-- ── 17. ENERGY RINGS ─────────────────────────────────────────────────────────
Visuals["energyrings"] = {
    name = "energy rings",
    desc = "spinning energy rings surround you",
    settings = {"color","rainbow","size","count","speed"},
    start = function(key)
        local n=math.floor(math.clamp(getSetting(key,"count"),1,6)); local rings={}
        for i=1,n do
            local ring=makePart(Vector3.new(5,0.08,5)*getSetting(key,"size"), getColor(key))
            ring.Transparency=0.3
            local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Cylinder
            mesh.Scale=Vector3.new(0.04,1,1); mesh.Parent=ring
            table.insert(rings,ring)
        end
        Objects[key]=rings
        local t0=tick()
        Conns[key]=RunService.Heartbeat:Connect(function()
            local hrp=getHRP(); if not hrp then return end
            local t=tick()-t0; local spd=getSetting(key,"speed")
            for i,ring in ipairs(rings) do
                if not ring.Parent then continue end
                local tilt=(i-1)/n*math.pi
                local rot=t*spd*(1+i*0.3)
                ring.CFrame=CFrame.new(hrp.Position)*CFrame.Angles(tilt,rot,0)
                if getSetting(key,"rainbow") then ring.Color=rainbowColor((i-1)/n) end
            end
        end)
    end,
    stop = function(key) disconnectConn(key); cleanObjects(key) end,
}

-- ── 18. GHOST ECHO ───────────────────────────────────────────────────────────
Visuals["ghost"] = {
    name = "ghost echo",
    desc = "transparent ghost copies trail behind you",
    settings = {"color","rainbow","opacity","speed"},
    start = function(key)
        local timer=0
        Conns[key]=RunService.Heartbeat:Connect(function(dt)
            local char=getChar(); if not char then return end
            local hrp=getHRP(); if not hrp then return end
            timer=timer+dt
            if timer<0.12/getSetting(key,"speed") then return end
            timer=0
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name~="HumanoidRootPart" then
                    local ghost=makePart(part.Size, getSetting(key,"rainbow") and rainbowColor() or getSetting(key,"color"))
                    ghost.CFrame=part.CFrame; ghost.Transparency=1-getSetting(key,"opacity")*0.4
                    for _, v in pairs(part:GetChildren()) do
                        if v:IsA("SpecialMesh") then v:Clone().Parent=ghost end
                    end
                    tween(ghost,0.4,{Transparency=1}):Play()
                    game:GetService("Debris"):AddItem(ghost,0.45)
                end
            end
        end)
    end,
    stop = function(key) disconnectConn(key) end,
}

-- ── 19. BUBBLE FLOAT ─────────────────────────────────────────────────────────
Visuals["bubbles"] = {
    name = "bubble float",
    desc = "iridescent bubbles float up around you",
    settings = {"color","rainbow","size","count"},
    start = function(key)
        local timer=0
        Conns[key]=RunService.Heartbeat:Connect(function(dt)
            local hrp=getHRP(); if not hrp then return end
            timer=timer+dt
            if timer<0.3 then return end
            timer=0
            local n=math.floor(getSetting(key,"count")*0.5+1)
            for _=1,n do
                local sz=(0.2+math.random()*0.5)*getSetting(key,"size")
                local bubble=makePart(Vector3.new(sz,sz,sz), getColor(key))
                bubble.Transparency=0.5
                local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Sphere; mesh.Parent=bubble
                bubble.CFrame=CFrame.new(hrp.Position+Vector3.new(math.random(-3,3),0,math.random(-3,3)))
                local rise=math.random(5,12)
                tween(bubble,rise*0.3,{CFrame=CFrame.new(bubble.Position+Vector3.new(math.random(-2,2),rise,math.random(-2,2))), Transparency=1}):Play()
                game:GetService("Debris"):AddItem(bubble,rise*0.35)
            end
        end)
    end,
    stop = function(key) disconnectConn(key) end,
}

-- ── 20. FIRE CROWN ───────────────────────────────────────────────────────────
Visuals["firecrown"] = {
    name = "fire crown",
    desc = "fiery crown of flames on your head",
    settings = {"color","rainbow","size","count"},
    start = function(key)
        local char=getChar(); if not char then return end
        local head=char:FindFirstChild("Head"); if not head then return end
        local n=math.floor(getSetting(key,"count")); local flames={}
        for i=1,n do
            local flame=makePart(Vector3.new(0.2,0.2,0.2)*getSetting(key,"size"), getColor(key))
            flame.Parent=workspace; table.insert(flames,flame)
        end
        Objects[key]=flames
        local t0=tick()
        Conns[key]=RunService.Heartbeat:Connect(function()
            local char2=getChar(); if not char2 then return end
            local head2=char2:FindFirstChild("Head"); if not head2 then return end
            local t=tick()-t0
            for i,flame in ipairs(flames) do
                if not flame.Parent then continue end
                local ao=(i-1)/n*math.pi*2
                local radius=0.7*getSetting(key,"size")
                local flicker=math.sin(t*8+ao)*0.15
                local height=1+math.sin(t*5+ao)*0.3+0.8
                flame.CFrame=CFrame.new(head2.Position+Vector3.new(math.cos(ao)*radius,height+flicker,math.sin(ao)*radius))
                local sz=(0.15+math.abs(math.sin(t*6+ao))*0.15)*getSetting(key,"size")
                flame.Size=Vector3.new(sz,sz*1.5,sz)
                if getSetting(key,"rainbow") then flame.Color=rainbowColor(i/n) else
                    local ratio=math.abs(math.sin(t*3+ao))
                    local c=getSetting(key,"color")
                    flame.Color=Color3.new(math.min(c.R+0.2,1), c.G*ratio, c.B*0.2)
                end
            end
        end)
    end,
    stop = function(key) disconnectConn(key); cleanObjects(key) end,
}

-- ── 21. ICE CRYSTALS ─────────────────────────────────────────────────────────
Visuals["icecrystals"] = {
    name = "ice crystals",
    desc = "sharp ice shards orbit around you",
    settings = {"color","rainbow","size","count","speed"},
    start = function(key)
        local n=math.floor(getSetting(key,"count")); local crystals={}
        for i=1,n do
            local cry=makePart(Vector3.new(0.15,0.8,0.15)*getSetting(key,"size"), getColor(key) )
            cry.Transparency=0.2
            local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Diamond; mesh.Parent=cry
            table.insert(crystals,cry)
        end
        Objects[key]=crystals
        local t0=tick()
        Conns[key]=RunService.Heartbeat:Connect(function()
            local hrp=getHRP(); if not hrp then return end
            local t=tick()-t0; local spd=getSetting(key,"speed")
            for i,cry in ipairs(crystals) do
                if not cry.Parent then continue end
                local ao=(i-1)/n*math.pi*2
                local angle=t*spd+ao
                local bob=math.sin(t*1.5+ao)*0.5
                local radius=3*getSetting(key,"size")
                cry.CFrame=CFrame.new(hrp.Position+Vector3.new(math.cos(angle)*radius,bob,math.sin(angle)*radius))*CFrame.Angles(t*2+ao,t+ao,0)
                if getSetting(key,"rainbow") then cry.Color=rainbowColor((i-1)/n) end
            end
        end)
    end,
    stop = function(key) disconnectConn(key); cleanObjects(key) end,
}

-- ── 22. NEON GRID ────────────────────────────────────────────────────────────
Visuals["neongrid"] = {
    name = "neon grid",
    desc = "neon grid platform under your feet",
    settings = {"color","rainbow","size","opacity"},
    start = function(key)
        local sz=getSetting(key,"size")*8; local lines={}
        for i=-4,4 do
            for _, axis in ipairs({"x","z"}) do
                local line=makePart(axis=="x" and Vector3.new(sz,0.05,0.05) or Vector3.new(0.05,0.05,sz), getColor(key))
                line.Transparency=1-getSetting(key,"opacity")*0.7
                table.insert(lines,{part=line,offset=i*getSetting(key,"size"),axis=axis})
            end
        end
        Objects[key]=#lines>0 and (function() local t={} for _,l in ipairs(lines) do table.insert(t,l.part) end return t end)() or {}
        Conns[key]=RunService.Heartbeat:Connect(function()
            local hrp=getHRP(); if not hrp then return end
            local base=hrp.Position-Vector3.new(0,3,0)
            for _,l in ipairs(lines) do
                if not l.part.Parent then continue end
                if l.axis=="x" then
                    l.part.CFrame=CFrame.new(base+Vector3.new(0,0,l.offset))
                else
                    l.part.CFrame=CFrame.new(base+Vector3.new(l.offset,0,0))
                end
                if getSetting(key,"rainbow") then l.part.Color=rainbowColor(l.offset/10) end
            end
        end)
    end,
    stop = function(key) disconnectConn(key); cleanObjects(key) end,
}

-- ── 23. COMET TAIL ───────────────────────────────────────────────────────────
Visuals["comet"] = {
    name = "comet tail",
    desc = "bright comet-like streak trails you",
    settings = {"color","rainbow","size","opacity"},
    start = function(key)
        local char=getChar(); if not char then return end
        local hrp=getHRP(); if not hrp then return end
        local att=Instance.new("Attachment"); att.Parent=hrp
        local trail=Instance.new("Trail")
        trail.Attachment0=att; trail.Attachment1=att
        trail.Lifetime=1.2; trail.MinLength=0; trail.FaceCamera=true
        trail.LightEmission=1; trail.LightInfluence=0
        trail.Color=ColorSequence.new({
            ColorSequenceKeypoint.new(0, getSetting(key,"color")),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255,255,255)),
            ColorSequenceKeypoint.new(1, getSetting(key,"color")),
        })
        trail.Transparency=NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1-getSetting(key,"opacity")),
            NumberSequenceKeypoint.new(1, 1)
        })
        trail.WidthScale=NumberSequence.new({
            NumberSequenceKeypoint.new(0, getSetting(key,"size")*3),
            NumberSequenceKeypoint.new(1, 0)
        })
        trail.Parent=hrp
        Objects[key]={att,trail}
        if getSetting(key,"rainbow") then
            RainbowC[key]=RunService.Heartbeat:Connect(function()
                if not Enabled[key] then stopRainbow(key) return end
                local c=rainbowColor()
                trail.Color=ColorSequence.new({
                    ColorSequenceKeypoint.new(0, c),
                    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255,255,255)),
                    ColorSequenceKeypoint.new(1, c),
                })
            end)
        end
    end,
    stop = function(key) stopRainbow(key); cleanObjects(key) end,
}

-- ── 24. VOID RIPPLE ──────────────────────────────────────────────────────────
Visuals["voidripple"] = {
    name = "void ripple",
    desc = "dark energy ripples expand from you",
    settings = {"color","rainbow","size","speed"},
    start = function(key)
        local timer=0
        Conns[key]=RunService.Heartbeat:Connect(function(dt)
            local hrp=getHRP(); if not hrp then return end
            timer=timer+dt
            if timer<0.8/getSetting(key,"speed") then return end
            timer=0
            local col=getColor(key)
            for i=1,3 do
                local ring=makePart(Vector3.new(1,0.1,1), col)
                ring.Transparency=0.3
                local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Cylinder
                mesh.Scale=Vector3.new(0.05,1,1); mesh.Parent=ring
                ring.CFrame=CFrame.new(hrp.Position)
                local delay=i*0.15
                coroutine.wrap(function()
                    wait(delay)
                    local sz=getSetting(key,"size")*(4+i*2)
                    tween(ring,0.7,{Size=Vector3.new(sz,0.05,sz), Transparency=1}):Play()
                    game:GetService("Debris"):AddItem(ring,0.8)
                end)()
            end
        end)
    end,
    stop = function(key) disconnectConn(key) end,
}

-- ── 25. ANGEL HALO ───────────────────────────────────────────────────────────
Visuals["halo"] = {
    name = "angel halo",
    desc = "glowing halo floats above your head",
    settings = {"color","rainbow","size","opacity"},
    start = function(key)
        local halo=makePart(Vector3.new(3,0.15,3)*getSetting(key,"size"), getColor(key))
        halo.Transparency=1-getSetting(key,"opacity")
        local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Cylinder
        mesh.Scale=Vector3.new(0.06,1,1); mesh.Parent=halo
        Objects[key]={halo}
        local t0=tick()
        Conns[key]=RunService.Heartbeat:Connect(function()
            local char=getChar(); if not char then return end
            local head=char:FindFirstChild("Head"); if not head then return end
            local t=tick()-t0
            local bob=math.sin(t*1.5)*0.15
            halo.CFrame=CFrame.new(head.Position+Vector3.new(0,1.5+bob,0))*CFrame.Angles(math.rad(10),t*0.5,0)
            if getSetting(key,"rainbow") then halo.Color=rainbowColor() end
        end)
    end,
    stop = function(key) disconnectConn(key); cleanObjects(key) end,
}

-- ── 26. DRAGON AURA ──────────────────────────────────────────────────────────
Visuals["dragon"] = {
    name = "dragon aura",
    desc = "fierce dragon-like energy surrounds you",
    settings = {"color","rainbow","size","opacity","speed"},
    start = function(key)
        local segments=20; local parts={}
        for i=1,segments do
            local p=makePart(Vector3.new(0.3,0.3,0.3)*getSetting(key,"size"), getColor(key))
            p.Transparency=1-getSetting(key,"opacity")*0.7
            local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Sphere; mesh.Parent=p
            table.insert(parts,p)
        end
        Objects[key]=parts
        local t0=tick()
        Conns[key]=RunService.Heartbeat:Connect(function()
            local hrp=getHRP(); if not hrp then return end
            local t=tick()-t0; local spd=getSetting(key,"speed")
            for i,p in ipairs(parts) do
                if not p.Parent then continue end
                local phase=(i-1)/segments*math.pi*2
                local spiralAngle=t*spd*2+phase
                local spiralHeight=math.sin(t*spd+phase)*2.5
                local radius=(2+math.sin(phase)*1)*getSetting(key,"size")
                p.CFrame=CFrame.new(hrp.Position+Vector3.new(math.cos(spiralAngle)*radius,spiralHeight,math.sin(spiralAngle)*radius))
                local sz=(0.2+math.abs(math.sin(t*4+phase))*0.15)*getSetting(key,"size")
                p.Size=Vector3.new(sz,sz,sz)
                if getSetting(key,"rainbow") then p.Color=rainbowColor(phase/(math.pi*2)) end
            end
        end)
    end,
    stop = function(key) disconnectConn(key); cleanObjects(key) end,
}

-- ── 27. MUSIC BARS ───────────────────────────────────────────────────────────
Visuals["musicbars"] = {
    name = "music bars",
    desc = "equalizer bars bounce around you",
    settings = {"color","rainbow","size","count","speed"},
    start = function(key)
        local n=math.floor(getSetting(key,"count")); local bars={}
        for i=1,n do
            local bar=makePart(Vector3.new(0.3*getSetting(key,"size"),1,0.3*getSetting(key,"size")), getColor(key))
            bar.Transparency=0.2; table.insert(bars,bar)
        end
        Objects[key]=bars
        local t0=tick()
        Conns[key]=RunService.Heartbeat:Connect(function()
            local hrp=getHRP(); if not hrp then return end
            local t=tick()-t0; local spd=getSetting(key,"speed")
            for i,bar in ipairs(bars) do
                if not bar.Parent then continue end
                local ao=(i-1)/n*math.pi*2
                local radius=4*getSetting(key,"size")
                local height=1+(math.abs(math.sin(t*spd*3+ao*2)))*3*getSetting(key,"size")
                bar.Size=Vector3.new(0.3*getSetting(key,"size"),height,0.3*getSetting(key,"size"))
                bar.CFrame=CFrame.new(hrp.Position+Vector3.new(math.cos(ao)*radius,height/2-1,math.sin(ao)*radius))
                if getSetting(key,"rainbow") then bar.Color=rainbowColor((i-1)/n) end
            end
        end)
    end,
    stop = function(key) disconnectConn(key); cleanObjects(key) end,
}

-- ── 28. GLITCH EFFECT ────────────────────────────────────────────────────────
Visuals["glitch"] = {
    name = "glitch effect",
    desc = "your body glitches and fragments",
    settings = {"color","rainbow","opacity","speed"},
    start = function(key)
        local timer=0
        Conns[key]=RunService.Heartbeat:Connect(function(dt)
            local char=getChar(); if not char then return end
            timer=timer+dt
            if timer<0.15/getSetting(key,"speed") then return end
            timer=0
            if math.random()>0.4 then return end
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name~="HumanoidRootPart" and math.random()>0.5 then
                    local ghost=makePart(part.Size, getSetting(key,"rainbow") and rainbowColor() or getSetting(key,"color"))
                    ghost.CFrame=part.CFrame*CFrame.new(math.random(-1,1)*0.5,math.random(-1,1)*0.3,math.random(-1,1)*0.5)
                    ghost.Transparency=1-getSetting(key,"opacity")*0.6
                    tween(ghost,0.08,{Transparency=1}):Play()
                    game:GetService("Debris"):AddItem(ghost,0.1)
                end
            end
        end)
    end,
    stop = function(key) disconnectConn(key) end,
}

-- ── 29. CONSTELLATION ────────────────────────────────────────────────────────
Visuals["constellation"] = {
    name = "constellation",
    desc = "stars connected by lines orbit you",
    settings = {"color","rainbow","size","count"},
    start = function(key)
        local n=math.floor(getSetting(key,"count")); local stars={}; local beams={}
        for i=1,n do
            local star=makePart(Vector3.new(0.18,0.18,0.18)*getSetting(key,"size"), getColor(key))
            local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Sphere; mesh.Parent=star
            table.insert(stars,star)
        end
        for i=1,n do
            local beam=makePart(Vector3.new(0.04,0.04,1), getColor(key))
            beam.Transparency=0.5; table.insert(beams,beam)
        end
        Objects[key]=#stars>0 and (function() local t={} for _,s in ipairs(stars) do table.insert(t,s) end for _,b in ipairs(beams) do table.insert(t,b) end return t end)() or {}
        local t0=tick()
        local positions={}
        Conns[key]=RunService.Heartbeat:Connect(function()
            local hrp=getHRP(); if not hrp then return end
            local t=tick()-t0
            for i,star in ipairs(stars) do
                if not star.Parent then continue end
                local ao=(i-1)/n*math.pi*2
                local angle=t*0.4+ao
                local y=math.sin(t*0.8+ao)*2
                local r=5*getSetting(key,"size")
                local pos=hrp.Position+Vector3.new(math.cos(angle)*r,y,math.sin(angle)*r)
                star.CFrame=CFrame.new(pos)
                positions[i]=pos
                if getSetting(key,"rainbow") then star.Color=rainbowColor((i-1)/n) end
            end
            for i,beam in ipairs(beams) do
                if not beam.Parent then continue end
                local p1=positions[i]; local p2=positions[(i%n)+1]
                if not p1 or not p2 then continue end
                local mid=(p1+p2)/2; local len=(p2-p1).Magnitude
                beam.CFrame=CFrame.new(mid,p2)*CFrame.new(0,0,-len/2)
                beam.Size=Vector3.new(0.04,0.04,len)
                if getSetting(key,"rainbow") then beam.Color=rainbowColor((i-1)/n+0.1) end
            end
        end)
    end,
    stop = function(key) disconnectConn(key); cleanObjects(key) end,
}

-- ── 30. DEATH EXPLOSION ──────────────────────────────────────────────────────
Visuals["deathexplosion"] = {
    name = "death explosion",
    desc = "epic explosion when you die",
    settings = {"color","rainbow","size"},
    start = function(key)
        local char=getChar(); if not char then return end
        local hum=getHum(); if not hum then return end
        Conns[key]=hum.Died:Connect(function()
            local hrp=getHRP(); if not hrp then return end
            local col=getColor(key)
            for wave=1,5 do
                coroutine.wrap(function()
                    wait(wave*0.1)
                    local ring=makePart(Vector3.new(1,0.1,1), col)
                    ring.CFrame=CFrame.new(hrp.Position)
                    local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Cylinder
                    mesh.Scale=Vector3.new(0.05,1,1); mesh.Parent=ring
                    local sz=getSetting(key,"size")*(wave*6)
                    tween(ring,0.6,{Size=Vector3.new(sz,0.08,sz), Transparency=1}, Enum.EasingStyle.Quart):Play()
                    game:GetService("Debris"):AddItem(ring,0.7)
                end)()
            end
            for _=1,30 do
                local shard=makePart(Vector3.new(0.15,0.15,0.5)*getSetting(key,"size"), getSetting(key,"rainbow") and rainbowColor(math.random()) or col)
                shard.CFrame=CFrame.new(hrp.Position)
                local dir=Vector3.new(math.random(-10,10),math.random(2,15),math.random(-10,10)).Unit
                tween(shard,0.8,{CFrame=CFrame.new(hrp.Position+dir*8*getSetting(key,"size")), Transparency=1, Size=Vector3.new(0.02,0.02,0.02)}, Enum.EasingStyle.Quart):Play()
                game:GetService("Debris"):AddItem(shard,0.9)
            end
        end)
    end,
    stop = function(key) disconnectConn(key) end,
}

-- ── 31. SPIRAL VORTEX ────────────────────────────────────────────────────────
Visuals["spiralvortex"] = {
    name = "spiral vortex",
    desc = "particles spiral up from the ground",
    settings = {"color","rainbow","size","count","speed"},
    start = function(key)
        local n=math.floor(getSetting(key,"count")); local dots={}
        for i=1,n do
            local d=makePart(Vector3.new(0.2,0.2,0.2)*getSetting(key,"size"), getColor(key))
            local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Sphere; mesh.Parent=d
            table.insert(dots,d)
        end
        Objects[key]=dots
        local t0=tick()
        Conns[key]=RunService.Heartbeat:Connect(function()
            local hrp=getHRP(); if not hrp then return end
            local t=tick()-t0; local spd=getSetting(key,"speed")
            for i,d in ipairs(dots) do
                if not d.Parent then continue end
                local prog=((t*spd*0.3+(i-1)/n)%1)
                local angle=prog*math.pi*6+( (i-1)/n*math.pi*2)
                local height=(prog*6-3)*getSetting(key,"size")
                local radius=(1-prog)*3*getSetting(key,"size")
                d.CFrame=CFrame.new(hrp.Position+Vector3.new(math.cos(angle)*radius,height,math.sin(angle)*radius))
                d.Transparency=prog
                if getSetting(key,"rainbow") then d.Color=rainbowColor(prog+(i-1)/n) end
            end
        end)
    end,
    stop = function(key) disconnectConn(key); cleanObjects(key) end,
}

-- ── 32. METEOR SHOWER ────────────────────────────────────────────────────────
Visuals["meteors"] = {
    name = "meteor shower",
    desc = "meteors streak down around you",
    settings = {"color","rainbow","size","speed"},
    start = function(key)
        local timer=0
        Conns[key]=RunService.Heartbeat:Connect(function(dt)
            local hrp=getHRP(); if not hrp then return end
            timer=timer+dt
            if timer<0.3/getSetting(key,"speed") then return end
            timer=0
            local col=getColor(key)
            local offset=Vector3.new(math.random(-8,8),0,math.random(-8,8))
            local startP=hrp.Position+offset+Vector3.new(0,15,0)
            local endP=hrp.Position+offset-Vector3.new(0,5,0)
            local meteor=makePart(Vector3.new(0.2,0.2,2)*getSetting(key,"size"), col)
            meteor.CFrame=CFrame.new(startP, endP)
            local tail=Instance.new("Trail")
            local a1=Instance.new("Attachment"); a1.Position=Vector3.new(0,0,1); a1.Parent=meteor
            local a2=Instance.new("Attachment"); a2.Position=Vector3.new(0,0,-1); a2.Parent=meteor
            tail.Attachment0=a1; tail.Attachment1=a2; tail.Lifetime=0.3
            tail.Color=ColorSequence.new(col); tail.LightEmission=1
            tail.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})
            tail.Parent=meteor
            tween(meteor,0.5,{CFrame=CFrame.new(endP,startP)*CFrame.new(0,0,-(startP-endP).Magnitude)}, Enum.EasingStyle.Quad, Enum.EasingDirection.In):Play()
            tween(meteor,0.5,{Transparency=0.8}):Play()
            game:GetService("Debris"):AddItem(meteor,0.6)
        end)
    end,
    stop = function(key) disconnectConn(key) end,
}

-- ── 33. RAINBOW AURA ─────────────────────────────────────────────────────────
Visuals["rainbowaura"] = {
    name = "rainbow aura",
    desc = "full-body rainbow glow aura",
    settings = {"size","opacity","speed"},
    start = function(key)
        local layers=5; local auras={}
        for i=1,layers do
            local a=makePart(Vector3.new(4+i*0.5,6+i*0.5,4+i*0.5)*getSetting(key,"size"), Color3.fromRGB(255,0,0))
            a.Transparency=1-(getSetting(key,"opacity")*0.15/i)
            local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Sphere
            mesh.Scale=Vector3.new(1,1.2,1); mesh.Parent=a
            table.insert(auras,a)
        end
        Objects[key]=auras
        local t0=tick()
        Conns[key]=RunService.Heartbeat:Connect(function()
            local hrp=getHRP(); if not hrp then return end
            local t=tick()-t0; local spd=getSetting(key,"speed")
            for i,a in ipairs(auras) do
                if not a.Parent then continue end
                a.CFrame=CFrame.new(hrp.Position)
                a.Color=Color3.fromHSV(((t*spd*0.2)+(i-1)/layers)%1, 1, 1)
                local pulse=1+math.sin(t*2+(i-1))*0.04
                local sz=(4+i*0.5)*getSetting(key,"size")*pulse
                a.Size=Vector3.new(sz,sz*1.2,sz)
            end
        end)
    end,
    stop = function(key) disconnectConn(key); cleanObjects(key) end,
}

-- ── 34. PORTAL RING ──────────────────────────────────────────────────────────
Visuals["portalring"] = {
    name = "portal ring",
    desc = "swirling portal ring around your waist",
    settings = {"color","rainbow","size","opacity","speed"},
    start = function(key)
        local n=24; local segments={}
        for i=1,n do
            local seg=makePart(Vector3.new(0.2,0.2,0.4)*getSetting(key,"size"), getColor(key))
            seg.Transparency=1-getSetting(key,"opacity")
            table.insert(segments,seg)
        end
        Objects[key]=segments
        local t0=tick()
        Conns[key]=RunService.Heartbeat:Connect(function()
            local hrp=getHRP(); if not hrp then return end
            local t=tick()-t0; local spd=getSetting(key,"speed")
            for i,seg in ipairs(segments) do
                if not seg.Parent then continue end
                local ao=(i-1)/n*math.pi*2
                local angle=ao+t*spd
                local radius=2.5*getSetting(key,"size")
                local waver=math.sin(t*3+ao)*0.2
                seg.CFrame=CFrame.new(hrp.Position+Vector3.new(math.cos(angle)*radius,waver,math.sin(angle)*radius),hrp.Position+Vector3.new(math.cos(angle+0.1)*radius,waver,math.sin(angle+0.1)*radius))
                if getSetting(key,"rainbow") then seg.Color=rainbowColor((i-1)/n) end
            end
        end)
    end,
    stop = function(key) disconnectConn(key); cleanObjects(key) end,
}

-- ── 35. SPARKLE BURST ────────────────────────────────────────────────────────
Visuals["sparkleburst"] = {
    name = "sparkle burst",
    desc = "random sparkles pop all over your body",
    settings = {"color","rainbow","size","speed"},
    start = function(key)
        local timer=0
        Conns[key]=RunService.Heartbeat:Connect(function(dt)
            local hrp=getHRP(); if not hrp then return end
            timer=timer+dt
            if timer<0.05/getSetting(key,"speed") then return end
            timer=0
            for _=1,3 do
                local col=getColor(key)
                local sparkle=makePart(Vector3.new(0.1,0.1,0.1)*getSetting(key,"size"), col)
                local offset=Vector3.new(math.random(-2,2),math.random(-3,3),math.random(-2,2))
                sparkle.CFrame=CFrame.new(hrp.Position+offset)
                local mesh=Instance.new("SpecialMesh"); mesh.MeshType=Enum.MeshType.Sphere; mesh.Parent=sparkle
                local bb=makeBillboard(sparkle,16); makeGlow(bb,col,16)
                tween(sparkle,0.35,{Size=Vector3.new(0.3,0.3,0.3)*getSetting(key,"size"), Transparency=1}):Play()
                game:GetService("Debris"):AddItem(sparkle,0.4)
            end
        end)
    end,
    stop = function(key) disconnectConn(key) end,
}

-- ── Ordered list for display ──────────────────────────────────────────────────
local VisualOrder = {
    "trail","jumpcircle","shockwave","orbit","wings","groundglow",
    "speedlines","headaura","footsparks","nametag","chams","runes",
    "lightning","smoke","petals","starburst","energyrings","ghost",
    "bubbles","firecrown","icecrystals","neongrid","comet","voidripple",
    "halo","dragon","musicbars","glitch","constellation","deathexplosion",
    "spiralvortex","meteors","rainbowaura","portalring","sparkleburst",
}

-- Init default settings
for _, key in ipairs(VisualOrder) do
    Settings[key] = {
        color   = Config.Accent,
        rainbow = false,
        neon    = true,
        size    = 1.0,
        speed   = 1.0,
        opacity = 0.7,
        count   = 6,
    }
    Enabled[key] = false
end

-- ── Enable / Disable ──────────────────────────────────────────────────────────
local function enableVisual(key)
    if Enabled[key] then return end
    Enabled[key]=true
    if Visuals[key] and Visuals[key].start then
        pcall(Visuals[key].start, key)
    end
end

local function disableVisual(key)
    if not Enabled[key] then return end
    Enabled[key]=false
    if Visuals[key] and Visuals[key].stop then
        pcall(Visuals[key].stop, key)
    end
end

-- Respawn handler
player.CharacterAdded:Connect(function()
    wait(0.5)
    for _, key in ipairs(VisualOrder) do
        if Enabled[key] then
            pcall(Visuals[key].stop, key)
            wait(0.05)
            pcall(Visuals[key].start, key)
        end
    end
end)

-- ════════════════════════════════════════════════════════════════════════════
-- ── GUI ───────────────────────────────────────────────────────────────────
-- ════════════════════════════════════════════════════════════════════════════

-- ── SETTINGS PANEL ───────────────────────────────────────────────────────────
local function openSettingsPanel(key)
    if playerGui:FindFirstChild("VisualSettings_"..key) then
        playerGui["VisualSettings_"..key]:Destroy(); return
    end

    local visual = Visuals[key]
    local supportedSettings = visual.settings or {}
    local panelH = 70 + #supportedSettings * 54 + 10

    local sg = Instance.new("ScreenGui")
    sg.Name="VisualSettings_"..key; sg.ResetOnSpawn=false; sg.DisplayOrder=30; sg.Parent=playerGui

    local frame = Instance.new("Frame")
    frame.Size=UDim2.new(0,0,0,0); frame.Position=UDim2.new(0.5,0,0.5,0)
    frame.BackgroundColor3=Config.Panel; frame.BorderSizePixel=0; frame.Parent=sg
    corner(frame,14); stroke(frame,1,Config.Border)

    tween(frame,0.3,{Size=UDim2.new(0,360,0,panelH),Position=UDim2.new(0.5,-180,0.5,-panelH/2)},Enum.EasingStyle.Back):Play()

    local titleBar=Instance.new("Frame")
    titleBar.Size=UDim2.new(1,0,0,50); titleBar.BackgroundColor3=Config.Accent
    titleBar.BorderSizePixel=0; titleBar.Parent=frame; corner(titleBar,14)

    local t0=tick()
    local titleRainbow=RunService.Heartbeat:Connect(function()
        if not frame.Parent then return end
        titleBar.BackgroundColor3=rainbowColor(0)
    end)
    sg.AncestryChanged:Connect(function()
        if not sg.Parent then titleRainbow:Disconnect() end
    end)

    local titleLbl=Instance.new("TextLabel")
    titleLbl.Size=UDim2.new(1,-50,1,0); titleLbl.Position=UDim2.new(0,16,0,0)
    titleLbl.BackgroundTransparency=1; titleLbl.Text="⚙ "..visual.name
    titleLbl.TextColor3=Config.Text; titleLbl.Font=Enum.Font.GothamBold
    titleLbl.TextSize=15; titleLbl.TextXAlignment=Enum.TextXAlignment.Left; titleLbl.Parent=titleBar

    local closeX=Instance.new("TextButton")
    closeX.Size=UDim2.new(0,34,0,34); closeX.Position=UDim2.new(1,-42,0,8)
    closeX.BackgroundColor3=Color3.fromRGB(60,20,20); closeX.TextColor3=Config.Text
    closeX.Text="✕"; closeX.TextSize=16; closeX.Font=Enum.Font.GothamBold
    closeX.BorderSizePixel=0; closeX.Parent=titleBar; corner(closeX,8)
    closeX.MouseButton1Click:Connect(function() sg:Destroy() end)

    local yPos=60
    local s=Settings[key]

    local function settingRow(label, content)
        local row=Instance.new("Frame")
        row.Size=UDim2.new(1,-24,0,44); row.Position=UDim2.new(0,12,0,yPos)
        row.BackgroundColor3=Config.Card; row.BorderSizePixel=0; row.Parent=frame; corner(row,8)
        local lbl=Instance.new("TextLabel")
        lbl.Size=UDim2.new(0.5,0,1,0); lbl.BackgroundTransparency=1; lbl.Text=label
        lbl.TextColor3=Config.SubText; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=12
        lbl.TextXAlignment=Enum.TextXAlignment.Left; lbl.Position=UDim2.new(0,12,0,0)
        lbl.Parent=row; content(row); yPos=yPos+50
    end

    -- COLOR presets
    if table.find(supportedSettings,"color") then
        local colorRow=Instance.new("Frame")
        colorRow.Size=UDim2.new(1,-24,0,54); colorRow.Position=UDim2.new(0,12,0,yPos)
        colorRow.BackgroundColor3=Config.Card; colorRow.BorderSizePixel=0; colorRow.Parent=frame; corner(colorRow,8)
        local clbl=Instance.new("TextLabel")
        clbl.Size=UDim2.new(1,0,0,20); clbl.Position=UDim2.new(0,12,0,4)
        clbl.BackgroundTransparency=1; clbl.Text="color"
        clbl.TextColor3=Config.SubText; clbl.Font=Enum.Font.GothamBold
        clbl.TextSize=12; clbl.TextXAlignment=Enum.TextXAlignment.Left; clbl.Parent=colorRow

        local colorGrid=Instance.new("Frame")
        colorGrid.Size=UDim2.new(1,-12,0,28); colorGrid.Position=UDim2.new(0,6,0,24)
        colorGrid.BackgroundTransparency=1; colorGrid.Parent=colorRow
        local gl=Instance.new("UIGridLayout")
        gl.CellSize=UDim2.new(0,26,0,22); gl.CellPadding=UDim2.new(0,4,0,0)
        gl.SortOrder=Enum.SortOrder.LayoutOrder; gl.Parent=colorGrid

        local colorPresets={
            Color3.fromRGB(255,80,80), Color3.fromRGB(255,160,40),
            Color3.fromRGB(255,230,40), Color3.fromRGB(80,220,80),
            Color3.fromRGB(40,180,255), Color3.fromRGB(120,80,255),
            Color3.fromRGB(255,80,180), Color3.fromRGB(255,255,255),
            Color3.fromRGB(0,255,120), Color3.fromRGB(20,20,20),
        }
        for ci,col in ipairs(colorPresets) do
            local cb=Instance.new("TextButton")
            cb.Size=UDim2.new(0,26,0,22); cb.BackgroundColor3=col
            cb.Text=""; cb.BorderSizePixel=0; cb.LayoutOrder=ci; cb.Parent=colorGrid; corner(cb,5)
            cb.MouseButton1Click:Connect(function()
                s.color=col; s.rainbow=false
                if Enabled[key] then disableVisual(key); wait(0.05); enableVisual(key) end
            end)
        end
        -- Rainbow button
        local rbtn=Instance.new("TextButton")
        rbtn.Size=UDim2.new(0,26,0,22); rbtn.Text=""
        rbtn.BorderSizePixel=0; rbtn.LayoutOrder=11; rbtn.Parent=colorGrid; corner(rbtn,5)
        RunService.Heartbeat:Connect(function() if rbtn.Parent then rbtn.BackgroundColor3=rainbowColor() end end)
        rbtn.MouseButton1Click:Connect(function()
            s.rainbow=not s.rainbow
            if Enabled[key] then disableVisual(key); wait(0.05); enableVisual(key) end
        end)
        yPos=yPos+60
    end

    -- SIZE slider
    if table.find(supportedSettings,"size") then
        settingRow("size: "..string.format("%.1f",s.size), function(row)
            local lbl2=row:FindFirstChildOfClass("TextLabel")
            local sliderBg=Instance.new("Frame")
            sliderBg.Size=UDim2.new(0.45,0,0,6); sliderBg.Position=UDim2.new(0.52,0,0.5,-3)
            sliderBg.BackgroundColor3=Config.Border; sliderBg.BorderSizePixel=0; sliderBg.Parent=row; corner(sliderBg,3)
            local sliderFill=Instance.new("Frame")
            sliderFill.Size=UDim2.new(s.size/3,0,1,0); sliderFill.BackgroundColor3=Config.Accent
            sliderFill.BorderSizePixel=0; sliderFill.Parent=sliderBg; corner(sliderFill,3)
            local handle=Instance.new("TextButton")
            handle.Size=UDim2.new(0,14,0,14); handle.Position=UDim2.new(s.size/3,-7,0.5,-7)
            handle.BackgroundColor3=Config.Text; handle.Text=""; handle.BorderSizePixel=0
            handle.Parent=sliderBg; corner(handle,7)
            local dragging=false
            handle.MouseButton1Down:Connect(function() dragging=true end)
            UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
            UserInputService.InputChanged:Connect(function(i)
                if not dragging then return end
                if not sliderBg.Parent then return end
                local rel=(i.Position.X - sliderBg.AbsolutePosition.X)/sliderBg.AbsoluteSize.X
                rel=math.clamp(rel,0.05,1)
                s.size=math.floor(rel*3*10+0.5)/10
                sliderFill.Size=UDim2.new(rel,0,1,0)
                handle.Position=UDim2.new(rel,-7,0.5,-7)
                lbl2.Text="size: "..string.format("%.1f",s.size)
            end)
        end)
    end

    -- SPEED slider
    if table.find(supportedSettings,"speed") then
        settingRow("speed: "..string.format("%.1f",s.speed), function(row)
            local lbl2=row:FindFirstChildOfClass("TextLabel")
            local sliderBg=Instance.new("Frame")
            sliderBg.Size=UDim2.new(0.45,0,0,6); sliderBg.Position=UDim2.new(0.52,0,0.5,-3)
            sliderBg.BackgroundColor3=Config.Border; sliderBg.BorderSizePixel=0; sliderBg.Parent=row; corner(sliderBg,3)
            local sliderFill=Instance.new("Frame")
            sliderFill.Size=UDim2.new(s.speed/3,0,1,0); sliderFill.BackgroundColor3=Config.AccentB
            sliderFill.BorderSizePixel=0; sliderFill.Parent=sliderBg; corner(sliderFill,3)
            local handle=Instance.new("TextButton")
            handle.Size=UDim2.new(0,14,0,14); handle.Position=UDim2.new(s.speed/3,-7,0.5,-7)
            handle.BackgroundColor3=Config.Text; handle.Text=""; handle.BorderSizePixel=0
            handle.Parent=sliderBg; corner(handle,7)
            local dragging=false
            handle.MouseButton1Down:Connect(function() dragging=true end)
            UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
            UserInputService.InputChanged:Connect(function(i)
                if not dragging then return end
                if not sliderBg.Parent then return end
                local rel=(i.Position.X-sliderBg.AbsolutePosition.X)/sliderBg.AbsoluteSize.X
                rel=math.clamp(rel,0.05,1)
                s.speed=math.floor(rel*3*10+0.5)/10
                sliderFill.Size=UDim2.new(rel,0,1,0)
                handle.Position=UDim2.new(rel,-7,0.5,-7)
                lbl2.Text="speed: "..string.format("%.1f",s.speed)
                if Enabled[key] then disableVisual(key); wait(0.05); enableVisual(key) end
            end)
        end)
    end

    -- OPACITY slider
    if table.find(supportedSettings,"opacity") then
        settingRow("opacity: "..string.format("%.1f",s.opacity), function(row)
            local lbl2=row:FindFirstChildOfClass("TextLabel")
            local sliderBg=Instance.new("Frame")
            sliderBg.Size=UDim2.new(0.45,0,0,6); sliderBg.Position=UDim2.new(0.52,0,0.5,-3)
            sliderBg.BackgroundColor3=Config.Border; sliderBg.BorderSizePixel=0; sliderBg.Parent=row; corner(sliderBg,3)
            local sliderFill=Instance.new("Frame")
            sliderFill.Size=UDim2.new(s.opacity,0,1,0); sliderFill.BackgroundColor3=Color3.fromRGB(200,200,100)
            sliderFill.BorderSizePixel=0; sliderFill.Parent=sliderBg; corner(sliderFill,3)
            local handle=Instance.new("TextButton")
            handle.Size=UDim2.new(0,14,0,14); handle.Position=UDim2.new(s.opacity,-7,0.5,-7)
            handle.BackgroundColor3=Config.Text; handle.Text=""; handle.BorderSizePixel=0
            handle.Parent=sliderBg; corner(handle,7)
            local dragging=false
            handle.MouseButton1Down:Connect(function() dragging=true end)
            UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
            UserInputService.InputChanged:Connect(function(i)
                if not dragging then return end
                if not sliderBg.Parent then return end
                local rel=(i.Position.X-sliderBg.AbsolutePosition.X)/sliderBg.AbsoluteSize.X
                rel=math.clamp(rel,0,1); s.opacity=rel
                sliderFill.Size=UDim2.new(rel,0,1,0)
                handle.Position=UDim2.new(rel,-7,0.5,-7)
                lbl2.Text="opacity: "..string.format("%.1f",s.opacity)
            end)
        end)
    end

    -- COUNT slider
    if table.find(supportedSettings,"count") then
        settingRow("count: "..math.floor(s.count), function(row)
            local lbl2=row:FindFirstChildOfClass("TextLabel")
            local sliderBg=Instance.new("Frame")
            sliderBg.Size=UDim2.new(0.45,0,0,6); sliderBg.Position=UDim2.new(0.52,0,0.5,-3)
            sliderBg.BackgroundColor3=Config.Border; sliderBg.BorderSizePixel=0; sliderBg.Parent=row; corner(sliderBg,3)
            local sliderFill=Instance.new("Frame")
            sliderFill.Size=UDim2.new(s.count/20,0,1,0); sliderFill.BackgroundColor3=Color3.fromRGB(255,120,200)
            sliderFill.BorderSizePixel=0; sliderFill.Parent=sliderBg; corner(sliderFill,3)
            local handle=Instance.new("TextButton")
            handle.Size=UDim2.new(0,14,0,14); handle.Position=UDim2.new(s.count/20,-7,0.5,-7)
            handle.BackgroundColor3=Config.Text; handle.Text=""; handle.BorderSizePixel=0
            handle.Parent=sliderBg; corner(handle,7)
            local dragging=false
            handle.MouseButton1Down:Connect(function() dragging=true end)
            UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
            UserInputService.InputChanged:Connect(function(i)
                if not dragging then return end
                if not sliderBg.Parent then return end
                local rel=(i.Position.X-sliderBg.AbsolutePosition.X)/sliderBg.AbsoluteSize.X
                rel=math.clamp(rel,0.05,1); s.count=math.floor(rel*20+0.5)
                sliderFill.Size=UDim2.new(rel,0,1,0)
                handle.Position=UDim2.new(rel,-7,0.5,-7)
                lbl2.Text="count: "..s.count
                if Enabled[key] then disableVisual(key); wait(0.05); enableVisual(key) end
            end)
        end)
    end

    -- Done button
    local doneBtn=Instance.new("TextButton")
    doneBtn.Size=UDim2.new(1,-24,0,36); doneBtn.Position=UDim2.new(0,12,1,-46)
    doneBtn.BackgroundColor3=Config.Accent; doneBtn.TextColor3=Config.Text
    doneBtn.Text="apply & close"; doneBtn.Font=Enum.Font.GothamBold; doneBtn.TextSize=14
    doneBtn.BorderSizePixel=0; doneBtn.Parent=frame; corner(doneBtn,10)
    doneBtn.MouseButton1Click:Connect(function()
        if Enabled[key] then disableVisual(key); wait(0.05); enableVisual(key) end
        sg:Destroy()
    end)
end

-- ── MAIN GUI ─────────────────────────────────────────────────────────────────
local function createMainGui(fromMinimized, minSg, minBtn)
    if playerGui:FindFirstChild("VisualsMinimized") then playerGui.VisualsMinimized:Destroy() end

    local sg=Instance.new("ScreenGui")
    sg.Name="VisualsWin"; sg.ResetOnSpawn=false; sg.DisplayOrder=10; sg.Parent=playerGui

    local mainFrame=Instance.new("Frame")
    mainFrame.Name="Main"; mainFrame.Size=UDim2.new(0,480,0,620)
    mainFrame.Position=UDim2.new(0.5,-240,0.5,-310)
    mainFrame.BackgroundColor3=Config.BG; mainFrame.BackgroundTransparency=1
    mainFrame.BorderSizePixel=0; mainFrame.Active=true; mainFrame.Parent=sg
    corner(mainFrame,16); stroke(mainFrame,1,Config.Border)

    -- Open animation
    if fromMinimized and minBtn then
        local vp=minBtn.AbsolutePosition; local vs=minBtn.AbsoluteSize
        mainFrame.Size=UDim2.new(0,vs.X,0,vs.Y); mainFrame.Position=UDim2.new(0,vp.X,0,vp.Y)
        if minSg then minSg:Destroy() end
        tween(mainFrame,0.45,{Size=UDim2.new(0,480,0,620),Position=UDim2.new(0.5,-240,0.5,-310)},Enum.EasingStyle.Back):Play()
        tween(mainFrame,0.3,{BackgroundTransparency=0}):Play()
    else
        mainFrame.Position=UDim2.new(0.5,-240,0.5,-340)
        tween(mainFrame,0.4,{Position=UDim2.new(0.5,-240,0.5,-310),BackgroundTransparency=0}):Play()
    end

    -- Title bar with rainbow gradient
    local titleBar=Instance.new("Frame")
    titleBar.Size=UDim2.new(1,0,0,56); titleBar.BackgroundColor3=Config.Accent
    titleBar.BorderSizePixel=0; titleBar.Parent=mainFrame; corner(titleBar,16)
    local titleGrad=Instance.new("UIGradient")
    titleGrad.Color=ColorSequence.new(Config.Accent,Config.AccentB)
    titleGrad.Rotation=45; titleGrad.Parent=titleBar
    RunService.Heartbeat:Connect(function()
        if not titleBar.Parent then return end
        titleGrad.Color=ColorSequence.new(rainbowColor(0),rainbowColor(0.3),rainbowColor(0.6))
    end)

    local titleLbl=Instance.new("TextLabel")
    titleLbl.Size=UDim2.new(1,-100,1,0); titleLbl.Position=UDim2.new(0,18,0,0)
    titleLbl.BackgroundTransparency=1; titleLbl.Text="$visuals.win$"
    titleLbl.TextColor3=Color3.fromRGB(255,255,255); titleLbl.TextSize=22
    titleLbl.Font=Enum.Font.GothamBold; titleLbl.TextXAlignment=Enum.TextXAlignment.Left
    titleLbl.Parent=titleBar

    local subLbl=Instance.new("TextLabel")
    subLbl.Size=UDim2.new(1,-100,0,16); subLbl.Position=UDim2.new(0,18,1,-18)
    subLbl.BackgroundTransparency=1; subLbl.Text=tostring(#VisualOrder).." effects"
    subLbl.TextColor3=Color3.fromRGB(200,200,255); subLbl.TextSize=11
    subLbl.Font=Enum.Font.Gotham; subLbl.TextXAlignment=Enum.TextXAlignment.Left; subLbl.Parent=titleBar

    local closeBtn=Instance.new("TextButton")
    closeBtn.Size=UDim2.new(0,38,0,38); closeBtn.Position=UDim2.new(1,-46,0,9)
    closeBtn.BackgroundColor3=Color3.fromRGB(60,15,15); closeBtn.TextColor3=Config.Text
    closeBtn.Text="—"; closeBtn.TextSize=20; closeBtn.Font=Enum.Font.GothamBold
    closeBtn.BorderSizePixel=0; closeBtn.Parent=titleBar; corner(closeBtn,10)

    -- Search bar
    local searchBg=Instance.new("Frame")
    searchBg.Size=UDim2.new(1,-24,0,34); searchBg.Position=UDim2.new(0,12,0,64)
    searchBg.BackgroundColor3=Config.Card; searchBg.BorderSizePixel=0; searchBg.Parent=mainFrame
    corner(searchBg,10); stroke(searchBg,1,Config.Border)

    local searchBox=Instance.new("TextBox")
    searchBox.Size=UDim2.new(1,-12,1,0); searchBox.Position=UDim2.new(0,10,0,0)
    searchBox.BackgroundTransparency=1; searchBox.Text=""; searchBox.PlaceholderText="  search effects..."
    searchBox.TextColor3=Config.Text; searchBox.PlaceholderColor3=Config.SubText
    searchBox.Font=Enum.Font.Gotham; searchBox.TextSize=13
    searchBox.TextXAlignment=Enum.TextXAlignment.Left; searchBox.Parent=searchBg

    -- Enable ALL button
    local enableAllBtn=Instance.new("TextButton")
    enableAllBtn.Size=UDim2.new(0.47,0,0,28); enableAllBtn.Position=UDim2.new(0,12,0,104)
    enableAllBtn.BackgroundColor3=Color3.fromRGB(20,60,30); enableAllBtn.TextColor3=Config.On
    enableAllBtn.Text="⚡ enable all"; enableAllBtn.Font=Enum.Font.GothamBold; enableAllBtn.TextSize=12
    enableAllBtn.BorderSizePixel=0; enableAllBtn.Parent=mainFrame; corner(enableAllBtn,8); stroke(enableAllBtn,1,Config.On)
    enableAllBtn.MouseButton1Click:Connect(function()
        for _,key in ipairs(VisualOrder) do enableVisual(key) end
    end)

    local disableAllBtn=Instance.new("TextButton")
    disableAllBtn.Size=UDim2.new(0.47,0,0,28); disableAllBtn.Position=UDim2.new(0.53,-12,0,104)
    disableAllBtn.BackgroundColor3=Color3.fromRGB(60,15,15); disableAllBtn.TextColor3=Config.Off
    disableAllBtn.Text="✕ disable all"; disableAllBtn.Font=Enum.Font.GothamBold; disableAllBtn.TextSize=12
    disableAllBtn.BorderSizePixel=0; disableAllBtn.Parent=mainFrame; corner(disableAllBtn,8); stroke(disableAllBtn,1,Config.Off)
    disableAllBtn.MouseButton1Click:Connect(function()
        for _,key in ipairs(VisualOrder) do disableVisual(key) end
    end)

    -- Scrollable list
    local scroll=Instance.new("ScrollingFrame")
    scroll.Size=UDim2.new(1,-12,1,-144); scroll.Position=UDim2.new(0,6,0,140)
    scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0
    scroll.ScrollBarThickness=3; scroll.ScrollBarImageColor3=Config.Accent
    scroll.CanvasSize=UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
    scroll.Parent=mainFrame

    local listPad=Instance.new("UIPadding")
    listPad.PaddingLeft=UDim.new(0,6); listPad.PaddingRight=UDim.new(0,6)
    listPad.PaddingTop=UDim.new(0,6); listPad.PaddingBottom=UDim.new(0,6)
    listPad.Parent=scroll

    local listLayout=Instance.new("UIListLayout")
    listLayout.Padding=UDim.new(0,8); listLayout.SortOrder=Enum.SortOrder.LayoutOrder
    listLayout.Parent=scroll

    local cardRefs={}

    local function buildCard(key)
        local visual=Visuals[key]; if not visual then return end

        local card=Instance.new("Frame")
        card.Name=key; card.Size=UDim2.new(1,0,0,72)
        card.BackgroundColor3=Config.Card; card.BorderSizePixel=0; card.Parent=scroll
        corner(card,12); stroke(card,1,Config.Border)
        cardRefs[key]=card

        -- Color swatch (left accent bar)
        local swatch=Instance.new("Frame")
        swatch.Size=UDim2.new(0,4,1,-16); swatch.Position=UDim2.new(0,4,0,8)
        swatch.BackgroundColor3=Settings[key].color; swatch.BorderSizePixel=0; swatch.Parent=card; corner(swatch,3)
        RunService.Heartbeat:Connect(function()
            if not swatch.Parent then return end
            if Settings[key].rainbow then swatch.BackgroundColor3=rainbowColor() end
        end)

        -- Name label
        local nameLbl=Instance.new("TextLabel")
        nameLbl.Size=UDim2.new(0.6,0,0,24); nameLbl.Position=UDim2.new(0,16,0,10)
        nameLbl.BackgroundTransparency=1; nameLbl.Text=visual.name
        nameLbl.TextColor3=Config.Text; nameLbl.Font=Enum.Font.GothamBold
        nameLbl.TextSize=14; nameLbl.TextXAlignment=Enum.TextXAlignment.Left; nameLbl.Parent=card

        -- Desc label
        local descLbl=Instance.new("TextLabel")
        descLbl.Size=UDim2.new(0.7,0,0,20); descLbl.Position=UDim2.new(0,16,0,34)
        descLbl.BackgroundTransparency=1; descLbl.Text=visual.desc
        descLbl.TextColor3=Config.SubText; descLbl.Font=Enum.Font.Gotham
        descLbl.TextSize=11; descLbl.TextXAlignment=Enum.TextXAlignment.Left
        descLbl.TextWrapped=true; descLbl.Parent=card

        -- Settings button
        local settingsBtn=Instance.new("TextButton")
        settingsBtn.Size=UDim2.new(0,36,0,36); settingsBtn.Position=UDim2.new(1,-92,0.5,-18)
        settingsBtn.BackgroundColor3=Color3.fromRGB(25,25,40); settingsBtn.TextColor3=Config.SubText
        settingsBtn.Text="⚙"; settingsBtn.TextSize=18; settingsBtn.Font=Enum.Font.GothamBold
        settingsBtn.BorderSizePixel=0; settingsBtn.Parent=card; corner(settingsBtn,8); stroke(settingsBtn,1,Config.Border)
        settingsBtn.MouseButton1Click:Connect(function() openSettingsPanel(key) end)
        settingsBtn.MouseEnter:Connect(function() tween(settingsBtn,0.15,{BackgroundColor3=Config.Accent}):Play() end)
        settingsBtn.MouseLeave:Connect(function() tween(settingsBtn,0.15,{BackgroundColor3=Color3.fromRGB(25,25,40)}):Play() end)

        -- Toggle button
        local toggleBtn=Instance.new("TextButton")
        toggleBtn.Size=UDim2.new(0,46,0,36); toggleBtn.Position=UDim2.new(1,-50,0.5,-18)
        toggleBtn.BackgroundColor3=Color3.fromRGB(50,15,15)
        toggleBtn.TextColor3=Config.Off; toggleBtn.Text="off"
        toggleBtn.TextSize=13; toggleBtn.Font=Enum.Font.GothamBold
        toggleBtn.BorderSizePixel=0; toggleBtn.Parent=card; corner(toggleBtn,8)
        stroke(toggleBtn,1,Config.Off)

        local function refreshToggle()
            if Enabled[key] then
                toggleBtn.Text="on"; toggleBtn.TextColor3=Config.On
                tween(toggleBtn,0.2,{BackgroundColor3=Color3.fromRGB(15,50,25)}):Play()
                tween(card,0.2,{BackgroundColor3=Color3.fromRGB(15,22,20)}):Play()
                local stroke2=toggleBtn:FindFirstChildOfClass("UIStroke")
                if stroke2 then stroke2.Color=Config.On end
            else
                toggleBtn.Text="off"; toggleBtn.TextColor3=Config.Off
                tween(toggleBtn,0.2,{BackgroundColor3=Color3.fromRGB(50,15,15)}):Play()
                tween(card,0.2,{BackgroundColor3=Config.Card}):Play()
                local stroke2=toggleBtn:FindFirstChildOfClass("UIStroke")
                if stroke2 then stroke2.Color=Config.Off end
            end
        end
        refreshToggle()

        toggleBtn.MouseButton1Click:Connect(function()
            if Enabled[key] then disableVisual(key) else enableVisual(key) end
            refreshToggle()
        end)

        card.MouseEnter:Connect(function()
            if not Enabled[key] then tween(card,0.15,{BackgroundColor3=Color3.fromRGB(28,28,42)}):Play() end
        end)
        card.MouseLeave:Connect(function()
            if not Enabled[key] then tween(card,0.15,{BackgroundColor3=Config.Card}):Play() end
        end)
    end

    for _, key in ipairs(VisualOrder) do buildCard(key) end

    -- Search filter
    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local q=searchBox.Text:lower()
        for _, key in ipairs(VisualOrder) do
            local card=cardRefs[key]
            if not card then continue end
            if q=="" or Visuals[key].name:lower():find(q,1,true) then
                card.Visible=true
            else
                card.Visible=false
            end
        end
    end)

    -- Dragging
    local dragging,dragInput,dragStart,startPos=false,nil,nil,nil
    titleBar.InputBegan:Connect(function(input,gp)
        if gp then return end
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true; dragStart=input.Position; startPos=mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState==Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    titleBar.InputChanged:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then dragInput=input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input==dragInput and dragging then
            local d=input.Position-dragStart
            mainFrame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)

    -- Close
    closeBtn.MouseButton1Click:Connect(function()
        tween(mainFrame,0.3,{Size=UDim2.new(0,50,0,50),Position=UDim2.new(0,20,1,-70),BackgroundTransparency=1},Enum.EasingStyle.Back,Enum.EasingDirection.In):Play()
        coroutine.wrap(function() wait(0.32); sg:Destroy(); createMinimizedButton() end)()
    end)
end

-- ── MINIMIZED BUTTON ──────────────────────────────────────────────────────────
function createMinimizedButton()
    if playerGui:FindFirstChild("VisualsMinimized") then playerGui.VisualsMinimized:Destroy() end

    local sg=Instance.new("ScreenGui")
    sg.Name="VisualsMinimized"; sg.ResetOnSpawn=false; sg.Parent=playerGui

    local btn=Instance.new("TextButton")
    btn.Name="MinBtn"; btn.Size=UDim2.new(0,54,0,54)
    btn.Position=UDim2.new(0,20,1,-80)
    btn.TextColor3=Color3.fromRGB(255,255,255)
    btn.Text="✦"; btn.TextSize=24; btn.Font=Enum.Font.GothamBold
    btn.BorderSizePixel=0; btn.BackgroundColor3=Config.Accent; btn.Parent=sg; corner(btn,12)
    stroke(btn,1,Color3.fromRGB(255,255,255))

    RunService.Heartbeat:Connect(function()
        if not btn.Parent then return end
        btn.BackgroundColor3=rainbowColor()
    end)

    coroutine.wrap(function()
        while btn.Parent do
            tween(btn,1,{Size=UDim2.new(0,58,0,58)},Enum.EasingStyle.Sine):Play(); wait(1)
            if not btn.Parent then break end
            tween(btn,1,{Size=UDim2.new(0,54,0,54)},Enum.EasingStyle.Sine):Play(); wait(1)
        end
    end)()

    local clicked=false
    local function onClick()
        if clicked then return end; clicked=true
        tween(btn,0.1,{Size=UDim2.new(0,44,0,44)}):Play(); wait(0.1)
        createMainGui(true,sg,btn)
    end
    btn.MouseButton1Click:Connect(onClick)
    btn.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch then onClick() end end)
end

-- ── INJECTION SPLASH ─────────────────────────────────────────────────────────
local function createSplash()
    local sg=Instance.new("ScreenGui")
    sg.Name="VisualsSplash"; sg.ResetOnSpawn=false; sg.DisplayOrder=100; sg.Parent=playerGui

    local bg=Instance.new("Frame")
    bg.Size=UDim2.new(1,0,1,0); bg.BackgroundColor3=Color3.fromRGB(0,0,0)
    bg.BackgroundTransparency=0; bg.BorderSizePixel=0; bg.Parent=sg

    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,0,0,80); lbl.Position=UDim2.new(0,0,0.5,-70)
    lbl.BackgroundTransparency=1; lbl.Text="$visuals.win$"
    lbl.Font=Enum.Font.GothamBold; lbl.TextSize=56
    lbl.TextTransparency=1; lbl.TextStrokeTransparency=1; lbl.Parent=bg

    local sub=Instance.new("TextLabel")
    sub.Size=UDim2.new(1,0,0,30); sub.Position=UDim2.new(0,0,0.5,20)
    sub.BackgroundTransparency=1; sub.Text="ultimate visual effects"
    sub.Font=Enum.Font.Gotham; sub.TextSize=18
    sub.TextColor3=Color3.fromRGB(180,180,220); sub.TextTransparency=1; sub.Parent=bg

    -- Animated rainbow text color
    local titleRainbow=RunService.Heartbeat:Connect(function()
        if not lbl.Parent then return end
        lbl.TextColor3=rainbowColor()
    end)

    -- Fade in
    tween(lbl,0.8,{TextTransparency=0,TextStrokeTransparency=0.8}):Play()
    tween(sub,1,{TextTransparency=0}):Play()

    -- Particles behind title
    coroutine.wrap(function()
        for i=1,20 do
            wait(0.05)
            local spark=Instance.new("Frame")
            spark.Size=UDim2.new(0,4,0,4)
            spark.Position=UDim2.new(math.random(10,90)/100,0,math.random(20,80)/100,0)
            spark.BackgroundColor3=rainbowColor(i/20)
            spark.BorderSizePixel=0; spark.Parent=bg; corner(spark,2)
            tween(spark,1.5,{Size=UDim2.new(0,0,0,0),BackgroundTransparency=1}):Play()
        end
    end)()

    wait(1.8)
    titleRainbow:Disconnect()
    tween(lbl,0.6,{TextTransparency=1}):Play()
    tween(sub,0.6,{TextTransparency=1}):Play()
    tween(bg,0.6,{BackgroundTransparency=1}):Play()
    wait(0.7)
    sg:Destroy()
end

-- ── INIT ─────────────────────────────────────────────────────────────────────
createSplash()
wait(2.5)
createMainGui(false,nil,nil)
