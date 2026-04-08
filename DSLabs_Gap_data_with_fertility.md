```r
library(MotionChart)
gap_dslabs <- load_gapminder_dslabs()
head(gap_dslabs)
#
```     

 <pre><code><sub>  
              country year infant_mortality life_expectancy   fertility   population         gdp  continent          region gdpPercap
1             Albania 1960           115.40           62.87        6.19      1636054           NA    Europe Southern Europe        NA
2             Algeria 1960           148.20           47.50        7.65     11124892  13828152297    Africa Northern Africa  1242.992
3              Angola 1960           208.00           35.98        7.32      5270844           NA    Africa   Middle Africa        NA
4 Antigua and Barbuda 1960               NA           62.97        4.43        54681           NA  Americas       Caribbean        NA
5           Argentina 1960            59.87           65.39        3.11     20619075 108322326649  Americas   South America  5253.501
6             Armenia 1960               NA           66.86        4.55      1867396           NA      Asia    Western Asia        NA
</sub></code></pre>
<br>
<br>
Life expectancy by gross domestic product per capita


     motionChart(gap_dslabs,
               id           = "country",
               time         = "year",
               x            = "gdpPercap",
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
               x_label      = "Gross Domestic Product per Capita",
               y_label      = "Life Expectancy",
               title        = "Gapminder — Health & Wealth of Nations")
               # 

               
<br>
<br>
Life expectancy by fertility 


     motionChart(gap_dslabs,
               id           = "country",
               time         = "year",
               x            = "fertility",
               y            = "life_expectancy",
               size         = "population",
               color        = "continent",
               x_log        = FALSE,
               duration     = 20000,  # Larger values move the bubbles slower
               trails       = TRUE,
               trail_length = 4,
              hover_focus   = c("group", "entity")[1],
             tooltip_follow = FALSE,
               label_colour = TRUE,
               x_label      = "Fertility rate, total (births per woman)",
               y_label      = "Life Expectancy",
               title        = "Gapminder — Health & Wealth of Nations")  
               # 
                       
<br>
<br>     
# Life expectancy by fertility for United States and Vietnam only (Hans uses this example) <br>
&nbsp;&nbsp; # Note that the trail length is now the number or rows of the data, this more matches Hans example.


     US.Viet <- gap_dslabs[gap_dslabs$country %in% c('United States', 'Vietnam'), ]    
     
     motionChart(US.Viet,
               id           = "country",
               time         = "year",
               x            = "fertility",
               y            = "life_expectancy",
               size         = "population",
               color        = "continent",
               x_log        = FALSE,
               duration     = 20000,
               trails       = TRUE,
               trail_length = nrow(US.Viet),
              hover_focus   = c("group", "entity")[1],
             tooltip_follow = FALSE,
               label_colour = TRUE,
               x_label      = "Fertility rate, total (births per woman)",
               y_label      = "Life Expectancy",
               title        = "Gapminder — US and Vietnam")  
               #
<br>
<br>             
Fertility rate vs. infant mortality, sized by population


     motionChart(gap_dslabs,        
                 id       = "country",
                 time     = "year",
                 x        = "fertility",
                 y        = "infant_mortality",
                 size     = "population",
                 color    = "continent",
                 x_log    = FALSE,
               duration   = 30000,  # Larger values move the bubbles slower
           tooltip_follow = FALSE,
                 title    = "Fertility & Infant Mortality - After Hans Rosling")   
                 # 
            

<br>
<br>        

More Gapminder data: https://www.gapminder.org/data/            

A Gapminder bubble chart is here: https://observablehq.com/@gapminder/bubblechart-tutorial-solved <br>
(Of course, the motionChart function will handle any data of the correct format and has trails.)

