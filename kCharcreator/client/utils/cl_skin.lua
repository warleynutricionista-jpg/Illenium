CORE = CORE or {}
CORE.Skin = CORE.Skin or {}
CORE.Skin.Config = CORE.Skin.Config or {}

function CORE.Skin.IsPedFreemode(ped)
    local pPed = ped or PlayerPedId()
    return IsPedModel(pPed, GetHashKey("mp_m_freemode_01")) or
               IsPedModel(pPed, GetHashKey("mp_f_freemode_01"))
end
exports('IsPedFreemode', CORE.Skin.IsPedFreemode)

function CORE.Skin.IsMale(ped)
    local pPed = ped or PlayerPedId()
    return IsPedModel(pPed, GetHashKey("mp_m_freemode_01"))
end
exports('IsMale', CORE.Skin.IsMale)

function CORE.Skin.IsFemale(ped)
    local pPed = ped or PlayerPedId()
    return IsPedModel(pPed, GetHashKey("mp_f_freemode_01"))
end
exports('IsFemale', CORE.Skin.IsFemale)

function CORE.Skin.GetSex(ped)
    ped = ped or PlayerPedId()
    for k, v in pairs(CORE.Skin.Config.peds["males"]) do
        if IsPedModel(ped, GetHashKey(v)) then return v end
    end
    for k, v in pairs(CORE.Skin.Config.peds["females"]) do
        if IsPedModel(ped, GetHashKey(v)) then return v end
    end
end
exports('GetSex', CORE.Skin.GetSex)

function CORE.Skin.IsModelExist(model)
    for k, v in pairs(CORE.Skin.Config.peds["males"]) do
        if v == model then return true end
    end
    for k, v in pairs(CORE.Skin.Config.peds["females"]) do
        if v == model then return true end
    end

    return false
end
exports('IsModelExist', CORE.Skin.IsModelExist)

local function GetHeadBlend(ped)
    if DoesEntityExist(ped) and IsEntityAPed(ped) then
        if HasPedHeadBlendFinished(ped) then
            local data = {}

            -- natives FiveM
            local success,
                shapeFirstID,
                shapeSecondID,
                shapeThirdID,
                skinFirstID,
                skinSecondID,
                skinThirdID,
                shapeMix,
                skinMix,
                thirdMix = GetPedHeadBlendData(ped)

            if success then
                data = {
                    shapeFirstID = shapeFirstID,
                    shapeSecondID = shapeSecondID,
                    shapeThirdID = shapeThirdID,
                    skinFirstID  = skinFirstID,
                    skinSecondID = skinSecondID,
                    skinThirdID  = skinThirdID,
                    shapeMix     = shapeMix,
                    skinMix      = skinMix,
                    thirdMix     = thirdMix
                }
            end

            return data
        end
    end

    -- équivalent de "new PedHeadBlendData()"
    return {
        shapeFirstID = 0,
        shapeSecondID = 0,
        shapeThirdID = 0,
        skinFirstID = 0,
        skinSecondID = 0,
        skinThirdID = 0,
        shapeMix = 0.0,
        skinMix = 0.0,
        thirdMix = 0.0
    }
end

