📊 Application Shiny STATS-j
================
Romain Méjean — URHAJ Occitanie
2025-10-03

- [🧠 Description du projet](#brain-description-du-projet)
- [👤 Auteur](#bust_in_silhouette-auteur)
- [⚙️ Environnement et dépendances](#gear-environnement-et-dépendances)
  - [🔧 Installation de
    l’environnement](#wrench-installation-de-lenvironnement)
- [📦 Packages principaux](#package-packages-principaux)
- [📂 Structure du projet](#open_file_folder-structure-du-projet)
- [🧩 Structure générale de
  l’application](#jigsaw-structure-générale-de-lapplication)
  - [📁 `global.R`](#file_folder-globalr)
  - [💻 `ui.R`](#computer-uir)
  - [⚙️ `server.R`](#gear-serverr)
- [📊 Indicateurs disponibles](#bar_chart-indicateurs-disponibles)
- [🧠 Fonctionnalités principales](#brain-fonctionnalités-principales)
- [🚀 Lancement de l’application](#rocket-lancement-de-lapplication)
- [🧪 Test rapide](#test_tube-test-rapide)
- [📬 Contact](#mailbox_with_mail-contact)

# 🧠 Description du projet

L’application **STATS-j** permet de générer des **tableaux de bord
interactifs** à partir des fichiers-détail du **recensement INSEE**
(`MIGCOM`, `MOBPRO`, `MOBSCO`, `LOG`).  
Elle a été développée par **Romain Méjean (URHAJ Occitanie)** dans le
cadre d’un financement **UNHAJ**.

------------------------------------------------------------------------

# 👤 Auteur

| Élément         | Information                     |
|-----------------|---------------------------------|
| **Auteur**      | Romain Méjean — URHAJ Occitanie |
| **Financement** | UNHAJ                           |
| **Date**        | 2025-10-03                      |
| **Version**     | 1.0                             |

------------------------------------------------------------------------

# ⚙️ Environnement et dépendances

L’application utilise **{renv}** pour garantir la reproductibilité de
l’environnement R.  
Les versions des packages sont figées dans `renv.lock`.

## 🔧 Installation de l’environnement

``` r
install.packages("renv")
renv::restore()  # restaure les packages selon renv.lock
```

------------------------------------------------------------------------

# 📦 Packages principaux

| Package | Utilisation principale |
|----|----|
| **shiny**, **shinydashboard** | Structure de l’application et UI |
| **shinyWidgets** | Sélecteurs dynamiques et boutons améliorés |
| **dplyr**, **tidyr**, **readr** | Manipulation et importation des données |
| **highcharter** | Visualisations interactives |
| **DT** | Tableaux interactifs |
| **stringr** | Traitement de chaînes de caractères |

------------------------------------------------------------------------

# 📂 Structure du projet

    STATS-j/
    ├── data/
    │   ├── commune_2022.csv
    │   ├── resultats_epci.rds
    │   └── territoire.csv   # Pour fallback
    ├── ui.R                 # Interface utilisateur (UI)
    ├── server.R             # Logique serveur (Server)
    ├── global.R             # Fonctions, paramètres et données communes
    ├── labels.R             # Dictionnaire de libellés des variables INSEE
    ├── parameters.R         # Paramètres généraux (régions, départements, etc.)
    ├── www/logo.png         # Logo de l’application
    ├── renv.lock            # Dépendances R figées
    └── README.Rmd           # Ce fichier

------------------------------------------------------------------------

# 🧩 Structure générale de l’application

## 📁 `global.R`

Contient : - le chargement des packages, - l’import des données
principales (`commune_2022.csv`, `resultats_epci.rds`), - les
dictionnaires de labels (`labels.R`), - la fonction utilitaire
`make_donut()` pour générer les graphiques circulaires, - des fonctions
d’accès (`get_val()`, `get_total()`) aux résultats par indicateur.

## 💻 `ui.R`

Définit la structure visuelle : - utilisation de `shinydashboard`
(sidebar, body, onglets), - navigation entre les sections : - Vue
d’ensemble  
- Mobilités résidentielles (nouveaux arrivants / jeunes partis)  
- Mobilités professionnelles  
- Mobilités scolaires  
- Parc et conditions de logement  
- chargement dynamique des menus déroulants (`région`, `département`,
`EPCI`), - intégration du style CSS et du logo.

## ⚙️ `server.R`

Définit la logique serveur : - gestion des entrées utilisateur
(`input$region`, `input$epci`, etc.), - filtrage réactif des données
(`eventReactive()`), - calculs dynamiques (nombre de jeunes, de
logements, etc.), - création des graphiques interactifs avec
`highcharter`, - génération de **tableaux dynamiques (DT)** et
**fichiers téléchargeables (CSV)**, - mise en forme des **valueBox**.

------------------------------------------------------------------------

# 📊 Indicateurs disponibles

| Indicateur | Signification | Source |
|----|----|----|
| **TACT** | Type d’activité | MIGCOM |
| **GS** | Groupe socioprofessionnel (6 postes) | MIGCOM |
| **EMPL** | Condition d’emploi | MIGCOM |
| **DIPL** | Diplôme le plus élevé | MIGCOM |
| **RECH** | Ancienneté de recherche d’emploi | MIGCOM |
| **NA_DCRAN** | Lieu de résidence des nouveaux arrivants à n-1 | MIGCOM |
| **QP_DCRAN** | Destination géographique des jeunes partis | MIGCOM |
| **TACT_NA** | Type d’activité des nouveaux arrivants | MIGCOM |
| **TACT_QP** | Type d’activité des jeunes partis | MIGCOM |
| **DIPL_NA** | Diplôme des nouveaux arrivants | MIGCOM |
| **DIPL_QP** | Diplôme des jeunes partis | MIGCOM |
| **EMPL_NA** | Condition d’emploi des nouveaux arrivants | MIGCOM |
| **EMPL_QP** | Condition d’emploi des jeunes partis | MIGCOM |
| **STOCD_NA** | Statut d’occupation des nouveaux arrivants | MIGCOM |
| **STOCD_QP** | Statut d’occupation des jeunes partis | MIGCOM |
| **FLUX_PRO_ENT** | Flux entrants (lieu de travail dans l’EPCI) | MOBPRO |
| **FLUX_PRO_ENT_AGG** | Flux entrants agrégés par zone géographique | MOBPRO |
| **FLUX_PRO_SOR** | Flux sortants (résidents travaillant hors EPCI) | MOBPRO |
| **TRANS** | Mode de transport principal pour aller travailler | MOBPRO |
| **FLUX_SCO_ENT** | Flux scolaires entrants (élèves scolarisés dans l’EPCI) | MOBSCO |
| **FLUX_SCO_SOR** | Flux scolaires sortants (élèves résidents hors EPCI) | MOBSCO |
| **CATL** | Catégorie du logement | LOG |
| **TYPL** | Type de logement | LOG |
| **STOCD** | Statut d’occupation détaillé | LOG |
| **NBPI** | Nombre de pièces du logement | LOG |
| **ANEM** | Ancienneté d’emménagement | LOG |
| **HLML** | Logement social (HLM ou non) | LOG |
| **LOG_CATL** | Catégorie de logement (résidence principale, secondaire, etc.) | LOG |
| **LOG_TYPL_RP** | Type de logement – résidences principales | LOG |
| **LOG_TYPL_RP_JEUNES** | Type de logement – résidences principales occupées par des jeunes | LOG |
| **LOG_NBPI_RP** | Nombre de pièces – résidences principales | LOG |
| **LOG_NBPI_RP_JEUNES** | Nombre de pièces – résidences principales occupées par des jeunes | LOG |
| **LOG_STOCD_RP** | Statut d’occupation – résidences principales | LOG |
| **LOG_ANEM_RP** | Ancienneté d’emménagement – résidences principales | LOG |
| **LOG_ANEM_RP_JEUNES** | Ancienneté d’emménagement – résidences principales occupées par des jeunes | LOG |
| **LOG_HLM_RP** | Logement social – résidences principales | LOG |
| **LOG_HLM_RP_JEUNES** | Logement social – résidences principales occupées par des jeunes | LOG |

------------------------------------------------------------------------

💡 *Les indicateurs marqués “NA” concernent les jeunes **nouveaux
arrivants**, tandis que ceux marqués “QP” concernent les **jeunes
partis**.  
Les indicateurs “LOG\_…” décrivent le parc de logements et les
conditions d’habitat par statut et âge de la personne de référence.*

------------------------------------------------------------------------

# 🧠 Fonctionnalités principales

✅ Visualisations interactives via **highcharter** (graphiques en donut
et colonnes)  
✅ Sélections dynamiques de territoire (région, département, EPCI)  
✅ Tableaux exportables (CSV)  
✅ Navigation fluide entre onglets (vue d’ensemble, mobilités,
logement)  
✅ Valeurs réactives et boîtes d’indicateurs (valueBox)

------------------------------------------------------------------------

# 🚀 Lancement de l’application

``` r
# Depuis R ou RStudio
shiny::runApp()
```

L’application se lancera automatiquement dans votre navigateur à
l’adresse :  
👉 `http://127.0.0.1:xxxx`

------------------------------------------------------------------------

# 🧪 Test rapide

Pour vérifier le bon chargement de l’environnement et du dataset :

``` r
tryCatch({
  source("global.R", local = new.env())
  message("✅ Chargement global.R OK")
}, error = function(e) {
  message("❌ Erreur dans global.R : ", e$message)
})
```

------------------------------------------------------------------------

# 📬 Contact

📧 <romain.mejean@urhaj.org>
