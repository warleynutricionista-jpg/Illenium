# kCharcreator

> **FR** | [EN](#english)

---

## Francais

### Description

**kCharcreator** est un systeme complet de creation de personnage pour FiveM avec une interface moderne en React/TypeScript. Il remplace les character creators par defaut (esx_skin, skinchanger, qb-clothing) et supporte plusieurs frameworks.

### Fonctionnalites

- Personnalisation complete : visage, cheveux, maquillage, vetements, accessoires
- Interface moderne avec apercu en temps reel
- 5 vues camera (visage, haut, corps, corps entier, chaussures) avec zoom
- Lecteur de musique integre
- 8 langues supportees (EN, FR, DE, ES, PT, RU, HR, AR)
- Themes personnalisables (gold, blue, purple, green, red ou HEX custom)
- Compatible ESX / QBCore / QBox / Standalone
- Detection automatique du framework

### Pre-requis

- [oxmysql](https://github.com/overextended/oxmysql) (obligatoire)

### Installation

#### 1. Telecharger et placer la resource

Placez le dossier `kCharcreator` dans votre dossier `resources`.

#### 2. Configurer `server.cfg`

Ajoutez `ensure kCharcreator` dans votre `server.cfg` **apres** votre framework et ses dependances.

**ESX seul :**
```cfg
ensure oxmysql
ensure es_extended
ensure kCharcreator
```

**ESX + esx_identity + esx_multicharacter :**
```cfg
ensure oxmysql
ensure es_extended
ensure esx_multicharacter
ensure esx_identity
ensure kCharcreator   # EN DERNIER
```

**QBCore :**
```cfg
ensure oxmysql
ensure qb-core
ensure kCharcreator
```

**QBCore + qb-multicharacter :**
```cfg
ensure oxmysql
ensure qb-core
ensure qb-multicharacter
ensure kCharcreator
```

**QBox :**
```cfg
ensure oxmysql
ensure qbx_core
ensure kCharcreator
```

**Standalone :**
```cfg
ensure oxmysql
ensure kCharcreator
```

#### 3. Base de donnees

- **ESX** : utilise la colonne `skin` de la table `users` (deja existante)
- **QBCore / QBox** : utilise la table `playerskins` (deja existante)
- **Standalone** : executez le fichier `install.sql` dans votre base de donnees

#### 4. Desactiver les scripts en conflit

Commentez ou supprimez les anciens scripts de skin dans votre `server.cfg` :
```cfg
# ensure esx_skin
# ensure skinchanger
# ensure qb-clothing
```

Si vous utilisez **esx_identity**, ajoutez dans sa config :
```lua
Config.EnableSkin = false
```

Si vous utilisez **esx_multicharacter** :
```lua
Config.Skin = false
```

Si vous utilisez **qb-multicharacter** :
```lua
Config.EnableClothing = false
```

#### 5. Configuration

Editez le fichier `shared/sh_charcreator.lua` :

```lua
CORE.Charcreator.Config = {
    Framework = "auto",          -- "auto", "esx", "qbcore", "qbox", "standalone"
    lang = "fr",                 -- "en", "fr", "de", "es", "pt", "ru", "hr", "ar"
    autoOpen = true,             -- Ouvrir auto pour les nouveaux joueurs
    autoloadskin = true,         -- Charger le skin auto a la connexion
    color = "gold",              -- "gold", "blue", "purple", "green", "red" ou "#HEX"
    player_position = vec4(...), -- Position pendant la creation
    spawn_position = vec4(...),  -- Position apres la creation
}
```

#### 6. Demarrer le serveur

C'est pret ! Le character creator s'ouvrira automatiquement pour les nouveaux joueurs.

### Commandes

| Commande | Description |
|----------|-------------|
| `/charcreator` | Ouvrir le character creator manuellement |

### Exports

```lua
-- Verifications
exports.kCharcreator:IsPedFreemode(ped)
exports.kCharcreator:IsMale(ped)
exports.kCharcreator:IsFemale(ped)
exports.kCharcreator:GetSex(ped)

-- Gestion du skin
exports.kCharcreator:GetSkin(ped, save)
exports.kCharcreator:SetSkin(skinTable, ped, changeFace)
exports.kCharcreator:ChangeClothes(clothesTable, ped)

-- Composants et accessoires
exports.kCharcreator:SetComponentById(ped, componentId, drawableId, textureId)
exports.kCharcreator:GetComponentById(ped, componentId)
exports.kCharcreator:SetPropById(ped, propId, drawableId, textureId)
exports.kCharcreator:GetPropById(ped, propId)

-- Modele
exports.kCharcreator:SetPlayerModel(model, ped, applyNaked)
```

### Events

```lua
-- Ouvrir le character creator depuis un autre script
TriggerEvent("CORE.Charcreator:Open")

-- Hooks dans la config
event_before_open = { "votre:event:ici" }
event_after_spawn = { "votre:event:ici" }
```

### Depannage

| Probleme | Solution |
|----------|----------|
| Le creator ne s'ouvre pas | Verifiez l'ordre dans `server.cfg` et que `autoOpen = true` |
| Le skin ne se sauvegarde pas | Verifiez que oxmysql fonctionne et que la table/colonne existe |
| Conflit avec d'autres scripts | Desactivez esx_skin, skinchanger, qb-clothing |
| S'ouvre avant esx_identity | esx_identity doit etre **avant** kCharcreator dans server.cfg |

---

## English

### Description

**kCharcreator** is a complete character creation system for FiveM with a modern React/TypeScript UI. It replaces default character creators (esx_skin, skinchanger, qb-clothing) and supports multiple frameworks.

### Features

- Full customization: face, hair, makeup, clothing, accessories
- Modern UI with real-time preview
- 5 camera views (face, top, body, full body, shoes) with zoom
- Built-in music player
- 8 languages supported (EN, FR, DE, ES, PT, RU, HR, AR)
- Customizable themes (gold, blue, purple, green, red or custom HEX)
- Compatible with ESX / QBCore / QBox / Standalone
- Automatic framework detection

### Requirements

- [oxmysql](https://github.com/overextended/oxmysql) (required)

### Installation

#### 1. Download and place the resource

Place the `kCharcreator` folder in your `resources` directory.

#### 2. Configure `server.cfg`

Add `ensure kCharcreator` in your `server.cfg` **after** your framework and its dependencies.

**ESX only:**
```cfg
ensure oxmysql
ensure es_extended
ensure kCharcreator
```

**ESX + esx_identity + esx_multicharacter:**
```cfg
ensure oxmysql
ensure es_extended
ensure esx_multicharacter
ensure esx_identity
ensure kCharcreator   # LAST
```

**QBCore:**
```cfg
ensure oxmysql
ensure qb-core
ensure kCharcreator
```

**QBCore + qb-multicharacter:**
```cfg
ensure oxmysql
ensure qb-core
ensure qb-multicharacter
ensure kCharcreator
```

**QBox:**
```cfg
ensure oxmysql
ensure qbx_core
ensure kCharcreator
```

**Standalone:**
```cfg
ensure oxmysql
ensure kCharcreator
```

#### 3. Database

- **ESX**: uses the `skin` column in the `users` table (already exists)
- **QBCore / QBox**: uses the `playerskins` table (already exists)
- **Standalone**: run the `install.sql` file in your database

#### 4. Disable conflicting scripts

Comment out or remove old skin scripts from your `server.cfg`:
```cfg
# ensure esx_skin
# ensure skinchanger
# ensure qb-clothing
```

If using **esx_identity**, add to its config:
```lua
Config.EnableSkin = false
```

If using **esx_multicharacter**:
```lua
Config.Skin = false
```

If using **qb-multicharacter**:
```lua
Config.EnableClothing = false
```

#### 5. Configuration

Edit the file `shared/sh_charcreator.lua`:

```lua
CORE.Charcreator.Config = {
    Framework = "auto",          -- "auto", "esx", "qbcore", "qbox", "standalone"
    lang = "en",                 -- "en", "fr", "de", "es", "pt", "ru", "hr", "ar"
    autoOpen = true,             -- Auto open for new players
    autoloadskin = true,         -- Auto load skin on connection
    color = "gold",              -- "gold", "blue", "purple", "green", "red" or "#HEX"
    player_position = vec4(...), -- Position during creation
    spawn_position = vec4(...),  -- Position after creation
}
```

#### 6. Start the server

You're all set! The character creator will automatically open for new players.

### Commands

| Command | Description |
|---------|-------------|
| `/charcreator` | Open the character creator manually |

### Exports

```lua
-- Checks
exports.kCharcreator:IsPedFreemode(ped)
exports.kCharcreator:IsMale(ped)
exports.kCharcreator:IsFemale(ped)
exports.kCharcreator:GetSex(ped)

-- Skin management
exports.kCharcreator:GetSkin(ped, save)
exports.kCharcreator:SetSkin(skinTable, ped, changeFace)
exports.kCharcreator:ChangeClothes(clothesTable, ped)

-- Components & props
exports.kCharcreator:SetComponentById(ped, componentId, drawableId, textureId)
exports.kCharcreator:GetComponentById(ped, componentId)
exports.kCharcreator:SetPropById(ped, propId, drawableId, textureId)
exports.kCharcreator:GetPropById(ped, propId)

-- Model
exports.kCharcreator:SetPlayerModel(model, ped, applyNaked)
```

### Events

```lua
-- Open character creator from another script
TriggerEvent("CORE.Charcreator:Open")

-- Hooks in config
event_before_open = { "your:event:here" }
event_after_spawn = { "your:event:here" }
```

### Troubleshooting

| Issue | Solution |
|-------|----------|
| Creator doesn't open | Check resource order in `server.cfg` and that `autoOpen = true` |
| Skin doesn't save | Check that oxmysql is running and table/column exists |
| Conflict with other scripts | Disable esx_skin, skinchanger, qb-clothing |
| Opens before esx_identity | esx_identity must be **before** kCharcreator in server.cfg |

---

### Credits

Made by **Karat Store**