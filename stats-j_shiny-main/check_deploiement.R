# ------------------------------------------------------------
# Vérification avant déploiement Shiny
# ------------------------------------------------------------

# 1. Packages nécessaires
packages <- c(
  "dplyr", "readr", "tidyr", "stringr", "shiny", "shinyWidgets", "bslib", 
  "shinydashboard", "highcharter",
  "DF"
)

cat("🔍 Vérification des packages...\n")
not_installed <- packages[!sapply(packages, requireNamespace, quietly = TRUE)]
if (length(not_installed) > 0) {
  cat("❌ Packages manquants :", paste(not_installed, collapse = ", "), "\n")
} else {
  cat("✅ Tous les packages sont installés\n")
}

# 2. Vérification des fichiers critiques
files_needed <- c(
  "data/commune_2022.csv",
  "data/resultats_epci.rds",
  "www/logo.png",
  "parameters.R",
  "labels.R",
  "global.R",
  "ui.R",
  "server.R"
)

cat("\n🔍 Vérification des fichiers...\n")
missing_files <- files_needed[!file.exists(files_needed)]
if (length(missing_files) > 0) {
  cat("❌ Fichiers manquants :", paste(missing_files, collapse = ", "), "\n")
} else {
  cat("✅ Tous les fichiers nécessaires sont présents\n")
}

# 3. Vérification du lancement de l'application
cat("\n🔍 Test du lancement de server.R...\n")
tryCatch(
  {
    source("server.R", local = new.env())
    cat("✅  server.R s'exécute sans erreur bloquante\n")
  },
  error = function(e) {
    cat("❌ Erreur dans server.R :", conditionMessage(e), "\n")
  }
)

cat("\n✅ Vérification terminée.\n")
