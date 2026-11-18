###############################################################
# Projet   : STATS-j
# Auteur   : Romain Méjean URHAJ Occitanie
# Date     : 2025-10-03
# Version  : 1.0
# Description :
#   Script principal pour le traitement des fichiers INSEE 
#   (MIGCOM, MOBPRO, MOBSCO, LOG) avec DuckDB.
#   Les résultats sont sauvegardés en .rds pour être mobilisés ensuite
#   par l'app shiny.
#
# Environnement :
#   Le projet utilise {renv} pour figer les versions des packages.
#   Pour restaurer l’environnement :
#       install.packages("renv")
#       renv::restore()
#
# Dépendances principales :
#   - dplyr
#   - DBI
#   - readr
#   - duckdb
#
# Sorties :
#   - data/resultats_epci.rds, à placer dans le répertoire /data de l'app shiny.
###############################################################

# Charger renv (reproduire l’environnement, uniquement la première fois !)
if (requireNamespace("renv", quietly = TRUE)) {
  renv::activate()
} else {
  install.packages("renv")
  renv::activate()
}

# Chargement des librairies
library(dplyr)
library(DBI)
library(readr)
library(duckdb)
library(data.table)
library(arrow)

###################################################################
# CONVERSION DES FICHIERS SOURCE INSEE CSV MIG EN PARQUET
###################################################################

if (file.exists("data/RP2023_migcom.parquet")) {
  print("✅ Le fichier parquet migCOM existe déjà.")
} else {
  write_parquet(
    fread("data/RP2023_migcom.csv") |>
      mutate(across(-IPONDI, as.factor)),
    "data/RP2023_migcom.parquet"
  )
}

if (file.exists("data/RP2023_mobpro.parquet")) {
  print("✅ Le fichier parquet mobPRO existe déjà.")
} else {
  write_parquet(
    fread("data/RP2023_mobpro.csv") |>
      mutate(across(-IPONDI, as.factor)),
    "data/RP2023_mobpro.parquet"
  )
}

if (file.exists("data/RP2023_mobsco.parquet")) {
  print("✅ Le fichier parquet mobSCO existe déjà.")
} else {
  write_parquet(
    fread("data/RP2023_mobsco.csv") |>
      mutate(across(-IPONDI, as.factor)),
    "data/RP2023_mobsco.parquet"
  )
}

###############################################################
# Fusion des 5 fichiers logement régionaux INSEE
# et conversion en un seul fichier Parquet global
###############################################################

# ------------------------------------------------------------
# Étape 1 : Conversion des 5 fichiers CSV régionaux en Parquet
# ------------------------------------------------------------
zones <- c("A", "B", "C", "D", "E")

for (z in zones) {
  csv_path <- sprintf("data/FD_LOGEMTZ%s_2022.csv", z)
  parquet_path <- sprintf("data/FD_LOGEMTZ%s_2022.parquet", z)
  
  if (file.exists(parquet_path)) {
    message("✅ ", parquet_path, " existe déjà, saut...")
  } else {
    message("🔄 Conversion de ", csv_path, " → ", parquet_path)
    
    # Lecture CSV (on garde COMMUNE en texte pour préserver les zéros initiaux)
    dt <- fread(csv_path, colClasses = list(character = "COMMUNE"))
    
    # Conversion rapide en Parquet
    write_parquet(dt, parquet_path)
    
    message("💾 ", parquet_path, " créé avec ", nrow(dt), " lignes.")
  }
}

# ------------------------------------------------------------
# Étape 2 : Fusion rapide des 5 Parquet régionaux
# ------------------------------------------------------------
fichiers_parquet <- sprintf("data/FD_LOGEMTZ%s_2022.parquet", zones)
fichier_final <- "data/FD_LOGEMT_2022.parquet"

