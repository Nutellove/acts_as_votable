require 'acts_as_votable'
require 'spec_helper'

describe ActsAsVotable::Vote do

  before(:each) do
    clean_database
  end


  describe "Scopes" do

    before do
      @alice = Voter.new(:name => 'Alice')
      @alice.save
      @bruno = Voter.new(:name => 'Bruno')
      @bruno.save
      @votable1 = Votable.new(:name => 'Free the Seeds')
      @votable1.save
      @votable2 = Votable.new(:name => 'Adapt education to new communication paradigm')
      @votable2.save
    end

    describe ":on" do
      before do
        @alice.vote_for @votable1, 1
        @alice.vote_for @votable2, 1
      end
      it "filters votes on a specific votable" do
        @alice.votes.on(@votable1).should have(1).vote
        @alice.votes.for(@votable2).should have(1).vote
      end
      it "returns nothing if votable is nil (or invalid)" do
        @alice.votes.on(nil).should have(0).vote
      end
    end

    describe ":by" do
      before do
        @alice.vote_for @votable1, 1
        @bruno.vote_for @votable1, 1
      end
      it "filters votes by a specific voter" do
        @votable1.votes.by(@alice).should have(1).vote
        @votable1.votes.by(@bruno).should have(1).vote
      end

      it "returns nothing if voter is nil (or invalid)" do
        @votable1.votes.by(nil).should have(0).vote
      end
    end

  end

end
