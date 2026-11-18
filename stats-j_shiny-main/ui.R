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
# 🧩 Interface utilisateur (UI)
# ============================================================

ui <- dashboardPage(
  skin = "yellow",
  title = "STATS-j",
  dashboardHeader(
    title = tags$div(
      tags$img(
        src = "logo.png",
        height = "40px",
        style = "margin-right:10px;"
      ),
      "STATS-j",
      style = "display: flex; align-items: center;"
    )
  ),

  # ------------------------------------------------------------
  # Barre de menu à gauche
  # ------------------------------------------------------------

  dashboardSidebar(
    sidebarMenu(
      menuItem("Bienvenue", tabName = "welcome", icon = icon("home")),
      menuItem(
        "Informations",
        tabName = "infos",
        icon = icon("info-circle")
      ),
      menuItem(
        "Vue d'ensemble",
        tabName = "overview",
        icon = icon("chart-pie")
      ),
      menuItem(
        "Mobilités résidentielles",
        icon = icon("people-arrows"),
        menuSubItem("Nouveaux arrivants", tabName = "na"),
        menuSubItem("Jeunes partis", tabName = "qp")
      ),
      menuItem(
        "Mobilités professionnelles",
        tabName = "pro",
        icon = icon("briefcase")
      ),
      menuItem(
        "Mobilités scolaires",
        tabName = "sco",
        icon = icon("graduation-cap")
      ),
      menuItem(
        "Parc de logement",
        tabName = "log_parc",
        icon = icon("home")
      ),
      menuItem(
        "Conditions de logement",
        tabName = "log_cond",
        icon = icon("house-user")
      ),
      hr(),
      radioButtons(
        "terr_type",
        "Type de territoire :",
        choices = c("EPCI"),
        selected = "EPCI"
      ),
      pickerInput(
        "region",
        "Choisir une région :",
        choices = setNames(names(regions), region_labels),
        options = list(`live-search` = TRUE)
      ),
      uiOutput("departement_ui"),
      uiOutput("epci_ui"),
      actionButton("run", "Charger les données", class = "btn-primary")
    )
  ),

  # ------------------------------------------------------------
  # Modifs CSS (style de la page)
  # ------------------------------------------------------------

  dashboardBody(
    tags$head(tags$style(
      HTML(
        "
    /* ---- Police globale ---- */
    body, .content-wrapper, .sidebar, .main-header, .main-footer {
      font-size: 16px;
      line-height: 1.5;
    }

    /* ---- Titres ---- */
    h1, h2, h3, h4, h5 {
      font-weight: 600;
    }

    /* ---- Blockquote (citation INSEE) ---- */
    blockquote {
      background: linear-gradient(135deg, #fffbea, #fff5cc);
      border-left: 6px solid #f5b301;
      border-radius: 6px;
      padding: 15px 20px;
      color: #333;
      font-style: italic;
      font-size: 14px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
      margin: 15px 0;
    }

    blockquote footer {
      text-align: right;
      font-style: normal;
      color: #666;
      font-size: 13px;
      margin-top: 5px;
    }
  "
      )
    )),

    # ------------------------------------------------------------
    # Onglet Bienvenue
    # ------------------------------------------------------------

    tabItems(
      tabItem(
        tabName = "welcome",
        HTML(
          "
    <h4>Bienvenue sur l’application STATS-j</h4>
    <p>Cette application permet de générer des <b>rapports statistiques</b>
    à partir des fichiers « détail » des <b>recensements INSEE</b>.

    <p>Pour générer un rapport, vous devez :</p>
    <ul>
      <li>Sélectionner la <b>région</b></li>
      <li>Sélectionner le <b>département</b></li>
      <li>Sélectionner l’<b>intercommunalité</b></li>
    </ul>

    <p>Cliquez ensuite sur <b>Charger les données</b> pour obtenir vos résultats.</p>
    
    <hr>
    <hr>
    
    <p>---</p>

    <p style='font-size: 0.9em; color: #555;'>
      Contacts maintenance et développement :
      <a href='mailto:romain.mejean@urhaj.org'>romain.mejean@urhaj.org</a> ; <a href='mailto:lea.luquet@unhaj.org'>lea.luquet@unhaj.org</a>.
    </p>
  "
        )
      ),

      # ------------------------------------------------------------
      # Onglet Infos
      # ------------------------------------------------------------

      tabItem(
        tabName = "infos",
        HTML(
          "
  <h3>💡 Informations générales</h3>

  <p>
    Cette application s’appuie sur les données détaillées du
    <b>recensement de la population</b> pour produire automatiquement
    des analyses statistiques par territoire.
  </p>

  <p>
    Les données sources sont publiques et disponibles sur le site de l’INSEE :<br><br>
    👉 fichiers migCOM, mobPRO et mobSCO : <a href='https://www.insee.fr/fr/statistiques/8590191?sommaire=8590191' target='_blank'>
      https://www.insee.fr/fr/statistiques/8590191?sommaire=8590191
    </a> (millésime 2022).<br>
    👉 fichiers logement : <a href='https://www.insee.fr/fr/statistiques/8647099' target='_blank'>
      https://www.insee.fr/fr/statistiques/8647099
    </a> (millésime 2022).<br>
  </p>

  <hr>

  <h4>👥 Définition des jeunes</h4>
  <p>
    Les <b>jeunes</b> correspondent aux personnes âgées de
    <b>15 à 29 ans</b> (âge révolu). Il s'agit de la tranche d'âge INSEE qui correspond le plus au public des RHAJ.</p>
    <p>️ Le fichier détail <i>« logements ordinaires »</i> n'est pas découpé selon les mêmes classes d'âge ! Les analyses des
    onglets <i>Parc de logements</i> et <i>Conditions de logement</i> sont donc réalisées sur la
    tranche d’âge <b>15 à 24 ans</b>
    (variable <code>AGEMEN8</code>, modalités <code>15</code> et <code>20</code>).</p>


  <hr>

  <h4>📊 Méthodologie</h4>
<p>
  Les chiffres présentés sont calculés à partir de la variable
  <code>IPONDI</code>, un <b>coefficient de pondération</b>
  attribué à chaque individu du fichier de recensement.
  Comme le recensement est désormais réalisé par sondage,
  chaque personne de l’échantillon représente un certain nombre
  de personnes dans la population réelle.
</p>

<p>
  Les valeurs affichées sont <b>arrondies</b> pour faciliter la lecture :
  il peut donc exister de légères différences (de quelques unités) avec
  d’autres sources ou agrégations issues des mêmes données.
</p>


  <hr>

  <h4>⚠️ Fiabilité statistique</h4>
  <blockquote>
    <p>
      « Les effectifs supérieurs à 500 peuvent normalement être utilisés en toute confiance.
      Les effectifs inférieurs à 200 doivent être maniés avec précaution car,
      en raison de l’imprécision liée au sondage, ils peuvent ne pas être significatifs.
      De ce fait, les comparaisons entre territoires de petite taille sont à proscrire.
      Pour des zones de moins de 2 000 habitants, il est recommandé de ne pas utiliser
      les données issues de l’exploitation complémentaire. »
    </p>
    <footer>— <i>Documentation INSEE</i></footer>
  </blockquote>

  <hr>

  <h4>ℹ️ À noter</h4>
  <p>
    Le nom exact de la variable INSEE utilisée est indiqué entre parenthèses
    dans le titre de chaque graphique.
  </p>
  <p>
    Les <b>valeurs relatives</b> (parts en %) peuvent être consultées
    en survolant les graphiques.
  </p>
  
  
  <hr>
  
  <h4>💫 Crédits</h4>
  <p>
  <b>Réalisation et développement</b> : Romain Méjean (URHAJ Occitanie), avec le financement de l’UNHAJ. 
  </p>
  <p> 
  <b>Maintenance</b> : Léa Luquet (UNHAJ). 
  </p> 
  <p> 
  <b>Dépôt Git (code source)</b> : 
  <a href='https://framagit.org/rmejean/stats-j_shiny' target='_blank'> https://framagit.org/rmejean/stats-j_shiny </a> 
  </p>
"
        )
      ),

      # ------------------------------------------------------------
      # Onglet Vue d'ensemble
      # ------------------------------------------------------------

      tabItem(
        tabName = "overview",
        h2("🔭 Vue d'ensemble"),
        fluidRow(
          valueBoxOutput("box_nb_jeunes", width = 4),
          valueBoxOutput("box_nbjMOCO_32", width = 4),
          valueBoxOutput("box_emploiprecaire", width = 4)
        ),
        fluidRow(
          box(
            title = "Type d'activité (TACT)",
            width = 6,
            status = "primary",
            solidHeader = TRUE,
            highchartOutput("graph_tact", height = "300px")
          ),
          box(
            "Sur le total des jeunes actifs",
            title = "Groupe socio-professionnel (GS)",
            width = 6,
            status = "primary",
            solidHeader = TRUE,
            highchartOutput("graph_GS", height = "300px")
          )
        ),
        fluidRow(
          box(
            title = "Condition d'emploi (EMPL)",
            width = 6,
            status = "primary",
            solidHeader = TRUE,
            highchartOutput("graph_empl", height = "300px")
          ),
          box(
            "Sur le total des jeunes qui ont un diplôme",
            title = "Diplôme (DIPL)",
            width = 6,
            status = "primary",
            solidHeader = TRUE,
            highchartOutput("graph_dipl", height = "300px")
          )
        ),
        fluidRow(
          box(
            title = "Statut logement (STOCD)",
            width = 6,
            status = "primary",
            solidHeader = TRUE,
            highchartOutput("graph_stocd", height = "300px")
          ),
          box(
            title = "Type de logement (TYPL)",
            width = 6,
            status = "primary",
            solidHeader = TRUE,
            highchartOutput("graph_typl", height = "300px")
          )
        )
      ),

      # ------------------------------------------------------------
      # Onglet Mob résidentielles - nouveaux arrivants
      # ------------------------------------------------------------

      tabItem(
        tabName = "na",
        h2("📦 Nouveaux arrivants"),
        "Les nouveaux arrivants sont les jeunes qui n'étaient pas présents sur le territoire à n-1 (année précédent celle du recensement).",
        br(),
        br(),
        fluidRow(
          valueBoxOutput("box_nb_jeunes_NA", width = 4),
        ),
        fluidRow(
          box(
            title = "Lieu de résidence des jeunes de l'EPCI à n-1 (DCRAN)",
            width = 6,
            status = "warning",
            solidHeader = TRUE,
            highchartOutput("graph_na1", height = "300px")
          ),
          box(
            title = "Type d'activité des nouveaux arrivants (TACT)",
            width = 6,
            status = "warning",
            solidHeader = TRUE,
            highchartOutput("graph_na2", height = "300px")
          )
        ),
        fluidRow(
          box(
            "Sur le total des jeunes chômeurs",
            title = "Ancienneté de recherche d'emploi des nouveaux arrivants (RECH)",
            width = 6,
            status = "warning",
            solidHeader = TRUE,
            highchartOutput("graph_na3", height = "300px")
          ),
          box(
            "Sur le total des actifs ayant un emploi",
            title = "Condition d'emploi (EMPL)",
            width = 6,
            status = "warning",
            solidHeader = TRUE,
            highchartOutput("graph_na4", height = "300px")
          )
        ),
        fluidRow(
          box(
            title = "Statut d’occupation (STOCD)",
            width = 6,
            status = "warning",
            solidHeader = TRUE,
            highchartOutput("graph_na5", height = "300px")
          )
        )
      ),

      # ------------------------------------------------------------
      # Onglet Mob résidentielles - jeunes partis
      # ------------------------------------------------------------

      tabItem(
        tabName = "qp",
        h2("📦 Jeunes partis"),
        "Les jeunes partis sont ceux qui étaient présents sur le territoire à n-1 mais ne le sont plus à n (année du recensement).",
        br(),
        br(),
        fluidRow(
          valueBoxOutput("box_nb_jeunes_QP", width = 4),
        ),
        fluidRow(
          box(
            title = "Destination (COMMUNE)",
            width = 6,
            status = "danger",
            solidHeader = TRUE,
            highchartOutput("graph_qp1", height = "300px")
          ),
          box(
            title = "Type d'activité (TACT)",
            width = 6,
            status = "danger",
            solidHeader = TRUE,
            highchartOutput("graph_qp2", height = "300px")
          )
        ),
        fluidRow(
          box(
            title = "Diplôme (DIPL)",
            width = 6,
            status = "danger",
            solidHeader = TRUE,
            highchartOutput("graph_qp3", height = "300px")
          ),
          box(
            title = "Condition d'emploi (EMPL)",
            width = 6,
            status = "danger",
            solidHeader = TRUE,
            highchartOutput("graph_qp4", height = "300px")
          )
        ),
        fluidRow(
          box(
            title = "Statut d’occupation (STOCD)",
            width = 6,
            status = "danger",
            solidHeader = TRUE,
            highchartOutput("graph_qp5", height = "300px")
          )
        )
      ),

      # ------------------------------------------------------------
      # Onglet Mob Pro
      # ------------------------------------------------------------

      tabItem(
        tabName = "pro",
        h2("🧰 Mobilités professionnelles"),
        fluidRow(valueBoxOutput("box_nb_jeunes_travaillent", width = 4)),
        fluidRow(
          box(
            title = "Lieu de résidence des jeunes qui travaillent dans l'EPCI (DCLT)",
            width = 6,
            status = "success",
            solidHeader = TRUE,
            highchartOutput("graph_flux_pro", height = "300px")
          ),
          box(
            title = "Mode de transport principal pour aller travailler (TRANS)",
            width = 6,
            status = "success",
            solidHeader = TRUE,
            highchartOutput("graph_trans", height = "300px")
          )
        ),
        fluidRow(
          tabBox(
            title = "mobPRO tab.",
            width = 12,
            id = "tab_travail",
            side = "left",
            selected = "Entrants",

            # -- mobPRO tab. : Flux entrants ----
            tabPanel(
              title = "Entrants (travail dans l’EPCI)",
              icon = icon("briefcase"),
              downloadButton("download_travail_ent", "📥 Télécharger le tableau complet"),
              br(),
              br(),
              DT::dataTableOutput("table_top10_travail")
            ),

            # -- mobPRO tab. : Flux sortants ----
            tabPanel(
              title = "Sortants (résidents de l’EPCI)",
              icon = icon("arrow-right"),
              downloadButton("download_travail_sor", "📥 Télécharger le tableau complet"),
              br(),
              br(),
              DT::dataTableOutput("table_top10_travail_sor")
            )
          )
        ),
      ),

      # ------------------------------------------------------------
      # Onglet Mob Sco
      # ------------------------------------------------------------

      tabItem(
        tabName = "sco",
        h2("🎓 Mobilités scolaires"),
        fluidRow(valueBoxOutput("box_nb_jeunes_etudient", width = 4)),
        fluidRow(
          box(
            title = "Lieu de résidence des scolarisés (DCETUF)",
            width = 6,
            status = "success",
            solidHeader = TRUE,
            highchartOutput("graph_flux_sco", height = "300px")
          )
        ),
        fluidRow(
          tabBox(
            title = "mobSCO tab.",
            width = 12,
            id = "tab_sco",
            side = "left",
            selected = "Entrants",

            # -- mobSCO tab. : Flux entrants ----
            tabPanel(
              title = "Entrants (scolarisation dans l’EPCI)",
              icon = icon("school"),
              downloadButton("download_sco_ent", "📥 Télécharger le tableau complet"),
              br(),
              br(),
              DT::dataTableOutput("table_top10_sco_ent")
            ),

            # -- mobSCO tab. : Flux sortants ----
            tabPanel(
              title = "Sortants (résidents de l’EPCI)",
              icon = icon("arrow-right"),
              downloadButton("download_sco_sor", "📥 Télécharger le tableau complet"),
              br(),
              br(),
              DT::dataTableOutput("table_top10_sco_sor")
            )
          )
        ),
      ),

      # ------------------------------------------------------------
      # Onglet Parc de logements
      # ------------------------------------------------------------

      tabItem(
        tabName = "log_parc",
        h2("🏠 Parc de logements"),
        fluidRow(valueBoxOutput("box_nb_logements", width = 4)),
        fluidRow(
          box(
            title = "Catégorie des logements (CATL)",
            width = 6,
            status = "primary",
            solidHeader = TRUE,
            highchartOutput("graph_log_catl", height = "300px")
          ),
          box(
            "À gauche : sur l'ensemble du parc
            de résidences principales (RP). À droite : sur les RP occupées par des jeunes (les RP dont la personne de référence du
            ménage est dans la tranche d'âge 15-24 ans).",
            br(),
            br(),
            title = "Type de logement (TYPL)",
            width = 6,
            status = "primary",
            solidHeader = TRUE,
            highchartOutput("graph_log_typl", height = "300px")
          )
        ),
        fluidRow(
          box(
            "À gauche : sur l'ensemble du parc
            de résidences principales (RP). À droite : sur les RP occupées par des jeunes (les RP dont la personne de référence du
            ménage est dans la tranche d'âge 15-24 ans).",
            br(),
            br(),
            title = "Nombre de pièces (NBPI)",
            width = 6,
            status = "primary",
            solidHeader = TRUE,
            highchartOutput("graph_log_nbpi", height = "300px")
          )
        )
      ),

      # ------------------------------------------------------------
      # Onglet Conditions de logement
      # ------------------------------------------------------------

      tabItem(
        tabName = "log_cond",
        h2("✌️ Conditions de logement des jeunes"),
        fluidRow(
          valueBoxOutput("box_nb_resprinc", width = 4),
          valueBoxOutput("box_nb_resprinc_jeunes", width = 4)
        ),
        fluidRow(
          box(
            "À gauche : sur l'ensemble du parc
            de résidences principales (RP). À droite : sur les RP occupées par des jeunes (les RP dont la personne de référence du
            ménage est dans la tranche d'âge 15-24 ans).",
            br(),
            br(),
            title = "Ancienneté d’emménagement (ANEM)",
            width = 6,
            status = "success",
            solidHeader = TRUE,
            highchartOutput("graph_log_anem", height = "300px")
          )
        ),
        fluidRow(
          box(
            "À gauche : sur l'ensemble du parc
            de résidences principales (RP). À droite : sur les RP occupées par des jeunes (les RP dont la personne de référence du
            ménage est dans la tranche d'âge 15-24 ans).",
            br(),
            br(),
            title = "Logements sociaux (HLML)",
            width = 6,
            status = "success",
            solidHeader = TRUE,
            highchartOutput("graph_log_hlml", height = "300px")
          )
        )
      )
    )
  )
)
