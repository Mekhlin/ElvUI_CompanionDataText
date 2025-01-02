-- Environment
local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule("DataTexts")
local EP = E.Libs.EP
local ACH = E.Libs.ACH

local displayString = ""

local classSupport = {
    HUNTER      = true,
    MAGE        = true,
    WARLOCK     = true,
    DEATHKNIGHT = true
}

P["CompanionDataText"] = {
    hide_inactive_pet = false,
    pet_name_header = false,
}

-- Option page registration
local function ConfigTable()
    local function get(info) return E.db.CompanionDataText[info[#info]] end
    local function set(info, value) E.db.CompanionDataText[info[#info]] = value; DT:ForceUpdate_DataText("CompanionDataText") end

    E.Options.args.CompanionDataText = ACH:Group("Companion DataText")
    E.Options.args.CompanionDataText.args.description = ACH:Description("DataText that shows information about the active companion", 1)
    
    E.Options.args.CompanionDataText.args.datatext_settings = ACH:Group("DataText settings", nil, 2, nil, get, set)
    E.Options.args.CompanionDataText.args.datatext_settings.inline = true
    E.Options.args.CompanionDataText.args.datatext_settings.args.hide_inactive_pet = ACH:Toggle("Hide on inactive pet", "Hide text on DataText when no companion is summoned")
    
    E.Options.args.CompanionDataText.args.tooltip_settings = ACH:Group("Tooltip settings", nil, 3, nil, get, set)
    E.Options.args.CompanionDataText.args.tooltip_settings.inline = true
    E.Options.args.CompanionDataText.args.tooltip_settings.args.pet_name_header = ACH:Toggle("Use name as header", "Use name of companion as header on tooltip")
end

EP:RegisterPlugin(..., ConfigTable)

-- DataText
local function OnEvent(self, event, ...)
    self.text:SetFormattedText(displayString, GetDataText())
end

function GetDataText()
if not HasPetSupport() then
        return ""
    end

    if HasPetUI() then        
        if UnitHealth("pet") == 0 then
            return TextColor(GetPlayerClassCreatureType() .. " is dead", "ffff0000")
        end
    
        return string.format("Active %s", GetPlayerClassCreatureType())
    end

    if not E.db.CompanionDataText.hide_inactive_pet then
        return string.format("No active %s", GetPlayerClassCreatureType():lower())
    end
    
    return ""
end

-- Tooltip
local function OnEnter(self)
    if not HasPetSupport() then
        return
    end
    
    if not HasPetUI() and E.db.CompanionDataText.hide_inactive_pet then
        return
    end

    if not HasPetUI() and not E.db.CompanionDataText.hide_inactive_pet then
        DT:SetupTooltip(self)
        DT.tooltip:AddLine("No " .. GetPlayerClassCreatureType():lower() .. " summoned")
        DT.tooltip:Show()
        return
    end

    DT:SetupTooltip(self)

    local petName = UnitName("pet")
    local petFamily = UnitCreatureFamily("pet")
    local petHealth = UnitHealth("pet")
    local petMaxHealth = UnitHealthMax("pet")
    local petHealthPercent = (petHealth / petMaxHealth) * 100

    if not E.db.CompanionDataText.pet_name_header then
        DT.tooltip:AddLine(TextColor("Active " .. GetPlayerClassCreatureType(), "ffc0c0c0"))
        DT.tooltip:AddDoubleLine("Name", TextColor(petName or "Unknown", "ffffffff"))
    else
        DT.tooltip:AddLine(TextColor(petName, "ffc0c0c0"))
    end

    DT.tooltip:AddDoubleLine(STABLE_SORT_TYPE_LABEL, TextColor(petFamily or "Unknown", "ffffffff"))

    if select(2, UnitClass("player")) == "HUNTER" then
        DT.tooltip:AddDoubleLine("Specialization", TextColor(GetHunterPetSpec(), "ffffffff"))
    end

    DT.tooltip:AddDoubleLine("Health", TextColor(string.format("%.1f%%", petHealthPercent), petHealth == petMaxHealth and "ff00ff00" or "ffff0000"))

    DT.tooltip:Show()
end

local function OnLeave(self)
    DT.tooltip:Hide()
end

function HasPetSupport()
    local className = select(2, UnitClass("player"))
    if className and classSupport[className] then
        if className == "DEATHKNIGHT" then
            local specialization = GetSpecialization()
            if specialization then
                return select(2, GetSpecializationInfo(specialization)) == "Unholy"
            end
        end
        return classSupport[className]
    end
    return false
end

function GetPlayerClassCreatureType()
    local playerClass = {
        HUNTER      = "Pet",
        MAGE        = "Elemental",
        WARLOCK     = "Demon",
        DEATHKNIGHT = "Ghoul"
    }

    local className = select(2, UnitClass("player"))
    if className and playerClass[className] then
        return playerClass[className]
    end
    return "Companion"
end

function GetHunterPetSpec()
    local petBuffs = {
        [264656] = STABLE_PET_SPEC_CUNNING,  -- Pathfinding
        [264662] = STABLE_PET_SPEC_TENACITY, -- Endurance Training
        [264663] = STABLE_PET_SPEC_FEROCITY  -- Predator"s Thirst
    }

    for spellId, specName in pairs(petBuffs) do
        if HasBuff(spellId) then
            return specName
        end
    end
    return STABLE_PET_UNCATEGORIZED
end

function HasBuff(spellId)
    for i = 1, 40 do
        local auraData = C_UnitAuras.GetBuffDataByIndex("player", i)
        if auraData == nil then
            return false
        end
        
        if auraData.spellId == spellId then
            return true
        end
    end
    
    return false
end

function TextColor(text, hex)
    return hex ~= nil and ("|c" .. hex .. (text or "") .. "|r") or text
end

local function ValueColorUpdate(self, hex, r, g, b)
	displayString = string.format("%s%%s|r", hex)
	OnEvent(self)
end

local events = { "PLAYER_ENTERING_WORLD", "UNIT_PET" }
DT:RegisterDatatext("CompanionDataText", nil, events, OnEvent, nil, nil, OnEnter, OnLeave, "Companion", nil, ValueColorUpdate)