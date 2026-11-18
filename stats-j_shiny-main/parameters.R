# ============================================================
# parameters.R
# ------------------------------------------------------------
# Définition des régions, départements
# + éléments pour fallback hors-Shiny si besoin
# ============================================================

regions <- list(
  aura = c(
    "01",
    "03",
    "07",
    "15",
    "26",
    "38",
    "42",
    "43",
    "63",
    "69",
    "73",
    "74"
  ),
  bourgogne_franche_comte = c("21", "25", "39", "58", "70", "71", "89", "90"),
  bretagne = c("22", "29", "35", "56"),
  centre_val_de_loire = c("18", "28", "36", "37", "41", "45"),
  grand_est = c("08", "10", "51", "52", "54", "55", "57", "67", "68", "88"),
  hauts_de_france = c("02", "59", "60", "62", "80"),
  ile_de_france = c("75", "77", "78", "91", "92", "93", "94", "95"),
  normandie = c("14", "27", "50", "61", "76"),
  nouvelle_aquitaine = c(
    "16",
    "17",
    "19",
    "23",
    "24",
    "33",
    "40",
    "47",
    "64",
    "79",
    "86",
    "87"
  ),
  occitanie = c(
    "09",
    "11",
    "12",
    "30",
    "31",
    "32",
    "34",
    "46",
    "48",
    "65",
    "66",
    "81",
    "82"
  ),
  pdl = c("44", "49", "53", "72", "85"),
  paca = c("04", "05", "06", "13", "83", "84"),
  corse = c("2A", "2B")
)

region_labels <- c(
  aura = "Auvergne-Rhône-Alpes",
  bourgogne_franche_comte = "Bourgogne-Franche-Comté",
  bretagne = "Bretagne",
  centre_val_de_loire = "Centre-Val de Loire",
  grand_est = "Grand Est",
  hauts_de_france = "Hauts-de-France",
  ile_de_france = "Île-de-France",
  normandie = "Normandie",
  nouvelle_aquitaine = "Nouvelle-Aquitaine",
  occitanie = "Occitanie",
  pdl = "Pays de la Loire",
  paca = "Provence-Alpes-Côte d’Azur",
  corse = "Corse"
)

###################################################################
# Paramètres utilisateur (injectés par app.R)
###################################################################

if (file.exists("parameters_user.R")) {
  source("parameters_user.R", encoding = "UTF-8")
} else {
  # fallback pour tests hors Shiny
  choix_region <- regions[["occitanie"]]
  terr_type <- "EPCI"
  dpt <- "11"
  EPCI_code <- "200069193"
  nom_region <- "occitanie"
}

if (exists("choix_region") && exists("dpt")) {
  dpt_autres <- setdiff(choix_region, dpt)
} else {
  dpt_autres <- character(0)
}

###################################################################
# Chargement des fichiers de référence
###################################################################

# Table attributaire des communes
communes <- readr::read_csv(
  "data/commune_2022.csv",
  col_types = cols_only(
    COM = col_character(),
    LIBELLE = col_character(),
    EPCI = col_character(),
    LIBEPCI = col_character(),
    DEP = col_character(),
    REG = col_character()
  )
)

# Territoire généré par l'app
if (file.exists("data/territoire.csv")) {
  territoire <- readr::read_csv("data/territoire.csv", show_col_types = FALSE)
  territoire_liste <- territoire$CODGEO
} else {
  territoire_liste <- c("11006", "11007", "11013") # fallback
}

###################################################################
# Extraction département
###################################################################

code_insee <- territoire_liste[1] |> as.character()
dpt_code <- substr(code_insee, 1, 2)

###################################################################
# Territoire selon type choisi (EPCI ou DPT)
###################################################################

if (terr_type == "EPCI") {
  com_dpt <- communes %>% filter(DEP == dpt)
  com_epci <- communes %>% filter(EPCI == EPCI_code)
  
  EPCI_nom <- first(communes %>% filter(EPCI == EPCI_code) %>% pull(LIBEPCI))

} else if (terr_type == "DPT") {
  com_dpt <- communes %>% filter(DEP == dpt)
  
  # Nom du département (récupéré depuis communes.csv si dispo)
  DPT_nom <- first(communes %>% filter(DEP == dpt) %>% pull(DEP))
}
