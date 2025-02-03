-- Environment
local E, L, V, P, G = unpack(ElvUI)
local DT = E:GetModule("DataTexts")
local EP = E.Libs.EP
local ACH = E.Libs.ACH

local displayString = ""

P["CompanionDataText"]  = {
    hide_inactive_pet   = false,
    pet_name_header     = false,
    battle_pet_tooltip  = false,
    battle_pet_extended = false
}

local function ConfigTable()
    local function get(info) return E.db.CompanionDataText[info[#info]] end
    local function set(info, value) E.db.CompanionDataText[info[#info]] = value; DT:ForceUpdate_DataText("CompanionDataText") end

    E.Options.args.CompanionDataText = ACH:Group("|cffA67B5BCompanion DataText|r")
    E.Options.args.CompanionDataText.args.datatext_settings = ACH:Group("DataText", nil, 1, nil, get, set)
    E.Options.args.CompanionDataText.args.datatext_settings.inline = true
    E.Options.args.CompanionDataText.args.datatext_settings.args.hide_inactive_pet = ACH:Toggle("Hide on inactive pet", "Hide text on DataText when no companion is summoned")

    E.Options.args.CompanionDataText.args.tooltip_settings = ACH:Group("Tooltip settings", nil, 2, nil, get, set)
    E.Options.args.CompanionDataText.args.tooltip_settings.inline = true
    E.Options.args.CompanionDataText.args.tooltip_settings.args.pet_name_header = ACH:Toggle("Use name as header", "Use name of companion as header on tooltip", 1)
    E.Options.args.CompanionDataText.args.tooltip_settings.args.battle_pet_tooltip = ACH:Toggle(TOOLTIP_BATTLE_PET, "Show information about summoned Battle Pet", 2)  
    
    E.Options.args.CompanionDataText.args.battle_pet = ACH:Group("Battle Pet", nil, 3, nil, get, set)
    E.Options.args.CompanionDataText.args.battle_pet.inline = true    
    E.Options.args.CompanionDataText.args.battle_pet.disabled = function() return not E.db.CompanionDataText.battle_pet_tooltip end
    E.Options.args.CompanionDataText.args.battle_pet.args.battle_pet_extended = ACH:Toggle("Extended tooltip", "Show level and quality on Battle Pet tooltip", 1)
    
    E.Options.args.CompanionDataText.args.description = ACH:Description("\nhttps://github.com/Mekhlin/ElvUI_CompanionDataText", -1)
end

EP:RegisterPlugin(..., ConfigTable)

-- DataText
local function OnEvent(self, event, ...)
    self.text:SetFormattedText(displayString, GetDataText())
end

function GetDataText()

    if HasCombatPetSupport() then
        if UnitExists("pet") then
            if IsPetDead() then
                return TextColor(GetPlayerClassCreatureType() .. " is dead", "ffff0000")
            end

            return string.format("Active %s", GetPlayerClassCreatureType())
        end
        
        if not E.db.CompanionDataText.hide_inactive_pet then
            return string.format("No active %s", GetPlayerClassCreatureType():lower())
        end
    end

    if E.db.CompanionDataText.battle_pet_tooltip and C_PetJournal.GetSummonedPetGUID() then
        return TOOLTIP_BATTLE_PET
    end    

    return ""
end

-- Tooltip
local function OnEnter(self)
    local hasCombatPet = UnitExists("pet") and HasCombatPetSupport()
    local hasBattlePet = C_PetJournal.GetSummonedPetGUID() ~= nil


    if not hasCombatPet and not hasBattlePet then
        return
    end

    DT:SetupTooltip(self)

    if hasCombatPet then
        SetupCombatPetTooltip()
    end

    if hasBattlePet and E.db.CompanionDataText.battle_pet_tooltip then
        SetupBattlePetTooltip()
    end

    DT.tooltip:Show()
end

function SetupCombatPetTooltip()
    local petName = UnitName("pet")
    local petFamily = UnitCreatureFamily("pet")
    local petHealth = UnitHealth("pet")
    local petMaxHealth = UnitHealthMax("pet")
    local petHealthPercent = (petHealth / petMaxHealth) * 100

    if not E.db.CompanionDataText.pet_name_header then
        DT.tooltip:AddLine(TextColor(string.format("Active %s", GetPlayerClassCreatureType()), "ffc0c0c0"))
        DT.tooltip:AddDoubleLine(NAME, TextColor(petName or "Unknown", "ffffffff"))
    else
        DT.tooltip:AddLine(TextColor(petName, "ffc0c0c0"))
    end

    DT.tooltip:AddDoubleLine(STABLE_SORT_TYPE_LABEL, TextColor(petFamily or STABLE_PET_UNCATEGORIZED, "ffffffff"))

    if select(2, UnitClass("player")) == "HUNTER" then
        DT.tooltip:AddDoubleLine(STABLE_SORT_SPECIALIZATION_LABEL, TextColor(GetHunterPetSpec(), "ffffffff"))
    end

    DT.tooltip:AddDoubleLine(HEALTH, TextColor(string.format("%.1f%%", petHealthPercent), petHealth == petMaxHealth and "ff00ff00" or "ffff0000"))
end

function SetupBattlePetTooltip()
    local petID = C_PetJournal.GetSummonedPetGUID()
    if not petID then
        return
    end

    local _, customName, level, xp, maxXp, _, _, name, _, petType, _, _, _, _, canBattle, _, _, _ = C_PetJournal.GetPetInfoByPetID(petID)
    DT.tooltip:AddLine(TextColor(TOOLTIP_BATTLE_PET, "ffc0c0c0"))
    DT.tooltip:AddDoubleLine(NAME, TextColor((customName or name), "ffffffff"))
    DT.tooltip:AddDoubleLine(STABLE_SORT_TYPE_LABEL, TextColor((_G["BATTLE_PET_DAMAGE_NAME_"..petType] or "Unknown type"), "ffffffff"))

    if E.db.CompanionDataText.battle_pet_extended then
        local petLevelXp = ((level and level < 25) and TextColor(string.format(" (%s/%s)", xp, maxXp), "ffc0c0c0") or "")
        DT.tooltip:AddDoubleLine(LEVEL, TextColor((level or "Unknown level"), "ffffffff") .. petLevelXp)
        health, maxHealth, power, speed, rarity = C_PetJournal.GetPetStats(petID)
        DT.tooltip:AddDoubleLine(PET_BATTLE_STAT_QUALITY, TextColor(_G["BATTLE_PET_BREED_QUALITY"..rarity], "ffffffff"))
    end
end

local function OnLeave(self)
    DT.tooltip:Hide()
end

function TextColor(text, hex)
    return hex ~= nil and ("|c" .. hex .. (text or "") .. "|r") or text
end

local function ValueColorUpdate(self, hex, r, g, b)
	displayString = string.format("%s%%s|r", hex)
	OnEvent(self)
end

local events = { "PLAYER_ENTERING_WORLD", "UNIT_PET", "COMPANION_UPDATE" }
DT:RegisterDatatext("CompanionDataText", nil, events, OnEvent, nil, nil, OnEnter, OnLeave, "Companion", nil, ValueColorUpdate)