function CORE.Skin.GetSkin(ped, save)
    ped = ped or PlayerPedId()

    local headblendData = GetHeadBlend(ped)

    local skin = {
        sex = CORE.Skin.GetSex(ped),
        face2 = GetPedDrawableVariation(ped, 0),
        face2_text = GetPedTextureVariation(ped, 0),
        masks = GetPedDrawableVariation(ped, 1),
        masks_text = GetPedTextureVariation(ped, 1),
        hair = GetPedDrawableVariation(ped, 2),
        hair_text = GetPedTextureVariation(ped, 2),
        hair_color = GetPedHairColor(ped),
        hair_highlight = GetPedHairHighlightColor(ped),
        torsos = GetPedDrawableVariation(ped, 3),
        torsos_text = GetPedTextureVariation(ped, 3),
        legs = GetPedDrawableVariation(ped, 4),
        legs_text = GetPedTextureVariation(ped, 4),
        bagsandparachutes = GetPedDrawableVariation(ped, 5),
        bagsandparachutes_text = GetPedTextureVariation(ped, 5),
        shoes = GetPedDrawableVariation(ped, 6),
        shoes_text = GetPedTextureVariation(ped, 6),
        accessories = GetPedDrawableVariation(ped, 7),
        accessories_text = GetPedTextureVariation(ped, 7),
        undershirts = GetPedDrawableVariation(ped, 8),
        undershirts_text = GetPedTextureVariation(ped, 8),
        bodyarmors = GetPedDrawableVariation(ped, 9),
        bodyarmors_text = GetPedTextureVariation(ped, 9),
        decals = GetPedDrawableVariation(ped, 10),
        decals_text = GetPedTextureVariation(ped, 10),
        tops = GetPedDrawableVariation(ped, 11),
        tops_text = GetPedTextureVariation(ped, 11),
        hats = GetPedPropIndex(ped, 0),
        hats_text = GetPedPropTextureIndex(ped, 0),
        glasses = GetPedPropIndex(ped, 1),
        glasses_text = GetPedPropTextureIndex(ped, 1),
        ears = GetPedPropIndex(ped, 2),
        ears_text = GetPedPropTextureIndex(ped, 2),
        watches = GetPedPropIndex(ped, 6),
        watches_text = GetPedPropTextureIndex(ped, 6),
        bracelets = GetPedPropIndex(ped, 7),
        bracelets_text = GetPedPropTextureIndex(ped, 7),
        face = {
            headblendData = {
                face_one = headblendData.shapeFirstID,
                skin_one = headblendData.skinFirstID,
                face_two = headblendData.shapeSecondID,
                skin_two = headblendData.skinSecondID,
                face_three = headblendData.shapeThirdID,
                skin_three = headblendData.skinThirdID,
                face_mix = headblendData.shapeMix,
                skin_mix = headblendData.skinMix,
                third_mix = headblendData.thirdMix
            },
            nose_width = GetPedFaceFeature(ped, 0),
            nose_peak_height = GetPedFaceFeature(ped, 1),
            nose_peak_length = GetPedFaceFeature(ped, 2),
            nose_bone_high = GetPedFaceFeature(ped, 3),
            nose_peak_lowering = GetPedFaceFeature(ped, 4),
            nose_bone_twist = GetPedFaceFeature(ped, 5),
            eyebrow_high = GetPedFaceFeature(ped, 6),
            eyebrow_forward = GetPedFaceFeature(ped, 7),
            cheeks_bone_high = GetPedFaceFeature(ped, 8),
            cheeks_bone_width = GetPedFaceFeature(ped, 9),
            cheeks_width = GetPedFaceFeature(ped, 10),
            eyes_opening = GetPedFaceFeature(ped, 11),
            lips_thickness = GetPedFaceFeature(ped, 12),
            jaw_bone_width = GetPedFaceFeature(ped, 13),
            jaw_bone_back_length = GetPedFaceFeature(ped, 14),
            chimp_bone_lowering = GetPedFaceFeature(ped, 15),
            chimp_bone_length = GetPedFaceFeature(ped, 16),
            chimp_bone_width = GetPedFaceFeature(ped, 17),
            chimp_hole = GetPedFaceFeature(ped, 18),
            neck_thickness = GetPedFaceFeature(ped, 19),
            eye_color = GetPedEyeColor(ped)
        },
        overlays = CORE.Skin.GetOverlays(ped)
    }

    if save then
        TriggerServerEvent("CORE.UI:charcreator:save_character", {skin = skin})
    end
    return skin
end
exports('GetSkin', CORE.Skin.GetSkin)

