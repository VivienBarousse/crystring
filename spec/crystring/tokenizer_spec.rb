require 'spec_helper'

describe Crystring::Tokenizer do
  subject { described_class.new(StringIO.new(code)) }

  describe "identifiers" do
    let(:code) { "abc efg" }

    it "should return identifier tokens" do
      expect(subject.next_token).to eq(Crystring::Tokenizer::Token.new(Crystring::Tokenizer::Token::IDENTIFIER, "abc"))
      expect(subject.next_token).to eq(Crystring::Tokenizer::Token.new(Crystring::Tokenizer::Token::IDENTIFIER, "efg"))
    end

    describe "with underscores" do
      let(:code) { "abc_efg" }

      it "should include underscores in identifiers" do
        expect(subject.next_token).to eq(Crystring::Tokenizer::Token.new(Crystring::Tokenizer::Token::IDENTIFIER, "abc_efg"))
      end
    end
  end

  describe "keywords" do
    describe "elsif" do
      let(:code) { "elsif" }

      it "should return a keyword token" do
        expect(subject.next_token).to eq(Crystring::Tokenizer::Token.new(Crystring::Tokenizer::Token::KEYWORD_ELSIF, "elsif"))
        expect(subject.next_token).to be_nil
      end
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

  describe "line comments" do
    let(:code) { "abc #this comment\ncde" }

    it "should ignore the comment" do
      expect(subject.next_token).to eq(Crystring::Tokenizer::Token.new(Crystring::Tokenizer::Token::IDENTIFIER, "abc"))
      expect(subject.next_token).to eq(Crystring::Tokenizer::Token.new(Crystring::Tokenizer::Token::IDENTIFIER, "cde"))
      expect(subject.next_token).to be_nil
    end

    describe "comment on last line" do
      let(:code) { "abc cde\n#this comment" }

      it "should ignore the comment" do
        expect(subject.next_token).to eq(Crystring::Tokenizer::Token.new(Crystring::Tokenizer::Token::IDENTIFIER, "abc"))
        expect(subject.next_token).to eq(Crystring::Tokenizer::Token.new(Crystring::Tokenizer::Token::IDENTIFIER, "cde"))
        expect(subject.next_token).to be_nil
      end
    end
  end
end

