ComfyCastBar = ComfyCastBar or {}
local A=ComfyCastBar

local controls={}
local currentTab=1

local function Check(parent,text,x,y,get,set)
    local c=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate")
    c:SetPoint("TOPLEFT",x,y)
    local label=c.Text or c.text or c:CreateFontString(nil,"ARTWORK","GameFontNormal")
    if not c.Text and not c.text then label:SetPoint("LEFT",c,"RIGHT",3,1); c.Text=label end
    label:SetText(text)
    c._get=get
    c:SetScript("OnClick",function(self) set(self:GetChecked() and true or false); A:ApplyAll(); A:RefreshOptions() end)
    controls[#controls+1]=c
    return c
end

local function Button(parent,text,x,y,w,fn)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetSize(w or 130,24); b:SetPoint("TOPLEFT",x,y); b:SetText(text); b:SetScript("OnClick",fn)
    return b
end

local sliderIndex=0
local function Slider(parent,label,minv,maxv,step,x,y,w,get,set)
    sliderIndex=sliderIndex+1
    local name="ComfyCastBarSlider"..sliderIndex
    local s=CreateFrame("Slider",name,parent,"OptionsSliderTemplate")
    s:SetPoint("TOPLEFT",x,y); s:SetWidth(w or 220); s:SetMinMaxValues(minv,maxv); s:SetValueStep(step); s:SetObeyStepOnDrag(true)
    _G[name.."Low"]:SetText(tostring(minv)); _G[name.."High"]:SetText(tostring(maxv)); _G[name.."Text"]:SetText(label)
    s.value=parent:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); s.value:SetPoint("LEFT",s,"RIGHT",10,0)
    s._get=get
    s:SetScript("OnValueChanged",function(self,v)
        if self._refresh then return end
        v=math.floor(v/step+0.5)*step; set(v); self.value:SetText(tostring(v)); A:ApplyAll()
    end)
    controls[#controls+1]=s
    return s
end

local function Edit(parent,label,x,y,w,get,set)
    local l=parent:CreateFontString(nil,"ARTWORK","GameFontNormal"); l:SetPoint("TOPLEFT",x,y); l:SetText(label)
    local e=CreateFrame("EditBox",nil,parent,"InputBoxTemplate"); e:SetPoint("TOPLEFT",x,y-22); e:SetSize(w or 180,28); e:SetAutoFocus(false)
    e._get=get
    e:SetScript("OnEnterPressed",function(self) set(self:GetText() or ""); self:ClearFocus(); A:ApplyAll() end)
    e:SetScript("OnEditFocusLost",function(self) set(self:GetText() or ""); A:ApplyAll() end)
    controls[#controls+1]=e
    return e
end

local function Dropdown(parent,x,y,w,items,get,set)
    local d=CreateFrame("Frame",nil,parent,"UIDropDownMenuTemplate"); d:SetPoint("TOPLEFT",x,y); UIDropDownMenu_SetWidth(d,w or 180)
    UIDropDownMenu_Initialize(d,function(_,level)
        local current=get()
        for _,it in ipairs(items()) do
            local info=UIDropDownMenu_CreateInfo(); info.text=it.text; info.value=it.value; info.checked=it.value==current
            info.func=function() set(it.value); CloseDropDownMenus(); A:RefreshOptions() end
            UIDropDownMenu_AddButton(info,level)
        end
    end)
    d._refresh=function()
        local cur=get(); local txt=tostring(cur or "")
        for _,it in ipairs(items()) do if it.value==cur then txt=it.text break end end
        UIDropDownMenu_SetText(d,txt)
    end
    controls[#controls+1]=d
    return d
end

local function SelectTab(i)
    currentTab=i
    for n,p in ipairs(A.optionsPages or {}) do p:SetShown(n==i) end
    for n,b in ipairs(A.optionsTabs or {}) do b:SetEnabled(n~=i); b:SetButtonState(n==i and "PUSHED" or "NORMAL",n==i) end
end

function A:RefreshOptions()
    if not self.optionsFrame or not self.db then return end
    for _,c in ipairs(controls) do
        if c._get then
            local v=c._get()
            local t=c:GetObjectType()
            if t=="CheckButton" then c:SetChecked(v and true or false)
            elseif t=="Slider" then c._refresh=true; c:SetValue(tonumber(v) or 0); c._refresh=false; if c.value then c.value:SetText(tostring(v)) end
            elseif t=="EditBox" and not c:HasFocus() then c:SetText(tostring(v or ""))
            elseif t=="Frame" and c._refresh then c._refresh() end
        end
    end
end

function A:ShowOptions()
    if not self.optionsFrame then self:InitializeOptions() end
    self.optionsFrame:Show(); self.optionsFrame:Raise(); self:RefreshOptions()
end

function A:InitializeOptions()
    if self.optionsFrame then return end
    local f=CreateFrame("Frame","ComfyCastBarOptions",UIParent,"BasicFrameTemplateWithInset")
    f:SetSize(900,660); f:SetPoint("CENTER",0,20); f:SetFrameStrata("HIGH"); f:SetMovable(true); f:EnableMouse(true); f:RegisterForDrag("LeftButton")
    f.TitleText:SetText("ComfyCastBar")
    f:SetScript("OnDragStart",function(self) if not A.db.ui.windowLocked then self:StartMoving() end end)
    f:SetScript("OnDragStop",function(self) self:StopMovingOrSizing() end)
    table.insert(UISpecialFrames,f:GetName())
    self.optionsFrame=f; self.optionsTabs={}; self.optionsPages={}

    local tabs={A:T("GENERAL"),A:T("UNITS"),A:T("STYLE"),A:T("PROFILES"),A:T("INFO")}
    for i,label in ipairs(tabs) do
        self.optionsTabs[i]=Button(f,label,18+(i-1)*150,-35,140,function() SelectTab(i) end)
        local p=CreateFrame("Frame",nil,f); p:SetPoint("TOPLEFT",12,-70); p:SetPoint("BOTTOMRIGHT",-12,12); self.optionsPages[i]=p
    end

    local p=self.optionsPages[1]
    Check(p,A:T("ENABLE"),20,-20,function() return A.db.enabled end,function(v) A.db.enabled=v end)
    Check(p,A:T("TEST"),20,-55,function() return A.db.testMode end,function(v) A.db.testMode=v end)
    Check(p,A:T("HIDE_BLIZZARD"),20,-90,function() return A.db.hideBlizzardPlayer end,function(v) A.db.hideBlizzardPlayer=v end)
    Check(p,A:T("LATENCY"),20,-125,function() return A.db.latency end,function(v) A.db.latency=v end)
    Button(p,A:T("UNLOCK"),20,-175,160,function() A:SetUnlocked(true); A:RefreshOptions() end)
    Button(p,A:T("LOCK"),190,-175,160,function() A:SetUnlocked(false); A:RefreshOptions() end)
    Button(p,A:T("RESET_POSITIONS"),360,-175,210,function() A:ResetPositions() end)
    Button(p,A:T("PRESET_MINIMAL"),20,-235,160,function() A:ApplyPreset("minimal") end)
    Button(p,A:T("PRESET_STANDARD"),190,-235,160,function() A:ApplyPreset("standard") end)
    Button(p,A:T("PRESET_PVP"),360,-235,160,function() A:ApplyPreset("pvp") end)

    p=self.optionsPages[2]
    local units={"player","target","focus","pet"}
    for row,unit in ipairs(units) do
        local unitKey=unit
        local y=-20-(row-1)*135
        local title=p:CreateFontString(nil,"ARTWORK","GameFontNormalLarge"); title:SetPoint("TOPLEFT",20,y); title:SetText(A:T(string.upper(unitKey)))
        Check(p,A:T("ENABLE"),20,y-30,function() return A.db.units[unitKey].enabled end,function(v) A.db.units[unitKey].enabled=v end)
        Check(p,A:T("SHOW_ICON"),200,y-30,function() return A.db.units[unitKey].showIcon end,function(v) A.db.units[unitKey].showIcon=v end)
        Check(p,A:T("SHOW_NAME"),365,y-30,function() return A.db.units[unitKey].showName end,function(v) A.db.units[unitKey].showName=v end)
        Check(p,A:T("SHOW_TIME"),530,y-30,function() return A.db.units[unitKey].showTime end,function(v) A.db.units[unitKey].showTime=v end)
        Slider(p,A:T("WIDTH"),160,500,5,35,y-80,180,function() return A.db.units[unitKey].width end,function(v) A.db.units[unitKey].width=v end)
        Slider(p,A:T("HEIGHT"),14,48,1,285,y-80,180,function() return A.db.units[unitKey].height end,function(v) A.db.units[unitKey].height=v end)
        Slider(p,A:T("FONT_SIZE"),9,24,1,535,y-80,180,function() return A.db.units[unitKey].fontSize end,function(v) A.db.units[unitKey].fontSize=v end)
    end

    p=self.optionsPages[3]
    local hint=p:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall"); hint:SetPoint("TOPLEFT",20,-20); hint:SetText(A:T("COLOR_HINT"))
    Edit(p,A:T("CAST_COLOR"),20,-60,180,function() return A.db.style.castColor end,function(v) A.db.style.castColor=v end)
    Edit(p,A:T("CHANNEL_COLOR"),230,-60,180,function() return A.db.style.channelColor end,function(v) A.db.style.channelColor=v end)
    Edit(p,A:T("UNINTERRUPTIBLE_COLOR"),440,-60,180,function() return A.db.style.uninterruptibleColor end,function(v) A.db.style.uninterruptibleColor=v end)
    Edit(p,A:T("BACKGROUND_COLOR"),20,-130,180,function() return A.db.style.backgroundColor end,function(v) A.db.style.backgroundColor=v end)

    p=self.optionsPages[4]
    local hint2=p:CreateFontString(nil,"ARTWORK","GameFontHighlight"); hint2:SetPoint("TOPLEFT",20,-20); hint2:SetWidth(700); hint2:SetJustifyH("LEFT"); hint2:SetText(A:T("PROFILES_HINT"))
    Dropdown(p,5,-75,260,function() return A:GetProfileEntries() end,function() return A:GetActiveProfileKey() end,function(v) A:SetActiveProfile(v) end)
    local edit=Edit(p,A:T("CUSTOM_PROFILE"),20,-135,220,function() return "" end,function() end)
    Button(p,A:T("CREATE"),250,-157,120,function() if A:CreateCustomProfile(edit:GetText()) then edit:SetText("") end end)
    Button(p,A:T("DELETE"),380,-157,140,function() A:DeleteActiveCustomProfile() end)
    Button(p,A:T("RESET_PROFILE"),530,-157,150,function() A:ResetActiveProfile() end)

    p=self.optionsPages[5]
    local version=p:CreateFontString(nil,"ARTWORK","GameFontNormalLarge"); version:SetPoint("TOPLEFT",20,-20); version:SetText("ComfyCastBar "..A.version.." "..A.status)
    local info=p:CreateFontString(nil,"ARTWORK","GameFontHighlight"); info:SetPoint("TOPLEFT",20,-65); info:SetWidth(760); info:SetJustifyH("LEFT")
    local cv,cb,_,ci=A:GetClientBuildInfo()
    info:SetText(
        "Build-Datum: "..A.buildDate.."\n"..
        "Autor: "..A.author.."\nDiscord: "..A.discord.."\nGitHub: "..A.github.."\n\n"..
        "Client: "..cv.." / Build "..cb.." / Interface "..tostring(ci or "?").."\n"..
        "Target: "..A.gameVersion.." / Interface "..A.interface.."\n\n"..
        A:T("INFO_COMMANDS").."\n\n"..A:T("INFO_NOTICE")
    )

    SelectTab(1); self:RefreshOptions()
end
