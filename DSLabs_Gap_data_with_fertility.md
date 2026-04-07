
     gap_dslabs <- load_gapminder_dslabs()
       
     head(gap_dslabs)      
                   country year infant_mortality life_expectancy fertility population          gdp continent          region   gdp_bil
     1             Albania 1960           115.40           62.87      6.19    1636054           NA    Europe Southern Europe        NA
     2             Algeria 1960           148.20           47.50      7.65   11124892  13828152297    Africa Northern Africa  13828.15
     3              Angola 1960           208.00           35.98      7.32    5270844           NA    Africa   Middle Africa        NA
     4 Antigua and Barbuda 1960               NA           62.97      4.43      54681           NA  Americas       Caribbean        NA
     5           Argentina 1960            59.87           65.39      3.11   20619075 108322326649  Americas   South America 108322.33
     6             Armenia 1960               NA           66.86      4.55    1867396           NA      Asia    Western Asia        NA


Life expectancy by gross domestic product per capita (billions) 


     motionChart(gap_dslabs,
               id           = "country",
               time         = "year",
               x            = "gdp_bil",
               y            = "life_expectancy",
               size         = "population",
               color        = "continent",
               x_log        = TRUE,
               duration     = 17000,
               trails       = TRUE,
               trail_length = 4,
              hover_focus   = c("group", "entity")[1],
             tooltip_follow = FALSE,
               label_colour = TRUE,
               x_label      = "Gross Domestic Product per Capita (billions)",
               y_label      = "Life Expectancy",
               title        = "Gapminder — Health & Wealth of Nations")          
               

Life expectancy by fertility 


     motionChart(gap_dslabs,
               id           = "country",
               time         = "year",
               x            = "fertility",
               y            = "life_expectancy",
               size         = "population",
               color        = "continent",
               x_log        = FALSE,
               duration     = 20000,
               trails       = TRUE,
               trail_length = 4,
              hover_focus   = c("group", "entity")[1],
             tooltip_follow = FALSE,
               label_colour = TRUE,
               x_label      = "Fertility rate, total (births per woman)",
               y_label      = "Life Expectancy",
               title        = "Gapminder — Health & Wealth of Nations")          
                       
            
            
More Gapminder data: https://www.gapminder.org/data/            

A Gapminder bubble chart is here: https://observablehq.com/@gapminder/bubblechart-tutorial-solved

