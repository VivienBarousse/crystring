module Crystring
  class Parser

    class DefaultLookupScope
      def initialize
        @variables = {}
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

    class Statement
      def initialize(*args, &block)
        @args = args
        @block = block
      end

      def invoke
        @block.call(*@args)
      end
    end

    class Expression
      def initialize(*args, &block)
        @args = args
        @block = block
      end

      def evaluate
        @block.call(*@args)
      end
    end

    class Function
      def initialize(lookup_scopes, formal_params, statements)
        @lookup_scopes = lookup_scopes
        @formal_params = formal_params
        @statements = statements
        @variables = {}
      end

      def invoke(actual_params)
        unless @formal_params.length == actual_params.length
          raise "Invalid cardinality for function: expected #{@formal_params.length} arguments, got #{actual_params.length}"
        end
        @formal_params.length.times do |i|
          @variables[@formal_params[i]] = actual_params[i]
        end
        begin
          @lookup_scopes << self
          value = nil
          @statements.each do |s|
            value = s.invoke
          end
          value
        ensure
          @lookup_scopes.pop
        end
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

    def initialize(tokenizer)
      @tokenizer = tokenizer
      @variables = {}
      @functions = {}
      @lookup_scopes = [DefaultLookupScope.new]

      @functions["puts"] = Function.new(
        @lookup_scopes,
        ["value"],
        [Statement.new { puts get_variable("value") }]
      )
      @functions["gets"] = Function.new(
        @lookup_scopes,
        [],
        [Statement.new { Types::String.new(STDIN.readline.gsub(/\n$/, '')) }]
      )

      Types::String.def_method("+", Function.new(
        @lookup_scopes,
        ["a"],
        [Statement.new { Types::String.new(get_variable("self").to_s + get_variable("a").to_s) }]
      ))
      Types::String.def_method("upcase", Function.new(
        @lookup_scopes,
        [],
        [Statement.new { Types::String.new(get_variable("self").upcase) }]
      ))
      Types::String.def_method("downcase", Function.new(
        @lookup_scopes,
        [],
        [Statement.new { Types::String.new(get_variable("self").downcase) }]
      ))
      Types::String.def_method("length", Function.new(
        @lookup_scopes,
        [],
        [Statement.new { Types::Integer.new(get_variable("self").length) }]
      ))

      Types::Integer.def_method("+", Function.new(
        @lookup_scopes,
        ["a"],
        [Statement.new { Types::Integer.new((Integer(get_variable("self").to_s) + Integer(get_variable("a").to_s)).to_s) }]
      ))

      set_variable("Integer", Types::Integer)
      set_variable("String", Types::String)

      next_token
    end

    def parse
      while @token
        if @token.type == Tokenizer::Token::IDENTIFIER
          parse_statement.invoke
        elsif @token.type == Tokenizer::Token::KEYWORD_DEF
          f = parse_function
          @functions[f[0]] = f[1]
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

    def lookup_type(type_name)
      type = get_variable(type_name)
      unless type.is_a?(Class) && type <= Types::Base
        raise "Unexpected base type `#{type_name}`, is a variable, not a type."
      end
      type
    end

    def parse_class
      assert_token(Tokenizer::Token::KEYWORD_CLASS)
      type_name = assert_token(Tokenizer::Token::IDENTIFIER).value
      if @token.type == Tokenizer::Token::KEYWORD_EXTENDS
        assert_token(Tokenizer::Token::KEYWORD_EXTENDS)
        base_type_name = assert_token(Tokenizer::Token::IDENTIFIER).value
      end
      assert_token(Tokenizer::Token::OPENING_CURLY)

      if variable_exists?(type_name)
        type = lookup_type(type_name)
        if base_type_name
          raise "Unexpected `extends` on type redeclaration."
        end
      else
        base_type = Types::String
        if base_type_name
          base_type = lookup_type(base_type_name)
        end
        type = Class.new(Types::Base) do
          base_class base_type
        end
        set_variable(type_name, type)
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

      return Statement.new do
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

        statements << [Expression.new { "true" }, parse_statements_block]
      end

      return Statement.new(statements) do |statements|
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

      return Statement.new do
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

      return [function_name, Function.new(@lookup_scopes, formal_params, statements)]
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
        expression = Expression.new do
          lhs.evaluate == rhs.evaluate ? "true" : "false"
        end
      elsif @token.type == Tokenizer::Token::PLUS
        assert_token(Tokenizer::Token::PLUS)

        lhs = expression
        rhs = parse_value
        expression = Expression.new do
          value = lhs.evaluate
          @lookup_scopes << value
          result = value.call_method("+", [rhs.evaluate])
          @lookup_scopes.pop
          result
        end
      elsif @token.type == Tokenizer::Token::NOT_EQUALS
        assert_token(Tokenizer::Token::NOT_EQUALS)

        lhs = expression
        rhs = parse_value
        expression = Expression.new do
          lhs.evaluate != rhs.evaluate ? "true" : "false"
        end
      elsif @token.type == Tokenizer::Token::ASSIGN
        assert_token(Tokenizer::Token::ASSIGN)

        param = parse_expression
        return Expression.new do
          v = param.evaluate
          set_variable(expression_name, v)
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

        return Expression.new do
          if @functions.has_key?(expression_name)
            params = value_expressions.map(&:evaluate)
            @functions[expression_name].invoke(params)
          else
            raise "Unknown function #{expression_name}"
          end
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

          expression = Expression.new(function_name, expression, value_expressions) do |f, target, value_expressions|
            value = target.evaluate
            @lookup_scopes << value
            result = value.call_method(f, value_expressions.map(&:evaluate))
            @lookup_scopes.pop
            result
          end
        end
      end

      expression
    end

    def parse_value
      if @token.type == Tokenizer::Token::STRING_LITERAL
        value = assert_token(Tokenizer::Token::STRING_LITERAL).value
        Expression.new do
          Types::String.new(value)
        end
      elsif @token.type == Tokenizer::Token::IDENTIFIER
        value_token = assert_token(Tokenizer::Token::IDENTIFIER)
        Expression.new do
          raise "Unknown variable '#{value_token.value}'" unless variable_exists?(value_token.value)
          get_variable(value_token.value)
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

    def variable_exists?(name)
      @lookup_scopes.any? { |s| s.variable_exists?(name) }
    end

    def get_variable(name)
      scope = @lookup_scopes.reverse.detect { |s| s.variable_exists?(name) }
      scope.get_variable(name)
    end

    def set_variable(name, value)
      @lookup_scopes.last.set_variable(name, value)
    end
  end
end

