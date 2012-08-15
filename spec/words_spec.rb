require 'acts_as_votable'
require 'spec_helper'

describe ActsAsVotable::Helpers::Words do

  before :each do
    @vote = ActsAsVotable::Vote.new
  end

  it "should know that like is a true vote" do
    @vote.votable_words.that_mean_one.should include "like"
  end

  it "should know that bad is a false vote" do
    @vote.votable_words.that_mean_minus_one.should include "bad"
  end

  describe 'self.meaning_of' do

    it "should be a vote for 1 when word is up" do
      @vote.votable_words.meaning_of('up').should be 1
    end

    it "should be a vote for -1 when word is down" do
      @vote.votable_words.meaning_of('down').should be -1
    end

    it "should be a vote for true when the word is unknown" do
      @vote.votable_words.meaning_of('lsdhklkadhfs').should be 0
    end

  end

end
