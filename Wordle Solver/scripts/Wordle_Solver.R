# Wordle Solver 2
# This iteration of the wordle solver will encapsulate more of the code into
# functions in order to run many games over a list of historical answers in 
# order to evaluate performance over many games. 

library(tidyverse)
source("scripts/utils.R") #loads the

alphabet = c("a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", 
             "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z")

# Read in the valid word text file and create a nx5 matrix 
all_valid_words <- readr::read_delim("data/valid-wordle-words.txt", 
                                 delim = "\n", 
                                 show_col_types = FALSE)

game <- function(answer) {
  # New game set up
  valid_words = all_valid_words # Reset valid words
  
  valid_words_matrix <- valid_words %>%
    mutate(char = str_split(Words, "")) %>%
    unnest_wider(char, names_sep = "_") %>%
    select(c("char_1", "char_2", "char_3", "char_4", "char_5"))
  
  # Initialize and create a frequency table for each letter in each position
  alphabet_matrix = relative_frequency(matrix(
    data = 0,
    nrow = 26,
    ncol = 5
  ),
  valid_words_matrix)
  word_probabilities <-
    apply(valid_words_matrix,
          MARGIN = 1,
          word_prob,
          alphabet_matrix = alphabet_matrix) #Going to need to fix
  
  # Run a game with six guesses
  guesses = c("", "", "", "", "", "")
  guesses_feedback <- matrix(0, nrow = 6, ncol = 5)
  i <-  1
  found <-  FALSE
  
  while (i <= 6 & found != TRUE) {
    guess <- valid_words[which.max(word_probabilities), 1]
    guesses[i] <- guess[[1, 1]]
    
    guess_feedback = feedback(guess, answer)
    guesses_feedback[i, ] <- guess_feedback
    
    if (sum(guess_feedback) == 10) {
      found <- TRUE
    }
    else {
      update_results <-
        bayesian_update(
          guess,
          guess_feedback,
          alphabet_matrix,
          word_probabilities,
          valid_words,
          valid_words_matrix
        )
      
      alphabet_matrix <- update_results$alphabet_matrix
      word_probabilities <- update_results$word_probabilities
      valid_words <- update_results$valid_words
      valid_words_matrix <- update_results$valid_words_matrix
      
      i <- i + 1
    }
  }
  
  return(list(
    guesses = guesses,
    guesses_feedback = guesses_feedback,
    i = i,
    found = found
  ))
}

## Loading past wordle answers

past_words <- readr::read_delim("data/past_wordle_answers.txt",
                                delim = "\n",
                                show_col_types = FALSE) %>%
              mutate(across(everything(), str_to_lower))

game_results <- lapply(past_words[[1]], game)
games_summary <- map_dfr(game_results, ~tibble(i = .x$i, found = .x$found))

win_rate = sum(games_summary$found)/length(games_summary$found)
win_results = games_summary[which(games_summary$found), 1]

ggplot(win_results, aes(i)) +
  geom_histogram(binwidth = 1, fill = "forestgreen", color = "black") +
  geom_text(stat = "count", aes(label = ..count..), vjust = -0.5) +
  labs(x = "Number of Guesses", y = "frequency") +
  theme_minimal()

