
#' @importFrom magrittr %>%
#' @import dplyr
get_match_results <- function() {
  
  # Get data ----
  column_names <- c("Game", "Date", "Round", "Home.Team", "Home.Score", "Away.Team", "Away.Score", "Venue")
  url_text <- "https://afltables.com/afl/stats/biglists/bg3.txt"
  match_data <- suppressMessages(
    readr::read_table(url_text, skip = 2, col_names = column_names)
  )

  # Separate score out into components ----
  match_data <- match_data %>%
    separate(Home.Score, into = c("Home.Goals", "Home.Behinds", "Home.Points"), sep = "\\.", convert = T) %>%
    separate(Away.Score, into = c("Away.Goals", "Away.Behinds", "Away.Points"), sep = "\\.", convert = T)

  # Fix columns ----
  match_data <- match_data %>%
    mutate(
      Margin = Home.Points - Away.Points,
      Date = lubridate::dmy(Date),
      Season = lubridate::year(Date)
    )

  # Find round number ----
  # QF/EF weekend is tricky as it is the same round number but different code
  round_levels <- c(
    "R1", "R2", "R3", "R4", "R5", "R6", "R7", "R8", "R9",
    "R10", "R11", "R12", "R13", "R14", "R15", "R16", "R17",
    "R18", "R19", "R20", "R21", "R22", "R23",
    "QF/EF", "SF", "PF", "GF"
  )
  finals <- c("QF", "EF", "SF", "PF", "GF")

  # Create finals column
  match_data <- match_data %>%
    mutate(Round.Type = ifelse(Round %in% finals, "Finals", "Regular"))

  # Temporarily create a combined "QF/EF" value
  match_data <- match_data %>%
    mutate(
      Round.New = ifelse(stringr::str_detect("QF/EF", Round), "QF/EF", Round),
      Round.New = factor(Round.New, levels = round_levels)
    )

  # Add in round counter and remove temp column
  match_data <- match_data %>%
    group_by(Season) %>%
    mutate(Round.Number = dense_rank(Round.New)) %>%
    select(-Round.New) %>%
    ungroup()

  # Fix teams ----
  # Create mapping function - update this as needed
  replace_teams <- function(team) {
    if (team == "Kangaroos") return("North Melbourne")
    if (team == "Western Bulldog") return("Footscray")
    if (team == "South Melbourne") return("Sydney")
    if (team == "Brisbane Bears") return("Brisbane Lions")
    return(team)
  }

  # Replace all teams
  match_data <- match_data %>%
    group_by(Game) %>%
    mutate_at(c("Home.Team", "Away.Team"), replace_teams) %>%
    ungroup()


  # Return data
  return(match_data)
}