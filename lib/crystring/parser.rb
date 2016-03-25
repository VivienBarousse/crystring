module Crystring
  class Parser

    def initialize(tokenizer)
      @tokenizer = tokenizer
      @syntax_tree = SyntaxTree.new

      next_token
    end

    def parse
      while @token
        if @token.type == Tokenizer::Token::IDENTIFIER
          parse_statement.invoke
        elsif @token.type == Tokenizer::Token::KEYWORD_DEF
          f = parse_function
          @syntax_tree.set_function(f[0], f[1])
        elsif @token.type == Tokenizer::Token::KEYWORD_IF
          parse_if.invoke
        elsif @token.type == Tokenizer::Token::KEYWORD_WHILE
          parse_while.invoke
        elsif @token.type == Tokenizer::Token::KEYWORD_CLASS
          parse_class
        else
          raise "Unexpected token `#{@token.value}`"
        end
      end
    end

    def parse_class
      assert_token(Tokenizer::Token::KEYWORD_CLASS)
      type_name = assert_token(Tokenizer::Token::IDENTIFIER).value
      if @token.type == Tokenizer::Token::KEYWORD_EXTENDS
        assert_token(Tokenizer::Token::KEYWORD_EXTENDS)
        base_type_name = assert_token(Tokenizer::Token::IDENTIFIER).value
      end
      assert_token(Tokenizer::Token::OPENING_CURLY)

      if @syntax_tree.variable_exists?(type_name)
        type = @syntax_tree.lookup_type(type_name)
        if base_type_name
          raise "Unexpected `extends` on type redeclaration."
        end
      else
        base_type = Types::String
        if base_type_name
          base_type = @syntax_tree.lookup_type(base_type_name)
        end
        type = Class.new(Types::Base) do
          base_class base_type
        end
        @syntax_tree.set_variable(type_name, type)
      end

      while @token.type == Tokenizer::Token::KEYWORD_DEF
        f = parse_function
        type.def_method(f[0], f[1])
      end

      assert_token(Tokenizer::Token::CLOSING_CURLY)
    end

    # expression, ";"
    def parse_statement
      if @token.type == Tokenizer::Token::KEYWORD_IF
        return parse_if
      end
      if @token.type == Tokenizer::Token::KEYWORD_WHILE
        return parse_while
      end

      expression = parse_expression

      assert_token(Tokenizer::Token::SEMICOLON)

      return SyntaxTree::Statement.new do
        expression.evaluate
      end
    end

    # "if", "(", expression, ")", "{", [statement], "}"
    def parse_if
      assert_token(Tokenizer::Token::KEYWORD_IF)
      assert_token(Tokenizer::Token::OPENING_PAREN)

      value_expression = parse_expression

      assert_token(Tokenizer::Token::CLOSING_PAREN)

      statements = []
      statements << [value_expression, parse_statements_block]

      while @token && @token.type == Tokenizer::Token::KEYWORD_ELSIF
        assert_token(Tokenizer::Token::KEYWORD_ELSIF)
        assert_token(Tokenizer::Token::OPENING_PAREN)

        value_expression = parse_expression

        assert_token(Tokenizer::Token::CLOSING_PAREN)

        statements << [value_expression, parse_statements_block]
      end

      if @token && @token.type == Tokenizer::Token::KEYWORD_ELSE
        assert_token(Tokenizer::Token::KEYWORD_ELSE)

        statements << [SyntaxTree::Expression.new { "true" }, parse_statements_block]
      end

      return SyntaxTree::Statement.new(statements) do |statements|
        statements.each do |expression, statements|
          case expression.evaluate
          when "true"
            statements.each(&:invoke)
            break
          when "false"
          else
            raise "Invalid value for boolean: `#{value_expression.evaluate}`"
          end
        end
      end
    end

    # "while", "(", expression, ")", "{", [statement], "}"
    def parse_while
      assert_token(Tokenizer::Token::KEYWORD_WHILE)
      assert_token(Tokenizer::Token::OPENING_PAREN)

      value_expression = parse_expression

      assert_token(Tokenizer::Token::CLOSING_PAREN)

      while_statements = parse_statements_block

      return SyntaxTree::Statement.new do
        while value_expression.evaluate == "true"
          while_statements.each(&:invoke)
        end
      end
    end

    def parse_function
      assert_token(Tokenizer::Token::KEYWORD_DEF)
      function_name = assert_token(Tokenizer::Token::IDENTIFIER).value
      assert_token(Tokenizer::Token::OPENING_PAREN)

      formal_params = []
      while @token.type == Tokenizer::Token::IDENTIFIER
        formal_params << assert_token(Tokenizer::Token::IDENTIFIER).value

        if @token.type == Tokenizer::Token::COMMA
          next_token
        elsif @token.type == Tokenizer::Token::CLOSING_PAREN
          break
        else
          raise "Invalid token #{@token.value}, expected \")\" or \",\"" unless @token.type == Tokenizer::Token::CLOSING_PAREN
        end
      end

      assert_token(Tokenizer::Token::CLOSING_PAREN)

      statements = parse_statements_block

      return [function_name, SyntaxTree::Function.new(@syntax_tree, formal_params, statements)]
    end

    def parse_statements_block
      assert_token(Tokenizer::Token::OPENING_CURLY)

      statements = []
      while @token.type != Tokenizer::Token::CLOSING_CURLY
        statements << parse_statement
      end

      assert_token(Tokenizer::Token::CLOSING_CURLY)

      statements
    end

    def parse_expression
      case @token.type
      when Tokenizer::Token::STRING_LITERAL, Tokenizer::Token::IDENTIFIER
        if @token.type == Tokenizer::Token::IDENTIFIER
          expression_name = @token.value
        end
        expression = parse_value
      else
        raise "Invalid token #{@token.type}, expected expression"
      end

      if @token.type == Tokenizer::Token::EQUALS
        assert_token(Tokenizer::Token::EQUALS)

        lhs = expression
        rhs = parse_value
        expression = SyntaxTree::Expression.new do
          lhs.evaluate == rhs.evaluate ? "true" : "false"
        end
      elsif @token.type == Tokenizer::Token::PLUS
        assert_token(Tokenizer::Token::PLUS)

        lhs = expression
        rhs = parse_expression
        expression = SyntaxTree::Expression.new do
          value = lhs.evaluate
          @syntax_tree.with_lookup_scope(value) do
            value.call_method("+", [rhs.evaluate])
          end
        end
      elsif @token.type == Tokenizer::Token::NOT_EQUALS
        assert_token(Tokenizer::Token::NOT_EQUALS)

        lhs = expression
        rhs = parse_value
        expression = SyntaxTree::Expression.new do
          lhs.evaluate != rhs.evaluate ? "true" : "false"
        end
      elsif @token.type == Tokenizer::Token::ASSIGN
        assert_token(Tokenizer::Token::ASSIGN)

        param = parse_expression
        return SyntaxTree::Expression.new do
          v = param.evaluate
          @syntax_tree.set_variable(expression_name, v)
          v
        end
      elsif @token.type == Tokenizer::Token::OPENING_PAREN
        assert_token(Tokenizer::Token::OPENING_PAREN)

        value_expressions = []
        until @token.type == Tokenizer::Token::CLOSING_PAREN
          value_expressions << parse_expression

          unless @token.type == Tokenizer::Token::CLOSING_PAREN
            assert_token(Tokenizer::Token::COMMA)
          end
        end

        assert_token(Tokenizer::Token::CLOSING_PAREN)

        return SyntaxTree::Expression.new do
          @syntax_tree.call_function(expression_name, value_expressions)
        end
      elsif @token.type == Tokenizer::Token::PERIOD
        while @token.type == Tokenizer::Token::PERIOD
          assert_token(Tokenizer::Token::PERIOD)
          function_name = assert_token(Tokenizer::Token::IDENTIFIER).value
          assert_token(Tokenizer::Token::OPENING_PAREN)

          value_expressions = []
          until @token.type == Tokenizer::Token::CLOSING_PAREN
            value_expressions << parse_expression

            unless @token.type == Tokenizer::Token::CLOSING_PAREN
              assert_token(Tokenizer::Token::COMMA)
            end
          end

          assert_token(Tokenizer::Token::CLOSING_PAREN)

          expression = SyntaxTree::Expression.new(function_name, expression, value_expressions) do |f, target, value_expressions|
            value = target.evaluate
            @syntax_tree.with_lookup_scope(value) do
              value.call_method(f, value_expressions.map(&:evaluate))
            end
          end
        end
      end

      expression
    end

    def parse_value
      if @token.type == Tokenizer::Token::STRING_LITERAL
        value = assert_token(Tokenizer::Token::STRING_LITERAL).value
        SyntaxTree::Expression.new do
          Types::String.new(value)
        end
      elsif @token.type == Tokenizer::Token::IDENTIFIER
        value_token = assert_token(Tokenizer::Token::IDENTIFIER)
        SyntaxTree::Expression.new do
          raise "Unknown variable '#{value_token.value}'" unless @syntax_tree.variable_exists?(value_token.value)
          @syntax_tree.get_variable(value_token.value)
        end
      end
    end

    private

    def assert_token(type)
      t = @token
      unless @token.type == type
        raise "Invalid token type #{@token.type}, expected #{type}"
      end
      next_token
      t
    end

    def next_token
      @token = @tokenizer.next_token
    end
  end
end

