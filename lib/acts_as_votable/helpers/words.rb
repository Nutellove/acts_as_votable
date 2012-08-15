module ActsAsVotable::Helpers

  # this helper provides methods that help find what words are 
  # up votes and what words are down votes
  #
  # It can be called 
  #
  # votable_object.votable_words.that_mean_true
  #
  module Words

    def votable_words
      VotableWords
    end

  end

  class VotableWords

    def self.that_mean_one
      ['up', 'upvote', 'like', 'liked', 'positive', 'yes', 'good', 'true', 1, true]
    end

    def self.that_mean_minus_one
      ['down', 'downvote', 'dislike', 'disliked', 'negative', 'no', 'bad', 'false', -1, false]
    end

    # Check if the word means 1 or -1, return it if it is already an integer
    # Defaults to 0
    def self.meaning_of word
      return word if word.is_a? Integer
      return  1   if that_mean_one.include? word
      return -1   if that_mean_minus_one.include? word
      return  0
    end

  end
end