if (file.exists(fichier_final)) {
  message("✅ Le fichier global existe déjà : ", fichier_final)
} else {
  message("🔄 Fusion des fichiers Parquet régionaux...")
  
  # Lecture simultanée et écriture directe en Parquet global
  # (sans tout charger en mémoire)
  dataset <- open_dataset(fichiers_parquet, format = "parquet")
  write_dataset(dataset, path = "data/tmp_log_union", format = "parquet", existing_data_behavior = "overwrite")
  
  # Relecture du dataset fusionné et écriture finale
  final <- open_dataset("data/tmp_log_union", format = "parquet")
  write_parquet(collect(final), fichier_final)
  
  unlink("data/tmp_log_union", recursive = TRUE)
  message("💾 Fichier global créé : ", fichier_final)
}

message("✅ Fusion LOG20212erminée.")


# ------------------------------------------------------------
# 1. Connexion + tables DuckDB
# ------------------------------------------------------------
con <- dbConnect(duckdb::duckdb())

dbSendQuery(con, "CREATE OR REPLACE TABLE DATA_migCOM AS
                    SELECT *,
                           SUM(IPONDI) AS NB
                    FROM read_parquet('data/FD_MIGCOM_2022.parquet')
                    WHERE AGEREVQ IN (015, 020, 025)
                    GROUP BY ALL")

dbSendQuery(con, "CREATE OR REPLACE TABLE DATA_mobPRO AS
                    SELECT *,
                           SUM(IPONDI) AS NB
                    FROM read_parquet('data/FD_MOBPRO_2022.parquet')
                    WHERE AGEREVQ IN (015, 020, 025)
                    GROUP BY ALL")

dbSendQuery(con, "CREATE OR REPLACE TABLE DATA_mobSCO AS
                    SELECT *,
                           SUM(IPONDI) AS NB
                    FROM read_parquet('data/FD_MOBSCO_2022.parquet')
                    WHERE AGEREV10 IN (15, 18, 25)
                    GROUP BY ALL")

dbSendQuery(con, "CREATE OR REPLACE TABLE DATA_LOG AS
                    SELECT *,
                           SUM(IPONDL) AS NB
                    FROM read_parquet('data/FD_LOGEMT_2022.parquet')
                    GROUP BY ALL")


# Table communes
dbSendQuery(con, "CREATE OR REPLACE TABLE COMMUNES AS SELECT * FROM read_csv_auto('data/commune_2022.csv')")

# ------------------------------------------------------------
# 2. Fonction générique pour MIGCOM (globaux / NA / QP)
# ------------------------------------------------------------
build_migcom_indic <- function(var, name) {
  list(
    # Global
    dbGetQuery(con, sprintf("
      SELECT COM.EPCI AS SIREN, '%s' AS indicateur,
             CAST(DATA.%s AS VARCHAR) AS modalite, SUM(DATA.NB) AS valeur
      FROM DATA_migCOM AS DATA
      JOIN COMMUNES AS COM ON DATA.COMMUNE = COM.COM
      WHERE DATA.%s IS NOT NULL
      GROUP BY COM.EPCI, DATA.%s
    ", name, var, var, var)),
    
    # Nouveaux arrivants (NA)
    dbGetQuery(con, sprintf("
      SELECT COM.EPCI AS SIREN, '%s_NA' AS indicateur,
             CAST(DATA.%s AS VARCHAR) AS modalite, SUM(DATA.NB) AS valeur
      FROM DATA_migCOM AS DATA
      JOIN COMMUNES AS COM ON DATA.COMMUNE = COM.COM
      WHERE DATA.%s IS NOT NULL
        AND DATA.DCRAN NOT IN (SELECT COM FROM COMMUNES WHERE EPCI = COM.EPCI)
      GROUP BY COM.EPCI, DATA.%s
    ", name, var, var, var)),
    
    # Jeunes partis (QP)
    dbGetQuery(con, sprintf("
      SELECT COM.EPCI AS SIREN, '%s_QP' AS indicateur,
             CAST(DATA.%s AS VARCHAR) AS modalite, SUM(DATA.NB) AS valeur
      FROM DATA_migCOM AS DATA
      JOIN COMMUNES AS COM ON DATA.DCRAN = COM.COM
      WHERE DATA.%s IS NOT NULL
        AND DATA.COMMUNE NOT IN (SELECT COM FROM COMMUNES WHERE EPCI = COM.EPCI)
      GROUP BY COM.EPCI, DATA.%s
    ", name, var, var, var))
  )
}

# Appliquer pour toutes les variables MIGCOM
migcom_tabs <- list(
  build_migcom_indic("TACT", "TACT"),
  build_migcom_indic("GS", "GS"),
  build_migcom_indic("EMPL", "EMPL"),
  build_migcom_indic("DIPL", "DIPL"),
  build_migcom_indic("STOCD", "STOCD"),
  build_migcom_indic("TYPL", "TYPL"),
  build_migcom_indic("MOCO", "MOCO"),
  build_migcom_indic("RECH", "RECH")
)

migcom_tabs <- bind_rows(unlist(migcom_tabs, recursive = FALSE))

# ------------------------------------------------------------
# 2bis. MIGCOM : Origine géographique des nouveaux arrivants (NA_DCRAN)
# ------------------------------------------------------------
na_dcran_tab <- dbGetQuery(con, "
  SELECT COM.EPCI AS SIREN, 'NA_DCRAN' AS indicateur,
         CASE
           WHEN substr(DATA.DCRAN, 1, 2) = substr(COM.COM, 1, 2)
                AND DATA.DCRAN NOT IN (SELECT COM FROM COMMUNES WHERE EPCI = COM.EPCI)
             THEN 'DPT'
           WHEN substr(DATA.DCRAN, 1, 2) != substr(COM.COM, 1, 2)
                AND substr(DATA.DCRAN, 1, 2) IN (SELECT distinct substr(COM,1,2) FROM COMMUNES WHERE REG = COM.REG)
             THEN 'HDPT'
           WHEN DATA.DCRAN = '99999' THEN 'ETR'
           ELSE 'HREG'
         END AS modalite,
         SUM(DATA.NB) AS valeur
  FROM DATA_migCOM AS DATA
  JOIN COMMUNES AS COM ON DATA.COMMUNE = COM.COM
  WHERE DATA.DCRAN IS NOT NULL
    AND DATA.DCRAN NOT IN (SELECT COM FROM COMMUNES WHERE EPCI = COM.EPCI)
  GROUP BY COM.EPCI, modalite
")

# ------------------------------------------------------------
# 2ter. MIGCOM : Destination géographique des jeunes partis (QP_DCRAN)
# ------------------------------------------------------------
qp_dcran_tab <- dbGetQuery(con, "
  SELECT COM.EPCI AS SIREN, 'QP_DCRAN' AS indicateur,
         CASE
           WHEN substr(DATA.COMMUNE, 1, 2) = substr(COM.COM, 1, 2)
                AND DATA.COMMUNE NOT IN (SELECT COM FROM COMMUNES WHERE EPCI = COM.EPCI)
             THEN 'DPT'
           WHEN substr(DATA.COMMUNE, 1, 2) != substr(COM.COM, 1, 2)
                AND substr(DATA.COMMUNE, 1, 2) IN (SELECT distinct substr(COM,1,2) FROM COMMUNES WHERE REG = COM.REG)
             THEN 'HDPT'
           WHEN DATA.COMMUNE = '99999' THEN 'ETR'
           ELSE 'HREG'
         END AS modalite,
         SUM(DATA.NB) AS valeur
  FROM DATA_migCOM AS DATA
  JOIN COMMUNES AS COM ON DATA.DCRAN = COM.COM
  WHERE DATA.COMMUNE IS NOT NULL
    AND DATA.COMMUNE NOT IN (SELECT COM FROM COMMUNES WHERE EPCI = COM.EPCI)
  GROUP BY COM.EPCI, modalite
")

# ------------------------------------------------------------
# 3. MOBPRO
# ------------------------------------------------------------
trans_tab <- dbGetQuery(con, "
  SELECT COM.EPCI AS SIREN, 'TRANS' AS indicateur,
         CAST(DATA.TRANS AS VARCHAR) AS modalite, SUM(DATA.NB) AS valeur
  FROM DATA_mobPRO AS DATA
  JOIN COMMUNES AS COM ON DATA.DCLT = COM.COM
  WHERE DATA.TRANS IS NOT NULL
  GROUP BY COM.EPCI, DATA.TRANS
")

flux_mobPRO_ent <- dbGetQuery(con, "
  SELECT COM.EPCI AS SIREN, 'FLUX_PRO_ENT' AS indicateur,
         DATA.COMMUNE || '->' || DATA.DCLT AS modalite, SUM(DATA.NB) AS valeur
  FROM DATA_mobPRO AS DATA
  JOIN COMMUNES AS COM ON DATA.DCLT = COM.COM
  GROUP BY COM.EPCI, DATA.COMMUNE, DATA.DCLT
")

flux_mobPRO_ent_agg <- dbGetQuery(con, "
  SELECT COM.EPCI AS SIREN, 'FLUX_PRO_ENT_AGG' AS indicateur,
         CASE
           WHEN DATA.COMMUNE IN (SELECT COM FROM COMMUNES WHERE EPCI = COM.EPCI)
             THEN 'EPCI'
           WHEN substr(DATA.COMMUNE, 1, 2) = substr(COM.COM, 1, 2)
             THEN 'DPT'
           WHEN substr(DATA.COMMUNE, 1, 2) IN (SELECT distinct substr(COM,1,2) FROM COMMUNES WHERE REG = COM.REG)
             THEN 'HDPT'
           WHEN DATA.COMMUNE = '99999' THEN 'ETR'
           ELSE 'HREG'
         END AS modalite,
         SUM(DATA.NB) AS valeur
  FROM DATA_mobPRO AS DATA
  JOIN COMMUNES AS COM ON DATA.DCLT = COM.COM
  GROUP BY COM.EPCI, modalite
")

flux_mobPRO_sor <- dbGetQuery(con, "
  SELECT COM.EPCI AS SIREN, 'FLUX_PRO_SOR' AS indicateur,
         DATA.COMMUNE || '->' || DATA.DCLT AS modalite, SUM(DATA.NB) AS valeur
  FROM DATA_mobPRO AS DATA
  JOIN COMMUNES AS COM ON DATA.COMMUNE = COM.COM
  GROUP BY COM.EPCI, DATA.COMMUNE, DATA.DCLT
")

# ------------------------------------------------------------
# 4. MOBSCO
# ------------------------------------------------------------
flux_mobSCO_ent <- dbGetQuery(con, "
  SELECT COM.EPCI AS SIREN, 'FLUX_SCO_ENT' AS indicateur,
         DATA.COMMUNE || '->' || DATA.DCETUF AS modalite, SUM(DATA.NB) AS valeur
  FROM DATA_mobSCO AS DATA
  JOIN COMMUNES AS COM ON DATA.DCETUF = COM.COM
  GROUP BY COM.EPCI, DATA.COMMUNE, DATA.DCETUF
")

flux_mobSCO_sor <- dbGetQuery(con, "
  SELECT COM.EPCI AS SIREN, 'FLUX_SCO_SOR' AS indicateur,
         DATA.COMMUNE || '->' || DATA.DCETUF AS modalite, SUM(DATA.NB) AS valeur
  FROM DATA_mobSCO AS DATA
  JOIN COMMUNES AS COM ON DATA.COMMUNE = COM.COM
  GROUP BY COM.EPCI, DATA.COMMUNE, DATA.DCETUF
")

flux_sco_ent_agg <- dbGetQuery(con, "
  SELECT COM.EPCI AS SIREN, 'FLUX_SCO_ENT_AGG' AS indicateur,
         CASE
           WHEN DATA.COMMUNE = DATA.DCETUF THEN 'EPCI'
           WHEN substr(DATA.COMMUNE, 1, 2) = substr(COM.COM, 1, 2)
                AND DATA.COMMUNE NOT IN (SELECT COM FROM COMMUNES WHERE EPCI = COM.EPCI)
             THEN 'DPT'
           WHEN substr(DATA.COMMUNE, 1, 2) != substr(COM.COM, 1, 2)
                AND substr(DATA.COMMUNE, 1, 2) IN (SELECT distinct substr(COM,1,2) FROM COMMUNES WHERE REG = COM.REG)
             THEN 'HDPT'
           WHEN DATA.COMMUNE = '99999' THEN 'ETR'
           ELSE 'HREG'
         END AS modalite,
         SUM(DATA.NB) AS valeur
  FROM DATA_mobSCO AS DATA
  JOIN COMMUNES AS COM ON DATA.DCETUF = COM.COM
  GROUP BY COM.EPCI, modalite
")

# ------------------------------------------------------------
# 5. Fonction générique LOG
# ------------------------------------------------------------
build_log_indic <- function(var, name, filter_expr = NULL) {
  filter_sql <- if (!is.null(filter_expr)) paste0("AND ", filter_expr) else ""
  
  dbGetQuery(con, sprintf("
    SELECT COM.EPCI AS SIREN, '%s' AS indicateur,
           CAST(DATA.%s AS VARCHAR) AS modalite, SUM(DATA.NB) AS valeur
    FROM DATA_LOG AS DATA
    JOIN COMMUNES AS COM ON LPAD(CAST(DATA.COMMUNE AS VARCHAR), 5, '0') = COM.COM
    WHERE DATA.%s IS NOT NULL %s
    GROUP BY COM.EPCI, DATA.%s
  ", name, var, var, filter_sql, var))
}

# Variables LOG à calculer
log_tabs <- list(
  build_log_indic("CATL", "LOG_CATL"),
  build_log_indic("TYPL", "LOG_TYPL_RP", "DATA.CATL = 1"),
  build_log_indic("TYPL", "LOG_TYPL_RP_JEUNES", "DATA.CATL = 1 AND TRY_CAST(DATA.AGEMEN8 AS INT) IN (15,20)"),
  build_log_indic("NBPI", "LOG_NBPI_RP", "DATA.CATL = 1"),
  build_log_indic("NBPI", "LOG_NBPI_RP_JEUNES", "DATA.CATL = 1 AND TRY_CAST(DATA.AGEMEN8 AS INT) IN (15,20)"),
  build_log_indic("STOCD", "LOG_STOCD_RP", "DATA.CATL = 1"),
  build_log_indic("ANEM", "LOG_ANEM_RP", "DATA.CATL = 1"),
  build_log_indic("ANEM", "LOG_ANEM_RP_JEUNES", "DATA.CATL = 1 AND TRY_CAST(DATA.AGEMEN8 AS INT) IN (15,20)"),
  build_log_indic("HLML", "LOG_HLM_RP", "DATA.CATL = 1"),
  build_log_indic("HLML", "LOG_HLM_RP_JEUNES", "DATA.CATL = 1 AND TRY_CAST(DATA.AGEMEN8 AS INT) IN (15,20)")
)


log_tabs <- bind_rows(log_tabs)

# ------------------------------------------------------------
# 6. Fusionner tous les résultats
# ------------------------------------------------------------
resultats <- bind_rows(
  migcom_tabs,
  na_dcran_tab,
  qp_dcran_tab,
  trans_tab,
  flux_mobPRO_ent,
  flux_mobPRO_ent_agg,
  flux_mobPRO_sor,
  flux_mobSCO_ent,
  flux_mobSCO_sor,
  log_tabs
)

# ------------------------------------------------------------
# 7. Sauvegarde
# ------------------------------------------------------------
saveRDS(resultats, "data/resultats_epci.rds")

dbDisconnect(con)
