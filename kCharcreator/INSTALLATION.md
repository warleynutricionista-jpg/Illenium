# kCharcreator - Guide d'Installation

## Pré-requis

- **oxmysql** (obligatoire)
- FiveM Server Build 5181+

---

## Installation de Base

1. Placez le dossier `kCharcreator` dans votre dossier `resources`
2. Ajoutez dans votre `server.cfg` (voir sections ci-dessous pour l'ordre exact)
3. Configurez `shared/sh_charcreator.lua` selon vos besoins

---

# ESX Legacy

## Option 1 : ESX Seul (sans multichar, sans identity)

### server.cfg
```cfg
ensure oxmysql
ensure es_extended
ensure kCharcreator
```

### Configuration (`shared/sh_charcreator.lua`)
```lua
Framework = "esx",
autoOpen = true,
autoloadskin = true,
lang = "fr",
```

### Scripts à désactiver
```cfg
# ensure esx_skin
# ensure skinchanger
```

### Comportement
| Joueur | Action |
|--------|--------|
| Nouveau | kCharcreator s'ouvre automatiquement |
| Existant | Skin chargé automatiquement |

---

## Option 2 : ESX + esx_identity (sans multichar)

### server.cfg
```cfg
ensure oxmysql
ensure es_extended
ensure esx_identity
ensure kCharcreator  # APRÈS esx_identity
```

### Configuration (`shared/sh_charcreator.lua`)
```lua
Framework = "esx",
autoOpen = true,
autoloadskin = true,
lang = "fr",
```

### Configuration esx_identity (`esx_identity/config.lua`)
```lua
Config.EnableSkin = false  -- kCharcreator gère le skin
```

### Scripts à désactiver
```cfg
# ensure esx_skin
# ensure skinchanger
```

### Comportement
| Joueur | Action |
|--------|--------|
| Nouveau | 1. esx_identity s'ouvre → 2. kCharcreator s'ouvre après |
| Existant | Skin chargé automatiquement |

**Note :** kCharcreator détecte automatiquement esx_identity et attend qu'il termine.

---

## Option 3 : ESX + esx_multicharacter (sans identity)

### server.cfg
```cfg
ensure oxmysql
ensure es_extended
ensure esx_multicharacter
ensure kCharcreator
```

### Configuration (`shared/sh_charcreator.lua`)
```lua
Framework = "esx",
autoOpen = true,
autoloadskin = true,
lang = "fr",
```

### Configuration esx_multicharacter
```lua
Config.Skin = false  -- kCharcreator gère le skin
```

### Scripts à désactiver
```cfg
# ensure esx_skin
# ensure skinchanger
```

### Comportement
| Joueur | Action |
|--------|--------|
| Nouveau personnage | kCharcreator s'ouvre après création |
| Personnage existant | Skin chargé automatiquement |

---

## Option 4 : ESX + esx_multicharacter + esx_identity

### server.cfg
```cfg
ensure oxmysql
ensure es_extended
ensure esx_multicharacter
ensure esx_identity
ensure kCharcreator  # EN DERNIER
```

### Configuration (`shared/sh_charcreator.lua`)
```lua
Framework = "esx",
autoOpen = true,
autoloadskin = true,
lang = "fr",
```

### Configuration esx_multicharacter
```lua
Config.Skin = false
Config.Identity = true
```

### Configuration esx_identity
```lua
Config.EnableSkin = false
```

### Scripts à désactiver
```cfg
# ensure esx_skin
# ensure skinchanger
```

### Comportement
| Joueur | Action |
|--------|--------|
| Nouveau personnage | 1. Multichar → 2. esx_identity → 3. kCharcreator |
| Personnage existant | Skin chargé automatiquement |

---

# QBCore

## Option 1 : QBCore Seul (sans multichar)

### server.cfg
```cfg
ensure oxmysql
ensure qb-core
ensure kCharcreator
```

### Configuration (`shared/sh_charcreator.lua`)
```lua
Framework = "qbcore",
autoOpen = true,
autoloadskin = true,
lang = "fr",
```

### Comportement
| Joueur | Action |
|--------|--------|
| Nouveau | kCharcreator s'ouvre automatiquement |
| Existant | Skin chargé automatiquement |

**Note :** Utilise automatiquement la table `playerskins`.

---

## Option 2 : QBCore + qb-multicharacter

### server.cfg
```cfg
ensure oxmysql
ensure qb-core
ensure qb-multicharacter
ensure kCharcreator
```

### Configuration (`shared/sh_charcreator.lua`)
```lua
Framework = "qbcore",
autoOpen = true,
autoloadskin = true,
lang = "fr",
```

### Configuration qb-multicharacter
```lua
Config.EnableClothing = false  -- kCharcreator gère le skin
```

### Comportement
| Joueur | Action |
|--------|--------|
| Nouveau personnage | kCharcreator s'ouvre après identité QBCore |
| Personnage existant | Skin chargé automatiquement |

---

# QBox

## QBox (qbx_core)

### server.cfg
```cfg
ensure oxmysql
ensure qbx_core
ensure kCharcreator
```

### Configuration (`shared/sh_charcreator.lua`)
```lua
Framework = "qbox",
autoOpen = true,
autoloadskin = true,
lang = "fr",
```

### Comportement
Identique à QBCore - détection automatique.

---

# Standalone

## Sans Framework

### server.cfg
```cfg
ensure oxmysql
ensure kCharcreator
```

### Configuration (`shared/sh_charcreator.lua`)
```lua
Framework = "standalone",
autoOpen = true,
autoloadskin = true,
lang = "fr",
```

### Base de données (créer manuellement)
```sql
CREATE TABLE IF NOT EXISTS `skins` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `license` varchar(255) NOT NULL,
  `skin` longtext DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `license` (`license`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

---

# Résumé des configurations

| Configuration | multichar | identity | Ordre server.cfg |
|---------------|-----------|----------|------------------|
| ESX Seul | Non | Non | es_extended → kCharcreator |
| ESX + Identity | Non | Oui | es_extended → esx_identity → kCharcreator |
| ESX + Multichar | Oui | Non | es_extended → esx_multicharacter → kCharcreator |
| ESX + Multi + Identity | Oui | Oui | es_extended → esx_multicharacter → esx_identity → kCharcreator |
| QBCore Seul | Non | - | qb-core → kCharcreator |
| QBCore + Multichar | Oui | - | qb-core → qb-multicharacter → kCharcreator |
| QBox | - | - | qbx_core → kCharcreator |
| Standalone | - | - | kCharcreator |

---

# Dépannage

## Le character creator ne s'ouvre pas

1. Vérifiez l'ordre des resources dans `server.cfg`
2. Vérifiez que `autoOpen = true`
3. Vérifiez la console F8 pour les erreurs
4. Testez `/charcreator` manuellement

## Le skin ne se sauvegarde pas

1. Vérifiez que oxmysql fonctionne
2. ESX : Vérifiez que la colonne `skin` existe dans `users`
3. QBCore : Vérifiez la table `playerskins`

## Conflit avec d'autres scripts skin

Désactivez :
```cfg
# ensure esx_skin
# ensure skinchanger
# ensure qb-clothing
```

## kCharcreator s'ouvre AVANT esx_identity

Vérifiez l'ordre dans `server.cfg` : esx_identity DOIT être AVANT kCharcreator

---

# Commandes

| Commande | Description |
|----------|-------------|
| `/charcreator` | Ouvre le character creator manuellement |

---

# Exports

```lua
-- Vérifications
exports.kCharcreator:IsPedFreemode(ped)
exports.kCharcreator:IsMale(ped)
exports.kCharcreator:IsFemale(ped)
exports.kCharcreator:GetSex(ped)

-- Skin
exports.kCharcreator:GetSkin(ped, save)
exports.kCharcreator:SetSkin(skinTable, ped, changeFace)
exports.kCharcreator:ChangeClothes(clothesTable, ped)

-- Composants
exports.kCharcreator:SetComponentById(ped, componentId, drawableId, textureId)
exports.kCharcreator:GetComponentById(ped, componentId)
exports.kCharcreator:SetPropById(ped, propId, drawableId, textureId)
exports.kCharcreator:GetPropById(ped, propId)

-- Modèle
exports.kCharcreator:SetPlayerModel(model, ped, applyNaked)
```

---

# Events

```lua
-- Ouvrir manuellement
TriggerEvent("CORE.Charcreator:Open")

-- Events callback (dans config)
event_before_open = { "votre:event:ici" },
event_after_spawn = { "votre:event:ici" }
```
