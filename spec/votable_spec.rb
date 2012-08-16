require 'acts_as_votable'
require 'spec_helper'

describe ActsAsVotable::Votable do

  before do
    clean_database
  end

  describe 'self.votable?' do

    it "returns false for NotVotable" do
      NotVotable.votable?.should be false
      NotVotable.should_not be_votable
    end

    it "returns true for Votable" do
      Votable.votable?.should be true
      Votable.should be_votable
    end

  end




  describe "Voting on a votable object" do

    before do
      clean_database

      @alice = Voter.new(:name => 'Alice')
      @alice.save
      @bob = Voter.new(:name => 'Bob')
      @bob.save
      @eve = Voter.new(:name => 'Eve')
      @eve.save

      @votable = Votable.new(:name => 'Free the Seeds')
      @votable.save
    end

    it "should ignore and return false when no voter is specified" do
      @votable.vote.should be false
      @votable.votes.should have(0).votes
      @votable.vote(:voter => nil).should be false
      @votable.votes.should have(0).votes
    end

    it "should have one vote when saved" do
      @votable.vote :voter => @alice, :value => 'yes'
      @votable.votes.should have(1).vote
    end

    context "using aliases" do
      it "works using #vote_up" do
        @votable.vote_up @alice
        @votable.up_votes.should have(1).vote
        @votable.up_votes.first.voter.should == @alice
        @votable.vote_value_of(@alice).should == 1
      end
      it "works using #vote_obiwan" do
        @votable.vote_obiwan @alice
        @votable.obiwan_votes.should have(1).vote
        @votable.obiwan_votes.first.voter.should == @alice
        @votable.vote_value_of(@alice).should == 0
      end
      it "works using #vote_down" do
        @votable.vote_down @alice
        @votable.down_votes.should have(1).vote
        @votable.down_votes.first.voter.should == @alice
        @votable.vote_value_of(@alice).should == -1
      end
    end

    context "we already voted on" do
      before do
        @votable.vote :voter => @alice, :value => -1
        @votable.vote :voter => @alice, :value => 1
      end
      it "should have one vote, not two" do
        @votable.votes.should have(1).vote
      end
      it "should update the vote's value" do
        @votable.vote_value_of(@alice).should == 1
      end
    end


    context "Two different voters are voting" do
      before do
        @votable.vote :voter => @alice, :value => 1
        @votable.vote :voter => @bob, :value => -1
      end
      it "should have 2 votes" do
        @votable.votes.should have(2).votes
      end
      it "should have one up vote" do
        @votable.up_votes.should have(1).vote
      end
      it "should have one down vote" do
        @votable.down_votes.should have(1).vote
      end
      it "should not have obiwan kenobi" do
        @votable.obiwan_votes.should have(0).votes
      end
      it "should not have vote with value 42" do
        @votable.votes.valued(42).should have(0).votes
      end
    end


    describe "Vote registration" do

      it "should count the vote as registered if this is the voters first vote" do
        @votable.vote :voter => @alice
        @votable.vote_registered?.should be true
      end

      it "should not count the vote as being registered if that voter has already voted and the vote has not changed" do
        @votable.vote :voter => @alice, :value => true
        @votable.vote :voter => @alice, :value => 'yes'
        @votable.vote_registered?.should be false
      end

      it "should count the vote as registered if the voter has voted and the vote has changed" do
        @votable.vote :voter => @alice, :value => true
        @votable.vote :voter => @alice, :value => 'dislike'
        @votable.vote_registered?.should be true
      end

      it "should be contained to instances" do
        votable2 = Votable.new(:name => '2nd votable')
        votable2.save

        @votable.vote :voter => @alice, :value => false
        votable2.vote :voter => @alice, :value => true
        votable2.vote :voter => @alice, :value => true

        @votable.vote_registered?.should be true
        votable2.vote_registered?.should be false
      end

    end


    describe "#voted_on_by?" do

      it "returns true if it has been voted on by voter" do
        @votable.vote :voter => @alice
        @votable.voted_on_by?(@alice).should be true
      end

      it "returns false otherwise" do
        @votable.voted_on_by?(@alice).should be false
      end

    end

    describe "#unvote" do

      it "should unvote a positive vote" do
        @votable.vote :voter => @alice, :value => 'no'
        @votable.unvote :voter => @alice
        @votable.find_votes.should have(0).votes
      end

      it "should set the votable to unregistered after unvoting" do
        @votable.vote :voter => @alice
        @votable.unvote :voter => @alice
        @votable.vote_registered?.should be false
      end

      it "should unvote a negative vote" do
        @votable.vote :voter => @alice, :value => 'no'
        @votable.unvote :voter => @alice
        @votable.find_votes.should have(0).votes
      end

      it "should unvote only the from a single voter" do
        @votable.vote :voter => @alice
        @votable.vote :voter => @bob
        @votable.unvote :voter => @alice
        @votable.find_votes.should have(1).vote
      end

    end


    context "with cached votes" do

      before do
        clean_database

        @votable = Votable.new(:name => 'a voting model without a cache')
        @votable.save

        @votable_cache = VotableCache.new(:name => 'voting model with cache')
        @votable_cache.save
      end

      it "should not update cached votes if there are no columns" do
        @votable.vote :voter => @alice
      end

      it "should update cached total votes if there is a total column" do
        @votable_cache.cached_votes_total = 50
        @votable_cache.vote :voter => @alice
        @votable_cache.cached_votes_total.should == 1
      end

      it "should update cached total votes when a vote up is removed" do
        @votable_cache.vote :voter => @alice, :value => 1
        @votable_cache.unvote :voter => @alice
        @votable_cache.cached_votes_total.should == 0
      end

      it "should update cached total votes when a vote down is removed" do
        @votable_cache.vote :voter => @alice, :value => -1
        @votable_cache.unvote :voter => @alice
        @votable_cache.cached_votes_total.should == 0
      end

      it "should update cached up votes if there is an up vote column" do
        @votable_cache.cached_votes_up = 50
        @votable_cache.vote :voter => @alice, :value => 1
        @votable_cache.vote :voter => @alice, :value => 1
        @votable_cache.cached_votes_up.should == 1
      end

      it "should update cached down votes if there is a down vote column" do
        @votable_cache.cached_votes_down = 50
        @votable_cache.vote :voter => @alice, :value => -1
        @votable_cache.cached_votes_down.should == 1
      end

      it "should update cached up votes when a vote up is removed" do
        @votable_cache.vote :voter => @alice, :value => 1
        @votable_cache.unvote :voter => @alice
        @votable_cache.cached_votes_up.should == 0
      end

      it "should update cached down votes when a vote down is removed" do
        @votable_cache.vote :voter => @alice, :value => -1
        @votable_cache.unvote :voter => @alice
        @votable_cache.cached_votes_down.should == 0
      end

      it "should select from cached total votes if there a total column" do
        @votable_cache.vote :voter => @alice
        @votable_cache.cached_votes_total = 50
        @votable_cache.count_votes_total.should == 50
      end

      it "should select from cached up votes if there is an up vote column" do
        @votable_cache.vote :voter => @alice, :value => 1
        @votable_cache.cached_votes_up = 50
        @votable_cache.count_votes_up.should == 50
      end

      it "should select from cached down votes if there is a down vote column" do
        @votable_cache.vote :voter => @alice, :value => -1
        @votable_cache.cached_votes_down = 50
        @votable_cache.count_votes_down.should == 50
      end

    end

    context "sti models" do

      before do
        clean_database
      end

      it "should be able to vote on a votable child of a non votable sti model" do
        votable = VotableChildOfStiNotVotable.create(:name => 'sti child')

        votable.vote :voter => @alice, :value => 'yes'
        votable.votes.should have(1).vote
      end

      it "should not be able to vote on a parent non votable" do
        StiNotVotable.should_not be_votable
      end

      it "should be able to vote on a child when its parent is votable" do
        votable = ChildOfStiVotable.create(:name => 'sti child')

        votable.vote :voter => @alice, :value => 'yes'
        votable.votes.should have(1).vote
      end

    end

  end




  describe "Accessors with calculus" do

    describe "#mean_vote" do
      before do
        @votable = Votable.new(:name => 'Free the Seeds')
        @votable.save
      end
      it 'initially is 0 (without votes)' do
        @votable.mean_vote.should == 0
      end
      it 'has the value of the vote if there is only one' do
        @votable.vote :voter => new_voter, :value => 42
        @votable.mean_vote.should == 42
      end
      it 'holds the mean value of the values of the votes' do
        [1, 2, 3].each { |v| @votable.vote :voter => new_voter, :value => v }
        @votable.mean_vote.should == 2
      end
      it 'works with negative decision values' do
        [-5, -25, -30].each { |v| @votable.vote :voter => new_voter, :value => v }
        @votable.mean_vote.should == -20
      end
      it 'works with floating results' do
        [0, 5].each { |v| @votable.vote :voter => new_voter, :value => v }
        @votable.mean_vote.should == Rational(5, 2)
        @votable.mean_vote.should == 2.5
      end
    end

    describe "#votes_sum" do
      before do
        @votable = Votable.new(:name => 'Free the Seeds')
        @votable.save
      end
      it 'initially is 0 (without decisions)' do
        @votable.votes_sum.should == 0
      end
      it 'has the value of the vote if there is only one' do
        @votable.vote :voter => new_voter, :value => 42
        @votable.votes_sum.should == 42
      end
      it 'holds the sum of the values of the votes' do
        [1, 2, 3].each { |v| @votable.vote :voter => new_voter, :value => v }
        @votable.votes_sum.should == 6
      end
      it 'works with negative decision values' do
        [1, 1, -3].each { |v| @votable.vote :voter => new_voter, :value => v }
        @votable.votes_sum.should == -1
      end
    end

    describe '#winner_vote' do
      before do
        @votable = Votable.new(:name => 'Free the Seeds')
        @votable.save
      end
      it 'should return false initially' do
        @votable.winner_vote.should be false
      end
      it 'should return the value for a single Vote' do
        [1].each { |v| @votable.vote :voter => new_voter, :value => v }
        @votable.winner_vote.should == 1
      end
      it 'should return the most chosen value of all votes' do
        [1,1,0,-1].each { |v| @votable.vote :voter => new_voter, :value => v }
        @votable.winner_vote.should == 1
        [7,7,7].each { |v| @votable.vote :voter => new_voter, :value => v }
        @votable.winner_vote.should == 7
      end
      it 'should return 0 only if it is the most voted value' do
        [1,0,0].each { |v| @votable.vote :voter => new_voter, :value => v }
        @votable.winner_vote.should === 0
      end
      it 'should return false in case of a draw' do
        [5,6].each { |v| @votable.vote :voter => new_voter, :value => v }
        @votable.winner_vote.should be false
      end
    end

  end


end
