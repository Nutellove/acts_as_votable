require 'acts_as_votable'
require 'spec_helper'

describe ActsAsVotable::Votable do

  before(:each) do
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


  describe "#mean_vote" do
    before do
      # unused
      @alice = Voter.new(:name => 'Alice')
      @alice.save
      @bob = Voter.new(:name => 'Bob')
      @bob.save
      @eve = Voter.new(:name => 'Eve')
      @eve.save
      ########
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
      @votable.mean_vote.should == Rational(5,2)
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

  describe "voting on a votable object" do

    before(:each) do
      clean_database
      @voter = Voter.new(:name => 'i can vote!')
      @voter.save

      @voter2 = Voter.new(:name => 'a new person')
      @voter2.save

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
      @votable.vote :voter => @voter, :value => 'yes'
      @votable.votes.should have(1).vote
    end

    context "we already voted on" do

      before do
        @votable.vote :voter => @voter, :value => -1
        @votable.vote :voter => @voter, :value =>  1
      end

      it "should have one vote, not two" do
        @votable.votes.should have(1).vote
      end

      it "should update the vote's value" do
        @votable.vote_value_of(@voter).should == 1
      end

    end



    it "should be callable with vote_up" do
      @votable.vote_up @voter
      @votable.up_votes.first.voter.should == @voter
    end

    it "should be callable with vote_obiwan" do
      @votable.vote_obiwan @voter
      @votable.vote_value_of(@voter).should == 0
      @votable.obiwan_votes.first.voter.should == @voter
    end

    it "should be callable with vote_down" do
      @votable.vote_down @voter
      @votable.down_votes.first.voter.should == @voter
    end

    it "should have 2 votes when voted on once by two different people" do
      @votable.vote :voter => @voter
      @votable.vote :voter => @voter2
      @votable.votes.size.should == 2
    end

    it "should have one up vote" do
      @votable.vote :voter => @voter,  :value => 'like'
      @votable.vote :voter => @voter2, :value => 'dislike'
      @votable.up_votes.size.should == 1
    end

    it "should have 2 false votes" do
      @votable.vote :voter => @voter, :value => 'no'
      @votable.vote :voter => @voter2, :value => 'dislike'
      @votable.down_votes.size.should == 2
    end

    it "should have been voted on by voter2" do
      @votable.vote :voter => @voter2, :value => true
      @votable.find_votes.first.voter.id.should be @voter2.id
    end

    it "should count the vote as registered if this is the voters first vote" do
      @votable.vote :voter => @voter
      @votable.vote_registered?.should be true
    end

    it "should not count the vote as being registered if that voter has already voted and the vote has not changed" do
      @votable.vote :voter => @voter, :value => true
      @votable.vote :voter => @voter, :value => 'yes'
      @votable.vote_registered?.should be false
    end

    it "should count the vote as registered if the voter has voted and the vote has changed" do
      @votable.vote :voter => @voter, :value => true
      @votable.vote :voter => @voter, :value => 'dislike'
      @votable.vote_registered?.should be true
    end

    it "should be voted on by voter" do
      @votable.vote :voter => @voter
      @votable.voted_on_by?(@voter).should be true
    end

    it "should unvote a positive vote" do
      @votable.vote :voter => @voter
      @votable.unvote :voter => @voter
      @votable.find_votes.count.should == 0
    end

    it "should set the votable to unregistered after unvoting" do
      @votable.vote :voter => @voter
      @votable.unvote :voter => @voter
      @votable.vote_registered?.should be false
    end

    it "should unvote a negative vote" do
      @votable.vote :voter => @voter, :value => 'no'
      @votable.unvote :voter => @voter
      @votable.find_votes.count.should == 0
    end

    it "should unvote only the from a single voter" do
      @votable.vote :voter => @voter
      @votable.vote :voter => @voter2
      @votable.unvote :voter => @voter
      @votable.find_votes.count.should == 1
    end

    it "should be contained to instances" do
      votable2 = Votable.new(:name => '2nd votable')
      votable2.save

      @votable.vote :voter => @voter, :value => false
      votable2.vote :voter => @voter, :value => true
      votable2.vote :voter => @voter, :value => true

      @votable.vote_registered?.should be true
      votable2.vote_registered?.should be false
    end

    describe "with cached votes" do

      before(:each) do
        clean_database
        @voter = Voter.new(:name => 'i can vote!')
        @voter.save

        @votable = Votable.new(:name => 'a voting model without a cache')
        @votable.save

        @votable_cache = VotableCache.new(:name => 'voting model with cache')
        @votable_cache.save
      end

      it "should not update cached votes if there are no columns" do
        @votable.vote :voter => @voter
      end

      it "should update cached total votes if there is a total column" do
        @votable_cache.cached_votes_total = 50
        @votable_cache.vote :voter => @voter
        @votable_cache.cached_votes_total.should == 1
      end

      it "should update cached total votes when a vote up is removed" do
        @votable_cache.vote :voter => @voter, :value => 1
        @votable_cache.unvote :voter => @voter
        @votable_cache.cached_votes_total.should == 0
      end

      it "should update cached total votes when a vote down is removed" do
        @votable_cache.vote :voter => @voter, :value => -1
        @votable_cache.unvote :voter => @voter
        @votable_cache.cached_votes_total.should == 0
      end

      it "should update cached up votes if there is an up vote column" do
        @votable_cache.cached_votes_up = 50
        @votable_cache.vote :voter => @voter, :value => 1
        @votable_cache.vote :voter => @voter, :value => 1
        @votable_cache.cached_votes_up.should == 1
      end

      it "should update cached down votes if there is a down vote column" do
        @votable_cache.cached_votes_down = 50
        @votable_cache.vote :voter => @voter, :value => -1
        @votable_cache.cached_votes_down.should == 1
      end

      it "should update cached up votes when a vote up is removed" do
        @votable_cache.vote :voter => @voter, :value => 1
        @votable_cache.unvote :voter => @voter
        @votable_cache.cached_votes_up.should == 0
      end

      it "should update cached down votes when a vote down is removed" do
        @votable_cache.vote :voter => @voter, :value => -1
        @votable_cache.unvote :voter => @voter
        @votable_cache.cached_votes_down.should == 0
      end

      it "should select from cached total votes if there a total column" do
        @votable_cache.vote :voter => @voter
        @votable_cache.cached_votes_total = 50
        @votable_cache.count_votes_total.should == 50
      end

      it "should select from cached up votes if there is an up vote column" do
        @votable_cache.vote :voter => @voter, :value => 1
        @votable_cache.cached_votes_up = 50
        @votable_cache.count_votes_up.should == 50
      end

      it "should select from cached down votes if there is a down vote column" do
        @votable_cache.vote :voter => @voter, :value => -1
        @votable_cache.cached_votes_down = 50
        @votable_cache.count_votes_down.should == 50
      end

    end

    describe "sti models" do

      before(:each) do
        clean_database
        @voter = Voter.create(:name => 'i can vote!')
      end

      it "should be able to vote on a votable child of a non votable sti model" do
        votable = VotableChildOfStiNotVotable.create(:name => 'sti child')

        votable.vote :voter => @voter, :value => 'yes'
        votable.votes.size.should == 1
      end

      it "should not be able to vote on a parent non votable" do
        StiNotVotable.should_not be_votable
      end

      it "should be able to vote on a child when its parent is votable" do
        votable = ChildOfStiVotable.create(:name => 'sti child')

        votable.vote :voter => @voter, :value => 'yes'
        votable.votes.size.should == 1
      end

    end

  end


end
