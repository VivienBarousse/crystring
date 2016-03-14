require 'spec_helper'

describe Crystring::Tokenizer do
  subject { described_class.new(StringIO.new(code)) }

  describe "identifiers" do
    let(:code) { "abc efg" }

    it "should return identifier tokens" do
      expect(subject.next_token).to eq(Crystring::Tokenizer::Token.new(Crystring::Tokenizer::Token::IDENTIFIER, "abc"))
      expect(subject.next_token).to eq(Crystring::Tokenizer::Token.new(Crystring::Tokenizer::Token::IDENTIFIER, "efg"))
    end
  end

  describe "strings" do
    let(:code) { "\"string\" \"abc\"" }

    it "should return literal strings" do
      expect(subject.next_token).to eq(Crystring::Tokenizer::Token.new(Crystring::Tokenizer::Token::STRING_LITERAL, "string"))
      expect(subject.next_token).to eq(Crystring::Tokenizer::Token.new(Crystring::Tokenizer::Token::STRING_LITERAL, "abc"))
    end

    describe "unterminated strings" do
      let(:code) { "\"string" }

      it "should raise an error" do
        expect { subject.next_token }.to raise_error(Crystring::Tokenizer::UnfinishedLiteral)
      end
    end
  end
end

