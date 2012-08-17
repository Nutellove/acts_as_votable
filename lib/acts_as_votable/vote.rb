require 'acts_as_votable/helpers/words'

module ActsAsVotable

  module VoteBehavior
    def self.included(base)
      base.class_eval do

        include Helpers::Words

        attr_accessible :votable_id, :votable_type,
                        :voter_id, :voter_type,
                        :votable, :voter,
                        :value

        belongs_to :votable, :polymorphic => true
        belongs_to :voter,   :polymorphic => true

        scope :up,       where(:value => 1)
        scope :obiwan,   where(:value => 0)
        scope :down,     where(:value => -1)
        scope :valued,   lambda{ |value|   where(:value => value) }

        scope :on,       lambda{ |votable| where(:votable_type => votable.class.name, :votable_id => votable.id) }
        scope :for,      lambda{ |votable| where(:votable_type => votable.class.name, :votable_id => votable.id) }
        scope :by,       lambda{ |voter|   where(:voter_type => voter.class.name, :voter_id => voter.id) }

        scope :for_type, lambda{ |klass|   where(:votable_type => klass) }
        scope :by_type,  lambda{ |klass|   where(:voter_type => klass) }

        validates_presence_of :votable_id
        validates_presence_of :voter_id

      end
    end
  end

  class Vote < ::ActiveRecord::Base
    include ActsAsVotable::VoteBehavior
  end

end

