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
        has_many :votes, :class_name => "ActsAsVotable::Vote", :as => :votable do
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

    # VOTING

    def vote args={}

      options = {
          :value => 0,
      }.merge(args)

      self.vote_registered = false

      if options[:voter].nil?
        return false
      end

      # find the vote
      _vote_ = vote_of options[:voter]

      if _vote_.nil?
        # this voter has never voted
        vote = ActsAsVotable::Vote.new(
            :votable => self,
            :voter => options[:voter]
        )
      else
        # this voter is potentially changing his vote
        vote = _vote_
      end

      last_update = vote.updated_at

      vote.value = votable_words.meaning_of(options[:value])

      save_is_a_success = vote.save

      if save_is_a_success
        self.vote_registered = true if last_update != vote.updated_at
        update_cached_votes
      else
        self.vote_registered = false
      end

      save_is_a_success
    end

    def unvote args={}
      return false if args[:voter].nil?
      _votes_ = votes_of args[:voter]

      return true if _votes_.size == 0
      _votes_.each(&:destroy)
      update_cached_votes
      self.vote_registered = false if votes.count == 0
      return true
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

    def find_votes extra_conditions = {}
      votes.where(extra_conditions)
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

    ## VOTERS

    def voted_on_by? voter
      votes_of(voter).count > 0
    end

    def votes_of voter
      find_votes(:voter_id => voter.id, :voter_type => voter.class.name)
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
