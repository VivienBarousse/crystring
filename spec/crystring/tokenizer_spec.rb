require 'spec_helper'

describe Crystring::Tokenizer do
  subject { described_class.new(StringIO.new(code)) }

  describe "literals" do
    let(:code) { "abc efg" }

    it "should return proper literals" do
      expect(subject.next_token).to eq(Crystring::Tokenizer::Token.new(Crystring::Tokenizer::Token::IDENTIFIER, "abc"))
      expect(subject.next_token).to eq(Crystring::Tokenizer::Token.new(Crystring::Tokenizer::Token::IDENTIFIER, "efg"))
    end
  end
end

