# This is shared by ActsAsVotable::Extenders::Votable and ActsAsVotable::Extenders::Voter
# It allows a custom Vote class to be used

module ActsAsVotable
  module Extenders

    module CustomizableVoteClass

      def acts_as_votable_vote_class; ActsAsVotable::Vote end

      def acts_as_votable_process_args args
        # Overwrite self.acts_as_votable_vote_class to return :class argument
        unless args[:class].nil?
          raise "Please provide a Class for :class" unless args[:class].is_a? Class
          class_eval %Q{
            def self.acts_as_votable_vote_class; #{args[:class]} end
          }
        end
      end

    end
  end
end
