# Wordle Solver
This repository will store all code for a solver of the popular game Wordle. 
Wordle is a popular online puzzle currently owned and run by the New York Times in which a user attempts to guess a 5 letter word with a total of 6 guesses available. Guesses where a user gets correct letters in the correct tile show as green, correct letters in the wrong tile shows as yellow, and letters not in the answer show as grey. 

This attempt at a Wordle solver uses logic from conditional probability to systematically eliminate unviable words as guesses are made, narrowing down a list of approximately 15000 words to make its pick. It begins its pick by initialising an `alphabet_matrix` of size 26x5 based on the relative frequency of how often each letter of the alphabet occurs in any given tile. This gives us 5 probability mass functions over the alphabet for each tile.  As guesses are made, feedback is given and the resulting information of green, grey, and yellow tiles are used to update the `alphabet_matrix` and the valid word list. 

This project is aimed to be educational and explorative in nature. It is not used as part of any automated systems aimed at interacting with the actual Wordle interface owned by the New York Times.  
## Installation
To install this project, have R installed. 

1. clone the repository:
```
git clone https://github.com/yourusername/wordle-solver.git
```

2.  Install the necessary R packages in the R console:
```
install.packages("tidyverse")
```

Alternatively you can install each of the specific packages used in this project. These are outlined in the dependencies section.
## Usage
to execute one run of a game, run the `game` function in the `Wordle_Solver.R` script.
The function takes the answer to the wordle round as it's argument.

```
game_results <- game("pious")
```

Will return the following:

```
$guesses
[1] "sores" "aloos" "chons" "quoys" "pious" ""     

$guesses_feedback
     [,1] [,2] [,3] [,4] [,5]
[1,]    1    1    0    0    2
[2,]    0    0    2    1    2
[3,]    0    0    2    0    2
[4,]    0    1    2    0    2
[5,]    2    2    2    2    2
[6,]    0    0    0    0    0

$i
[1] 5

$found
[1] TRUE
```

`game` Returns a list with a vector of guesses, a matrix of the feedback for each guess (0: grey, 1: yellow, 2: green), the number of guesses taken, and a boolean of whether the word was found.
## Features
### `feedback`:
This function takes in a guess and the answer to the game as parameters and returns a vector of length 5.
Each position of the returned `guess_feedback` vector corresponds to the code used to denote green, yellow, and grey tiles as 2,1, and 0 respectively.
### `relative_frequency`:
This function takes in the `alphabet_matrix` and the `valid_words_matrix` and returns an updated `alphabet_matrix`. It evaluates the frequency of each letter in each tile position from the `valid_words_matrix`, calculates a probability based on the number of rows in it, and stores each letter, tile probability in the `alphabet_matrix`.
### `word_prob`:
This function takes the `alphabet_matrix` and a single row from the `valid_words_matrix` and returns a probability corresponding to that word. It assumes independence between the different tiles and therefore multiplies the probabilities from the `alphabet_matrix` corresponding to the letters in each tile position.
### `bayesian_update`
This function, found in the `utils.R` script, performs the probability updating for both the `alphabet_matrix` as well as the `word_probabilities` vector. 
This function does not assume an explicit functional form of the probability distributions. Instead it relies on the conditional probability logic of narrowing down a set of possibilities based on new information.

The update starts with partially updating the `alphabet_matrix`:
When a green tile is guessed, it's probability in the matrix is set to 1, and all other letters in that column to 0.
When a grey tile is guessed, the probabilities in the entire row corresponding to that letter are set to 0.
When a yellow tile is guessed, the specific entry in the `alphabet_matrix` corresponding to that letter in that tile is set to 0. The indices of all words that have that word appearing in other tiles are then recorded in a `yellow_indices` vector.

The valid words are then found using the partially updated `alphabet_matrix` as well as the `yellow_indices`  to cancel out unviable answers. 

The `alphabet_matrix` is then made fully updated by calculating the new relative frequencies of the `valid_words_matrix`. After this is done, the updated `alphabet_matrix` is used to calculate the `word_probabilities` corresponding to the `valid_words`.

## Dependencies
All code has been written in R. The Tidyverse framework was utilised to  read, manipulate, and structure the data. Specifically, the following packages were used:
 - **readr**: for reading word lists
 - **stringr**: for string manipulation
 - **dplyr**: for data handling
 - **tidyr**: for data structuring

## Folder Structure
```
├── data/                          # Contains word lists and other data files
	├── valid-wordle-words.txt     # Text file of valid answers
	├── past_wordle_answers.txt    # Text file of previous answers (incomplete)
├── scripts/                       # Core game and solver scripts
│   ├── main.R                     # Primary script for running the game
│   ├── utils.R                    # Helper functions (probability calculations, feedback)
├── README.md                      # Project documentation
```
## Contributing
Please feel free to fork the project and improve on it as you see fit. I'd appreciate feedback, advice, or any other comments. 
## License
This project is licensed under the MIT License. See the LICENSE file for details.
