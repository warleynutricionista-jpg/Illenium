--[[
    kCharcreator - Client
    Character creation system
]]

CORE = CORE or {}
CORE.Charcreator = CORE.Charcreator or {}

-- State
CORE.Charcreator.Camera = nil
CORE.Charcreator.CameraPos = "full_body"
CORE.Charcreator.LastCameraPos = "full_body"
CORE.Charcreator.IsIn = false
CORE.Charcreator.ZoomOffset = 0
CORE.Charcreator.LastCycleTime = 0

exports("IsInCharCreator", function()
    return CORE.Charcreator.IsIn
end)
-- Constants
local CAMERA_ORDER = { "face", "top", "body", "full_body", "shoes" }
local CAMERA_INTERP_TIME = 500
local CYCLE_COOLDOWN = 600
local PED_BASE_HEIGHT = 0.9 -- Ped body center offset from ground

local COMPONENT = {
    MASK = 1,
    HAIR = 2,
    TORSO = 3,
    LEGS = 4,
    BAGS = 5,
    SHOES = 6,
    ACCESSORIES = 7,
    UNDERSHIRT = 8,
    ARMOR = 9,
    DECALS = 10,
    TOPS = 11
}

local PROP = {
    HATS = 0,
    GLASSES = 1,
    EARS = 2,
    WATCHES = 6,
    BRACELETS = 7
}

local OVERLAY = {
    BLEMISHES = 0,
    BEARD = 1,
    EYEBROWS = 2,
    AGEING = 3,
    MAKEUP = 4,
    BLUSH = 5,
    COMPLEXION = 6,
    SUN_DAMAGE = 7,
    LIPSTICK = 8,
    FRECKLES = 9,
    CHEST_HAIR = 10,
    BODY_BLEMISHES = 11
}

-- ============================================
-- HELPERS
-- ============================================

local function clamp(value, min, max)
    return math.max(min, math.min(max, tonumber(value) or min))
end

-- GTA has issues with exactly 0.0 or 1.0 for mix/opacity values
local function clampFloat(value, default)
    local v = tonumber(value) or default
    if v >= 1.0 then return 0.99 end
    if v <= 0.0 then return 0.01 end
    return v
end

local function getSexConfig()
    local sex = CORE.Charcreator.PlayerSex or "m"
    local config = CORE.Charcreator.Config
    local isMale = sex == "m"
    local defaultPed = isMale and config.defaultPedMale or config.defaultPedFemale
    local naked = isMale and CORE.Skin.Config.nakeds.male or CORE.Skin.Config.nakeds.female
    return sex, isMale, defaultPed, naked
end

-- ============================================
-- CAMERA SYSTEM
-- ============================================

function CORE.Charcreator:GetCameraPosition(camType)
    local position = self.Config.player_position
    local camParams = self.Config.cameras[camType]
    local zoomConfig = self.Config.zoom

    local distance = clamp(camParams.distance + self.ZoomOffset, zoomConfig.min, zoomConfig.max)
    local angleRad = math.rad(position.w)
    local baseZ = position.z + PED_BASE_HEIGHT

    return vector3(
        position.x + (distance * math.sin(-angleRad)),
        position.y + (distance * math.cos(-angleRad)),
        baseZ + camParams.height
    ), camParams.fov, camParams.height
end

function CORE.Charcreator:UpdateCameraZoom()
    if not self.Camera then return end

    local position = self.Config.player_position
    local camCoords, fov, height = self:GetCameraPosition(self.CameraPos)
    local baseZ = position.z + PED_BASE_HEIGHT

    SetCamCoord(self.Camera, camCoords)
    PointCamAtCoord(self.Camera, position.x, position.y, baseZ + height)
end

function CORE.Charcreator:ChangeCameraPosition(pos)
    pos = pos or self.CameraPos
    if not pos or self.LastCameraPos == pos then return end

    self.LastCameraPos = pos
    self.ZoomOffset = 0

    local position = self.Config.player_position
    local camCoords, fov, height = self:GetCameraPosition(pos)
    local baseZ = position.z + PED_BASE_HEIGHT
    local lastCamera = self.Camera

    -- Create new camera
    local newCamera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    if not newCamera or newCamera == 0 or newCamera == -1 then
        -- Fallback: move existing camera
        if self.Camera and DoesCamExist(self.Camera) then
            SetCamCoord(self.Camera, camCoords)
            PointCamAtCoord(self.Camera, position.x, position.y, baseZ + height)
            SetCamFov(self.Camera, fov)
        end
        return
    end

    SetCamCoord(newCamera, camCoords)
    PointCamAtCoord(newCamera, position.x, position.y, baseZ + height)
    SetCamFov(newCamera, fov)

    if lastCamera and DoesCamExist(lastCamera) then
        SetCamActiveWithInterp(newCamera, lastCamera, CAMERA_INTERP_TIME, true, true)
        SetTimeout(CAMERA_INTERP_TIME + 100, function()
            if DoesCamExist(lastCamera) then
                DestroyCam(lastCamera, false)
            end
        end)
    else
        SetCamActive(newCamera, true)
        RenderScriptCams(true, true, CAMERA_INTERP_TIME, true, false)
    end

    self.Camera = newCamera
