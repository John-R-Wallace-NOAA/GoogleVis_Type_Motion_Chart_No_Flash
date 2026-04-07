#' Load the classic Gapminder dataset (auto-installs if needed)
#' @return A data frame with columns: country, continent, year, lifeExp, pop, gdpPercap
#' @export
load_gapminder <- function() {
  if (!requireNamespace("gapminder", quietly = TRUE)) {
    message("Installing gapminder package...")
    install.packages("gapminder", repos = "https://cloud.r-project.org")
  }
  data.frame(gapminder::gapminder)
}