function CORE.Skin.SetSkin(table, ped, change_face)
    if not table then return end
    ped = ped or PlayerPedId()
    ped = ped == PlayerPedId() and CORE.Skin.SetPlayerModel(table.sex, ped) or
              ped

    while not ped do
        print("Wait player model")
        Wait(100)
    end

    ClearPedDecorations(ped)
    ClearPedFacialDecorations(ped)
    SetPedDefaultComponentVariation(ped)
    SetPedHairColor(ped, 0, 0)
    SetPedEyeColor(ped, 0)
    ClearAllPedProps(ped)

    if CORE.Skin.IsPedFreemode(ped) and change_face then
        SetPedHeadBlendData(ped, table.face.headblendData.face_one,
                            table.face.headblendData.face_two,
                            table.face.headblendData.face_three,
                            table.face.headblendData.skin_one,
                            table.face.headblendData.skin_two,
                            table.face.headblendData.skin_three,
                            table.face.headblendData.face_mix,
                            table.face.headblendData.skin_mix,
                            table.face.headblendData.third_mix, false)
        while not HasPedHeadBlendFinished(ped) do Wait(0) end
    end
    SetPedFaceFeature(ped, 0, table.face.nose_width)
    SetPedFaceFeature(ped, 1, table.face.nose_peak_height)
    SetPedFaceFeature(ped, 2, table.face.nose_peak_length)
    SetPedFaceFeature(ped, 3, table.face.nose_bone_high)
    SetPedFaceFeature(ped, 4, table.face.nose_peak_lowering)
    SetPedFaceFeature(ped, 5, table.face.nose_bone_twist)
    SetPedFaceFeature(ped, 6, table.face.eyebrow_high)
    SetPedFaceFeature(ped, 7, table.face.eyebrow_forward)
    SetPedFaceFeature(ped, 8, table.face.cheeks_bone_high)
    SetPedFaceFeature(ped, 9, table.face.cheeks_bone_width)
    SetPedFaceFeature(ped, 10, table.face.cheeks_width)
    SetPedFaceFeature(ped, 11, table.face.eyes_opening)
    SetPedFaceFeature(ped, 12, table.face.lips_thickness)
    SetPedFaceFeature(ped, 13, table.face.jaw_bone_width)
    SetPedFaceFeature(ped, 14, table.face.jaw_bone_back_length)
    SetPedFaceFeature(ped, 15, table.face.chimp_bone_lowering)
    SetPedFaceFeature(ped, 16, table.face.chimp_bone_length)
    SetPedFaceFeature(ped, 17, table.face.chimp_bone_width)
    SetPedFaceFeature(ped, 18, table.face.chimp_hole)
    SetPedFaceFeature(ped, 19, table.face.neck_thickness)

    -- Hair
    SetPedComponentVariation(ped, 2, table.hair, 0, 0)
    SetPedHairColor(ped, table.hair_color, table.hair_highlight)
    -- blemishes
    SetPedHeadOverlay(ped, 0, table.overlays["0"].overlayValue,
                      table.overlays["0"].overlayOpacity - 0.01)
    -- beard
    SetPedHeadOverlay(ped, 1, table.overlays["1"].overlayValue,
                      table.overlays["1"].overlayOpacity - 0.01)
    SetPedHeadOverlayColor(ped, 1, 1, table.overlays["1"].firstColour,
                           table.overlays["1"].firstColour)
    -- eyebrows
    SetPedHeadOverlay(ped, 2, table.overlays["2"].overlayValue,
                      table.overlays["2"].overlayOpacity - 0.01)
    SetPedHeadOverlayColor(ped, 2, 1, table.overlays["2"].firstColour,
                           table.overlays["2"].firstColour)
    -- ageing
    SetPedHeadOverlay(ped, 3, table.overlays["3"].overlayValue,
                      table.overlays["3"].overlayOpacity - 0.01)
    -- makeup
    SetPedHeadOverlay(ped, 4, table.overlays["4"].overlayValue,
                      table.overlays["4"].overlayOpacity - 0.01)
    SetPedHeadOverlayColor(ped, 4, 1, table.overlays["4"].firstColour,
                           table.overlays["4"].secondColour)
    -- blush
    SetPedHeadOverlay(ped, 5, table.overlays["5"].overlayValue,
                      table.overlays["5"].overlayOpacity - 0.01)
    SetPedHeadOverlayColor(ped, 5, 1, table.overlays["5"].firstColour,
                           table.overlays["5"].firstColour)
    -- complexion
    SetPedHeadOverlay(ped, 6, table.overlays["6"].overlayValue,
                      table.overlays["6"].overlayOpacity - 0.01)
    -- sundamage
    SetPedHeadOverlay(ped, 7, table.overlays["7"].overlayValue,
                      table.overlays["7"].overlayOpacity - 0.01)
    -- lipstick
    SetPedHeadOverlay(ped, 8, table.overlays["8"].overlayValue,
                      table.overlays["8"].overlayOpacity - 0.01)
    SetPedHeadOverlayColor(ped, 8, 1, table.overlays["8"].firstColour,
                           table.overlays["8"].secondColour)
    -- moles and freckles
    SetPedHeadOverlay(ped, 9, table.overlays["9"].overlayValue,
                      table.overlays["9"].overlayOpacity - 0.01)
    -- chest hair 
    SetPedHeadOverlay(ped, 10, table.overlays["10"].overlayValue,
                      table.overlays["10"].overlayOpacity - 0.01)
    SetPedHeadOverlayColor(ped, 10, 1, table.overlays["10"].firstColour,
                           table.overlays["10"].firstColour)
    -- body blemishes 
    SetPedHeadOverlay(ped, 11, table.overlays["11"].overlayValue,
                      table.overlays["11"].overlayOpacity - 0.01)
    -- eyecolor
    SetPedEyeColor(ped, table.face.eye_color)

    CORE.Skin.SetComponentById(ped, 0, table.face2, table.face2_text)
    CORE.Skin.SetComponentById(ped, 1, table.masks, table.masks_text)
    CORE.Skin.SetComponentById(ped, 3, table.torsos, table.torsos_text)
    CORE.Skin.SetComponentById(ped, 4, table.legs, table.legs_text)
    CORE.Skin.SetComponentById(ped, 5, table.bagsandparachutes,
                               table.bagsandparachutes_text)
    CORE.Skin.SetComponentById(ped, 6, table.shoes, table.shoes_text)
    CORE.Skin.SetComponentById(ped, 7, table.accessories, table.accessories_text)
    CORE.Skin.SetComponentById(ped, 8, table.undershirts, table.undershirts_text)
    CORE.Skin.SetComponentById(ped, 9, table.bodyarmors, table.bodyarmors_text)
    CORE.Skin.SetComponentById(ped, 10, table.decals, table.decals_text)
    CORE.Skin.SetComponentById(ped, 11, table.tops, table.tops_text)

    CORE.Skin.SetPropById(ped, 0, table.hats, table.hats_text)
    CORE.Skin.SetPropById(ped, 1, table.glasses, table.glasses_text)
    CORE.Skin.SetPropById(ped, 2, table.ears, table.ears_text)
    CORE.Skin.SetPropById(ped, 6, table.watches, table.watches_text)
    CORE.Skin.SetPropById(ped, 7, table.bracelets, table.bracelets_text)

    return ped
