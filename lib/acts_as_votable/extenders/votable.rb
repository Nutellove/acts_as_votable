module ActsAsVotable
  module Extenders

    module Votable

      def votable?; false end
      def acts_as_votable_vote_class; ActsAsVotable::Vote end

      # args may contain :class => CustomVote
      def acts_as_votable args={}

        # First, we configure the Vote class (how not to eval?)
        unless args[:class].nil?
          raise "Please provide a Class for :class" unless args[:class].is_a? Class
          class_eval %Q{
            def self.acts_as_votable_vote_class; #{args[:class]} end
          }
        end

        require 'acts_as_votable/votable'
        include ActsAsVotable::Votable

        class_eval do
          def self.votable?; true end
        end

      end

    end

  end
end
