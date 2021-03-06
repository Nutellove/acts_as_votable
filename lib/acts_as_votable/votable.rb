require 'acts_as_votable/helpers/words'

module ActsAsVotable
  module Votable

    include Helpers::Words

    def self.included base

      # allow the user to define these himself 
      aliases = {

          :vote_up => [
              :up_by, :upvote_by, :like_by, :liked_by, :vote_by,
              :up_from, :upvote_from, :upvote_by, :like_from, :liked_from, :vote_from
          ],

          :vote_down => [
              :down_by, :downvote_by, :dislike_by, :disliked_by,
              :down_from, :downvote_from, :downvote_by, :dislike_by, :disliked_by
          ],

          :up_votes => [
              :true_votes, :ups, :upvotes, :likes, :positives, :for_votes,
          ],

          :down_votes => [
              :false_votes, :downs, :downvotes, :dislikes, :negatives
          ],

          :unvote => [
              :unliked_by, :undisliked_by
          ],

      }

      base.class_eval do

        belongs_to :votable, :polymorphic => true
        has_many :votes, :class_name => self.acts_as_votable_vote_class, :as => :votable do
          def voters
            includes(:voter).map(&:voter)
          end
        end

        aliases.each do |method, links|
          links.each do |new_method|
            alias_method(new_method, method)
          end
        end

      end
    end

    attr_accessor :vote_registered

    def vote_registered?
      self.vote_registered
    end

    def default_conditions
      {
          :votable_id => self.id,
          :votable_type => self.class.base_class.name.to_s
      }
    end

    ## VOTING

    # Options :
    #   :voter => The Voter of the voting action
    #   :value => The Value he wants
    # @return Boolean Successful save ?
    def vote options={}
      self.vote_registered = false

      options = { :value => 0 }.merge(options)
      if options[:voter].nil?; return false end

      # find the vote
      _vote = vote_of options[:voter]

      if _vote.nil? # this voter has never voted
        #puts self.inspect
        #a = self.class
        _vote = self.class.acts_as_votable_vote_class.new :votable => self, :voter => options[:voter]
      end

      last_update = _vote.updated_at

      _vote.value = votable_words.meaning_of(options[:value])

      save_is_a_success = _vote.save

      if save_is_a_success
        self.vote_registered = true if last_update != _vote.updated_at
        update_cached_votes
      else
        self.vote_registered = false
      end

      save_is_a_success
    end

    # Options :
    #   :voter => The Voter of the unvoting action
    def unvote options={}
      return false if options[:voter].nil?

      _votes_ = votes_of options[:voter]
      return true if _votes_.size == 0

      _votes_.each(&:destroy)
      update_cached_votes
      self.vote_registered = false if votes.count == 0

      true
    end

    def vote_up voter
      self.vote :voter => voter, :value => 1
    end

    def vote_obiwan voter
      self.vote :voter => voter, :value => 0
    end

    def vote_down voter
      self.vote :voter => voter, :value => -1
    end


    ## RESULTS

    def find_votes where_options={}
      votes.where(where_options)
    end

    def up_votes
      find_votes(:value => 1)
    end

    def obiwan_votes
      find_votes(:value => 0)
    end

    def down_votes
      find_votes(:value => -1)
    end

    def mean_vote
      votes_count > 0 ? votes_sum.quo(votes_count) : 0
    end

    def votes_sum
      find_votes.map(&:value).inject(0, :+)
    end

    def votes_count(filter={})
      tmp = find_votes
      if filter[:voter]; tmp = tmp.find_all{|d| d.voter == filter[:voter]} end
      if filter[:value]; tmp = tmp.find_all{|d| d.value == filter[:value]} end
      tmp.size
    end

    # @return Integer The most voted value, or false if no votes or draw
    def winner_vote
      return false unless votes_count > 0
      values = find_votes.map(&:value).group_by{ |v| v }
      values.each{ |i,a| values[i] = a.size }
      max = values.max_by{ |a| a[1] }

      return false if max.nil? or values.count{|a| a[1] == max[1]} > 1
      max[0]
    end

    ## VOTERS

    def voted_on_by? voter
      votes_of(voter).count > 0
    end

    def votes_of voter
      find_votes(:voter_id => voter.id, :voter_type => voter.class.base_class.name.to_s)
    end

    def vote_of voter
      votes_of(voter).first
    end

    def vote_value_of voter
      vote = vote_of voter
      (vote) ? vote.value : nil
    end

    ## STATS IN CACHE

    def count_votes_total skip_cache = false
      if !skip_cache && self.respond_to?(:cached_votes_total)
        return self.send(:cached_votes_total)
      end
      find_votes.count
    end

    def count_votes_up skip_cache = false
      if !skip_cache && self.respond_to?(:cached_votes_up)
        return self.send(:cached_votes_up)
      end
      up_votes.count
    end

    def count_votes_obiwan skip_cache = false
      if !skip_cache && self.respond_to?(:cached_votes_obiwan)
        return self.send(:cached_votes_obiwan)
      end
      obiwan_votes.count
    end

    def count_votes_down skip_cache = false
      if !skip_cache && self.respond_to?(:cached_votes_down)
        return self.send(:cached_votes_down)
      end
      down_votes.count
    end

    ## CACHING

    def update_cached_votes

      updates = {}

      if self.respond_to?(:cached_votes_total=)
        updates[:cached_votes_total] = count_votes_total(true)
      end

      if self.respond_to?(:cached_votes_up=)
        updates[:cached_votes_up] = count_votes_up(true)
      end

      if self.respond_to?(:cached_votes_obiwan=)
        updates[:cached_votes_obiwan] = count_votes_obiwan(true)
      end

      if self.respond_to?(:cached_votes_down=)
        updates[:cached_votes_down] = count_votes_down(true)
      end

      self.update_attributes(updates, :without_protection => true) if updates.size > 0

    end

  end
end