end

-- ============================================
-- CONFIG BUILDERS
-- ============================================

local function buildParentsList()
    local fathers, mothers = {}, {}
    local fatherNames = {"Benjamin", "Daniel", "Joshua", "Noah", "Andrew", "Juan", "Alex", "Isaac", "Evan", "Ethan", "Vincent", "Angel", "Adrian", "Anthony", "Claude", "Diego", "Gabriel", "John", "Kevin", "Louis", "Michael", "Niko", "Samuel", "Santiago"}
    local motherNames = {"Hannah", "Audrey", "Jasmine", "Giselle", "Amelia", "Isabella", "Zoe", "Ava", "Camilla", "Violet", "Sophia", "Eveline", "Ashley", "Brianna", "Charlotte", "Elizabeth", "Emma", "Grace", "Misty", "Natalie", "Nicole", "Olivia"}

    for i = 0, 23 do
        fathers[#fathers + 1] = {
            id = i,
            name = fatherNames[i + 1] or ("Father " .. i),
            image = ("nui://kCharcreator/web/build/images/parents/%s.webp"):format(string.lower(fatherNames[i + 1] or "default"))
        }
    end

    for i = 0, 21 do
        mothers[#mothers + 1] = {
            id = i + 24,
            name = motherNames[i + 1] or ("Mother " .. i),
            image = ("nui://kCharcreator/web/build/images/parents/%s.webp"):format(string.lower(motherNames[i + 1] or "default"))
        }
    end

    return { fathers = fathers, mothers = mothers }
end

