#' Load the dslabs Gapminder dataset
#' @return A data frame with columns: country, year, infant_mortality, life_expectancy, fertility, population, gdp, continent, region, gdp_bil
#' @export
load_gapminder_dslabs <- 
function () 
{
    if (!requireNamespace("dslabs", quietly = TRUE)) {
        message("Installing dslabs package...")
        install.packages("dslabs", repos = "https://cloud.r-project.org")
    }
    
    gap_dslabs <- dslabs::gapminder
    gap_dslabs$gdp_bil <- gap_dslabs$gdp/1e9
    gap_dslabs
}
