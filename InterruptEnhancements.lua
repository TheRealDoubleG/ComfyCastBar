ComfyCastBar = ComfyCastBar or {}
local A = ComfyCastBar

A.version = "0.5"
A.buildDate = "04.10.2026"

local function EnsureDefaults()
    if not A.db then return end
    A.db.interrupt = A.db.interrupt or {}
    local c=A.db.interrupt
    if c.showLock==nil then c.showLock=true end
    if c.showText==nil then c.showText=false end
    if c.player==nil then c.player=false end
    if c.target==nil then c.target=true end
    if c.focus==nil then c.focus=true end
    if c.pet==nil then c.pet=false end
end

local originalInitializeDB=A.InitializeDB
function A:InitializeDB(...)
    local r
    if originalInitializeDB then r=originalInitializeDB(self,...) end
    EnsureDefaults(); return r
end

local function EnabledForUnit(unit)
    EnsureDefaults(); return A.db and A.db.interrupt and A.db.interrupt[unit] == true
end

local function EnsureExtras(bar)
    if bar.interruptLock then return end
    bar.interruptLock=bar.status:CreateFontString(nil,"OVERLAY","GameFontNormal")
    bar.interruptLock:SetPoint("RIGHT",bar.status,"RIGHT",-4,0)
    bar.interruptLock:SetText("🔒")
    bar.interruptText=bar.status:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    bar.interruptText:SetPoint("BOTTOM",bar.status,"TOP",0,2)
    bar.interruptLock:Hide(); bar.interruptText:Hide()
end

function A:UpdateInterruptVisual(bar)
    if not bar or not self.db then return end
    EnsureDefaults(); EnsureExtras(bar)
    local active=EnabledForUnit(bar.unit) and bar.cast and not bar.preview
    if not active or bar.cast.notInterruptible==nil then
        bar.interruptLock:Hide(); bar.interruptText:Hide(); return
    end
    if bar.cast.notInterruptible==true then
        bar.interruptLock:SetShown(self.db.interrupt.showLock==true)
        if self.db.interrupt.showText then bar.interruptText:SetText("Nicht unterbrechbar"); bar.interruptText:SetTextColor(1,.35,.25); bar.interruptText:Show() else bar.interruptText:Hide() end
    else
        bar.interruptLock:Hide()
        if self.db.interrupt.showText then bar.interruptText:SetText("Unterbrechbar"); bar.interruptText:SetTextColor(.35,1,.35); bar.interruptText:Show() else bar.interruptText:Hide() end
    end
end

local originalStyleBar=A.StyleBar
function A:StyleBar(bar)
    if originalStyleBar then originalStyleBar(self,bar) end
    self:UpdateInterruptVisual(bar)
    if bar and bar.time and bar.name and bar.interruptLock then
        -- Keep name/time readable when a lock icon is present.
        bar.name:ClearAllPoints(); bar.name:SetPoint("LEFT",bar.status,"LEFT",6,0)
        if bar.cast and bar.cast.notInterruptible==true and self.db.interrupt.showLock and EnabledForUnit(bar.unit) then
            bar.name:SetPoint("RIGHT",bar.interruptLock,"LEFT",-4,0)
        else
            bar.name:SetPoint("RIGHT",bar.time,"LEFT",-6,0)
        end
    end
end

local originalStopBar=A.StopBar
function A:StopBar(bar)
    if originalStopBar then originalStopBar(self,bar) end
    if bar and bar.interruptLock then bar.interruptLock:Hide() end
    if bar and bar.interruptText then bar.interruptText:Hide() end
end

local function SelectTab(index)
    for i,p in ipairs(A.optionsPages or {}) do p:SetShown(i==index) end
    for i,b in ipairs(A.optionsTabs or {}) do b:SetEnabled(true); b:SetButtonState(i==index and "PUSHED" or "NORMAL",false) end
end
local function Check(parent,text,x,y,get,set)
    local c=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate"); c:SetPoint("TOPLEFT",x,y); local t=c.Text or c.text; if t then t:SetText(text) end; c:SetChecked(get() and true or false)
    c:SetScript("OnClick",function(self) set(self:GetChecked() and true or false); A:ApplyAll() end); return c
end

local originalInitializeOptions=A.InitializeOptions
function A:InitializeOptions(...)
    if originalInitializeOptions then originalInitializeOptions(self,...) end
    if self.__interruptOptionsBuilt or not self.optionsFrame then return end
    self.__interruptOptionsBuilt=true; EnsureDefaults()
    for i,b in ipairs(self.optionsTabs or {}) do local index=i; b:SetScript("OnClick",function() SelectTab(index) end) end
    SelectTab(1)
    local p=self.optionsPages and self.optionsPages[1]; if not p then return end
    local c=self.db.interrupt
    local title=p:CreateFontString(nil,"ARTWORK","GameFontNormalLarge"); title:SetPoint("TOPLEFT",610,-20); title:SetText("Unterbrechbarkeit")
    Check(p,"Schloss anzeigen",610,-55,function() return c.showLock end,function(v) c.showLock=v end)
    Check(p,"Text anzeigen",610,-88,function() return c.showText end,function(v) c.showText=v end)
    Check(p,"Ziel",610,-125,function() return c.target end,function(v) c.target=v end)
    Check(p,"Fokus",710,-125,function() return c.focus end,function(v) c.focus=v end)
    Check(p,"Spieler",610,-158,function() return c.player end,function(v) c.player=v end)
    Check(p,"Begleiter",710,-158,function() return c.pet end,function(v) c.pet=v end)
end