local function buildOptions(pPed, cachedPed)
    local options = {
        eyeColors = {}, blemishes = {}, ageing = {}, complexion = {}, freckles = {},
        hairStyles = {}, hairColors = {}, beardStyles = {}, eyebrowStyles = {},
        makeupStyles = {}, blushStyles = {}, lipstickStyles = {},
        jackets = {}, undershirts = {}, pants = {}, shoes = {}, hats = {}, glasses = {}, masks = {},
        accessories = {}, torsos = {}, arms = {},
        clothingCategoryImages = {}, hairCategoryImages = {}
    }

    -- Eye colors
    local eyeColorNames = {"Green", "Emerald", "Light Blue", "Ocean Blue", "Blue", "Dark Blue", "Gray", "Hazel", "Light Brown", "Brown", "Violet", "Red", "Yellow", "Cyan", "Pink", "Orange"}
    local eyeColorHex = {"#4CAF50", "#2ECC71", "#87CEEB", "#4A90D9", "#3498DB", "#2C3E7B", "#95A5A6", "#A67C52", "#C4A77D", "#8B4513", "#9B59B6", "#E74C3C", "#F1C40F", "#00BCD4", "#E91E8F", "#FF9800"}
    for i = 0, 15 do
        options.eyeColors[#options.eyeColors + 1] = { id = i, name = eyeColorNames[i + 1] or ("Color " .. i), hex = eyeColorHex[i + 1] or "#FFFFFF" }
    end

    -- Head overlays (without images)
    local overlayConfigsSimple = {
        { key = "blemishes", index = OVERLAY.BLEMISHES },
        { key = "ageing", index = OVERLAY.AGEING },
        { key = "complexion", index = OVERLAY.COMPLEXION },
        { key = "freckles", index = OVERLAY.FRECKLES }
    }

    for _, cfg in ipairs(overlayConfigsSimple) do
        local max = GetNumHeadOverlayValues(cfg.index)
        options[cfg.key][1] = { id = -1, name = "None" }
        for i = 0, max - 1 do
            options[cfg.key][#options[cfg.key] + 1] = { id = i, name = "Style " .. (i + 1) }
        end
    end

    -- Head overlays (with images)
    local overlayConfigsWithImages = {
        { key = "beardStyles", index = OVERLAY.BEARD, folder = "beard" },
        { key = "eyebrowStyles", index = OVERLAY.EYEBROWS, folder = "eyebrows" },
        { key = "makeupStyles", index = OVERLAY.MAKEUP, folder = "makeup" },
        { key = "blushStyles", index = OVERLAY.BLUSH, folder = "blush" },
        { key = "lipstickStyles", index = OVERLAY.LIPSTICK, folder = "lipstick" }
    }

    for _, cfg in ipairs(overlayConfigsWithImages) do
        local max = GetNumHeadOverlayValues(cfg.index)
        options[cfg.key][1] = { id = -1, name = "None" }
        for i = 0, max - 1 do
            options[cfg.key][#options[cfg.key] + 1] = {
                id = i,
                name = "Style " .. (i + 1),
                image = ("nui://kCharcreator/web/build/images/charcreator/%s/%s/%d.png"):format(cachedPed, cfg.folder, i)
            }
        end
    end

    -- Hair styles
    local maxHair = GetNumberOfPedDrawableVariations(pPed, COMPONENT.HAIR)
    for i = 0, maxHair - 1 do
        options.hairStyles[#options.hairStyles + 1] = {
            id = i, name = "Style " .. i,
            image = ("nui://kCharcreator/web/build/images/charcreator/%s/hair/%d.png"):format(cachedPed, i)
        }
    end

    -- Hair colors
    local hairColorNames = {"Black", "Dark Brown", "Brown", "Chestnut", "Red", "Dark Blonde", "Blonde", "Platinum", "Gray", "White"}
    local hairColorHex = {"#1C1C1C", "#3D2314", "#5A3A29", "#8B4513", "#B7410E", "#C19A6B", "#E6BE8A", "#FAF0BE", "#808080", "#FFFFFF"}
    for i = 0, 9 do
        options.hairColors[#options.hairColors + 1] = { id = i, name = hairColorNames[i + 1] or ("Color " .. i), hex = hairColorHex[i + 1] or "#FFFFFF" }
    end

    -- Clothing components
    local clothingConfigs = {
        { key = "jackets", component = COMPONENT.TOPS, folder = "jacket" },
        { key = "undershirts", component = COMPONENT.UNDERSHIRT, folder = "undershirt" },
        { key = "pants", component = COMPONENT.LEGS, folder = "leg" },
        { key = "shoes", component = COMPONENT.SHOES, folder = "shoes" },
        { key = "masks", component = COMPONENT.MASK, folder = "mask" },
        { key = "accessories", component = COMPONENT.ACCESSORIES, folder = "accessory" },
        { key = "torsos", component = COMPONENT.TORSO, folder = "torso" }
    }

    -- Props for arms (bracelets)
    options.arms[1] = { id = -1, name = "None", textures = 0 }
    local maxArms = GetNumberOfPedPropDrawableVariations(pPed, PROP.BRACELETS)
    for i = 0, maxArms - 1 do
        options.arms[#options.arms + 1] = {
            id = i, name = "Style " .. i,
            textures = GetNumberOfPedPropTextureVariations(pPed, PROP.BRACELETS, i),
            image = ("nui://kCharcreator/web/build/images/charcreator/%s/bracelet/%d.webp"):format(cachedPed, i)
        }
    end

    for _, cfg in ipairs(clothingConfigs) do
        local max = GetNumberOfPedDrawableVariations(pPed, cfg.component)
        for i = 0, max - 1 do
            options[cfg.key][#options[cfg.key] + 1] = {
                id = i, name = "Style " .. i,
                textures = GetNumberOfPedTextureVariations(pPed, cfg.component, i),
                image = ("nui://kCharcreator/web/build/images/charcreator/%s/%s/%d.webp"):format(cachedPed, cfg.folder, i)
            }
        end
    end

    -- Props
    local propConfigs = {
        { key = "hats", prop = PROP.HATS, folder = "hat" },
        { key = "glasses", prop = PROP.GLASSES, folder = "glasses" }
    }

    for _, cfg in ipairs(propConfigs) do
        options[cfg.key][1] = { id = -1, name = "None", textures = 0 }
        local max = GetNumberOfPedPropDrawableVariations(pPed, cfg.prop)
        for i = 0, max - 1 do
            options[cfg.key][#options[cfg.key] + 1] = {
                id = i, name = "Style " .. i,
                textures = GetNumberOfPedPropTextureVariations(pPed, cfg.prop, i),
                image = ("nui://kCharcreator/web/build/images/charcreator/%s/%s/%d.webp"):format(cachedPed, cfg.folder, i)
            }
        end
    end

    -- Category images
    options.clothingCategoryImages = {
        jacket = "nui://kCharcreator/web/build/images/categories/jacket.webp",
        undershirt = "nui://kCharcreator/web/build/images/categories/tshirt.webp",
        pants = "nui://kCharcreator/web/build/images/categories/pants.webp",
        shoes = "nui://kCharcreator/web/build/images/categories/shoes.webp",
        hat = "nui://kCharcreator/web/build/images/categories/hat.webp",
        glasses = "nui://kCharcreator/web/build/images/categories/glasses.webp",
        mask = "nui://kCharcreator/web/build/images/categories/masks.webp",
        accessory = "nui://kCharcreator/web/build/images/categories/accessory.webp",
        torso = "nui://kCharcreator/web/build/images/categories/torso.png",
        arms = "nui://kCharcreator/web/build/images/categories/arms.webp"
    }

    options.hairCategoryImages = {
        hair = "nui://kCharcreator/web/build/images/categories/hair.webp",
        beard = "nui://kCharcreator/web/build/images/categories/beard.webp",
        eyebrows = "nui://kCharcreator/web/build/images/categories/eyebrows.webp",
        makeup = "nui://kCharcreator/web/build/images/categories/makeup.webp",
        blush = "nui://kCharcreator/web/build/images/categories/blush.webp",
        lipstick = "nui://kCharcreator/web/build/images/categories/lipstick.webp"
    }

    return options
end

local function buildLabels()
    local lang = CORE.Charcreator.Config.lang or "en"
    local t = CORE.Charcreator.Locale[lang] or CORE.Charcreator.Locale["en"] or {}

    return {
        title = t.TITLE or "Character Creation",
        sections = {
            parents = t.FACE or "Parents",
            face = t.FACE_FEAT or "Face",
            eyes = t.EYE_COLOR or "Eyes",
            skin = t.SKIN or "Skin",
            hair = t.HAIR or "Hair",
            beard = t.FACIAL_HAIR or "Beard",
            eyebrows = t.EYEBROWS or "Eyebrows",
            makeup = t.MAKEUP or "Makeup",
            blush = t.BLUSH or "Blush",
            lipstick = t.LIPSTICK or "Lipstick",
            top = t.CLOTHES or "Top",
            bottom = t.LEGS or "Bottom",
            accessories = t.ACCESSORIES or "Accessories"
        },
        parents = {
            father = "Father",
            mother = "Mother",
            fathers = t.MENS or "Fathers",
            mothers = t.WOMENS or "Mothers"
        },
        features = {
            nose_width = t.WIDTH or "Width",
            nose_height = t.BONE_HEIGHT or "Height",
            nose_length = t.PEAK_LENGTH or "Length",
            nose_bone = t.BONE_TWIST or "Bone",
            eyebrows_height = t.EYEBROW_HEIGHT or "Height",
            eyebrows_depth = t.EYEBROW_DEPTH or "Depth",
            cheeks_width = t.CHEEK_WIDTH or "Width",
            cheeks_bone = t.BONE_HEIGHT or "Bone",
            jaw_width = t.BONE_WIDTH or "Width",
            jaw_length = t.BONE_LENGTH or "Length",
            chin_height = t.BONE_HEIGHT or "Height",
            chin_width = t.BONE_WIDTH or "Width",
            chin_cleft = t.CHIN_CLEFT or "Cleft",
            lips_thickness = t.LIPS_THICKNESS or "Lips",
            neck_thickness = t.NECK_THICKNESS or "Neck",
            eyes_squint = t.EYES_SQUINT or "Squint"
        },
        skin = {
            blemishes = t.BLEMISHES or "Blemishes",
            ageing = t.AGEING or "Ageing",
            complexion = t.COMPLEXION or "Complexion",
            freckles = t.FRECKLES or "Freckles",
            opacity = t.OPACITY or "Opacity"
        },
        hair = {
            style = t.HAIR or "Style",
            color = t.COLOR or "Color",
            highlight = t.HIGHLIGHT_COLOR or "Highlight",
            opacity = t.OPACITY or "Opacity"
        },
        clothes = {
            jacket = t.JACKETS or "Jacket",
            undershirt = t.UNDERTSHIRT or "Undershirt",
            pants = t.LEGS or "Pants",
            shoes = t.SHOES or "Shoes",
            hat = t.HATS or "Hat",
            glasses = t.GLASSES or "Glasses",
            mask = t.MASKS or "Mask",
            accessories = t.ACCESSORIES_ITEM or "Accessories",
            torso = t.TORSOS or "Torso",
            bracelets = t.BRACELETS or "Bracelets",
            texture = "Texture"
        },
        buttons = {
            random = t.RANDOMIZE_FACE or "Random",
            reset = "Reset",
            finish = t.FINISH or "Finish",
            confirm = t.POPUP_CONFIRM or "Confirm",
            cancel = t.POPUP_CANCEL or "Cancel",
            randomize = t.RANDOMIZE_FACE or "Randomize"
        },
        misc = {
            none = t.NONE or "None",
            face_mix = t.FACE_MIX or "Face Mix",
            skin_mix = t.SKIN_MIX or "Skin Mix",
            confirm_title = t.POPUP_TITLE or "Confirm?",
            confirm_message = t.POPUP_SUBTITLE or "Are you sure you want to finish?",
            color = t.COLOR or "Color",
            style = "Style"
        },
        descriptions = {
            parents = t.SUBTITLE or "Select parents for your character",
            face = "Adjust facial features",
            eyes = "Choose eye color",
            skin = "Customize skin appearance",
            parent_select = "Select a face"
        }
    }
end

local function buildConfig(pPed, cachedPed)
    return {
        tabs = {
            { id = 0, label = "Appearance", icon = "fa-solid fa-face-smile" },
            { id = 1, label = "Hair & Style", icon = "fa-solid fa-scissors" },
            { id = 2, label = "Clothing", icon = "fa-solid fa-shirt" }
        },
        labels = buildLabels(),
        parents = buildParentsList(),
        options = buildOptions(pPed, cachedPed)
    }
end

-- ============================================
-- MAIN THREAD
-- ============================================

CreateThread(function()
    while true do
        if CORE.Charcreator.IsIn then
            local pPed = PlayerPedId()
            TaskStandStill(pPed, 1000)
            SetPedCanHeadIk(pPed, false)
            BlockWeaponWheelThisFrame()
            Wait(0)
        else
            Wait(1000)
        end
    end
end)

-- ============================================
-- OPEN / CLOSE
-- ============================================

AddEventHandler("LIB:PLAYER_LOADED", function ()
    PLAYER_IS_READY = true;
end)

RegisterNetEvent("CORE.Charcreator:Open", function()
    local config = CORE.Charcreator.Config

    while not PLAYER_IS_READY do
        Wait(1000)
    end

    while (exports["web"]:arrivalIsShowing()) do
        Wait(2000);
    end

    -- Trigger before events
    for _, event in pairs(config.event_before_open) do
        if event and event ~= "" then
            TriggerEvent(event)
            TriggerServerEvent(event)
        end
    end

    -- Put player in isolated instance
    TriggerServerEvent("kCharcreator:setInstance", true)

    CORE.Charcreator.IsIn = true

    local _, _, defaultPed = getSexConfig()
    local position = config.player_position

    -- Set ped model with naked clothes
    CORE.Skin.SetPlayerModel(defaultPed, PlayerPedId(), true)

    -- Teleport and setup
    CORE.Teleport:TeleportToWp(PlayerPedId(), position.xyz, position.w, false, function()
        CORE.Charcreator.ZoomOffset = 0

        local camCoords, fov, height = CORE.Charcreator:GetCameraPosition(CORE.Charcreator.CameraPos)
        local baseZ = position.z + PED_BASE_HEIGHT

        CORE.Charcreator.Camera = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
        SetCamCoord(CORE.Charcreator.Camera, camCoords)
        PointCamAtCoord(CORE.Charcreator.Camera, position.x, position.y, baseZ + height)
        SetCamFov(CORE.Charcreator.Camera, fov)
        SetCamActive(CORE.Charcreator.Camera, true)
        RenderScriptCams(true, false, 0, true, false)

        TriggerEvent("kCharcreator:UI:Open", "charcreator", nil, nil, true)
    end)
end)

RegisterNetEvent("kCharcreator:UI:charcreator:finishCreateCharacter", function()
    CORE.Charcreator.IsIn = false

    -- Return player to default instance
    TriggerServerEvent("kCharcreator:setInstance", false)

    local config = CORE.Charcreator.Config
    local position = config.spawn_position


    TriggerEvent('CORE.Charcreator:Finish')

    CORE.Teleport:TeleportToWp(PlayerPedId(), position.xyz, position.w, false, function()
        -- Cleanup camera
        if CORE.Charcreator.Camera then
            DestroyCam(CORE.Charcreator.Camera)
            RenderScriptCams(false, false, 0, true, false)
            CORE.Charcreator.Camera = nil
        end

        TriggerEvent("kCharcreator:UI:Close")
        

        -- Save skin
        local pPed = PlayerPedId()
        local skin = CORE.Skin.GetSkin(pPed, false)
        TriggerServerEvent("kCharcreator:saveSkin", skin, GetEntityModel(pPed))

        -- Trigger after events
        for _, event in pairs(config.event_after_spawn) do
            if event and event ~= "" then
                TriggerEvent(event)
                TriggerServerEvent(event)
            end
        end
    end)
end)

-- ============================================
-- INPUT EVENTS
-- ============================================

RegisterNetEvent("kCharcreator:UI:charcreator:drag", function(data)
    if not data or not data.deltaX then return end

    local pPed = PlayerPedId()
    local delta = clamp(data.deltaX * 0.3, -5.0, 5.0)
    SetEntityHeading(pPed, GetEntityHeading(pPed) + delta)
end)

RegisterNetEvent("kCharcreator:UI:charcreator:zoom", function(data)
    if not data or not data.delta then return end

    local zoomSpeed = CORE.Charcreator.Config.zoom.speed
    CORE.Charcreator.ZoomOffset = CORE.Charcreator.ZoomOffset + (data.delta * zoomSpeed * 0.05)
    CORE.Charcreator:UpdateCameraZoom()
end)

-- ============================================
-- GET CHARCREATOR DATA
-- ============================================

RegisterNetEvent("kCharcreator:UI:charcreator:getCharcreator", function()
    local pPed = PlayerPedId()
    local config = CORE.Charcreator.Config
    local sex, isMale, cachedPed, naked = getSexConfig()

    -- Theme
    TriggerEvent("kCharcreator:UI:SendReactMessage", {
        event = "setColor",
        data = config.backgroundGlass and { color = config.color or "gold", backgroundGlass = config.backgroundGlass } or (config.color or "gold")
    })

    -- Translations
    local lang = config.lang or "en"
    TriggerEvent("kCharcreator:UI:SendReactMessage", {
        event = "setTranslations",
        data = CORE.Charcreator.Locale[lang] or CORE.Charcreator.Locale["en"] or {}
    })

    -- Config + initial data
    TriggerEvent("kCharcreator:UI:SendReactMessage", {
        event = "setCharcreator",
        data = {
            config = buildConfig(pPed, cachedPed),
            face = {
                face_one = { id = 0 },
                face_two = { id = 24 },
                face_mix = { percent = 0.5 },
                skin_mix = { percent = 0.5 }
            },
            faceFeat = {
                nose = { width = 0.5, peak_height = 0.5, peak_length = 0.5, bone_height = 0.5 },
                eyebrows = { height = 0.5, depth = 0.5 },
                cheeks = { width = 0.5, bone_height = 0.5 },
                jaw = { width = 0.5, length = 0.5 },
                chin = { height = 0.5, width = 0.5, cleft = 0.5 },
                eyes = { squint = 0.5, color = 0 },
                lips = { thickness = 0.5 },
                neck = { thickness = 0.5 }
            },
            skin = {
                blemishes = { id = -1, opacity = 1.0 },
                ageing = { id = -1, opacity = 1.0 },
                complexion = { id = -1, opacity = 1.0 },
                freckles = { id = -1, opacity = 1.0 }
            },
            hair = {
                style = { id = 0 },
                color = { primary = 0, highlight = 0 },
                beard = { id = -1, opacity = 1.0, color = 0 },
                eyebrows = { id = 0, opacity = 1.0, color = 0 }
            },
            makeup = {
                makeup = { id = -1, opacity = 1.0, color = 0 },
                blush = { id = -1, opacity = 1.0, color = 0 },
                lipstick = { id = -1, opacity = 1.0, color = 0 }
            },
            clothes = {
                jacket = { id = naked.tops, texture = naked.tops_text },
                undershirt = { id = naked.undershirts, texture = naked.undershirts_text },
                pants = { id = naked.legs, texture = naked.legs_text },
                shoes = { id = naked.shoes, texture = naked.shoes_text },
                hat = { id = naked.hats, texture = naked.hats_text },
                glasses = { id = naked.glasses, texture = naked.glasses_text },
                mask = { id = naked.masks, texture = naked.masks_text },
                accessory = { id = naked.accessories, texture = naked.accessories_text },
                torso = { id = naked.torsos, texture = naked.torsos_text },
                arms = { id = naked.bracelets, texture = naked.bracelets_text }
            }
        }
    })

    -- Music
    local music = config.music
    if music and music.enabled then
        TriggerEvent("kCharcreator:UI:SendReactMessage", {
            event = "setMusicConfig",
            data = {
                enabled = music.enabled,
                autoplay = music.autoplay,
                volume = music.volume,
                playlist = music.playlist,
                currentTrackIndex = 0
            }
        })
    end
end)

-- ============================================
-- SET FACE (HeadBlend)
-- ============================================

RegisterNetEvent("kCharcreator:UI:charcreator:setFace", function(data)
    if not data or not data.face then return end

    local pPed = PlayerPedId()
    local face = data.face

    local faceOneId = tonumber(face.face_one.id) or 0
    local faceTwoId = tonumber(face.face_two.id) or 24
    local faceMix = clampFloat(face.face_mix.percent, 0.5)
    local skinMix = clampFloat(face.skin_mix.percent, 0.5)

    SetPedHeadBlendData(pPed, faceOneId, faceTwoId, 0, faceOneId, faceTwoId, 0, faceMix, skinMix, 0.0, false)
end)

RegisterNetEvent("kCharcreator:UI:charcreator:randomizeFace", function()
    local pPed = PlayerPedId()

    local fatherId = math.random(0, 23)
    local motherId = math.random(24, 45)
    local faceMix = math.random() * 0.5 + 0.25
    local skinMix = math.random() * 0.5 + 0.25

    SetPedHeadBlendData(pPed, fatherId, motherId, 0, fatherId, motherId, 0, faceMix, skinMix, 0.0, false)

    while not HasPedHeadBlendFinished(pPed) do Wait(0) end

    TriggerEvent("kCharcreator:UI:SendReactMessage", {
        event = "setCharcreator",
        data = {
            face = {
                face_one = { id = fatherId },
                face_two = { id = motherId },
                face_mix = { percent = faceMix },
                skin_mix = { percent = skinMix }
            }
        }
    })
end)

-- ============================================
-- SET FACE FEATURES
-- ============================================

RegisterNetEvent("kCharcreator:UI:charcreator:setFaceFeat", function(data)
    if not data or not data.faceFeat then return end

    local pPed = PlayerPedId()
    local ff = data.faceFeat

    local function toFeature(val)
        return (tonumber(val) or 0.5) * 2 - 1
    end

    -- Nose (0-5)
    SetPedFaceFeature(pPed, 0, toFeature(ff.nose.width))
    SetPedFaceFeature(pPed, 1, toFeature(ff.nose.peak_length))
    SetPedFaceFeature(pPed, 2, toFeature(ff.nose.peak_height))
    SetPedFaceFeature(pPed, 5, toFeature(ff.nose.bone_height))

    -- Eyebrows (6-7)
    SetPedFaceFeature(pPed, 6, toFeature(ff.eyebrows.depth))
    SetPedFaceFeature(pPed, 7, toFeature(ff.eyebrows.height))

    -- Cheeks (8-9)
    SetPedFaceFeature(pPed, 8, toFeature(ff.cheeks.width))
    SetPedFaceFeature(pPed, 9, toFeature(ff.cheeks.bone_height))

    -- Jaw (13-14)
    SetPedFaceFeature(pPed, 13, toFeature(ff.jaw.length))
    SetPedFaceFeature(pPed, 14, toFeature(ff.jaw.width))

    -- Chin (15-18)
    SetPedFaceFeature(pPed, 15, toFeature(ff.chin.height))
    SetPedFaceFeature(pPed, 16, toFeature(ff.chin.height))
    SetPedFaceFeature(pPed, 17, toFeature(ff.chin.cleft))
    SetPedFaceFeature(pPed, 18, toFeature(ff.chin.width))

    -- Misc
    SetPedFaceFeature(pPed, 11, toFeature(ff.eyes.squint))
    SetPedFaceFeature(pPed, 12, toFeature(ff.lips.thickness))
    SetPedFaceFeature(pPed, 19, toFeature(ff.neck.thickness))

    -- Eye color
    SetPedEyeColor(pPed, tonumber(ff.eyes.color) or 0)
end)

RegisterNetEvent("kCharcreator:UI:charcreator:randomizeFaceFeat", function()
    local newFaceFeat = {
        nose = { width = math.random(), peak_height = math.random(), peak_length = math.random(), bone_height = math.random() },
        eyebrows = { height = math.random(), depth = math.random() },
        cheeks = { width = math.random(), bone_height = math.random() },
        jaw = { width = math.random(), length = math.random() },
        chin = { height = math.random(), width = math.random(), cleft = math.random() },
        eyes = { squint = math.random(), color = math.random(0, 15) },
        lips = { thickness = math.random() },
        neck = { thickness = math.random() }
    }

    TriggerEvent("kCharcreator:UI:charcreator:setFaceFeat", { faceFeat = newFaceFeat })
    TriggerEvent("kCharcreator:UI:SendReactMessage", { event = "setCharcreator", data = { faceFeat = newFaceFeat } })
end)

-- ============================================
-- SET SKIN (Head Overlays)
-- ============================================

RegisterNetEvent("kCharcreator:UI:charcreator:setSkin", function(data)
    if not data or not data.skin then return end

    local pPed = PlayerPedId()
    local skin = data.skin

    SetPedHeadOverlay(pPed, OVERLAY.BLEMISHES, tonumber(skin.blemishes.id) or -1, clampFloat(skin.blemishes.opacity, 1.0))
    SetPedHeadOverlay(pPed, OVERLAY.AGEING, tonumber(skin.ageing.id) or -1, clampFloat(skin.ageing.opacity, 1.0))
    SetPedHeadOverlay(pPed, OVERLAY.COMPLEXION, tonumber(skin.complexion.id) or -1, clampFloat(skin.complexion.opacity, 1.0))
    SetPedHeadOverlay(pPed, OVERLAY.FRECKLES, tonumber(skin.freckles.id) or -1, clampFloat(skin.freckles.opacity, 1.0))
end)

-- ============================================
-- SET HAIR
-- ============================================

RegisterNetEvent("kCharcreator:UI:charcreator:setHair", function(data)
    if not data or not data.hair then return end

    local pPed = PlayerPedId()
    local hair = data.hair

    -- Hair style
    SetPedComponentVariation(pPed, COMPONENT.HAIR, tonumber(hair.style.id) or 0, 0, 0)
    SetPedHairColor(pPed, tonumber(hair.color.primary) or 0, tonumber(hair.color.highlight) or 0)

    -- Beard
    local beardId = tonumber(hair.beard.id) or -1
    SetPedHeadOverlay(pPed, OVERLAY.BEARD, beardId, clampFloat(hair.beard.opacity, 1.0))
    if beardId >= 0 then
        SetPedHeadOverlayColor(pPed, OVERLAY.BEARD, 1, tonumber(hair.beard.color) or 0, tonumber(hair.beard.color) or 0)
    end

    -- Eyebrows
    local eyebrowsId = tonumber(hair.eyebrows.id) or 0
    SetPedHeadOverlay(pPed, OVERLAY.EYEBROWS, eyebrowsId, clampFloat(hair.eyebrows.opacity, 1.0))
    SetPedHeadOverlayColor(pPed, OVERLAY.EYEBROWS, 1, tonumber(hair.eyebrows.color) or 0, tonumber(hair.eyebrows.color) or 0)
end)

-- ============================================
-- SET MAKEUP
-- ============================================

RegisterNetEvent("kCharcreator:UI:charcreator:setMakeup", function(data)
    if not data or not data.makeup then return end

    local pPed = PlayerPedId()
    local makeup = data.makeup

    local items = {
        { overlay = OVERLAY.MAKEUP, data = makeup.makeup },
        { overlay = OVERLAY.BLUSH, data = makeup.blush },
        { overlay = OVERLAY.LIPSTICK, data = makeup.lipstick }
    }

    for _, item in ipairs(items) do
        local id = tonumber(item.data.id) or -1
        SetPedHeadOverlay(pPed, item.overlay, id, clampFloat(item.data.opacity, 1.0))
        if id >= 0 then
            SetPedHeadOverlayColor(pPed, item.overlay, 2, tonumber(item.data.color) or 0, tonumber(item.data.color) or 0)
        end
    end
end)

-- ============================================
-- SET CLOTHES
-- ============================================

RegisterNetEvent("kCharcreator:UI:charcreator:setClothes", function(data)
    if not data or not data.clothes then return end

    local pPed = PlayerPedId()
    local clothes = data.clothes

    -- Components
    SetPedComponentVariation(pPed, COMPONENT.TOPS, tonumber(clothes.jacket.id) or 0, tonumber(clothes.jacket.texture) or 0, 0)
    SetPedComponentVariation(pPed, COMPONENT.UNDERSHIRT, tonumber(clothes.undershirt.id) or 0, tonumber(clothes.undershirt.texture) or 0, 0)
    SetPedComponentVariation(pPed, COMPONENT.LEGS, tonumber(clothes.pants.id) or 0, tonumber(clothes.pants.texture) or 0, 0)
    SetPedComponentVariation(pPed, COMPONENT.SHOES, tonumber(clothes.shoes.id) or 0, tonumber(clothes.shoes.texture) or 0, 0)
    SetPedComponentVariation(pPed, COMPONENT.MASK, tonumber(clothes.mask.id) or 0, tonumber(clothes.mask.texture) or 0, 0)
    SetPedComponentVariation(pPed, COMPONENT.ACCESSORIES, tonumber(clothes.accessory.id) or 0, tonumber(clothes.accessory.texture) or 0, 0)
    SetPedComponentVariation(pPed, COMPONENT.TORSO, tonumber(clothes.torso.id) or 0, tonumber(clothes.torso.texture) or 0, 0)

    -- Props
    local hatId = tonumber(clothes.hat.id) or -1
    if hatId == -1 then ClearPedProp(pPed, PROP.HATS) else SetPedPropIndex(pPed, PROP.HATS, hatId, tonumber(clothes.hat.texture) or 0, true) end

    local glassesId = tonumber(clothes.glasses.id) or -1
    if glassesId == -1 then ClearPedProp(pPed, PROP.GLASSES) else SetPedPropIndex(pPed, PROP.GLASSES, glassesId, tonumber(clothes.glasses.texture) or 0, true) end

    local armsId = tonumber(clothes.arms.id) or -1
    if armsId == -1 then ClearPedProp(pPed, PROP.BRACELETS) else SetPedPropIndex(pPed, PROP.BRACELETS, armsId, tonumber(clothes.arms.texture) or 0, true) end
end)

-- ============================================
-- CAMERA CONTROL
-- ============================================

RegisterNetEvent("kCharcreator:UI:charcreator:setCamera", function(data)
    if not data or not data.camera then return end

    local validCameras = { face = true, top = true, body = true, full_body = true, shoes = true }
    if not validCameras[data.camera] then return end

    CORE.Charcreator.CameraPos = data.camera
    CORE.Charcreator:ChangeCameraPosition(data.camera)
end)

RegisterNetEvent("kCharcreator:UI:charcreator:cycleCamera", function(data)
    if not data or not data.direction then return end

    local currentTime = GetGameTimer()
    if currentTime - CORE.Charcreator.LastCycleTime < CYCLE_COOLDOWN then return end
    CORE.Charcreator.LastCycleTime = currentTime

    local currentIndex = 1
    for i, cam in ipairs(CAMERA_ORDER) do
        if cam == CORE.Charcreator.CameraPos then
            currentIndex = i
            break
        end
    end

    if data.direction == "next" then
        currentIndex = currentIndex % #CAMERA_ORDER + 1
    else
        currentIndex = (currentIndex - 2) % #CAMERA_ORDER + 1
    end

    CORE.Charcreator.CameraPos = CAMERA_ORDER[currentIndex]
    CORE.Charcreator.LastCameraPos = ""
    CORE.Charcreator:ChangeCameraPosition(CORE.Charcreator.CameraPos)
end)

RegisterNetEvent("kCharcreator:UI:charcreator:changeCategory", function(data)
    if not data or not data.tab then return end

    local cameraForTab = { [0] = "face", [1] = "top", [2] = "full_body" }
    local newCamera = cameraForTab[data.tab]

    if newCamera then
        CORE.Charcreator.CameraPos = newCamera
        CORE.Charcreator:ChangeCameraPosition(newCamera)
    end
end)