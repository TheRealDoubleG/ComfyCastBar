ComfyCastBar = ComfyCastBar or {}
local A = ComfyCastBar

A.version = "0.5"
A.buildDate = "04.10.2026"

local function CleanCastName(text)
    if type(text) ~= "string" then return "" end
    local normalized = text:lower():gsub("^%s+", ""):gsub("%s+$", "")
    if normalized == "" then return "" end
    if normalized == "no text" then return "" end
    if normalized:find("no text", 1, true) then return "" end
    return text
end

local originalBeginBar = A.BeginBar
function A:BeginBar(bar, channel, castGUID)
    if type(originalBeginBar) ~= "function" then return false end
    local ok = originalBeginBar(self, bar, channel, castGUID)
    if ok and bar and bar.name then
        local current = bar.name:GetText()
        bar.name:SetText(CleanCastName(current))
    end
    return ok
end
