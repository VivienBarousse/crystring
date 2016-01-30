module Crystring
  class Parser

    class Statement
      def initialize(&block)
        @block = block
      end

      def invoke
        @block.call
      end
    end

    attr_reader :variables

    def initialize(tokenizer)
      @tokenizer = tokenizer
      @variables = {}
      @functions = {}
      next_token
    end

    def parse
      while @token
        if @token.type == Tokenizer::Token::IDENTIFIER
          parse_statement.invoke
        elsif @token.type == Tokenizer::Token::KEYWORD_DEF
          parse_function
        end
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
          value_token = @token
          raise "Invalid token #{@token.type}, expected string literal" unless @token.type == Tokenizer::Token::STRING_LITERAL
          next_token
        elsif @token.type == Tokenizer::Token::IDENTIFIER
          raise "Invalid token #{@token.type}, expected identifier" unless @token.type == Tokenizer::Token::IDENTIFIER
          value_token = @token
          next_token
        end
        raise "Invalid token #{@token.value}, expected \")\"" unless @token.type == Tokenizer::Token::CLOSING_PAREN
        next_token
        raise "Invalid token #{@token.value}, expected \";\"" unless @token.type == Tokenizer::Token::SEMICOLON
        next_token

        return Statement.new do
          if method_name == "puts"
            if value_token.type == Tokenizer::Token::STRING_LITERAL
              param = value_token.value
            elsif value_token.type == Tokenizer::Token::IDENTIFIER
              raise "Unknown variable '#{value_token.value}'" unless @variables.has_key?(value_token.value)
              param = variables[value_token.value]
            end
            puts param
          elsif @functions.has_key?(method_name)
            @functions[method_name].each(&:invoke)
          else
            raise "Unknown method #{method_name}"
          end
        end
      elsif @token.type == Tokenizer::Token::ASSIGN
        raise "Invalid token #{@token.value}, expected \"=\"" unless @token.type == Tokenizer::Token::ASSIGN
        next_token
        param = @token.value
        raise "Invalid token #{@token.type}, expected string literal" unless @token.type == Tokenizer::Token::STRING_LITERAL
        next_token
        raise "Invalid token #{@token.value}, expected \";\"" unless @token.type == Tokenizer::Token::SEMICOLON
        next_token

        return Statement.new do
          variables[method_name] = param
        end
      end
    end

    def parse_function
      raise "Invalid token #{@token.type}, expected \"def\"" unless @token.type == Tokenizer::Token::KEYWORD_DEF
      next_token

      method_name = @token.value
      raise "Invalid token #{@token.type}, expected identifier" unless @token.type == Tokenizer::Token::IDENTIFIER
      next_token

      raise "Invalid token #{@token.value}, expected \"(\"" unless @token.type == Tokenizer::Token::OPENING_PAREN
      next_token

      raise "Invalid token #{@token.value}, expected \")\"" unless @token.type == Tokenizer::Token::CLOSING_PAREN
      next_token

      raise "Invalid token #{@token.value}, expected \"{\"" unless @token.type == Tokenizer::Token::OPENING_CURLY
      next_token

      statements = []
      while @token.type != Tokenizer::Token::CLOSING_CURLY
        statements << parse_statement
      end

      @functions[method_name] = statements

      raise "Invalid token #{@token.value}, expected \"}\"" unless @token.type == Tokenizer::Token::CLOSING_CURLY
      next_token
    end

    private

    def next_token
      @token = @tokenizer.next_token
    end
  end
end

