library(shiny)
library(networkD3)
library(shinydashboard)
library(DT)

shinyUI(fluidPage(theme = "bootstrap.css", 
    tags$style(type="text/css",
      "label {font-size: 12px;}",
      #"label {font-weight: bold;}",
      ".recalculating {opacity: 1.0;}"),
   
    
    
    dashboardPage(skin = "yellow",
      
      # dashboardHeader(
      #   title = tags$h3("MD-Miner"),
      #   titleWidth= 230
      # ),
      
      dashboardHeader(title = tags$b("MD-Miner")),

      dashboardSidebar(
        #width = 450,
        fileInput('file1',tags$h5(tags$b("Choose Patient Fold Change Data")), 
                  accept=c('text/csv', 'text/comma-separated-values,text/plain', '.csv')),
        selectInput("networkType", tags$h5(tags$b("Choose A Network Type:")), 
                  choices = c("Patient-specific Network", "Drug Network", "Patient-drug Merge Network"))
        
        # tags$div("test this is a ag  g agasddf")
        # # sidebarPanel(), 
        # titlePanel(
        #   tags$h4('MD-Miner: test this a good example!')
        #     tags$head(
        #       # tags$style(type="text/css", "label.radio { display: inline-block; }", ".radio input[type=\"radio\"] { float: none; }"),
        #       # tags$style(type="text/css", "select { max-width: 200px; }"),
        #       # tags$style(type="text/css", "textarea { max-width: 185px; }"),
        #       # tags$style(type="text/css", ".jslider { max-width: 200px; }"),
        #       # tags$style(type='text/css', ".well { max-width: 310px; }"),
        #       # tags$style(type='text/css', ".span4 { max-width: 310px; }")
              
        #     ),            
        # )
      
        #tags$style

        # mainPanel(
        #   h4('MD-Miner')
        # )


        # tags$h5(mainPanel("MD-Miner: Mechanism-Drug Miner"))
        # mainPanel("test this is a goodlsffsfsd fdsfs fsf sdf sfs"),

        # tags$style(type="text/css", "textarea { max-width: 100px; }, h2('test') "),
        # tags$h5(tags$b("App Description:")),
        # tags$h5("-Upload fold change data of a patient in .txt file."),
        # tags$h5("-Drug suggestion will be generated in descending order."),
        # tags$h5("-Click the drug you want in the table to display drug network and merge network."),
        # tags$h5("-Choose a specific network to display the large window."),
        # tags$h5("-Click the title of each block to download corresponding data."),
        # tags$h5("Contact: FuhaiLi@osumc.edu")

      ),

      dashboardBody( 
        fluidRow(
          box(title=downloadButton('downloadData', tags$b("Top Drug Suggestions")), value = tags$p(style = "font-size: 10px;", tags$b()),  solidHeader= TRUE,collapsible = TRUE, DT::dataTableOutput("table"), width =12)
          ),
        fixedRow(
          box(title=tags$b("Chosen Displayed Network"), value = tags$p(style = "font-size: 10px;"), solidHeader= TRUE, collapsible = TRUE,width =12, verbatimTextOutput("text"), forceNetworkOutput("selectedNetwork", width=1000))
        ),
        fluidRow(
          box(title=downloadButton('downloadData1', tags$b("Patient Information and Gene Network")), value = tags$p(style = "font-size: 10px;"), solidHeader= TRUE, collapsible = TRUE, forceNetworkOutput("patientNetwork", width = 400)),
          box(title=downloadButton('downloadData2', tags$b("Drug Network")), value = tags$p(style = "font-size: 10px;"), solidHeader= TRUE, collapsible = TRUE,  forceNetworkOutput("drugNetwork", width = 400)),
          box(title=downloadButton('downloadData3', tags$b("Drug Suggestion and Gene Network")), value = tags$p(style = "font-size: 10px;"), solidHeader= TRUE, collapsible = TRUE, forceNetworkOutput("mergeNetwork", width = 400))
          )
        # fixedRow(
        #   column(6,
        #     forceNetworkOutput("force")
        #   ),
        #   column(6,
        #     forceNetworkOutput("geneforce")
        #   ),
          )
        )
      )
    )
  
