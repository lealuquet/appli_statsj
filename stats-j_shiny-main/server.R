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
# ⚙️ SERVER
# ============================================================

# -- sélections dynamiques ----

server <- function(input, output, session) {
  output$departement_ui <- renderUI({
    req(input$region)
    selectInput("departement", "Choisir un département :", choices = regions[[input$region]])
  })

  output$epci_ui <- renderUI({
    req(input$departement)
    if (input$terr_type == "EPCI") {
      epcis <- communes %>%
        filter(DEP == input$departement) %>%
        distinct(EPCI, LIBEPCI) %>%
        arrange(LIBEPCI)
      selectInput("epci",
        "Choisir une intercommunalité :",
        choices = setNames(epcis$EPCI, epcis$LIBEPCI)
      )
    }
  })

  # -- données filtrées après clic ----

  data_territoire <- eventReactive(input$run, {
    if (input$terr_type == "EPCI") {
      resultats_epci %>% filter(SIREN == input$epci)
    } else {
      NULL
    }
  })

  # -- variables dynamiques liées au territoire sélectionné ----

  nb_jeunes_NA <- reactive({
    req(input$epci)
    get_total(input$epci, "TACT_NA") # nb total jeunes nouveaux arrivants
  })

  nb_jeunes_QP <- reactive({
    req(input$epci)
    get_total(input$epci, "TACT_QP") # nb total jeunes qui partent
  })

  nb_jeunes_T_epci_mobPRO <- reactive({
    req(input$epci)
    get_total(input$epci, "FLUX_PRO_ENT") # nb jeunes qui travaillent sur le territoire
  })

  nb_jeunes_E_epci_mobSCO <- reactive({
    req(input$epci)
    get_total(input$epci, "FLUX_SCO_ENT") # nb total jeunes qui étudient sur le territoire
  })

  nb_logements_total <- reactive({
    req(input$epci)
    get_total(input$epci, "LOG_CATL") # nb total logements
  })

  nb_resprinc <- reactive({
    req(input$epci)
    get_total(input$epci, "LOG_TYPL_RP") # nb résidences principales
  })

  nb_resprinc_jeunes <- reactive({
    req(input$epci)
    get_total(input$epci, "LOG_TYPL_RP_JEUNES") # nb résidences principales occupées par jeunes
  })

  # ------------------------------------------------------------
  # Graphiques vue d'ensemble
  # ------------------------------------------------------------

  # -- 📊 valuebox Nb jeunes ----

  output$box_nb_jeunes <- renderValueBox({
    req(input$epci)
    nb_jeunes <- get_total(input$epci, "TACT")

    valueBox(
      value = format(round(nb_jeunes), big.mark = " "),
      subtitle = "Nombre de jeunes",
      icon = icon("users"),
      color = "blue"
    )
  })

  # -- 📊 valuebox Nb jeunes vivent seuls ----

  output$box_nbjMOCO_32 <- renderValueBox({
    req(input$epci)
    nbjMOCO_32 <- get_val("MOCO", "32", siren = input$epci)

    valueBox(
      value = format(round(nbjMOCO_32), big.mark = " "),
      subtitle = "déclarent vivre seuls",
      icon = icon("chart-bar"),
      color = "green"
    )
  })

  # -- 📊 valuebox Nb jeunes emploi précaire ----
  # -- (soit la somme de ceux occupant un emploi avec limite de durée) ----

  output$box_emploiprecaire <- renderValueBox({
    req(input$epci)
    nbjEMPL_11 <- get_val("EMPL", "11", siren = input$epci)
    nbjEMPL_12 <- get_val("EMPL", "12", siren = input$epci)
    nbjEMPL_13 <- get_val("EMPL", "13", siren = input$epci)
    nbjEMPL_14 <- get_val("EMPL", "14", siren = input$epci)
    nbjEMPL_15 <- get_val("EMPL", "15", siren = input$epci)
    nbjTACT_11 <- get_val("TACT", "11", siren = input$epci)

    valueBox(
      value = format(round(((nbjEMPL_11 + nbjEMPL_12 + nbjEMPL_13 + nbjEMPL_14 + nbjEMPL_15) /
        nbjTACT_11
      ) * 100), big.mark = " "),
      subtitle = "% occupent un emploi précaire",
      icon = icon("chart-bar"),
      color = "red"
    )
  })

  # -- graph TACT ----

  output$graph_tact <- renderHighchart({
    df <- data_territoire() %>%
      filter(
        indicateur == "TACT",
        modalite %in% names(modalite_labels$TACT)
      ) %>%
      mutate(label = modalite_labels$TACT[modalite], value = round(valeur)) %>%
      select(label, value)
    make_donut(df, filename = "TACT")
  })

  # -- graph GS ----
  
  output$graph_GS <- renderHighchart({
    df <- data_territoire() %>%
      filter(
        indicateur == "GS",
        modalite %in% names(modalite_labels$GS),
        modalite != "Z" # exclure "Sans objet"
      ) %>%
      mutate(
        label = modalite_labels$GS[modalite],
        value = round(valeur)
      ) %>%
      select(label, value)
    
    make_donut(df, filename = "GS")
  })

  # -- graph EMPL ----

  output$graph_empl <- renderHighchart({
    df <- data_territoire() %>%
      filter(
        indicateur == "EMPL",
        modalite %in% names(modalite_labels$EMPL)
      ) %>%
      mutate(label = modalite_labels$EMPL[modalite], value = round(valeur)) %>%
      select(label, value)
    make_donut(df, filename = "EMPL")
  })

  # -- graph DIPL ----

  output$graph_dipl <- renderHighchart({
    df <- data_territoire() %>%
      filter(
        indicateur == "DIPL",
        modalite %in% names(modalite_labels$DIPL)
      ) %>%
      mutate(label = modalite_labels$DIPL[modalite], value = round(valeur)) %>%
      select(label, value)
    make_donut(df, filename = "DIPL")
  })

  # -- graph STOCD ----

  output$graph_stocd <- renderHighchart({
    df <- data_territoire() %>%
      filter(
        indicateur == "STOCD",
        modalite %in% names(modalite_labels$STOCD)
      ) %>%
      mutate(label = modalite_labels$STOCD[modalite], value = round(valeur)) %>%
      select(label, value)
    make_donut(df, filename = "STOCD")
  })

  # -- graph TYPL ----

  output$graph_typl <- renderHighchart({
    df <- data_territoire() %>%
      filter(
        indicateur == "TYPL",
        modalite %in% names(modalite_labels$TYPL)
      ) %>%
      mutate(label = modalite_labels$TYPL[modalite], value = round(valeur)) %>%
      select(label, value)
    make_donut(df, filename = "TYPL")
  })

  # ------------------------------------------------------------
  # Graphiques migrations - nouveaux arrivants (NA)
  # ------------------------------------------------------------

  # -- 📊 valuebox Nb jeunes "nouveaux arrivants" ----
  output$box_nb_jeunes_NA <- renderValueBox({
    req(input$epci)
    
    valueBox(
      value = format(round(nb_jeunes_NA()), big.mark = " "),
      subtitle = "Jeunes nouveaux arrivants",
      icon = icon("user-plus"),
      color = "yellow"
    )
  })
  
  # -- graph DCRAN ----

  output$graph_na1 <- renderHighchart({
    df <- data_territoire() %>%
      filter(indicateur == "NA_DCRAN") %>%
      mutate(label = modalite_labels$NA_DCRAN[modalite], value = round(valeur)) %>%
      select(label, value)
    make_donut(df, filename = "NA_DCRAN")
  })

  # -- graph TACT ----

  output$graph_na2 <- renderHighchart({
    df <- data_territoire() %>%
      filter(indicateur == "TACT_NA") %>%
      mutate(label = modalite_labels$TACT[modalite], value = round(valeur)) %>%
      select(label, value)
    make_donut(df, filename = "TACT_NA")
  })

  # -- graph RECH ----

  output$graph_na3 <- renderHighchart({
    df <- data_territoire() %>%
      filter(indicateur == "RECH_NA", modalite %in% c("1", "2")) %>%
      mutate(label = modalite_labels$RECH[modalite], value = round(valeur)) %>%
      select(label, value)

    make_donut(df, filename = "RECH_NA")
  })

  # -- graph EMPL ----

  output$graph_na4 <- renderHighchart({
    df <- data_territoire() %>%
      filter(indicateur == "EMPL_NA", modalite != "ZZ") %>%
      mutate(label = modalite_labels$EMPL[modalite], value = round(valeur)) %>%
      select(label, value)

    make_donut(df, filename = "EMPL_NA")
  })

  # -- graph STOCD ----

  output$graph_na5 <- renderHighchart({
    df <- data_territoire() %>%
      filter(indicateur == "STOCD_NA") %>%
      mutate(label = modalite_labels$STOCD[modalite], value = round(valeur)) %>%
      select(label, value)
    make_donut(df, filename = "STOCD_NA")
  })

  # ------------------------------------------------------------
  # Graphiques migrations - jeunes qui partent (QP)
  # ------------------------------------------------------------

  # -- 📊 valuebox Nb jeunes "qui partent" ----
  output$box_nb_jeunes_QP <- renderValueBox({
    req(input$epci)
    
    valueBox(
      value = format(round(nb_jeunes_QP()), big.mark = " "),
      subtitle = "Jeunes partis",
      icon = icon("user-plus"),
      color = "red"
    )
  })
  
  # -- graph DCRAN ----

  output$graph_qp1 <- renderHighchart({
    df <- data_territoire() %>%
      filter(indicateur == "QP_DCRAN") %>%
      mutate(label = modalite_labels$QP_DCRAN[modalite], value = round(valeur)) %>%
      select(label, value)
    make_donut(df, filename = "QP_DCRAN")
  })

  # -- graph TACT ----

  output$graph_qp2 <- renderHighchart({
    df <- data_territoire() %>%
      filter(indicateur == "TACT_QP") %>%
      mutate(label = modalite_labels$TACT[modalite], value = round(valeur)) %>%
      select(label, value)
    make_donut(df, filename = "TACT_QP")
  })

  # -- graph DIPL ----

  output$graph_qp3 <- renderHighchart({
    df <- data_territoire() %>%
      filter(
        indicateur == "DIPL_QP",
        !modalite %in% c("01", "02", "03", "ZZ") # exclure
      ) %>%
      mutate(label = modalite_labels$DIPL[modalite], value = round(valeur)) %>%
      select(label, value)
    make_donut(df, filename = "DIPL_QP")
  })

  # -- graph EMPL ----

  output$graph_qp4 <- renderHighchart({
    df <- data_territoire() %>%
      filter(indicateur == "EMPL_QP", modalite != "ZZ") %>% # exclure ZZ
      mutate(label = modalite_labels$EMPL[modalite], value = round(valeur)) %>%
      select(label, value)

    make_donut(df, filename = "EMPL_QP")
  })

  # -- graph STOCD ----

  output$graph_qp5 <- renderHighchart({
    df <- data_territoire() %>%
      filter(indicateur == "STOCD_QP") %>%
      mutate(label = modalite_labels$STOCD[modalite], value = round(valeur)) %>%
      select(label, value)
    make_donut(df, filename = "STOCD_QP")
  })

  # ------------------------------------------------------------
  # Graphiques mobPRO + tableaux
  # ------------------------------------------------------------

  # -- 📊 valuebox Nb jeunes qui travaillent dans l'EPCI ----

  output$box_nb_jeunes_travaillent <- renderValueBox({
    valueBox(
      value = format(
        round(nb_jeunes_T_epci_mobPRO(), 0),
        big.mark = " ",
        scientific = FALSE
      ),
      subtitle = "jeunes travaillent sur le territoire",
      icon = icon("toolbox"),
      color = "red"
    )
  })

  # -- graph DCLT ----

  output$graph_flux_pro <- renderHighchart({
    req(data_territoire())
    d_mobPRO_ent <- data_territoire() %>% filter(indicateur == "FLUX_PRO_ENT")

    d_mobPRO_ent <- d_mobPRO_ent %>%
      mutate(
        COMMUNE = substr(modalite, 1, 5),       # récupère le code commune de résidence
        COMMUNE = str_pad(COMMUNE, 5, pad = "0")
      )

    territoire_liste <- communes %>%
      filter(EPCI == input$epci) %>%
      pull(COM)
    dpt <- input$departement
    choix_region <- regions[[input$region]]
    dpt_autres <- setdiff(choix_region, dpt)

    nb_jeunes_TR_epci_mobPRO <- round(sum(
      d_mobPRO_ent %>% filter(COMMUNE %in% territoire_liste) %>% pull(valeur)
    ))
    nb_jeunes_TR_dpt_mobPRO <- round(sum(d_mobPRO_ent %>% filter(
      substr(COMMUNE, 1, 2) == dpt, !(COMMUNE %in% territoire_liste)
    ) %>% pull(valeur)))
    nb_jeunes_TR_hdpt_mobPRO <- round(sum(
      d_mobPRO_ent %>% filter(substr(COMMUNE, 1, 2) %in% dpt_autres) %>% pull(valeur)
    ))
    nb_jeunes_TR_hregion_mobPRO <- round(sum(
      d_mobPRO_ent %>% filter(COMMUNE != "99999", !(
        substr(COMMUNE, 1, 2) %in% choix_region
      )) %>% pull(valeur)
    ))
    nb_jeunes_TR_etran_mobPRO <- round(sum(d_mobPRO_ent %>% filter(COMMUNE == "99999") %>% pull(valeur)))

    df <- data.frame(
      label = c(
        "Commune de l'EPCI",
        "Autre commune du département",
        "Autre département de la région",
        "Autre région",
        "À l'étranger"
      ),
      value = c(
        nb_jeunes_TR_epci_mobPRO,
        nb_jeunes_TR_dpt_mobPRO,
        nb_jeunes_TR_hdpt_mobPRO,
        nb_jeunes_TR_hregion_mobPRO,
        nb_jeunes_TR_etran_mobPRO
      )
    )

    make_donut(df, filename = "FLUX_MOB_PRO_ENT")
  })

  # -- graph TRANS ----

  output$graph_trans <- renderHighchart({
    req(data_territoire())
    df <- data_territoire() %>%
      filter(
        indicateur == "TRANS",
        modalite %in% names(modalite_labels$TRANS)
      ) %>%
      mutate(label = modalite_labels$TRANS[modalite], value = round(valeur)) %>%
      select(label, value)
    make_donut(df, filename = "TRANS")
  })

  # -- 📝 tableau flux pro entrants ----

  output$table_top10_travail <- DT::renderDataTable({
    req(input$epci)

    # 1 : communes de l’EPCI sélectionné
    communes_epci <- communes %>%
      filter(EPCI == input$epci) %>%
      pull(COM)

    # 2 : jeunes travaillant dans l’EPCI
    df <- resultats_epci %>%
      filter(indicateur == "FLUX_PRO_ENT") %>%
      tidyr::separate(modalite,
        into = c("commune_res", "commune_trav"),
        sep = "->"
      ) %>%
      filter(commune_trav %in% communes_epci) %>%
      group_by(commune_res) %>%
      summarise(
        Valeur = sum(valeur, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      filter(Valeur > 0) %>%
      arrange(desc(Valeur))

    # 3 : infos communes
    df <- df %>%
      left_join(communes %>% select(COM, LIBELLE, LIBEPCI),
        by = c("commune_res" = "COM")
      ) %>%
      mutate(
        Commune = ifelse(is.na(LIBELLE), commune_res, LIBELLE),
        EPCI = ifelse(is.na(LIBEPCI), "—", LIBEPCI)
      ) %>%
      select(COM = commune_res, Commune, EPCI, Valeur)

    # 4 : calcul de la part
    total_jeunes <- nb_jeunes_T_epci_mobPRO()
    df <- df %>%
      mutate(`Part (%)` = round(Valeur / total_jeunes * 100, 2))

    # 5 : afficher seulement le top 5
    df_top5 <- head(df, 5)

    # 6 : affichage du tableau
    DT::datatable(
      df_top5,
      rownames = FALSE,
      caption = htmltools::tags$caption(
        style = "caption-side: top; text-align: left;",
        "Top 5 des communes de résidence des jeunes travaillant dans l’EPCI sélectionné :"
      ),
      options = list(
        pageLength = 5,
        language = list(url = "//cdn.datatables.net/plug-ins/1.13.4/i18n/fr-FR.json")
      )
    )
  })

  # -- 📝 tableau flux pro entrants : téléchargement du tableau ----

  output$download_travail_ent <- downloadHandler(
    filename = function() {
      paste0("flux_pro_entiers_", input$epci, "_", Sys.Date(), ".csv")
    },
    content = function(file) {
      # même logique que dans renderDataTable, mais sans head()
      communes_epci <- communes %>%
        filter(EPCI == input$epci) %>%
        pull(COM)

      df <- resultats_epci %>%
        filter(indicateur == "FLUX_PRO_ENT") %>%
        tidyr::separate(modalite,
          into = c("commune_res", "commune_trav"),
          sep = "->"
        ) %>%
        filter(commune_trav %in% communes_epci) %>%
        group_by(commune_res) %>%
        summarise(
          Valeur = sum(valeur, na.rm = TRUE),
          .groups = "drop"
        ) %>%
        filter(Valeur > 0) %>%
        arrange(desc(Valeur)) %>%
        left_join(communes %>% select(COM, LIBELLE, LIBEPCI),
          by = c("commune_res" = "COM")
        ) %>%
        mutate(
          Commune = ifelse(is.na(LIBELLE), commune_res, LIBELLE),
          EPCI = ifelse(is.na(LIBEPCI), "—", LIBEPCI)
        ) %>%
        select(COM = commune_res, Commune, EPCI, Valeur) %>%
        mutate(`Part (%)` = round(Valeur / nb_jeunes_T_epci_mobPRO() * 100, 2))

      write.csv(df, file, row.names = FALSE, fileEncoding = "UTF-8")
    }
  )


  # -- 📝 tableau flux pro sortants ----

  output$table_top10_travail_sor <- DT::renderDataTable({
    req(input$epci)

    # 1 : communes de l’EPCI sélectionné
    communes_epci <- communes %>%
      filter(EPCI == input$epci) %>%
      pull(COM)

    # 2 : jeunes travaillant dans l’EPCI
    df <- resultats_epci %>%
      filter(indicateur == "FLUX_PRO_SOR") %>%
      tidyr::separate(modalite,
        into = c("commune_res", "commune_trav"),
        sep = "->"
      ) %>%
      filter(commune_res %in% communes_epci) %>%
      group_by(commune_trav) %>%
      summarise(
        Valeur = sum(valeur, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      filter(Valeur > 0) %>%
      arrange(desc(Valeur))

    # 3 : infos communes
    df <- df %>%
      left_join(communes %>% select(COM, LIBELLE, LIBEPCI),
        by = c("commune_trav" = "COM")
      ) %>%
      mutate(
        Commune = ifelse(is.na(LIBELLE), commune_trav, LIBELLE),
        EPCI = ifelse(is.na(LIBEPCI), "—", LIBEPCI)
      ) %>%
      select(COM = commune_trav, Commune, EPCI, Valeur)

    # 4 : calcul de la part
    total_jeunes <- nb_jeunes_T_epci_mobPRO()
    df <- df %>%
      mutate(`Part (%)` = round(Valeur / total_jeunes * 100, 2))

    # 5 : afficher seulement le top 5
    df_top5 <- head(df, 5)

    # 6 : affichage du tableau
    DT::datatable(
      df_top5,
      rownames = FALSE,
      caption = htmltools::tags$caption(
        style = "caption-side: top; text-align: left;",
        "Top 5 des communes de travail des jeunes résidents du territoire :"
      ),
      options = list(
        pageLength = 5,
        language = list(url = "//cdn.datatables.net/plug-ins/1.13.4/i18n/fr-FR.json")
      )
    )
  })

  # -- 📝 tableau flux pro sortants : téléchargement du tableau ----

  output$download_travail_sor <- downloadHandler(
    filename = function() {
      paste0("flux_pro_sortants_", input$epci, "_", Sys.Date(), ".csv")
    },
    content = function(file) {
      communes_epci <- communes %>%
        filter(EPCI == input$epci) %>%
        pull(COM)

      df <- resultats_epci %>%
        filter(indicateur == "FLUX_PRO_SOR") %>%
        tidyr::separate(modalite,
          into = c("commune_res", "commune_trav"),
          sep = "->"
        ) %>%
        filter(commune_res %in% communes_epci) %>%
        group_by(commune_trav) %>%
        summarise(
          Valeur = sum(valeur, na.rm = TRUE),
          .groups = "drop"
        ) %>%
        filter(Valeur > 0) %>%
        arrange(desc(Valeur)) %>%
        left_join(communes %>% select(COM, LIBELLE, LIBEPCI),
          by = c("commune_trav" = "COM")
        ) %>%
        mutate(
          Commune = ifelse(is.na(LIBELLE), commune_trav, LIBELLE),
          EPCI = ifelse(is.na(LIBEPCI), "—", LIBEPCI)
        ) %>%
        select(COM = commune_trav, Commune, EPCI, Valeur) %>%
        mutate(`Part (%)` = round(Valeur / nb_jeunes_T_epci_mobPRO() * 100, 2))

      write.csv(df, file, row.names = FALSE, fileEncoding = "UTF-8")
    }
  )

  # ------------------------------------------------------------
  # Graphiques mobSCO + tableaux
  # ------------------------------------------------------------

  # -- 📊 valuebox nb jeunes étudient dans l'EPCI ----

  output$box_nb_jeunes_etudient <- renderValueBox({
    valueBox(
      value = format(
        round(nb_jeunes_E_epci_mobSCO(), 0),
        big.mark = " ",
        scientific = FALSE
      ),
      subtitle = "jeunes étudient sur le territoire",
      icon = icon("graduation-cap"),
      color = "blue"
    )
  })

  # -- graph DCETUF ----

  output$graph_flux_sco <- renderHighchart({
    req(data_territoire())
    d_mobSCO_ent <- data_territoire() %>% filter(indicateur == "FLUX_SCO_ENT")

    d_mobSCO_ent <- d_mobSCO_ent %>%
      mutate(
        COMMUNE = substr(modalite, 1, 5),       # récupère le code commune de résidence
        COMMUNE = str_pad(COMMUNE, 5, pad = "0")
      )
    
    territoire_liste <- communes %>%
      filter(EPCI == input$epci) %>%
      pull(COM)
    dpt <- input$departement
    choix_region <- regions[[input$region]]
    dpt_autres <- setdiff(choix_region, dpt)

    nb_jeunes_SR_epci <- round(sum(
      d_mobSCO_ent %>% filter(COMMUNE %in% territoire_liste) %>% pull(valeur)
    ))
    nb_jeunes_SR_dpt <- round(sum(d_mobSCO_ent %>% filter(
      substr(COMMUNE, 1, 2) == dpt, !(COMMUNE %in% territoire_liste)
    ) %>% pull(valeur)))
    nb_jeunes_SR_hdpt <- round(sum(
      d_mobSCO_ent %>% filter(substr(COMMUNE, 1, 2) %in% dpt_autres) %>% pull(valeur)
    ))
    nb_jeunes_SR_hreg <- round(sum(
      d_mobSCO_ent %>% filter(COMMUNE != "99999", !(
        substr(COMMUNE, 1, 2) %in% choix_region
      )) %>% pull(valeur)
    ))
    nb_jeunes_SR_etr <- round(sum(d_mobSCO_ent %>% filter(COMMUNE == "99999") %>% pull(valeur)))

    df <- data.frame(
      label = c(
        "Commune de l'EPCI",
        "Autre commune du département",
        "Autre département de la région",
        "Autre région",
        "À l'étranger"
      ),
      value = c(
        nb_jeunes_SR_epci,
        nb_jeunes_SR_dpt,
        nb_jeunes_SR_hdpt,
        nb_jeunes_SR_hreg,
        nb_jeunes_SR_etr
      )
    )

    make_donut(df, filename = "FLUX_SCO_ENT")
  })

  # -- 📝 tableau flux sco entrants ----

  output$table_top10_sco_ent <- DT::renderDataTable({
    req(input$epci)

    # 1: communes de l’EPCI sélectionné
    communes_epci <- communes %>%
      filter(EPCI == input$epci) %>%
      pull(COM)

    # 2 : jeunes scolarisés dans l’EPCI
    df <- resultats_epci %>%
      filter(indicateur == "FLUX_SCO_ENT") %>%
      tidyr::separate(modalite,
        into = c("commune_res", "commune_sco"),
        sep = "->"
      ) %>%
      filter(commune_sco %in% communes_epci) %>%
      group_by(commune_res) %>%
      summarise(
        Valeur = sum(valeur, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      filter(Valeur > 0) %>%
      arrange(desc(Valeur))

    # 3 : infos communes
    df <- df %>%
      left_join(communes %>% select(COM, LIBELLE, LIBEPCI),
        by = c("commune_res" = "COM")
      ) %>%
      mutate(
        Commune = ifelse(is.na(LIBELLE), commune_res, LIBELLE),
        EPCI = ifelse(is.na(LIBEPCI), "—", LIBEPCI)
      ) %>%
      select(COM = commune_res, Commune, EPCI, Valeur)

    # 4: calcul de la part
    total_jeunes <- nb_jeunes_E_epci_mobSCO()
    df <- df %>%
      mutate(`Part (%)` = round(Valeur / total_jeunes * 100, 2))

    # 5 : afficher seulement le top 5
    df_top5 <- head(df, 5)

    # 6 : affichage du tableau
    DT::datatable(
      df_top5,
      rownames = FALSE,
      caption = htmltools::tags$caption(
        style = "caption-side: top; text-align: left;",
        "Top 5 des communes de résidence des jeunes scolarisés dans l’EPCI sélectionné :"
      ),
      options = list(
        pageLength = 5,
        language = list(url = "//cdn.datatables.net/plug-ins/1.13.4/i18n/fr-FR.json")
      )
    )
  })


  # -- 📝 tableau flux sco entrants : téléchargement du tableau ----

  output$download_sco_ent <- downloadHandler(
    filename = function() {
      paste0("flux_sco_entrants_", input$epci, "_", Sys.Date(), ".csv")
    },
    content = function(file) {
      communes_epci <- communes %>%
        filter(EPCI == input$epci) %>%
        pull(COM)

      df <- resultats_epci %>%
        filter(indicateur == "FLUX_SCO_ENT") %>%
        tidyr::separate(modalite,
          into = c("commune_res", "commune_sco"),
          sep = "->"
        ) %>%
        filter(commune_sco %in% communes_epci) %>%
        group_by(commune_res) %>%
        summarise(
          Valeur = sum(valeur, na.rm = TRUE),
          .groups = "drop"
        ) %>%
        filter(Valeur > 0) %>%
        arrange(desc(Valeur)) %>%
        left_join(communes %>% select(COM, LIBELLE, LIBEPCI),
          by = c("commune_res" = "COM")
        ) %>%
        mutate(
          Commune = ifelse(is.na(LIBELLE), commune_res, LIBELLE),
          EPCI = ifelse(is.na(LIBEPCI), "—", LIBEPCI)
        ) %>%
        select(COM = commune_res, Commune, EPCI, Valeur) %>%
        mutate(`Part (%)` = round(Valeur / nb_jeunes_E_epci_mobSCO() * 100, 2))

      write.csv(df, file, row.names = FALSE, fileEncoding = "UTF-8")
    }
  )

  # -- 📝 tableau flux sco sortants ----

  output$table_top10_sco_sor <- DT::renderDataTable({
    req(input$epci)

    # 1: communes de l’EPCI sélectionné
    communes_epci <- communes %>%
      filter(EPCI == input$epci) %>%
      pull(COM)

    # 2 : jeunes scolarisés dans l’EPCI
    df <- resultats_epci %>%
      filter(indicateur == "FLUX_SCO_SOR") %>%
      tidyr::separate(modalite,
        into = c("commune_res", "commune_sco"),
        sep = "->"
      ) %>%
      filter(commune_res %in% communes_epci) %>%
      group_by(commune_sco) %>%
      summarise(
        Valeur = sum(valeur, na.rm = TRUE),
        .groups = "drop"
      ) %>%
      filter(Valeur > 0) %>%
      arrange(desc(Valeur))

    # 3 : infos communes
    df <- df %>%
      left_join(communes %>% select(COM, LIBELLE, LIBEPCI),
        by = c("commune_sco" = "COM")
      ) %>%
      mutate(
        Commune = ifelse(is.na(LIBELLE), commune_sco, LIBELLE),
        EPCI = ifelse(is.na(LIBEPCI), "—", LIBEPCI)
      ) %>%
      select(COM = commune_sco, Commune, EPCI, Valeur)

    # 4: calcul de la part
    total_jeunes <- nb_jeunes_E_epci_mobSCO()
    df <- df %>%
      mutate(`Part (%)` = round(Valeur / total_jeunes * 100, 2))

    # 5 : afficher seulement le top 5
    df_top5 <- head(df, 5)

    # 6 : affichage du tableau
    DT::datatable(
      df_top5,
      rownames = FALSE,
      caption = htmltools::tags$caption(
        style = "caption-side: top; text-align: left;",
        "Top 5 des communes de scolarisation des jeunes résidents du territoire :"
      ),
      options = list(
        pageLength = 5,
        language = list(url = "//cdn.datatables.net/plug-ins/1.13.4/i18n/fr-FR.json")
      )
    )
  })


  # -- 📝 tableau flux sco entrants : téléchargement du tableau ----

  output$download_sco_sor <- downloadHandler(
    filename = function() {
      paste0("flux_sco_sortants_", input$epci, "_", Sys.Date(), ".csv")
    },
    content = function(file) {
      communes_epci <- communes %>%
        filter(EPCI == input$epci) %>%
        pull(COM)

      df <- resultats_epci %>%
        filter(indicateur == "FLUX_SCO_SOR") %>%
        tidyr::separate(modalite,
          into = c("commune_res", "commune_sco"),
          sep = "->"
        ) %>%
        filter(commune_res %in% communes_epci) %>%
        group_by(commune_sco) %>%
        summarise(
          Valeur = sum(valeur, na.rm = TRUE),
          .groups = "drop"
        ) %>%
        filter(Valeur > 0) %>%
        arrange(desc(Valeur)) %>%
        left_join(communes %>% select(COM, LIBELLE, LIBEPCI),
          by = c("commune_sco" = "COM")
        ) %>%
        mutate(
          Commune = ifelse(is.na(LIBELLE), commune_sco, LIBELLE),
          EPCI = ifelse(is.na(LIBEPCI), "—", LIBEPCI)
        ) %>%
        select(COM = commune_sco, Commune, EPCI, Valeur) %>%
        mutate(`Part (%)` = round(Valeur / nb_jeunes_E_epci_mobSCO() * 100, 2))

      write.csv(df, file, row.names = FALSE, fileEncoding = "UTF-8")
    }
  )

  # ------------------------------------------------------------
  # Graphiques Parc de logements
  # ------------------------------------------------------------

  # -- 📊 valuebox nb total logements ----

  output$box_nb_logements <- renderValueBox({
    valueBox(
      value = format(
        round(nb_logements_total(), 0),
        big.mark = " ",
        scientific = FALSE
      ),
      subtitle = "logements au total",
      icon = icon("home"),
      color = "aqua"
    )
  })

  # -- 📊 valuebox nb résidences principales (RP) ----

  output$box_nb_resprinc <- renderValueBox({
    valueBox(
      value = format(
        round(nb_resprinc(), 0),
        big.mark = " ",
        scientific = FALSE
      ),
      subtitle = "résidences principales",
      icon = icon("building"),
      color = "light-blue"
    )
  })

  # -- 📊 valuebox nb total résidences principales occupées par des jeunes ----

  output$box_nb_resprinc_jeunes <- renderValueBox({
    total <- nb_resprinc()
    jeunes <- nb_resprinc_jeunes()
    pourcentage <- if (!is.na(total) &&
      total > 0) {
      round(jeunes / total * 100, 2)
    } else {
      NA
    }

    valueBox(
      value = paste0(
        format(
          round(jeunes, 0),
          big.mark = " ",
          scientific = FALSE
        ),
        " (",
        pourcentage,
        " %)"
      ),
      subtitle = "résidences principales occupées par des jeunes",
      icon = icon("user-graduate"),
      color = "teal"
    )
  })

  # -- graph CATL ----

  output$graph_log_catl <- renderHighchart({
    df <- data_territoire() %>%
      filter(
        indicateur == "LOG_CATL",
        modalite %in% names(modalite_labels$CATL)
      ) %>%
      mutate(label = modalite_labels$CATL[modalite], value = round(valeur)) %>%
      select(label, value)
    make_donut(df, filename = "LOG_CATL")
  })

  # -- graph comparatif RP/RP jeunes sur TYPL ----

  output$graph_log_typl <- renderHighchart({
    # ---- RP
    df_rp <- data_territoire() %>%
      filter(
        indicateur == "LOG_TYPL_RP",
        modalite %in% names(modalite_labels$TYPL)
      ) %>%
      mutate(label = modalite_labels$TYPL[modalite], value = valeur) %>%
      group_by(label) %>%
      summarise(value = sum(value, na.rm = TRUE), .groups = "drop") %>%
      mutate(pct_RP = 100 * value / sum(value, na.rm = TRUE)) %>%
      select(label, pct_RP)

    # ---- RP JEUNES
    df_j <- data_territoire() %>%
      filter(
        indicateur == "LOG_TYPL_RP_JEUNES",
        modalite %in% names(modalite_labels$TYPL)
      ) %>%
      mutate(label = modalite_labels$TYPL[modalite], value = valeur) %>%
      group_by(label) %>%
      summarise(value = sum(value, na.rm = TRUE), .groups = "drop") %>%
      mutate(pct_J = 100 * value / sum(value, na.rm = TRUE)) %>%
      select(label, pct_J)

    # ---- Jointure + ordre des labels
    label_levels <- unname(modalite_labels$TYPL)
    df <- full_join(df_rp, df_j, by = "label") %>%
      mutate(
        pct_RP = ifelse(is.na(pct_RP), 0, pct_RP),
        pct_J = ifelse(is.na(pct_J), 0, pct_J)
      ) %>%
      arrange(factor(label, levels = label_levels))

    # ---- Deux catégories (colonnes)
    categories <- c("Résidences principales", "RP jeunes")

    # ---- Une série par modalité
    series_list <- lapply(seq_len(nrow(df)), function(i) {
      list(name = as.character(df$label[i]), data = as.numeric(c(df$pct_RP[i], df$pct_J[i])))
    })

    # ---- Graphique
    highchart() %>%
      hc_chart(type = "column") %>%
      hc_xAxis(categories = categories) %>%
      hc_yAxis(
        min = 0,
        max = 100,
        title = list(text = "Part en %")
      ) %>%
      hc_plotOptions(column = list(
        stacking = "percent",
        dataLabels = list(
          enabled = TRUE,
          format = "{point.percentage:.1f}%",
          # affichage arrondi sur la barre
          style = list(
            color = "#000000",
            textOutline = "none",
            fontSize = "11px"
          )
        )
      )) %>%
      hc_tooltip(
        useHTML = TRUE,
        headerFormat = "",
        pointFormat = "<b>{series.name}</b><br/>{point.y:.1f}%"
      ) %>% # arrondi au dixième sur le survol
      hc_add_series_list(series_list) %>%
      hc_colors(c(
        "#1b9e77",
        "#d95f02",
        "#7570b3",
        "#e7298a",
        "#66a61e",
        "#e6ab02",
        "#a6761d"
      )) %>%
      hc_legend(align = "center", verticalAlign = "bottom") %>%
      hc_exporting(enabled = TRUE, filename = "Type_de_logement") %>% # ✅ bouton d’export (PNG, SVG, etc.)
      hc_title(text = NULL)
  })

  # -- graph comparatif RP/RP jeunes sur NBPI ----

  output$graph_log_nbpi <- renderHighchart({
    # ---- RP
    df_rp <- data_territoire() %>%
      filter(indicateur == "LOG_NBPI_RP") %>%
      mutate(
        # 🔹 Fusionner les modalités 05 à 20
        modalite = ifelse(modalite %in% sprintf("%02d", 5:20), "05p", modalite),
        label = dplyr::case_when(
          modalite == "05p" ~ "5 pièces et plus",
          TRUE ~ modalite_labels$NBPI[modalite]
        ),
        value = valeur
      ) %>%
      # filtrer après fusion
      filter(modalite %in% names(modalite_labels$NBPI)) %>%
      group_by(label) %>%
      summarise(value = sum(value, na.rm = TRUE), .groups = "drop") %>%
      mutate(pct_RP = 100 * value / sum(value, na.rm = TRUE)) %>%
      select(label, pct_RP)

    # ---- RP JEUNES
    df_j <- data_territoire() %>%
      filter(indicateur == "LOG_NBPI_RP_JEUNES") %>%
      mutate(
        modalite = ifelse(modalite %in% sprintf("%02d", 5:20), "05p", modalite),
        label = dplyr::case_when(
          modalite == "05p" ~ "5 pièces et plus",
          TRUE ~ modalite_labels$NBPI[modalite]
        ),
        value = valeur
      ) %>%
      filter(modalite %in% names(modalite_labels$NBPI)) %>%
      group_by(label) %>%
      summarise(value = sum(value, na.rm = TRUE), .groups = "drop") %>%
      mutate(pct_J = 100 * value / sum(value, na.rm = TRUE)) %>%
      select(label, pct_J)

    # ---- Jointure + ordre des labels
    label_levels <- c(
      "1 pièce",
      "2 pièces",
      "3 pièces",
      "4 pièces",
      "5 pièces et plus",
      "Hors résidence principale",
      "Hors logement ordinaire"
    )

    df <- full_join(df_rp, df_j, by = "label") %>%
      mutate(
        pct_RP = ifelse(is.na(pct_RP), 0, pct_RP),
        pct_J = ifelse(is.na(pct_J), 0, pct_J)
      ) %>%
      arrange(factor(label, levels = label_levels))

    # ---- Deux catégories (colonnes)
    categories <- c("Résidences principales", "RP jeunes")

    # ---- Une série par modalité
    series_list <- lapply(seq_len(nrow(df)), function(i) {
      list(name = as.character(df$label[i]), data = as.numeric(c(df$pct_RP[i], df$pct_J[i])))
    })

    # ---- Graphique
    highchart() %>%
      hc_chart(type = "column") %>%
      hc_xAxis(categories = categories) %>%
      hc_yAxis(
        min = 0,
        max = 100,
        title = list(text = "Part en %")
      ) %>%
      hc_plotOptions(column = list(
        stacking = "percent",
        dataLabels = list(
          enabled = TRUE,
          format = "{point.percentage:.1f}%",
          style = list(
            color = "#000000",
            textOutline = "none",
            fontSize = "11px"
          )
        )
      )) %>%
      hc_tooltip(
        useHTML = TRUE,
        headerFormat = "",
        pointFormat = "<b>{series.name}</b><br/>{point.y:.1f}%"
      ) %>%
      hc_add_series_list(series_list) %>%
      hc_colors(c(
        "#1b9e77",
        "#d95f02",
        "#7570b3",
        "#e7298a",
        "#66a61e",
        "#e6ab02",
        "#a6761d"
      )) %>%
      hc_legend(align = "center", verticalAlign = "bottom") %>%
      hc_exporting(enabled = TRUE, filename = "Nombre_de_pieces") %>%
      hc_title(text = NULL)
  })

  # ------------------------------------------------------------
  # Graphiques Conditions de logement
  # ------------------------------------------------------------

  # -- graph comparatif RP/RP jeunes sur ANEM ----

  output$graph_log_anem <- renderHighchart({
    # ---- RP
    df_rp <- data_territoire() %>%
      filter(indicateur == "LOG_ANEM_RP") %>%
      mutate(label = modalite_labels$ANEM[modalite], value = valeur) %>%
      filter(modalite %in% names(modalite_labels$ANEM)) %>%
      group_by(label) %>%
      summarise(value = sum(value, na.rm = TRUE), .groups = "drop") %>%
      mutate(pct_RP = 100 * value / sum(value, na.rm = TRUE)) %>%
      select(label, pct_RP)

    # ---- RP JEUNES
    df_j <- data_territoire() %>%
      filter(indicateur == "LOG_ANEM_RP_JEUNES") %>%
      mutate(label = modalite_labels$ANEM[modalite], value = valeur) %>%
      filter(modalite %in% names(modalite_labels$ANEM)) %>%
      group_by(label) %>%
      summarise(value = sum(value, na.rm = TRUE), .groups = "drop") %>%
      mutate(pct_J = 100 * value / sum(value, na.rm = TRUE)) %>%
      select(label, pct_J)

    # ---- Jointure + ordre logique des labels
    label_levels <- c(
      "Moins de deux ans",
      "2 à 4 ans",
      "5 ans et plus",
      "Logement ordinaire inoccupé",
      "Hors logement ordinaire"
    )

    df <- full_join(df_rp, df_j, by = "label") %>%
      mutate(
        pct_RP = ifelse(is.na(pct_RP), 0, pct_RP),
        pct_J = ifelse(is.na(pct_J), 0, pct_J)
      ) %>%
      arrange(factor(label, levels = label_levels))

    # ---- Deux catégories (colonnes)
    categories <- c("Résidences principales", "RP jeunes")

    # ---- Une série par modalité
    series_list <- lapply(seq_len(nrow(df)), function(i) {
      list(name = as.character(df$label[i]), data = as.numeric(c(df$pct_RP[i], df$pct_J[i])))
    })

    # ---- Graphique
    highchart() %>%
      hc_chart(type = "column") %>%
      hc_xAxis(categories = categories) %>%
      hc_yAxis(
        min = 0,
        max = 100,
        title = list(text = "Part en %")
      ) %>%
      hc_plotOptions(column = list(
        stacking = "percent",
        dataLabels = list(
          enabled = TRUE,
          format = "{point.percentage:.1f}%",
          style = list(
            color = "#000000",
            textOutline = "none",
            fontSize = "11px"
          )
        )
      )) %>%
      hc_tooltip(
        useHTML = TRUE,
        headerFormat = "",
        pointFormat = "<b>{series.name}</b><br/>{point.y:.1f}%"
      ) %>%
      hc_add_series_list(series_list) %>%
      hc_colors(c("#1b9e77", "#d95f02", "#7570b3", "#e7298a", "#66a61e")) %>%
      hc_legend(align = "center", verticalAlign = "bottom") %>%
      hc_exporting(enabled = TRUE, filename = "Anciennete_emmenagement") %>%
      hc_title(text = NULL)
  })

  # -- graph comparatif RP/RP jeunes sur HLML ----

  output$graph_log_hlml <- renderHighchart({
    # ---- RP
    df_rp <- data_territoire() %>%
      filter(indicateur == "LOG_HLM_RP") %>%
      mutate(label = modalite_labels$HLML[modalite], value = valeur) %>%
      filter(modalite %in% names(modalite_labels$HLML)) %>%
      group_by(label) %>%
      summarise(value = sum(value, na.rm = TRUE), .groups = "drop") %>%
      mutate(pct_RP = 100 * value / sum(value, na.rm = TRUE)) %>%
      select(label, pct_RP)

    # ---- RP JEUNES
    df_j <- data_territoire() %>%
      filter(indicateur == "LOG_HLM_RP_JEUNES") %>%
      mutate(label = modalite_labels$HLML[modalite], value = valeur) %>%
      filter(modalite %in% names(modalite_labels$HLML)) %>%
      group_by(label) %>%
      summarise(value = sum(value, na.rm = TRUE), .groups = "drop") %>%
      mutate(pct_J = 100 * value / sum(value, na.rm = TRUE)) %>%
      select(label, pct_J)

    # ---- Jointure + ordre logique des labels
    label_levels <- c(
      "Appartient à un organisme HLM",
      "N'appartient pas à un organisme HLM",
      "Hors logement ordinaire"
    )

    df <- full_join(df_rp, df_j, by = "label") %>%
      mutate(
        pct_RP = ifelse(is.na(pct_RP), 0, pct_RP),
        pct_J = ifelse(is.na(pct_J), 0, pct_J)
      ) %>%
      arrange(factor(label, levels = label_levels))

    # ---- Deux catégories (colonnes)
    categories <- c("Résidences principales", "RP jeunes")

    # ---- Une série par modalité
    series_list <- lapply(seq_len(nrow(df)), function(i) {
      list(name = as.character(df$label[i]), data = as.numeric(c(df$pct_RP[i], df$pct_J[i])))
    })

    # ---- Graphique
    highchart() %>%
      hc_chart(type = "column") %>%
      hc_xAxis(categories = categories) %>%
      hc_yAxis(
        min = 0,
        max = 100,
        title = list(text = "Part en %")
      ) %>%
      hc_plotOptions(column = list(
        stacking = "percent",
        dataLabels = list(
          enabled = TRUE,
          format = "{point.percentage:.1f}%",
          style = list(
            color = "#000000",
            textOutline = "none",
            fontSize = "11px"
          )
        )
      )) %>%
      hc_tooltip(
        useHTML = TRUE,
        headerFormat = "",
        pointFormat = "<b>{series.name}</b><br/>{point.y:.1f}%"
      ) %>%
      hc_add_series_list(series_list) %>%
      hc_colors(c("#1b9e77", "#d95f02", "#7570b3")) %>%
      hc_legend(align = "center", verticalAlign = "bottom") %>%
      hc_exporting(enabled = TRUE, filename = "Logement_social") %>%
      hc_title(text = NULL)
  })
}
