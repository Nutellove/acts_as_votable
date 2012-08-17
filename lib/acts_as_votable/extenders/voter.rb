module ActsAsVotable
  module Extenders

    module Voter

      def voter?; false end

      def acts_as_votable_vote_class; ActsAsVotable::Vote end

      def acts_as_voter args={}

        # First, we configure the Vote class (how not to eval?)
        # /!\ DRY with ActsAsVotable::Extenders::Votable (how?)
        unless args[:class].nil?
          raise "Please provide a Class for :class" unless args[:class].is_a? Class
          class_eval %Q{
            def self.acts_as_votable_vote_class; #{args[:class]} end
          }
        end

        require 'acts_as_votable/voter'
        include ActsAsVotable::Voter

        class_eval do
          def self.voter?; true end
        end

      end

    end
  end
end
