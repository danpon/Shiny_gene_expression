# ==== TASk - 7 themes ==========================================================
# ==== global.R START ===========================================================
#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
library(shiny)
library(ggplot2)
library(DT)
library(shinythemes)
library(shinydashboard)
library(GeneBook)
gn <- read.csv('./inc/genes_names.csv')
g1 <- read.csv("./inc/g1.csv")
g2 <- read.csv("./inc/g2.csv")
g3 <- read.csv("./inc/g3.csv")
# ===================================================== global.R END ============

# ==== ui.R START ===============================================================
# Define UI for application that draws a histogram
#
# uncomment and run the following line to
# file.edit('C:/Users/Administrator/shiny2020/Task-6/themes/www/mytheme.css')
# file.edit('C:/Users/Administrator/shiny2020/Task-6/themes/www/bootstrap.css')
# file.edit('C:/Users/Administrator/shiny2020/Task-6/themes/www/bootstrap.min.css')
#
# ==== NEW UI using shinydashboard ==============================================
ui <- dashboardPage(
    dashboardHeader(
        title = "Gene Expression"
        ,
        # ==== Messages Menu =======================================
        dropdownMenu(
            type = "messages",
            messageItem(
                from = "The Other Side",
                message = "I'll leave that up to you.",
                href = "http://coursera.org/search?query=rhyme",
                icon = icon("user"),  # Try another icon: 'question', 'life-ring'
                time = "13:31")       # Try different date/time format '2020-4-29', '2020-4-29 01:45'
            
            # , # If you add one more messageItem you need one more comma!
            
        ),
        
        # ==== Tasks Menu ==========================================
        dropdownMenu(
            type = "tasks",
            badgeStatus = "success",
            # Other badgeStatus are 'primary', 'success', 'info', 'warning', 'danger', NULL
            
            taskItem(
                value = 92,
                color = "green",
                text = "Documentation")
            ,
            taskItem(
                value = 75,
                color = "yellow",
                text = "Sequencing")
            ,
            taskItem(
                value = 17,
                color = "aqua",
                text = "Project X"
            ),
            
            taskItem(
                value = 19,
                color = "red",
                text = "Known Interaction Network")
        ),
        
        # ==== Notifications menu ==================================
        dropdownMenu(
            type = "notifications",
            notificationItem(
                text = "5 new users today",
                icon = icon("users"),
                status = "info"
            ),
            
            notificationItem(
                text = "12 items delivered",
                icon = icon("truck"),
                status = "success"
            ),
            notificationItem(
                text = "Server load at 86%",
                icon = icon("exclamation-triangle"),
                status = "warning"
            )
        ),
        
        # ====  Message Menu filled by server function =============
         dropdownMenuOutput("messageMenu")
    ) 
    ,
    
    dashboardSidebar(
        selectInput(
            inputId = "G_groups",
            label = "A- Choose Group to plot:",
            choices = c(
                "1- Genes down regulated in resistant while
                                   up regulated in susceptible " = "g1",
                "2- Genes down regulated in both resistant
                                   and susceptible" = "g2",
                "3- Genes up regulated in both resistant and
                                   susceptible " = "g3"
            )
        )
        ,
        # We need comma between each input
        
        selectInput(
            inputId = "My_dataset",
            label = "B- Choose Gene ID to show it's full name:",
            #choices = levels(gn$GeneID)
            choices = gn$GeneID
        ),
        
        selectInput(
            inputId = "More_info",
            label = "C- Documentation:",
            choices = c(
                'Introduction',
                'Information',
                'Help',
                'References',
                'Table-1',
                'Table-2',
                'Table-3'
            ),
            selected = "Introduction"
        )
        
    ),
    
    dashboardBody(
        downloadButton(outputId = "downloadData",
                       label = "Download Data"),
        
        plotOutput(
            outputId = "myplot",
            width = "100%",
            height = "400px"
        ),
        
        verbatimTextOutput(outputId = "odataset"),
        
        uiOutput(outputId = "odataset_link"),
        
        uiOutput(outputId = "text1")
        
    )
)