end
exports('SetSkin', CORE.Skin.SetSkin)

function CORE.Skin.ChangeClothes(table, ped)
    ped = ped or PlayerPedId()
    if table.masks then
        CORE.Skin.SetComponentById(ped, 1, table.masks, table.masks_text)
    end
    if table.hair then SetPedComponentVariation(ped, 2, table.hair, 0, 0) end
    if table.torsos then
        CORE.Skin.SetComponentById(ped, 3, table.torsos, table.torsos_text)
    end
    if table.legs then
        CORE.Skin.SetComponentById(ped, 4, table.legs, table.legs_text)
    end
    if table.bagsandparachutes then
        CORE.Skin.SetComponentById(ped, 5, table.bagsandparachutes,
                                   table.bagsandparachutes_text)
    end
    if table.shoes then
        CORE.Skin.SetComponentById(ped, 6, table.shoes, table.shoes_text)
    end
    if table.accessories then
        CORE.Skin.SetComponentById(ped, 7, table.accessories,
                                   table.accessories_text)
    end
    if table.undershirts then
        CORE.Skin.SetComponentById(ped, 8, table.undershirts,
                                   table.undershirts_text)
    end
    if table.bodyarmors then
        CORE.Skin.SetComponentById(ped, 9, table.bodyarmors,
                                   table.bodyarmors_text)
    end
    if table.decals then
        CORE.Skin.SetComponentById(ped, 10, table.decals, table.decals_text)
    end
    if table.tops then
        CORE.Skin.SetComponentById(ped, 11, table.tops, table.tops_text)
    end
    if table.hats then
        CORE.Skin.SetPropById(ped, 0, table.hats, table.hats_text)
    end
    if table.glasses then
        CORE.Skin.SetPropById(ped, 1, table.glasses, table.glasses_text)
    end
    if table.ears then
        CORE.Skin.SetPropById(ped, 2, table.ears, table.ears_text)
    end
    if table.watches then
        CORE.Skin.SetPropById(ped, 6, table.watches, table.watches_text)
    end
    if table.bracelets then
        CORE.Skin.SetPropById(ped, 7, table.bracelets, table.bracelets_text)
    end
