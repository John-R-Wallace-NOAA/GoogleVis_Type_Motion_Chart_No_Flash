# GoogleVis_Type_Motion_Chart_No_Flash
GoogleVis type motion chart that doesn't need Flash to work.


Usage:

     gap <- load_gapminder()
     
     motionChart(gap,
                 id           = "country",
                 time         = "year",
                 x            = "gdpPercap",
                 y            = "lifeExp",
                 size         = "pop",
                 color        = "continent",
                 x_log        = TRUE,
                 duration     = 17000,
                 trails       = TRUE,
                 trail_length = 4,
                hover_focus   = c("group", "entity")[1],
               tooltip_follow = FALSE,
                 label_colour = TRUE,
                 x_label      = "Gross Domestic Product per Capita",
                 y_label      = "Life Expectancy",
                 title        = "Gapminder — Health & Wealth of Nations")