# ===================================================== NEW UI END ==============
# ===================================================== ui.R END ================

# ==== server.R START ===========================================================
# Define server logic
# To access any input use input$[inputId]
#                     ex. input$G_groups (the first select input value)
# To assign any output use output$[outputId] output$
#                      ex. output$myplot (assign the plot output)
server <- function(input, output) {
    output$odataset <- renderPrint({
        paste(input$My_dataset," = ", gn$Gene[gn$GeneID==input$My_dataset])
    })
    
    # using GeneBook library to construct a link to the gene database
    abbreviation <- reactive((GeneCard_ID_Convert(input$My_dataset)))
    
    # output for the odataset_link
    output$odataset_link <- renderPrint({
        tags$a(
            href = paste(
                "https://www.genecards.org/cgi-bin/carddisp.pl?gene=",
                as.character(abbreviation()[1]),
                sep = ''
            ),
            as.character(abbreviation()[1])
        )
    })
    
    
    full_file_name <-reactive(paste("./inc/", input$G_groups, ".csv", sep = ""))
    
    output$downloadData <- downloadHandler(
        
        filename = full_file_name,
        
        content = function(file){
            write.csv(read.csv(full_file_name()), quote = FALSE,file)
        } )
    
    output$myplot = renderPlot({
        g_x <- read.csv(full_file_name())
        
        p <- ggplot(g_x, aes(x=Gene_ID, y=log(Relative_expression_levels),
                             fill=Resistant_or_Susceptible_strains)) +
            
            geom_bar(stat="identity", position=position_dodge()) +
            geom_errorbar(aes(ymin=log(Relative_expression_levels)-(SD/10),
                              ymax=log(Relative_expression_levels)+(SD/10)),width=.3,
                          position=position_dodge(.9))
        p + scale_fill_brewer(palette="Paired")+
            ggtitle(paste("Relative expression levels of candidate gene list","\n",
                          "expressed as mean fold difference between pre- and",
                          "\n", "post-infection ± standard deviation (SD) ")) +
            guides(fill=guide_legend(title=NULL))
        
        p$theme <- theme(axis.text.x = element_text(angle = 90, hjust = 1))
        p$labels$x <- "Gene ID"
        p$labels$y <- "Log (base 10) Relative Expression Levels"
        p$labels$fill <- NULL
        
        return(p)
        
    })
    
    
    # renderDT() from DT library is a replacement for Shiny renderDataTable()
    output$datatable1 <- renderDT(datatable(g1))
    output$datatable2 <- renderDT(datatable(g2))
    output$datatable3 <- renderDT(datatable(g3))
    
    output$text1 <- renderUI({
        if(input$More_info=="Introduction"){
            includeHTML("inc/introduction.html")
        } else if(input$More_info=="Information"){
            includeHTML("inc/information.html")
        } else if(input$More_info=="Help"){
            includeHTML("inc/help.html")
        } else if(input$More_info=="Table-1"){
            DTOutput('datatable1')
        } else if(input$More_info=="Table-2"){
            DTOutput('datatable2')
        } else if(input$More_info=="Table-3"){
            DTOutput('datatable3')
        } else if(input$More_info=="References"){
            includeHTML("inc/references.html")
        }
    })
    
    output$messageMenu <- renderMenu({
        # Code to generate each of the messageItems here, in a list. This assumes
        # that gn is a data frame with two columns, 'GeneID' and 'Gene'.
        messageList <- apply(gn[1:3, ], 1, function(row) {
            messageItem(
                from = row[["GeneID"]],
                message = row[["Gene"]],
                icon = icon("question"),
                href = paste("https://www.genecards.org/cgi-bin/carddisp.pl?gene=",
                             as.character(row[["GeneID"]]),
                             sep = '')
            )
        })

        # This is equivalent to calling:
        #   dropdownMenu(type="messages", msgs[[1]], msgs[[2]], ...)
        dropdownMenu(type = "messages", .list = messageList)
    })
}
# ===================================================== server.R END ============

# Run the application
shinyApp(ui = ui, server = server)
