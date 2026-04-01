CORE = CORE or {}
CORE.Identity = CORE.Identity or {}
CORE.Identity.Locale = CORE.Identity.Locale or {}

CORE.Identity.Locale["fr"] = {
    TITLE = "Enregistrement du Personnage",

    SECTION_NAME = "Prenom & Nom",
    SECTION_DOB = "Date de Naissance",
    SECTION_NATIONALITY = "Nationalite",
    SECTION_GENDER = "Genre",

    DESC_NAME = "Ecrivez le prenom et le nom de votre personnage. Vous pouvez le generer aleatoirement.",
    DESC_DOB = "Selectionnez la date de naissance de votre personnage.",
    DESC_NATIONALITY = "Choisissez la nationalite de votre personnage.",
    DESC_GENDER = "",

    FIRST_NAME = "Prenom",
    LAST_NAME = "Nom",

    MALE = "Homme",
    FEMALE = "Femme",

    RANDOM = "Aleatoire",
    CREATE = "Creer",
    CANCEL = "Annuler",

    MONTHS = {
        "Janvier", "Fevrier", "Mars", "Avril", "Mai", "Juin",
        "Juillet", "Aout", "Septembre", "Octobre", "Novembre", "Decembre"
    },

    NATIONALITIES = {
        [0] = "Americain",
        [1] = "Francais",
        [2] = "Allemand",
        [3] = "Britannique",
        [4] = "Espagnol",
        [5] = "Italien",
        [6] = "Russe",
        [7] = "Chinois",
        [8] = "Japonais",
        [9] = "Coreen",
        [10] = "Bresilien",
        [11] = "Mexicain",
        [12] = "Canadien",
        [13] = "Australien",
        [14] = "Indien",
    },
}
