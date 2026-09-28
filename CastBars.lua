ComfyCastBar = ComfyCastBar or {}
local A=ComfyCastBar

A.bars=A.bars or {}

local UNITS={"player","target","focus","pet"}
local STOP={
    UNIT_SPELLCAST_STOP=true, UNIT_SPELLCAST_FAILED=true, UNIT_SPELLCAST_INTERRUPTED=true,
    UNIT_SPELLCAST_CHANNEL_STOP=true,
}

local function IsSecret(v)
    return type(issecretvalue)=="function" and issecretvalue(v)==true
end

local function PlainNumber(v)
    if IsSecret(v) or type(v)~="number" then return nil end
    return v
end

local function PlainBool(v)
    if IsSecret(v) then return nil end
    local ok,b=pcall(function() return v and true or false end)
    if not ok then return nil end
    return b
end

local function Hex(v,fallback)
    v=tostring(v or ""):gsub("#",""):gsub("%s+",""):upper()
    if not v:match("^[0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F]$") then return fallback end
    return (tonumber(v:sub(1,2),16) or 255)/255,(tonumber(v:sub(3,4),16) or 255)/255,(tonumber(v:sub(5,6),16) or 255)/255
end

local function SafeFont(fs,path,size)
    local ok,result=pcall(fs.SetFont,fs,path,size,"OUTLINE")
    if not ok or result==false then pcall(fs.SetFont,fs,STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF",size,"OUTLINE") end
end

local function Read(unit,channel)
    local fn=channel and UnitChannelInfo or UnitCastingInfo
    if type(fn)~="function" then return nil end
    local ok,info=pcall(function() return {fn(unit)} end)
    if not ok or type(info)~="table" or type(info[1])=="nil" then return nil end
    return info
end

local function DurationObject(unit,channel)
    local fn=channel and UnitChannelDuration or UnitCastingDuration
    if type(fn)~="function" then return nil end
    local ok,v=pcall(fn,unit)
    return ok and v or nil
end

local function SetTimer(bar,duration)
    if type(duration)=="nil" or type(bar.SetTimerDuration)~="function" then return false end
    local interp=Enum and Enum.StatusBarInterpolation and Enum.StatusBarInterpolation.Immediate
    local dir=Enum and Enum.StatusBarTimerDirection and Enum.StatusBarTimerDirection.ElapsedTime
    local ok=pcall(bar.SetTimerDuration,bar,duration,interp,dir)
    return ok
end

local function UpdateLatency(bar)
    bar.latency:Hide()
    if bar.unit~="player" or not A.db.latency or not bar.cast or bar.cast.channel then return end
    local s,e=PlainNumber(bar.cast.startMs),PlainNumber(bar.cast.endMs)
    if not s or not e or e<=s or type(GetNetStats)~="function" then return end
    local _,_,home=GetNetStats()
    home=tonumber(home) or 0
    local frac=math.max(0,math.min(1,home/(e-s)))
    local usable=bar.cfg.width-(bar.cfg.showIcon and bar.cfg.height or 0)
    bar.latency:ClearAllPoints()
    bar.latency:SetPoint("TOPRIGHT",bar.status,"TOPRIGHT")
    bar.latency:SetPoint("BOTTOMRIGHT",bar.status,"BOTTOMRIGHT")
    bar.latency:SetWidth(math.max(1,usable*frac))
    local r,g,b=Hex(A.db.style.latencyColor,0.9,0.25,0.25)
    bar.latency:SetColorTexture(r,g,b,0.45)
    bar.latency:Show()
end

function A:StopBar(bar)
    bar.cast=nil
    bar.timing=nil
    bar.latency:Hide()
    if self.db.testMode then return end
    bar:Hide()
end

function A:BeginBar(bar,channel,castGUID)
    local info=Read(bar.unit,channel)
    if not info then return false end

    local notInterruptible=channel and PlainBool(info[7]) or PlainBool(info[8])
    local duration=DurationObject(bar.unit,channel)
    bar.cast={
        channel=channel and true or false,
        startMs=info[4], endMs=info[5], guid=castGUID, duration=duration,
        notInterruptible=notInterruptible,
    }

    pcall(bar.status.SetMinMaxValues,bar.status,info[4],info[5])
    if bar.status.SetReverseFill then pcall(bar.status.SetReverseFill,bar.status,channel and true or false) end
    local now=(GetTime and GetTime()*1000) or 0
    pcall(bar.status.SetValue,bar.status,now)
    bar.timing=SetTimer(bar.status,duration) and true or nil

    bar.name:SetText(info[1])
    bar.icon:SetTexture(info[3])
    bar:Show()
    self:StyleBar(bar)
    UpdateLatency(bar)
    return true
end

function A:RefreshBar(bar)
    if self.db.testMode then self:ShowPreview(bar) return end
    if not self.db.enabled or not bar.cfg.enabled then self:StopBar(bar) return end
    if not self:BeginBar(bar,false) and not self:BeginBar(bar,true) then self:StopBar(bar) end
end

function A:HandleBarEvent(bar,event,unit,castGUID)
    if self.db.testMode then return end
    if unit and unit~=bar.unit then return end
    if event=="UNIT_SPELLCAST_START" or event=="UNIT_SPELLCAST_DELAYED" then
        if not self:BeginBar(bar,false,castGUID) then self:StopBar(bar) end
    elseif event=="UNIT_SPELLCAST_CHANNEL_START" or event=="UNIT_SPELLCAST_CHANNEL_UPDATE" then
        if not self:BeginBar(bar,true,castGUID) then self:StopBar(bar) end
    elseif STOP[event] then
        self:RefreshBar(bar)
    end
end

function A:OnBarUpdate(bar)
    local cast=bar.cast
    if not cast or self.db.testMode then return end
    local now=(GetTime and GetTime()*1000) or 0
    if not bar.timing then pcall(bar.status.SetValue,bar.status,now) end
    local e=PlainNumber(cast.endMs)
    if bar.cfg.showTime then
        if e then
            bar.time:SetFormattedText("%.1f",math.max(0,(e-now)/1000))
        elseif type(cast.duration)~="nil" and pcall(function() bar.time:SetFormattedText("%.1f",cast.duration:GetRemainingDuration()) end) then
        else
            bar.time:SetText("")
        end
    else
        bar.time:SetText("")
    end
    if e and now>=e then self:RefreshBar(bar) end
end

function A:StyleBar(bar)
    if not bar or not self.db then return end
    local cfg=self.db.units[bar.unit]
    bar.cfg=cfg
    bar:SetSize(cfg.width,cfg.height)
    bar:ClearAllPoints()
    bar:SetPoint("CENTER",UIParent,"CENTER",cfg.x,cfg.y)

    local iconWidth=cfg.showIcon and cfg.height or 0
    bar.icon:SetShown(cfg.showIcon)
    bar.icon:ClearAllPoints()
    bar.icon:SetPoint("TOPLEFT",bar,"TOPLEFT")
    bar.icon:SetSize(cfg.height,cfg.height)

    bar.status:ClearAllPoints()
    bar.status:SetPoint("TOPLEFT",bar,"TOPLEFT",iconWidth,0)
    bar.status:SetPoint("BOTTOMRIGHT",bar,"BOTTOMRIGHT")
    bar.status:SetStatusBarTexture(self.db.style.texture or "Interface\\TargetingFrame\\UI-StatusBar")

    local br,bg,bb=Hex(self.db.style.backgroundColor,0.08,0.08,0.08)
    bar.background:SetColorTexture(br,bg,bb,0.88)

    local key="castColor"
    if bar.cast and bar.cast.channel then key="channelColor"
    elseif bar.cast and bar.cast.notInterruptible==true then key="uninterruptibleColor" end
    local r,g,b=Hex(self.db.style[key],1,0.7,0)
    bar.status:SetStatusBarColor(r,g,b,1)

    bar.name:SetShown(cfg.showName)
    bar.time:SetShown(cfg.showTime)
    SafeFont(bar.name,self.db.style.font or STANDARD_TEXT_FONT,cfg.fontSize)
    SafeFont(bar.time,self.db.style.font or STANDARD_TEXT_FONT,cfg.fontSize)
    bar.name:ClearAllPoints(); bar.name:SetPoint("LEFT",bar.status,"LEFT",6,0); bar.name:SetPoint("RIGHT",bar.time,"LEFT",-6,0)
    bar.name:SetJustifyH("LEFT"); bar.name:SetWordWrap(false)
    bar.time:ClearAllPoints(); bar.time:SetPoint("RIGHT",bar.status,"RIGHT",-6,0)

    bar.mover:SetAllPoints(bar)
    bar.mover.label:SetText(self:T(string.upper(bar.unit)))
    bar.mover:SetShown(self.db.unlocked and not InCombatLockdown())
    bar.mover:EnableMouse(self.db.unlocked and not InCombatLockdown())
end

function A:ShowPreview(bar)
    if not bar.cfg.enabled then bar:Hide(); return end
    bar.cast={channel=bar.unit=="focus",notInterruptible=bar.unit=="target",startMs=0,endMs=1}
    bar.status:SetMinMaxValues(0,1); bar.status:SetValue(0.62)
    bar.name:SetText(self:T("TEST_SPELL"))
    bar.time:SetText(bar.cfg.showTime and "1.5" or "")
    bar.icon:SetTexture("Interface\\Icons\\Spell_Nature_TimeStop")
    bar:Show()
    self:StyleBar(bar)
end

function A:CreateBar(unit)
    local bar=CreateFrame("Frame","ComfyCastBar_"..unit,UIParent,"BackdropTemplate")
    bar.unit=unit
    bar.cfg=self.db.units[unit]
    bar:SetClampedToScreen(true)\n    bar:SetMovable(true)

    bar.background=bar:CreateTexture(nil,"BACKGROUND")
    bar.background:SetAllPoints(bar)

    bar.status=CreateFrame("StatusBar",nil,bar)
    bar.icon=bar:CreateTexture(nil,"ARTWORK")
    bar.latency=bar.status:CreateTexture(nil,"OVERLAY")
    bar.latency:Hide()
    bar.name=bar.status:CreateFontString(nil,"OVERLAY")
    bar.time=bar.status:CreateFontString(nil,"OVERLAY")

    local mover=CreateFrame("Frame",nil,bar)
    mover:SetFrameStrata("DIALOG")
    mover:SetMovable(true); mover:RegisterForDrag("LeftButton")
    mover.overlay=mover:CreateTexture(nil,"OVERLAY"); mover.overlay:SetAllPoints(); mover.overlay:SetColorTexture(0.3,0.76,0.97,0.35)
    mover.label=mover:CreateFontString(nil,"OVERLAY","GameFontNormal"); mover.label:SetPoint("CENTER")
    mover:SetScript("OnDragStart",function(self)
        if InCombatLockdown() then A:Print(A:T("LOCKED_COMBAT")); return end
        if not A.db.unlocked then return end
        bar:StartMoving()
    end)
    mover:SetScript("OnDragStop",function()
        bar:StopMovingOrSizing()
        local x,y=bar:GetCenter(); local ux,uy=UIParent:GetCenter()
        if x and y and ux and uy then
            bar.cfg.x=math.floor((x-ux)+0.5); bar.cfg.y=math.floor((y-uy)+0.5)
        end
    end)
    bar.mover=mover

    for _,ev in ipairs({
        "UNIT_SPELLCAST_START","UNIT_SPELLCAST_STOP","UNIT_SPELLCAST_FAILED","UNIT_SPELLCAST_INTERRUPTED",
        "UNIT_SPELLCAST_DELAYED","UNIT_SPELLCAST_CHANNEL_START","UNIT_SPELLCAST_CHANNEL_UPDATE","UNIT_SPELLCAST_CHANNEL_STOP"
    }) do
        if bar.RegisterUnitEvent then pcall(bar.RegisterUnitEvent,bar,ev,unit) else pcall(bar.RegisterEvent,bar,ev) end
    end
    bar:SetScript("OnEvent",function(_,event,u,castGUID) A:HandleBarEvent(bar,event,u,castGUID) end)
    bar:SetScript("OnUpdate",function() A:OnBarUpdate(bar) end)
    bar:Hide()

    self.bars[unit]=bar
    self:StyleBar(bar)
    return bar
end

function A:SetUnlocked(enabled)
    if InCombatLockdown() then self:Print(self:T("LOCKED_COMBAT")); return false end
    self.db.unlocked=enabled and true or false
    for _,bar in pairs(self.bars) do self:StyleBar(bar) end
    return true
end

function A:ResetPositions()
    local defaults=self.defaults.units
    for unit,cfg in pairs(self.db.units) do
        cfg.x=defaults[unit].x; cfg.y=defaults[unit].y
    end
    self:ApplyAll()
end

function A:RegisterWithComfyHub()
    local hub=_G.ComfyHub
    if not hub or type(hub.RegisterLayoutTarget)~="function" then return end
    for unit,bar in pairs(self.bars) do
        hub:RegisterLayoutTarget("ComfyCastBar",unit,bar,{
            setEditMode=function(on) A:SetUnlocked(on) end,
        })
    end
end

function A:ApplyBlizzardPlayerBar()
    local frame=_G.PlayerCastingBarFrame or _G.CastingBarFrame
    if not frame then return end
    if self.db.hideBlizzardPlayer then
        pcall(frame.SetAlpha,frame,0)
    else
        pcall(frame.SetAlpha,frame,1)
    end
end

function A:ApplyAll()
    if not self.db then return end
    for unit,bar in pairs(self.bars) do
        bar.cfg=self.db.units[unit]
        if self.db.testMode then self:ShowPreview(bar) else self:RefreshBar(bar) end
        self:StyleBar(bar)
        if not self.db.enabled or not bar.cfg.enabled then bar:Hide() end
    end
    self:ApplyBlizzardPlayerBar()
end

function A:InitializeCastBars()
    for _,unit in ipairs(UNITS) do if not self.bars[unit] then self:CreateBar(unit) end end

    local f=CreateFrame("Frame")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:RegisterEvent("PLAYER_TARGET_CHANGED")
    f:RegisterEvent("PLAYER_FOCUS_CHANGED")
    f:RegisterEvent("UNIT_PET")
    f:RegisterEvent("PLAYER_REGEN_DISABLED")
    f:RegisterEvent("ADDON_LOADED")
    f:SetScript("OnEvent",function(_,event,arg1)
        if event=="PLAYER_REGEN_DISABLED" and A.db.unlocked then
            A:SetUnlocked(false)
        elseif event=="ADDON_LOADED" and arg1=="ComfyHub" then
            A:RegisterWithComfyHub()
        else
            A:ApplyAll()
        end
    end)

    self:RegisterWithComfyHub()
    self:ApplyAll()
end
