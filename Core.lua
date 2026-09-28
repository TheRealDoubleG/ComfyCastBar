local ADDON_NAME=...

ComfyCastBar = ComfyCastBar or {}
local A=ComfyCastBar

A.name=ADDON_NAME or "ComfyCastBar"
A.version="0.4"
A.buildDate="28.09.2026"
A.status="Beta"
A.gameVersion="WoW Forever 1.60.1"
A.targetBuild="70009"
A.interface=16001
A.author="TheRealDoubleG"
A.discord="the.real.double.g"
A.github="https://github.com/TheRealDoubleG/ComfyCastBar"

local defaults={
    enabled=true,
    testMode=false,
    unlocked=false,
    hideBlizzardPlayer=false,
    latency=true,
    style={
        font="Fonts\\FRIZQT__.TTF",
        texture="Interface\\TargetingFrame\\UI-StatusBar",
        castColor="FFB300",
        channelColor="4FD36B",
        uninterruptibleColor="D85CFF",
        backgroundColor="1A1A1A",
        latencyColor="E34A4A",
    },
    units={
        player={enabled=true,width=300,height=26,x=0,y=-215,fontSize=13,showIcon=true,showName=true,showTime=true},
        target={enabled=true,width=300,height=24,x=0,y=-175,fontSize=13,showIcon=true,showName=true,showTime=true},
        focus={enabled=true,width=260,height=22,x=335,y=-175,fontSize=12,showIcon=true,showName=true,showTime=true},
        pet={enabled=false,width=220,height=20,x=0,y=-250,fontSize=11,showIcon=true,showName=true,showTime=true},
    },
    optionsWindow={point="CENTER",relativePoint="CENTER",x=0,y=20},
    ui={windowLocked=false,windowOpacity=100,showWindowBorder=true,backgroundAlpha=92},
}

A.defaults=defaults

local function Copy(src)
    if type(src)~="table" then return src end
    local out={}; for k,v in pairs(src) do out[k]=Copy(v) end; return out
end

function A:Print(msg)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffffd200ComfyCastBar:|r "..tostring(msg)) end
end

function A:GetClientBuildInfo()
    if not GetBuildInfo then return "?","?","?",nil end
    local v,b,d,i=GetBuildInfo()
    return tostring(v or "?"),tostring(b or "?"),tostring(d or "?"),tonumber(i)
end

function A:GetCompatibilityStatus()
    local _,_,_,i=self:GetClientBuildInfo()
    return tonumber(i)==tonumber(self.interface)
end

function A:InitializeDB()
    if self.InitializeProfileStorage then
        self:InitializeProfileStorage(defaults,"ComfyCastBarDB")
    else
        ComfyCastBarDB=type(ComfyCastBarDB)=="table" and ComfyCastBarDB or Copy(defaults)
        self.db=ComfyCastBarDB
    end
end

function A:ApplyPreset(key)
    if not self.db then return end
    local u=self.db.units
    if key=="minimal" then
        u.player.width=250;u.player.height=20;u.player.showIcon=false;u.player.showName=true;u.player.showTime=true
        u.target.width=250;u.target.height=20;u.focus.enabled=false;u.pet.enabled=false
        self.db.latency=false
    elseif key=="pvp" then
        u.player.width=320;u.player.height=28;u.target.width=330;u.target.height=28
        u.focus.enabled=true;u.focus.width=280;u.focus.height=24;u.pet.enabled=true
        self.db.latency=true
    else
        for k,v in pairs(defaults.units) do
            for kk,vv in pairs(v) do u[k][kk]=vv end
        end
        self.db.latency=true
    end
    self:ApplyAll()
    if self.RefreshOptions then self:RefreshOptions() end
end

SLASH_COMFYCASTBAR1="/comfycastbar"
SLASH_COMFYCASTBAR2="/ccb"
SlashCmdList.COMFYCASTBAR=function(msg)
    msg=tostring(msg or ""):lower():match("^%s*(.-)%s*$")
    if msg=="test" then
        A.db.testMode=not A.db.testMode
        A:ApplyAll()
    elseif msg=="unlock" then
        A:SetUnlocked(true)
    elseif msg=="lock" then
        A:SetUnlocked(false)
    elseif msg=="reset" then
        A:ResetPositions()
    else
        if A.ShowOptions then A:ShowOptions() end
    end
end

local f=CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent",function(_,event,arg1)
    if event=="ADDON_LOADED" and arg1==A.name then
        A:InitializeDB()
        if A.InitializeCastBars then A:InitializeCastBars() end
        if A.InitializeOptions then A:InitializeOptions() end
        A:Print(A:T("LOADED").." v"..A.version)
    elseif event=="PLAYER_LOGIN" then
        if A.ApplyAll then A:ApplyAll() end
    end
end)
