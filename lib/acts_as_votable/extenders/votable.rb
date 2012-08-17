module ActsAsVotable
  module Extenders

    module Votable

      def votable?; false end

      include ActsAsVotable::Extenders::CustomizableVoteClass

      def acts_as_votable_vote_class; ActsAsVotable::Vote end

      # args may contain :class => CustomVote
      def acts_as_votable args={}

        acts_as_votable_process_args args

        require 'acts_as_votable/votable'
        include ActsAsVotable::Votable

        class_eval do
          def self.votable?; true end
        end

      end

    end

  end
end
