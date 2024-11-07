# This script will build out a wordle solver using a Bayesian update function 
# to assign a probability of a word from a list being accepted.
# This version was to build the basic blocks of the code to run a single game
# over the whole script with a hard coded answer. 

library(tidyverse)
WORDLE_ANSWER = "crane" # will pull from an api or possibly find answer history to evaluate
alphabet = c(
  "a",
  "b",
  "c",
  "d",
  "e",
  "f",
  "g",
  "h",
  "i",
  "j",
  "k",
  "l",
  "m",
  "n",
  "o",
  "p",
  "q",
  "r",
  "s",
  "t",
  "u",
  "v",
  "w",
  "x",
  "y",
  "z"
)

# Read in the text file and create a nx5 matrix
valid_words <- readr::read_delim("data/valid-wordle-words.txt",
                                 delim = "\n",
                                 show_col_types = FALSE)

valid_words_matrix <- valid_words %>%
  mutate(char = str_split(Words, "")) %>%
  unnest_wider(char, names_sep = "_") %>%
  select(c("char_1", "char_2", "char_3", "char_4", "char_5"))


# create a function to compare a single guess to the answer.
feedback <- function(guess) {
  # Function to compare the guess to the hard coded answer and provide feedback.
  # returns guess_feedback vector. 0 if grey, 1 if yellow, 2 if green.
  guess = unlist(str_split(guess, ""))
  answer = unlist(str_split(WORDLE_ANSWER, ""))
  guess_feedback = c(0, 0, 0, 0, 0)
  
  for (i in 1:5) {
    if (guess[i] == answer[i]) {
      guess_feedback[i] = 2
    }
    else if (guess[i] %in% answer) {
      guess_feedback[i] = 1
    }
  }
  return(guess_feedback)
}


relative_frequency <- function(alphabet_matrix) {
  # There is probably a slicker way to do this by oh well
  for (i in 1:5) {
    for (j in 1:26) {
      # returns frequency of letter in guess position
      alphabet_matrix[j, i] <- valid_words_matrix[[i]] %>%
        str_count(alphabet[j]) %>%
        sum()
    }
    # creates a column wise probability distribution
    alphabet_matrix[, i] <-
      alphabet_matrix[, i] / sum(alphabet_matrix[, i])
  }
  return(alphabet_matrix)
}

# Initialize and create a frequency table for each letter in each position
alphabet_matrix = relative_frequency(matrix(data = 0, nrow = 26, ncol = 5))


#Plot of prior matrix for interest (each plot is a column)
#par(mfrow = c(5, 1), mar = c(4, 4, 2, 1))
#barplot(height = alphabet_matrix[, 1], names.arg = alphabet, xlab = "Alphabet", ylab = "Probability", title = "Guess 1")
#barplot(height = alphabet_matrix[, 2], names.arg = alphabet, xlab = "Alphabet", ylab = "Probability", title = "Guess 2")
#barplot(height = alphabet_matrix[, 3], names.arg = alphabet, xlab = "Alphabet", ylab = "Probability", title = "Guess 3")
#barplot(height = alphabet_matrix[, 4], names.arg = alphabet, xlab = "Alphabet", ylab = "Probability", title = "Guess 4")
#barplot(height = alphabet_matrix[, 5], names.arg = alphabet, xlab = "Alphabet", ylab = "Probability", title = "Guess 5")
#par(mfrow = c(1,1)) # reset subplot


word_prob <- function(word) {
  # function to calculate probability of word being a good guess
  alphabet_matrix[match(word[1], alphabet), 1] *
    alphabet_matrix[match(word[2], alphabet), 2] *
    alphabet_matrix[match(word[3], alphabet), 3] *
    alphabet_matrix[match(word[4], alphabet), 4] *
    alphabet_matrix[match(word[5], alphabet), 5]
}

word_probabilities <-
  apply(valid_words_matrix, MARGIN = 1, word_prob) %>% prop.table()




bayesian_update <- function(guess, feedback) {
  # We get new information in the form of the color of each tile.
  # We can set a column to 1 on a letter and 0 else where if the guess tile is green
  # We can set rows to 0 if its letter is grey.
  # We can boost letters that are yellow in available tiles (not this one)
  
  guess = unlist(str_split(guess, ""))
  yellows = guess[which(feedback == 1)]
  
  for (i in 1:5) {
    # update greens
    if (feedback[i] == 2) {
      alphabet_matrix[match(guess[i], alphabet), i] <<- 1
      alphabet_matrix[-match(guess[i], alphabet), i] <<- 0
    }
    
    # update greys
    if (feedback[i] == 0) {
      alphabet_matrix[match(guess[i], alphabet), ] <<- 0
    }
    
    # Stop yellows from reappearing in the same tile
    if (feedback[i] == 1) {
      alphabet_matrix[match(guess[i], alphabet), i] <<- 0
    }
  }
  
  
  #Get indices of words with yellows in them
  yellow_indices <- apply(valid_words_matrix, 1, function(row) {
    all(yellows %in% row)
  })
  
  # reevaluate relative frequencies based on valid words and yellow tile in word
  word_probabilities <<-
    apply(valid_words_matrix, MARGIN = 1, word_prob) %>% prop.table()
  #if (length(yellows))
  subset_condition <- word_probabilities > 0 & yellow_indices
  valid_words <<- valid_words[subset_condition, 1]
  valid_words_matrix <<- valid_words_matrix[subset_condition, ]
  #update the relative frequency for new valid words
  alphabet_matrix <<- relative_frequency(alphabet_matrix)
  word_probabilities <<-
    apply(valid_words_matrix, MARGIN = 1, word_prob) %>% prop.table()
}


# Run a game with six guesses
guesses = c("", "", "", "", "", "")
guesses_feedback <- matrix(0, nrow = 6, ncol = 5)
i <-  1
found <-  FALSE

while (i <= 6 & found != TRUE) {
  print(sum(word_probabilities))
  guess <- valid_words[which.max(word_probabilities), 1]
  guesses[i] <- guess[[1, 1]]
  
  guess_feedback = feedback(guess)
  guesses_feedback[i, ] <- guess_feedback
  
  if (sum(guess_feedback) == 10) {
    found <- TRUE
  }
  else {
    bayesian_update(guess, guess_feedback)
    i <- i + 1
  }
}

# Next steps:
#             - find text file of all historical answers and evaluate on that
#             - make a heat map of the alphabet_matrix over time (animate it?)