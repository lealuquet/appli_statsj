# ============================================================
# labels.R
# ------------------------------------------------------------
# Dictionnaire global de correspondance entre codes de modalités
# INSEE et libellés lisibles pour les graphiques STATS-j
# ============================================================

modalite_labels <- list(
  # ----------------------------------------------------------
  # Type d’activité (TACT)
  # ----------------------------------------------------------
  TACT = c(
    "11" = "Actifs ayant un emploi",
    "12" = "Chômeurs",
    "22" = "Élèves, étudiants, stagiaires non rémunérés",
    "24" = "Femmes ou hommes au foyer",
    "25" = "Autres inactifs"
  ),
  
  # ----------------------------------------------------------
  # Groupe socioprofessionnel en 6 postes (GS)
  # ----------------------------------------------------------
  GS = c(
    "1" = "Agriculteurs exploitants / Agricultrices exploitantes",
    "2" = "Artisans / Artisanes, commerçants / commerçantes et chefs / cheffes d'entreprise",
    "3" = "Cadres et professions intellectuelles supérieures",
    "4" = "Professions intermédiaires",
    "5" = "Employés / Employées",
    "6" = "Ouvriers / Ouvrières",
    "Z" = "Sans objet"
  ),
  
  # ----------------------------------------------------------
  # Condition d’emploi (EMPL)
  # ----------------------------------------------------------
  EMPL = c(
    "11" = "Contrat apprentissage / professionnalisation",
    "12" = "Intérim",
    "13" = "Emploi aidé",
    "14" = "Stagiaire rémunéré en entreprise",
    "15" = "Emploi à durée limitée",
    "16" = "Emploi sans limite de durée",
    "21" = "Indépendants",
    "22" = "Employeurs",
    "23" = "Aides familiaux"
  ),
  
  # ----------------------------------------------------------
  # Diplôme le plus élevé (DIPL)
  # ----------------------------------------------------------
  DIPL = c(
    "1"  = "Arrêt avant la fin du primaire",
    "2"  = "Arrêt avant la fin du collège",
    "3"  = "Aucun diplôme (scolarité collège et +)",
    "11" = "CEP",
    "12" = "DNB",
    "13" = "CAP, BEP",
    "14" = "Bac général ou technologique",
    "15" = "Bac professionnel",
    "16" = "BTS, DUT, autre bac+2",
    "17" = "Licence, licence pro, bac+3/+4",
    "18" = "Master, autre bac+5",
    "19" = "Doctorat"
  ),
  
  # ----------------------------------------------------------
  # Statut d’occupation détaillé (STOCD)
  # ----------------------------------------------------------
  STOCD = c(
    "10" = "Propriétaires",
    "21" = "Locataires (hors HLM)",
    "22" = "Locataires HLM",
    "23" = "Logement meublé / hôtel",
    "30" = "Logés gratuitement",
    "ZZ" = "Hors logement ordinaire"
  ),
  
  # ----------------------------------------------------------
  # Type de logement (TYPL)
  # ----------------------------------------------------------
  TYPL = c(
    "1" = "Maisons",
    "2" = "Appartements",
    "3" = "Logement-foyer",
    "4" = "Chambre d'hôtel",
    "5" = "Habitation de fortune",
    "6" = "Pièce indépendante",
    "Z" = "Hors logement ordinaire"
  ),
  
  # ----------------------------------------------------------
  # Ancienneté de la recherche d’emploi (RECH)
  # ----------------------------------------------------------
  RECH = c("1" = "Moins d’un an", "2" = "Plus d’un an"),
  
  # ----------------------------------------------------------
  # Mode de transport principal (TRANS)
  # ----------------------------------------------------------
  TRANS = c(
    "1" = "Sans transport",
    "2" = "Marche à pied",
    "3" = "Vélo",
    "4" = "2 roues motorisé",
    "5" = "Voiture",
    "6" = "Transports en commun"
  ),
  
  # ----------------------------------------------------------
  # Origine / destination géographique des flux
  # ----------------------------------------------------------
  GEO = c(
    "EPCI"  = "Dans l’EPCI",
    "DPT"   = "Autre commune du département",
    "HDPT"  = "Autre département de la région",
    "HREG"  = "Autre région",
    "ETR"   = "À l’étranger"
  ),
  
  # ----------------------------------------------------------
  # 🏠 LOG : Catégorie de logement (CATL)
  # ----------------------------------------------------------
  CATL = c(
    "1"  = "Résidences principales",
    "2"  = "Logements occasionnels",
    "3"  = "Résidences secondaires",
    "4"  = "Logements vacants",
    "Z"  = "Hors logement ordinaire"
  ),
  
  # ----------------------------------------------------------
  # 🏠 LOG : Nombre de pièces (NBPI)
  # ----------------------------------------------------------
  NBPI = c(
    "01"  = "1 pièce",
    "02"  = "2 pièces",
    "03"  = "3 pièces",
    "04"  = "4 pièces",
    "05p" = "5 pièces et plus",
    # ← ajout du code fusionné utilisé dans le graphique
    "YY"  = "Hors résidence principale",
    "ZZ"  = "Hors logement ordinaire"
  ),
  
  
  # ----------------------------------------------------------
  # ✌🏠 LOG : Ancienneté d’emménagement (ANEM)
  # ----------------------------------------------------------
  ANEM = c(
    "1" = "Moins de deux ans",
    "2" = "2 à 4 ans",
    "3" = "5 ans et plus",
    "999" = "Logement ordinaire inoccupé",
    "Z" = "Hors logement ordinaire"
  ),
  
  # ----------------------------------------------------------
  # ✌🏠 LOG : Logement social (HLML)
  # ----------------------------------------------------------
  HLML = c("1" = "Appartient à un organisme HLM", "2" = "N'appartient pas à un organisme HLM", "Z" = "Hors logement ordinaire")
)

# ------------------------------------------------------------
# Alias pour compatibilité directe avec les scripts
# ------------------------------------------------------------
modalite_labels$NA_DCRAN <- modalite_labels$GEO
modalite_labels$QP_DCRAN <- modalite_labels$GEO
modalite_labels$FLUX <- modalite_labels$GEO
