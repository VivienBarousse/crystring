module Crystring
  class Parser
    def initialize(tokenizer)
      @tokenizer = tokenizer
      next_token
    end

    def parse
      while @token
        parse_statement
      end
    end

    # identifier, "(", value, ")"
    def parse_statement
      method_name = @token.value
      raise "Invalid token #{@token.type}, expected identifier" unless @token.type == Tokenizer::Token::IDENTIFIER
      next_token
      raise "Invalid token #{@token.value}, expected \"(\"" unless @token.type == Tokenizer::Token::OPENING_PAREN
      next_token
      param = @token.value
      raise "Invalid token #{@token.type}, expected string literal" unless @token.type == Tokenizer::Token::STRING_LITERAL
      next_token
      raise "Invalid token #{@token.value}, expected \")\"" unless @token.type == Tokenizer::Token::CLOSING_PAREN
      next_token
      raise "Invalid token #{@token.value}, expected \";\"" unless @token.type == Tokenizer::Token::SEMICOLON
      next_token

      if method_name == "puts"
        puts param
      else
        raise "Unknown method #{method_name}"
      end
    end

    private

    def next_token
      @token = @tokenizer.next_token
    end
  end
end

