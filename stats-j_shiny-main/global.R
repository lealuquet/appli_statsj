###############################################################
# Projet   : STATS-j (app shiny)
# Auteur   : Romain Méjean URHAJ Occitanie
# Financement : UNHAJ
# Date     : 2025-10-03
# Version  : 1.0
#
# Environnement :
#   Le projet utilise {renv} pour figer les versions des packages.
#   Pour restaurer l’environnement :
#       install.packages("renv")
#       renv::restore()
###############################################################

# ============================================================
# 📦 Packages
# ============================================================

library(dplyr)
library(tidyr)
library(readr)
library(shiny)
library(shinyWidgets)
library(bslib)
library(stringr)
library(shinydashboard)
library(highcharter)
library(DT)

# ============================================================
# 📁 Chargement des données et scripts
# ============================================================

source("parameters.R") # paramètres généraux (liste régions, etc.)
source("labels.R", encoding = "UTF-8") # contient modalite_labels (dico des modalités)
communes <- read_csv("data/commune_2022.csv", show_col_types = FALSE)
resultats_epci <- readRDS("data/resultats_epci.rds")

# ============================================================
# 🍩 Fonction utilitaire : make_donut()
# ============================================================

make_donut <- function(df, filename = "graphique") {
  hchart(
    df,
    "pie",
    hcaes(x = label, y = value),
    name = "",
    innerSize = "50%",
    dataLabels = list(enabled = FALSE),
    showInLegend = TRUE
  ) %>%
    hc_tooltip(
      useHTML = TRUE,
      headerFormat = "",
      pointFormat = "{point.name}: <b>{point.percentage:.1f}%</b> ({point.y:,.0f})"
    ) %>%
    hc_legend(
      enabled = TRUE,
      align = "center",
      verticalAlign = "bottom",
      layout = "horizontal",
      itemStyle = list(fontSize = "12px")
    ) %>%
    hc_plotOptions(pie = list(showInLegend = TRUE)) %>%
    hc_exporting(enabled = TRUE, filename = filename)
}

# ============================================================
# ⚙️ Autres fonctions utilitaires
# ============================================================

# Récupérer une valeur unique
get_val <- function(siren, indic, mod) {
  resultats_epci %>%
    filter(SIREN == siren, indicateur == indic, modalite == mod) %>%
    pull(valeur) %>%
    {
      if (length(.) == 0) {
        NA
      } else {
        .
      }
    }
}

# Récupérer la somme de toutes modalités pour un indicateur
get_total <- function(siren, indic) {
  resultats_epci %>%
    filter(SIREN == siren, indicateur == indic) %>%
    summarise(total = sum(valeur, na.rm = TRUE)) %>%
    pull(total)
}
