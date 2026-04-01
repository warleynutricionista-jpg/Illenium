CORE = CORE or {}
CORE.Identity = CORE.Identity or {}
CORE.Identity.Config = CORE.Identity.Config or {}

CORE.Identity.Config = {
    Framework = "auto",

    lang = "en",

    autoOpen = false,

    characterCreator = "kCharcreator",

    characterCreatorEvent = nil,

    supportedCreators = {
        "kCharcreator",
        "qb-clothing",
        "illenium-appearance",
        "fivem-appearance",
        "esx_skin"
    },

    defaultPedMale = "mp_m_freemode_01",
    defaultPedFemale = "mp_f_freemode_01",

    camera = {
        distance = 2.0,
        height   = -0.5,
        fov      = 60.0,
    },

    color = "gold",

    backgroundGlass = "rgba(20, 20, 20, 0.5)",

    minYear = 1950,
    maxYear = 2005,

    nationalities = {
        { id = 0,  name = "American" },
        { id = 1,  name = "French" },
        { id = 2,  name = "German" },
        { id = 3,  name = "British" },
        { id = 4,  name = "Spanish" },
        { id = 5,  name = "Italian" },
        { id = 6,  name = "Russian" },
        { id = 7,  name = "Chinese" },
        { id = 8,  name = "Japanese" },
        { id = 9,  name = "Korean" },
        { id = 10, name = "Brazilian" },
        { id = 11, name = "Mexican" },
        { id = 12, name = "Canadian" },
        { id = 13, name = "Australian" },
        { id = 14, name = "Indian" },
    },

    player_position = vec4(-811.872498, 175.160446, 76.72888, 113.75),

    spawn_position = vec4(-1037.0, -2737.0, 20.0, 332.0),

    music = {
        enabled  = true,
        autoplay = true,
        volume   = 0.25,

        playlist = {
            {
                id       = 1,
                title    = "Chill Vibes",
                artist   = "LoFi Producer",
                coverUrl = "nui://kIdentity/web/build/images/music/cover1.svg",
                audioUrl = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3"
            },
            {
                id       = 2,
                title    = "Night Drive",
                artist   = "Synthwave Artist",
                coverUrl = "nui://kIdentity/web/build/images/music/cover2.svg",
                audioUrl = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3"
            },
            {
                id       = 3,
                title    = "Urban Flow",
                artist   = "Beat Maker",
                coverUrl = "nui://kIdentity/web/build/images/music/cover3.svg",
                audioUrl = "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3"
            },
        }
    },
}

function L(key)
    local lang = CORE.Identity.Config.lang or "en"
    local locale = CORE.Identity.Locale and CORE.Identity.Locale[lang]

    if locale and locale[key] then
        return locale[key]
    end

    if CORE.Identity.Locale and CORE.Identity.Locale["en"] and CORE.Identity.Locale["en"][key] then
        return CORE.Identity.Locale["en"][key]
    end

    return key
end

function CORE.Identity.GetNUIConfig()
    local lang = CORE.Identity.Config.lang or "en"
    local locale = CORE.Identity.Locale and CORE.Identity.Locale[lang]
    if not locale then
        locale = CORE.Identity.Locale and CORE.Identity.Locale["en"] or {}
    end

    local nationalities = {}
    for _, nat in ipairs(CORE.Identity.Config.nationalities) do
        local translatedName = locale.NATIONALITIES and locale.NATIONALITIES[nat.id] or nat.name
        table.insert(nationalities, { id = nat.id, name = translatedName })
    end

    return {
        labels = {
            title = locale.TITLE or "Register Character",
            sections = {
                name        = locale.SECTION_NAME or "First & Last Name",
                dateOfBirth = locale.SECTION_DOB or "Date of Birth",
                nationality = locale.SECTION_NATIONALITY or "Nationality",
                gender      = locale.SECTION_GENDER or "Gender",
            },
            descriptions = {
                name        = locale.DESC_NAME or "",
                dateOfBirth = locale.DESC_DOB or "",
                nationality = locale.DESC_NATIONALITY or "",
                gender      = locale.DESC_GENDER or "",
            },
            fields = {
                firstName = locale.FIRST_NAME or "First Name",
                lastName  = locale.LAST_NAME or "Last Name",
            },
            gender = {
                male   = locale.MALE or "Male",
                female = locale.FEMALE or "Female",
            },
            buttons = {
                random = locale.RANDOM or "Random",
                create = locale.CREATE or "Create Character",
                cancel = locale.CANCEL or "Cancel",
            },
        },
        nationalities = nationalities,
        monthNames    = locale.MONTHS or {
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"
        },
        minYear = CORE.Identity.Config.minYear,
        maxYear = CORE.Identity.Config.maxYear,
        music   = CORE.Identity.Config.music,
    }
end
