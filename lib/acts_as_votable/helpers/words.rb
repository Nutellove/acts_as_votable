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

    def self.that_mean_true
      ['up', 'upvote', 'like', 'liked', 'positive', 'yes', 'good', 'true', 1, true]
    end

    def self.that_mean_false
      ['down', 'downvote', 'dislike', 'disliked', 'negative', 'no', 'bad', 'false', 0, false]
    end

    # check is word is a true or bad vote
    # if the word is unknown, then it counts it as a true/good
    # vote.  this exists to allow all voting to be good by default
    def self.meaning_of word
      !that_mean_false.include?(word)
    end

    def self.that_mean_one
      ['up', 'upvote', 'like', 'liked', 'positive', 'yes', 'good', 'true', 1, true]
    end
    def self.that_mean_minus_one
      ['down', 'downvote', 'dislike', 'disliked', 'negative', 'no', 'bad', 'false', -1, false]
    end

    def self.integer_meaning_of word
      return word if word.is_a? Integer
      return  1   if that_mean_one.include? word
      return -1   if that_mean_minus_one.include? word
      return  0
    end

  end
end