end
exports('ChangeClothes', CORE.Skin.ChangeClothes)

function CORE.Skin.GetOverlays(ped)
    local pPed = ped or PlayerPedId()
    local overlays = {}
    for i = 0, 12 do
        local success, overlayValue, colourType, firstColour, secondColour,
              overlayOpacity = GetPedHeadOverlayData(pPed, i)
        overlays["" .. i .. ""] = {
            success = success,
            overlayValue = overlayValue,
            colourType = colourType,
            firstColour = firstColour,
            secondColour = secondColour,
            overlayOpacity = overlayOpacity
        }
    end
    return overlays
end
exports('GetOverlays', CORE.Skin.GetOverlays)

function CORE.Skin.SetComponentById(ped, componentId, drawableId, textureId)
    ped = ped or PlayerPedId()
    drawableId = tonumber(drawableId) or -1
    if drawableId == -1 then
        if CORE.Skin.IsMale(ped) then
            if CORE.Skin.Config.default_clothes[componentId] ~= nil then
                SetPedComponentVariation(ped, componentId, CORE.Skin.Config
                                             .default_clothes[componentId].male,
                                         0, 0)
            else
                print('Component ID: ' .. componentId ..
                          ' not found in default clothes')
            end
        else
            if CORE.Skin.Config.default_clothes[componentId] ~= nil then
                SetPedComponentVariation(ped, componentId, CORE.Skin.Config
                                             .default_clothes[componentId]
                                             .female, 0, 0)
            else
                print('Component ID: ' .. componentId ..
                          ' not found in default clothes')
            end
        end
    else
        textureId = tonumber(textureId)
        SetPedComponentVariation(ped, componentId, drawableId, textureId, 0)
    end
end
exports('SetComponentById', CORE.Skin.SetComponentById)

function CORE.Skin.SetPropById(ped, propId, drawableId, textureId, attach)
    ped = ped or PlayerPedId()
    drawableId = tonumber(drawableId)
    if drawableId == -1 then
        ClearPedProp(ped, propId)
    else
        textureId = tonumber(textureId)
        SetPedPropIndex(ped, propId, drawableId, textureId, attach or true)
    end
end
exports('SetPropById', CORE.Skin.SetPropById)

function CORE.Skin.GetComponentById(ped, componentId)
    ped = ped or PlayerPedId()
    local drawableId, textureId = GetPedDrawableVariation(ped, componentId),
                                  GetPedTextureVariation(ped, componentId)
    return drawableId, textureId
end
exports('GetComponentById', CORE.Skin.GetComponentById)

