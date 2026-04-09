#' Load the DSLabs Gapminder dataset
#' @return A data frame with columns: country, year, infant_mortality, life_expectancy, fertility, population, gdp, continent, region, gdpPercap
#' @export
load_gapminder_dslabs <- 
function () 
{
    if (!requireNamespace("dslabs", quietly = TRUE)) {
        message("Installing dslabs package...")
        install.packages("dslabs", repos = "https://cloud.r-project.org")
    }
    
    gap_dslabs <- dslabs::gapminder
    gap_dslabs$gdpPercap <- gap_dslabs$gdp/gap_dslabs$population
    gap_dslabs
}
