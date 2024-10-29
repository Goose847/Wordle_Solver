## This file includes the helper funcitons used in Wordle_Solver.R
library(tidyverse)

# create a function to compare a single guess to the answer.
feedback <- function(guess, answer){
  # Function to compare the guess to the hard coded answer and provide feedback.
  # returns guess_feedback vector. 0 if grey, 1 if yellow, 2 if green.
  guess = unlist(str_split(guess, ""))
  answer = unlist(str_split(answer, ""))
  guess_feedback = c(0, 0, 0, 0, 0)
  
  for (i in 1:5){
    if (guess[i] == answer[i]){
      guess_feedback[i] = 2
    }
    else if (guess[i] %in% answer){
      guess_feedback[i] = 1
    }
  }
  return(guess_feedback)
}

relative_frequency <- function(alphabet_matrix, valid_words_matrix) {
  # This function looks at the valid word list and 
  # calculates the relative frequency of each letter in each tile.
  # It takes the alphabet_matrix and valid_words_matrix as arguments.
  # It returns the updated alphabet matrix.
  for (i in 1:5) {
    for (j in 1:26) {
      # returns frequency of letter in guess position
      alphabet_matrix[j, i] <- valid_words_matrix[[i]] %>%
        str_count(alphabet[j]) %>%
        sum()
    }
    # creates a column wise probability distribution
    alphabet_matrix[, i] <- alphabet_matrix[, i] / sum(alphabet_matrix[, i])
  }
  return(alphabet_matrix)
}

word_prob <- function(word, alphabet_matrix) {
  # function to calculate probability of word being a good guess.
  # Assumes independence of the tiles.
  # Returns probability associated with a single word.
  alphabet_matrix[match(word[1], alphabet), 1] * 
    alphabet_matrix[match(word[2], alphabet), 2] *
    alphabet_matrix[match(word[3], alphabet), 3] *
    alphabet_matrix[match(word[4], alphabet), 4] *
    alphabet_matrix[match(word[5], alphabet), 5]
}


bayesian_update <- function(guess, feedback, alphabet_matrix, word_probabilities, valid_words, valid_words_matrix) {
  # We get new information in the form of the color of each tile.
  # We can set a column to 1 on a letter and 0 else where if the guess tile is green
  # We can set rows to 0 if its letter is grey.
  # We can boost letters that are yellow in available tiles (not this one)
  # Takes in the guess, feedback, alphabet_matrix, word_probabilities, valid_words, and valid_words_matrix.
  # Returns a list containing updated alphabet_matrix, word_probabilities, valid_words, and valid_words_matrix.
  
  guess = unlist(str_split(guess, ""))
  yellows = guess[which(feedback == 1)]
  
  for (i in 1:5) {
    # update greens
    if (feedback[i] == 2) {
      alphabet_matrix[match(guess[i], alphabet), i] <- 1
      alphabet_matrix[-match(guess[i], alphabet), i] <- 0
    }
    
    # update greys
    if (feedback[i] == 0) {
      alphabet_matrix[match(guess[i], alphabet),] <- 0
    }
    
    # Stop yellows from reappearing in the same tile
    if (feedback[i] == 1) {
      alphabet_matrix[match(guess[i], alphabet), i] <- 0
    }
  }
  
  
  #Get indices of words with yellows in them
  yellow_indices <- apply(valid_words_matrix, 1, function(row) {
    all(yellows %in% row)
  })
  
  # reevaluate relative frequencies based on valid words and yellow tile in word
  word_probabilities <- apply(valid_words_matrix, MARGIN = 1, word_prob, alphabet_matrix = alphabet_matrix)
  subset_condition <- word_probabilities > 0 & yellow_indices
  
  valid_words <- valid_words[subset_condition, 1]
  valid_words_matrix <- valid_words_matrix[subset_condition,]
  #update the relative frequency for new valid words
  alphabet_matrix <- relative_frequency(alphabet_matrix, valid_words_matrix)
  word_probabilities <- apply(valid_words_matrix, MARGIN = 1, word_prob, alphabet_matrix = alphabet_matrix)
  
  return(
    list(
      alphabet_matrix = alphabet_matrix,
      word_probabilities = word_probabilities,
      valid_words = valid_words,
      valid_words_matrix = valid_words_matrix
    )
  )
}