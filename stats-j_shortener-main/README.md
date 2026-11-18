📊 STATS-j shortener
================
Romain Méjean — URHAJ Occitanie
2025-10-03

- [🧠 Description du projet](#brain-description-du-projet)
- [👤 Auteur](#bust_in_silhouette-auteur)
- [⚙️ Environnement](#gear-environnement)
  - [Initialisation (première fois)](#initialisation-première-fois)
- [📦 Packages principaux](#package-packages-principaux)
- [📂 Structure du projet](#open_file_folder-structure-du-projet)
- [🧩 Étapes de traitement](#jigsaw-étapes-de-traitement)
  - [1️⃣ Conversion des fichiers CSV en
    Parquet](#one-conversion-des-fichiers-csv-en-parquet)
  - [2️⃣ Fusion des fichiers LOG
    régionaux](#two-fusion-des-fichiers-log-régionaux)
  - [3️⃣ Création et agrégation dans
    DuckDB](#three-création-et-agrégation-dans-duckdb)
  - [4️⃣ Calcul des indicateurs](#four-calcul-des-indicateurs)
  - [5️⃣ Export des résultats](#five-export-des-résultats)
- [🚀 Résultat final](#rocket-résultat-final)
- [🧰 Vérification rapide](#toolbox-vérification-rapide)
- [📬 Contact](#mailbox_with_mail-contact)

# 🧠 Description du projet

Le projet **STATS-j shortener** contient le script `prepare_DATA.R`, qui
automatise le traitement des fichiers-détail **INSEE** (`MIGCOM`,
`MOBPRO`, `MOBSCO`, `LOG`) à l’aide de **DuckDB** et **Arrow**.

Ce script : - Convertit les fichiers CSV INSEE en **Parquet** (format
optimisé) - Fusionne les fichiers régionaux LOG en un seul fichier
global - Crée et agrège les tables dans DuckDB - Calcule les indicateurs
statistiques par **EPCI** - Exporte les résultats consolidés dans un
fichier **RDS** utilisé par l’application shiny **STATS-j**

------------------------------------------------------------------------

# 👤 Auteur

- **Nom** : Romain Méjean — URHAJ Occitanie  
- **Financement** : UNHAJ  
- **Date de création** : 2025-10-03  
- **Version actuelle** : 1.0

------------------------------------------------------------------------

# ⚙️ Environnement

Le projet utilise **{renv}** pour garantir la reproductibilité de
l’environnement R.  
Cela permet de figer les versions exactes des packages dans `renv.lock`.

## Initialisation (première fois)

``` r
install.packages("renv")
renv::restore()  # restaure les packages selon renv.lock
```

------------------------------------------------------------------------

# 📦 Packages principaux

| Package        | Rôle principal                                    |
|----------------|---------------------------------------------------|
| **dplyr**      | Manipulation et agrégation de données             |
| **DBI**        | Interface pour DuckDB                             |
| **duckdb**     | Base de données analytique embarquée              |
| **data.table** | Lecture rapide des fichiers CSV                   |
| **arrow**      | Conversion et fusion de fichiers Parquet          |
| **readr**      | Lecture et écriture de fichiers plats             |
| **renv**       | Gestion des dépendances et de la reproductibilité |

------------------------------------------------------------------------

# 📂 Structure du projet

    project/
    ├── data/                    # Données brutes et traitées
    │   ├── FD_MIGCOM_2022.csv / .parquet
    │   ├── FD_MOBPRO_2022.csv / .parquet
    │   ├── FD_MOBSCO_2022.csv / .parquet
    │   ├── LOGEMTZ[A–E]_2021.csv / FD_LOGEMT_2021.parquet
    │   ├── commune_2022.csv
    │   └── resultats_epci.rds   # Résultats agrégés finaux
    ├── prepare_DATA.R           # Script principal de préparation des données
    ├── README.Rmd               # Ce fichier
    ├── renv.lock                # Dépendances figées
    └── renv/                    # Dossier de gestion renv

------------------------------------------------------------------------

# 🧩 Étapes de traitement

## 1️⃣ Conversion des fichiers CSV en Parquet

- Conversion automatique des fichiers INSEE (`MIGCOM`, `MOBPRO`,
  `MOBSCO`, `LOGEMTZ[A–E]`)
- Préservation du format texte pour les codes communes
- Vérification des fichiers déjà existants pour éviter les reconversions
  inutiles

## 2️⃣ Fusion des fichiers LOG régionaux

- Union des cinq fichiers `FD_LOGEMTZ[A–E]_2021.parquet`
- Création du fichier global `FD_LOGEMT_2021.parquet`

## 3️⃣ Création et agrégation dans DuckDB

- Création des tables :
  - `DATA_migCOM`
  - `DATA_mobPRO`
  - `DATA_mobSCO`
  - `DATA_LOG`
  - `COMMUNES`
- Calcul des pondérations (`IPONDI`, `IPONDL`)
- Filtrage sur les tranches d’âge jeunes :
  - 15–29 ans pour les fichiers mig et mob individuels
  - 15–24 ans pour les fichiers logement

## 4️⃣ Calcul des indicateurs

- Fonctions génériques pour construire les indicateurs par variable :
  - `TACT`, `CS1`, `EMPL`, `DIPL`, `STOCD`, `TYPL`, `MOCO`, `RECH`
- Calculs spécifiques :
  - **MIGCOM** : flux entrants/sortants, nouveaux arrivants, jeunes
    partis  
  - **MOBPRO** : mobilités professionnelles (entrants/sortants)
  - **MOBSCO** : mobilités scolaires (entrants/sortants)

## 5️⃣ Export des résultats

- Fusion de tous les tableaux produits

- Sauvegarde finale dans :

      data/resultats_epci.rds

  → Ce fichier est ensuite lu par l’application **Shiny STATS-j**

------------------------------------------------------------------------

# 🚀 Résultat final

| Fichier | Contenu |
|----|----|
| `data/resultats_epci.rds` | Indicateurs agrégés par EPCI, prêts pour l’application Shiny |
| `data/*.parquet` | Données transformées à partir des fichiers CSV INSEE |

------------------------------------------------------------------------

# 🧰 Vérification rapide

Tu peux tester l’exécution complète du script avec :

``` r
tryCatch(
  {
    source("prepare_DATA.R", local = new.env())
    cat("✅  prepare_DATA.R s'exécute sans erreur bloquante\n")
  },
  error = function(e) {
    cat("❌ Erreur dans prepare_DATA.R :", conditionMessage(e), "\n")
  }
)
```

------------------------------------------------------------------------

# 📬 Contact

📧 <romain.mejean@urhaj.org>
