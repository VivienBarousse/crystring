module Crystring
  class Parser
    attr_reader :variables

    def initialize(tokenizer)
      @tokenizer = tokenizer
      @variables = {}
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

      if @token.type == Tokenizer::Token::OPENING_PAREN
        raise "Invalid token #{@token.value}, expected \"(\"" unless @token.type == Tokenizer::Token::OPENING_PAREN
        next_token
        if @token.type == Tokenizer::Token::STRING_LITERAL
          param = @token.value
          raise "Invalid token #{@token.type}, expected string literal" unless @token.type == Tokenizer::Token::STRING_LITERAL
          next_token
        elsif @token.type == Tokenizer::Token::IDENTIFIER
          raise "Invalid token #{@token.type}, expected identifier" unless @token.type == Tokenizer::Token::IDENTIFIER
          raise "Unknown variable \"#{@token.value}\"" unless variables.has_key?(@token.value)
          param = variables[@token.value]
          next_token
        end
        raise "Invalid token #{@token.value}, expected \")\"" unless @token.type == Tokenizer::Token::CLOSING_PAREN
        next_token
        raise "Invalid token #{@token.value}, expected \";\"" unless @token.type == Tokenizer::Token::SEMICOLON
        next_token

        if method_name == "puts"
          puts param
        else
          raise "Unknown method #{method_name}"
        end
      elsif @token.type == Tokenizer::Token::ASSIGN
        raise "Invalid token #{@token.value}, expected \"=\"" unless @token.type == Tokenizer::Token::ASSIGN
        next_token
        param = @token.value
        raise "Invalid token #{@token.type}, expected string literal" unless @token.type == Tokenizer::Token::STRING_LITERAL
        next_token
        raise "Invalid token #{@token.value}, expected \";\"" unless @token.type == Tokenizer::Token::SEMICOLON
        next_token
        variables[method_name] = param
      end
    end

    private

    def next_token
      @token = @tokenizer.next_token
    end
  end
end

