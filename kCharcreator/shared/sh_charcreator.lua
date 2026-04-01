--[[
    ██╗  ██╗ ██████╗██╗  ██╗ █████╗ ██████╗  ██████╗██████╗ ███████╗ █████╗ ████████╗ ██████╗ ██████╗
    ██║ ██╔╝██╔════╝██║  ██║██╔══██╗██╔══██╗██╔════╝██╔══██╗██╔════╝██╔══██╗╚══██╔══╝██╔═══██╗██╔══██╗
    █████╔╝ ██║     ███████║███████║██████╔╝██║     ██████╔╝█████╗  ███████║   ██║   ██║   ██║██████╔╝
    ██╔═██╗ ██║     ██╔══██║██╔══██║██╔══██╗██║     ██╔══██╗██╔══╝  ██╔══██║   ██║   ██║   ██║██╔══██╗
    ██║  ██╗╚██████╗██║  ██║██║  ██║██║  ██║╚██████╗██║  ██║███████╗██║  ██║   ██║   ╚██████╔╝██║  ██║
    ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝

    Configuration File
    For translations, edit files in: locales/
]]

CORE = CORE or {}
CORE.Charcreator = CORE.Charcreator or {}
CORE.Charcreator.Config = CORE.Charcreator.Config or {}

CORE.Charcreator.Config = {

    ----------------------------------------------------------------
    -- FRAMEWORK
    ----------------------------------------------------------------
    -- Options: "auto", "esx", "qbcore", "qbox", "standalone"
    Framework = "auto",

    ----------------------------------------------------------------
    -- LANGUAGE
    ----------------------------------------------------------------
    -- Available: "en", "fr" (add more in locales/ folder)
    lang = "en",

    ----------------------------------------------------------------
    -- AUTO OPEN
    ----------------------------------------------------------------
    -- true  = Open character creator for new players (no saved skin)
    -- false = Only open via /charcreator command
    autoOpen = true,

    ----------------------------------------------------------------
    -- AUTO LOAD SKIN
    ----------------------------------------------------------------
    -- Automatically load player skin on connection
    autoloadskin = false,

    ----------------------------------------------------------------
    -- DEFAULT PEDS
    ----------------------------------------------------------------
    -- Ped loaded based on player sex from database (identity)
    defaultPedMale   = "mp_m_freemode_01",
    defaultPedFemale = "mp_f_freemode_01",

    ----------------------------------------------------------------
    -- THEME
    ----------------------------------------------------------------
    -- Presets: "gold", "blue", "purple", "green", "red"
    -- Or use custom HEX: "#FF5500"
    color = "gold",

    -- Glass panel background (CSS rgba value)
    backgroundGlass = "rgba(20, 20, 20, 0.5)",

    ----------------------------------------------------------------
    -- POSITIONS
    ----------------------------------------------------------------
    -- Where player spawns during character creation
    player_position = vec4(-617.43, 55.64, 101.82-0.98, 1.0),

    -- Where player spawns after finishing character creation
    spawn_position = vec4(-1037.0, -2737.0, 20.0, 332.0),

    ----------------------------------------------------------------
    -- CAMERAS
    ----------------------------------------------------------------
    cameras = {
        face      = { distance = 0.85, height = 0.7, fov = 30.0 },
        top       = { distance = 1.0,  height = 0.2,  fov = 50.0 },
        body      = { distance = 1.5,  height = 0.0,  fov = 50.0 },
        full_body = { distance = 2.0,  height = 0.0,  fov = 60.0 },
        shoes     = { distance = 1.2,  height = -0.7, fov = 40.0 }
    },

    ----------------------------------------------------------------
    -- ZOOM
    ----------------------------------------------------------------
    zoom = {
        min   = 0.5,   -- Closest
        max   = 2.8,   -- Farthest
        speed = 0.15   -- Scroll speed
    },

    ----------------------------------------------------------------
    -- MUSIC PLAYER
    ----------------------------------------------------------------
    music = {
        enabled  = true,  -- Enable/disable music player
        autoplay = true,  -- Auto start when creator opens
        volume   = 0.1,  -- Default volume (0.0 - 1.0)

        playlist = {
            {
                id       = 1,
                title    = "Blinding Lights",
                artist   = "The Weeknd",
                coverUrl = "nui://kCharcreator/web/build/images/music/theweeknd.webp", -- nui://kCharcreator/web/build/images/music/cover1.svg
                audioUrl = "nui://kCharcreator/web/build/images/music/blindinglights.mp3" -- nui://kCharcreator/web/build/images/music/cover1.svg
            }
        }
    },

    ----------------------------------------------------------------
    -- EVENTS (Advanced)
    ----------------------------------------------------------------
    -- Events triggered before character creator opens
    event_before_open = {
        -- "your:event:here"
    },

    -- Events triggered after character is saved
    event_after_spawn = {
        -- "your:event:here"
    }
}

----------------------------------------------------------------
-- LOCALE HELPER FUNCTION
----------------------------------------------------------------
function L(key)
    local lang = CORE.Charcreator.Config.lang or "en"
    local locale = CORE.Charcreator.Locale and CORE.Charcreator.Locale[lang]

    if locale and locale[key] then
        return locale[key]
    end

    -- Fallback to English
    if CORE.Charcreator.Locale and CORE.Charcreator.Locale["en"] and CORE.Charcreator.Locale["en"][key] then
        return CORE.Charcreator.Locale["en"][key]
    end

    return key
end
