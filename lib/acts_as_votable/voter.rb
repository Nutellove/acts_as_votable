module ActsAsVotable
  module Voter

    def self.included(base)

      # allow user to define these
      aliases = {
        :vote_up_for   => [:likes, :upvotes, :up_votes],
        :vote_down_for => [:dislikes, :downvotes, :down_votes],
        :unvote_for    => [:unlike, :undislike]
      }

      base.class_eval do

        belongs_to :voter, :polymorphic => true
        has_many   :votes, :class_name => self.acts_as_votable_vote_class, :as => :voter do
          def votables
            includes(:votable).map(&:votable)
          end
        end

        aliases.each do |method, links|
          links.each do |new_method|
            alias_method(new_method, method)
          end
        end

      end

    end


    ## VOTING

    def vote args
      args[:votable].vote args.merge({:voter => self})
    end

    def vote_for model, value
      vote :votable => model, :value => value
    end

    def vote_up_for model
      vote :votable => model, :value => 1
    end

    def vote_obiwan_for model
      vote :votable => model, :value => 0
    end

    def vote_down_for model
      vote :votable => model, :value => -1
    end

    def unvote_for model
      model.unvote :voter => self
    end


    ## RESULTS

    def voted_on? votable
      votes = find_votes(:votable_id => votable.id, :votable_type => votable.class.name)
      votes.size > 0
    end
    alias :voted_for? :voted_on?

    def voted_up_on? votable
      votes = find_votes(:votable_id => votable.id, :votable_type => votable.class.name, :value => 1)
      votes.size > 0
    end
    alias :voted_up_for? :voted_up_on?

    def voted_down_on? votable
      votes = find_votes(:votable_id => votable.id, :votable_type => votable.class.name, :value => -1)
      votes.size > 0
    end
    alias :voted_down_for? :voted_down_on?



    def find_votes extra_conditions = {}
      votes.where(extra_conditions)
    end

    def find_up_votes
      find_votes :value => 1
    end

    def find_obiwan_votes
      find_votes :value => 0
    end

    def find_down_votes
      find_votes :value => -1
    end

    def find_votes_by_value value
      find_votes :value => value
    end

    def find_votes_for_class klass, extra_conditions = {}
      find_votes extra_conditions.merge({:votable_type => klass.name})
    end

    def find_up_votes_for_class klass
      find_votes_for_class klass, :value => 1
    end

    def find_down_votes_for_class klass
      find_votes_for_class klass, :value => -1
    end

    # finds the last vote the voter made on specified target
    def find_vote_on target
      votes = find_votes :votable_id => target.id, :votable_type => target.class.name
      return nil if votes.size == 0
      votes.first
    end
    alias :find_vote_for :find_vote_on

    # finds the last value the voter voted on specified target
    def find_vote_value_on target
      vote = find_vote_on target
      return nil if vote.nil?
      vote.value
    end
    alias :find_vote_value_for      :find_vote_value_on
    alias :voted_as_when_voting_on  :find_vote_value_on
    alias :voted_as_when_voted_for  :voted_as_when_voting_on

  end
end
