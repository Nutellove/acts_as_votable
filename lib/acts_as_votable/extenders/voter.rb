module ActsAsVotable
  module Extenders

    module Voter

      def voter?; false end

      include ActsAsVotable::Extenders::CustomizableVoteClass

      def acts_as_voter args={}

        acts_as_votable_process_args args

        require 'acts_as_votable/voter'
        include ActsAsVotable::Voter

        class_eval do
          def self.voter?; true end
        end

      end

    end
  end
end
