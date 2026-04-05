load_gapminder <- function() {
  if (!requireNamespace("gapminder", quietly = TRUE)) {
    message("Installing gapminder package...")
    install.packages("gapminder", repos = "https://cloud.r-project.org")
  }
  gapminder::gapminder
}
