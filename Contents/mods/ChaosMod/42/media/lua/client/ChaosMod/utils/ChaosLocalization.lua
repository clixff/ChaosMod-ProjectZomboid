---@class ChaosLocalization
ChaosLocalization = ChaosLocalization or {}

---@type table<string, table<string, table<string, string>>>
-- Structure: data[langCode][libName][key] = value
ChaosLocalization.data = {}

function ChaosLocalization.ClearAll()
    ChaosLocalization.data = {}
end

---@param langCode string
function ChaosLocalization.LoadLanguage(langCode)
    if ChaosLocalization.data[langCode] then
        return
    end

    local filename = "lang/" .. langCode .. ".json"
    local langData = ChaosFileReader.ReadJsonFile(filename)
    if not langData then
        print("[ChaosLocalization] Failed to load language file: " .. filename)
        return
    end

    ChaosLocalization.data[langCode] = {}
    for libName, strings in pairs(langData) do
        if type(strings) == "table" then
            ChaosLocalization.data[langCode][libName] = {}
            for key, value in pairs(strings) do
                if type(value) == "string" then
                    ChaosLocalization.data[langCode][libName][key] = value
                end
            end
        end
    end

    local count = 0
    for _ in pairs(ChaosLocalization.data[langCode]) do count = count + 1 end
    print(string.format("[ChaosLocalization] Loaded language '%s' with %d libs", langCode, count))
end

---@param lib string
---@param key string
---@return string
function ChaosLocalization.GetString(lib, key)
    local lang = ChaosConfig.lang or "en"

    local langTable = ChaosLocalization.data[lang]
    if langTable then
        local libTable = langTable[lib]
        if libTable and libTable[key] then
            return libTable[key]
        end
    end

    local enTable = ChaosLocalization.data["en"]
    if enTable then
        local libTable = enTable[lib]
        if libTable and libTable[key] then
            return libTable[key]
        end
    end

    return string.format("%s_%s", lib or "", key or "")
end

function ChaosLocalization.ReloadLanguages()
    ChaosLocalization.ClearAll()
    ChaosLocalization.LoadLanguage("en")
    local lang = ChaosConfig.lang or "en"
    if lang ~= "en" then
        ChaosLocalization.LoadLanguage(lang)
    end
end
