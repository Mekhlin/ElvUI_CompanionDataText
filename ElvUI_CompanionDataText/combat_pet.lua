local classSupport = {
    HUNTER      = true,
    MAGE        = true,
    WARLOCK     = true,
    DEATHKNIGHT = true
}

function HasCombatPetSupport()
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

function IsPetDead()
    -- Check if the pet exists and is dead
    if UnitExists("pet") then
        if UnitIsDead("pet") then
            return true -- Pet exists and is dead
        else
            return false -- Pet exists and is alive
        end
    else
        return false -- No pet exists
    end
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