function CORE.Skin.GetPropById(ped, propId)
    ped = ped or PlayerPedId()
    local drawableId, textureId = GetPedPropIndex(ped, propId),
                                  GetPedPropTextureIndex(ped, propId)
    return drawableId, textureId
end
exports('GetPropById', CORE.Skin.GetPropById)

-- Apply naked clothes to a freemode ped
function CORE.Skin.ApplyNakedClothes(ped)
    ped = ped or PlayerPedId()
    local isMale = CORE.Skin.IsMale(ped)
    local naked = isMale and CORE.Skin.Config.nakeds.male or CORE.Skin.Config.nakeds.female

    -- Components: 1=masks, 3=torsos, 4=legs, 5=bags, 6=shoes, 7=accessories, 8=undershirts, 9=armor, 11=tops
    SetPedComponentVariation(ped, 1, naked.masks == -1 and 0 or naked.masks, naked.masks_text, 0)
    SetPedComponentVariation(ped, 3, naked.torsos, naked.torsos_text, 0)
    SetPedComponentVariation(ped, 4, naked.legs, naked.legs_text, 0)
    SetPedComponentVariation(ped, 5, naked.bagsandparachutes, naked.bagsandparachutes_text, 0)
    SetPedComponentVariation(ped, 6, naked.shoes, naked.shoes_text, 0)
    SetPedComponentVariation(ped, 7, naked.accessories == -1 and 0 or naked.accessories, naked.accessories_text, 0)
    SetPedComponentVariation(ped, 8, naked.undershirts, naked.undershirts_text, 0)
    SetPedComponentVariation(ped, 9, naked.bodyarmors, naked.bodyarmors_text, 0)
    SetPedComponentVariation(ped, 11, naked.tops, naked.tops_text, 0)

    -- Props: 0=hats, 1=glasses, 2=ears, 6=watches, 7=bracelets
    if naked.hats == -1 then ClearPedProp(ped, 0) else SetPedPropIndex(ped, 0, naked.hats, naked.hats_text, true) end
    if naked.glasses == -1 then ClearPedProp(ped, 1) else SetPedPropIndex(ped, 1, naked.glasses, naked.glasses_text, true) end
    if naked.ears == -1 then ClearPedProp(ped, 2) else SetPedPropIndex(ped, 2, naked.ears, naked.ears_text, true) end
    if naked.watches == -1 then ClearPedProp(ped, 6) else SetPedPropIndex(ped, 6, naked.watches, naked.watches_text, true) end
    if naked.bracelets == -1 then ClearPedProp(ped, 7) else SetPedPropIndex(ped, 7, naked.bracelets, naked.bracelets_text, true) end
end

function CORE.Skin.SetPlayerModel(model, ped, applyNaked)
    local ped = ped or PlayerPedId()
    model = model or "mp_m_freemode_01"
    if model then
        print("Set Player Model: " .. model)

        local newModel = GetHashKey(model)
        RequestModel(newModel)
        while not HasModelLoaded(newModel) do
            RequestModel(newModel)
            Citizen.Wait(0)
        end

        if not IsModelInCdimage(newModel) or not IsModelValid(newModel) then
            model = "mp_m_freemode_01"
        end
        if IsPedModel(ped, newModel) then return PlayerPedId() end
        SetPlayerModel(PlayerId(), newModel)
        while not IsPedModel(PlayerPedId(), newModel) do
            SetPlayerModel(PlayerId(), newModel)
            Wait(100)
        end

        local newPed = PlayerPedId()
        SetPedDefaultComponentVariation(newPed)
        SetModelAsNoLongerNeeded(newModel)
        SetEntityVisible(newPed, true)

        -- Apply naked clothes for freemode peds
        if applyNaked and (model == "mp_m_freemode_01" or model == "mp_f_freemode_01") then
            CORE.Skin.ApplyNakedClothes(newPed)
        end

        return newPed
    end

    return PlayerPedId()
end
exports('SetPlayerModel', CORE.Skin.SetPlayerModel)