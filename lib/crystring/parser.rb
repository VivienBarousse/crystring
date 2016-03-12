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

    class Expression
      def initialize(&block)
        @block = block
      end

      def evaluate
        @block.call
      end
    end

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
        unless @token.type == Tokenizer::Token::CLOSING_PAREN
          value_expression = parse_expression
        end
        raise "Invalid token #{@token.value}, expected \")\"" unless @token.type == Tokenizer::Token::CLOSING_PAREN
        next_token
        raise "Invalid token #{@token.value}, expected \";\"" unless @token.type == Tokenizer::Token::SEMICOLON
        next_token

        return Statement.new do
          if method_name == "puts"
            param = value_expression.evaluate
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
        param = parse_expression
        raise "Invalid token #{@token.value}, expected \";\"" unless @token.type == Tokenizer::Token::SEMICOLON
        next_token

        return Statement.new do
          set_variable(method_name, param.evaluate)
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

    def parse_expression
      case @token.type
      when Tokenizer::Token::STRING_LITERAL, Tokenizer::Token::IDENTIFIER
        expression = parse_value
      else
        raise "Invalid token #{@token.type}, expected expression"
      end

      if @token.type == Tokenizer::Token::EQUALS
        next_token
        lhs = expression
        rhs = parse_value
        expression = Expression.new do
          lhs.evaluate == rhs.evaluate ? "true" : "false"
        end
      elsif @token.type == Tokenizer::Token::NOT_EQUALS
        next_token
        lhs = expression
        rhs = parse_value
        expression = Expression.new do
          lhs.evaluate != rhs.evaluate ? "true" : "false"
        end
      end

      expression
    end

    def parse_value
      if @token.type == Tokenizer::Token::STRING_LITERAL
        value_token = @token
        raise "Invalid token #{@token.type}, expected string literal" unless @token.type == Tokenizer::Token::STRING_LITERAL
        next_token
        Expression.new do
          value_token.value
        end
      elsif @token.type == Tokenizer::Token::IDENTIFIER
        raise "Invalid token #{@token.type}, expected identifier" unless @token.type == Tokenizer::Token::IDENTIFIER
        value_token = @token
        next_token
        Expression.new do
          raise "Unknown variable '#{value_token.value}'" unless variable_exists?(value_token.value)
          get_variable(value_token.value)
        end
      end
    end

    private

    def next_token
      @token = @tokenizer.next_token
    end

    def variable_exists?(name)
      @variables.has_key?(name)
    end

    def get_variable(name)
      @variables[name]
    end

    def set_variable(name, value)
      @variables[name] = value
    end
  end
end

