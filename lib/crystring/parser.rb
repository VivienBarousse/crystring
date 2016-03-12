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
          @lookup_scopes.delete(self)
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

      Types::String.def_method("upcase", Function.new(
        @lookup_scopes,
        [],
        [Statement.new { get_variable("self").upcase }]
      ))

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
        elsif @token.type == Tokenizer::Token::KEYWORD_CLASS
          parse_class
        else
          raise "Unexpected token `#{@token.value}`"
        end
      end
    end

    def parse_class
      raise "Invalid token #{@token.type}, expected `class`" unless @token.type == Tokenizer::Token::KEYWORD_CLASS
      next_token
      type_name = @token.value
      raise "Invalid token #{@token.type}, expected identifier" unless @token.type == Tokenizer::Token::IDENTIFIER
      next_token
      raise "Invalid token #{@token.type}, expected `{`" unless @token.type == Tokenizer::Token::OPENING_CURLY
      next_token

      if type_name == "String"
        type = Types::String
      else
        raise "Unknown type `#{type_name}`"
      end

      while @token.type == Tokenizer::Token::KEYWORD_DEF
        f = parse_function
        type.def_method(f[0], f[1])
      end

      raise "Invalid token #{@token.type}, expected `}`" unless @token.type == Tokenizer::Token::CLOSING_CURLY
      next_token
    end

    # identifier, "(", value, ")"
    def parse_statement
      if @token.type == Tokenizer::Token::KEYWORD_IF
        return parse_if
      end

      function_name = @token.value
      raise "Invalid token #{@token.type}, expected identifier" unless @token.type == Tokenizer::Token::IDENTIFIER
      next_token

      if @token.type == Tokenizer::Token::OPENING_PAREN
        raise "Invalid token #{@token.value}, expected \"(\"" unless @token.type == Tokenizer::Token::OPENING_PAREN
        next_token

        value_expressions = []
        until @token.type == Tokenizer::Token::CLOSING_PAREN
          value_expressions << parse_expression

          unless @token.type == Tokenizer::Token::CLOSING_PAREN
            raise "Invalid token #{@token.value}, expected \",\"" unless @token.type == Tokenizer::Token::COMMA
            next_token
          end
        end

        raise "Invalid token #{@token.value}, expected \")\"" unless @token.type == Tokenizer::Token::CLOSING_PAREN
        next_token
        raise "Invalid token #{@token.value}, expected \";\"" unless @token.type == Tokenizer::Token::SEMICOLON
        next_token

        return Statement.new do
          if @functions.has_key?(function_name)
            params = value_expressions.map(&:evaluate)
            @functions[function_name].invoke(params)
          else
            raise "Unknown function #{function_name}"
          end
        end
      elsif @token.type == Tokenizer::Token::ASSIGN
        raise "Invalid token #{@token.value}, expected \"=\"" unless @token.type == Tokenizer::Token::ASSIGN
        next_token
        param = parse_expression
        raise "Invalid token #{@token.value}, expected \";\"" unless @token.type == Tokenizer::Token::SEMICOLON
        next_token

        return Statement.new do
          set_variable(function_name, param.evaluate)
        end
      elsif @token.type == Tokenizer::Token::PERIOD
        next_token
        target_name = function_name

        function_name = @token.value
        raise "Invalid token #{@token.type}, expected identifier" unless @token.type == Tokenizer::Token::IDENTIFIER
        next_token

        raise "Invalid token #{@token.value}, expected \"(\"" unless @token.type == Tokenizer::Token::OPENING_PAREN
        next_token

        value_expressions = []
        until @token.type == Tokenizer::Token::CLOSING_PAREN
          value_expressions << parse_expression

          unless @token.type == Tokenizer::Token::CLOSING_PAREN
            raise "Invalid token #{@token.value}, expected \",\"" unless @token.type == Tokenizer::Token::COMMA
            next_token
          end
        end

        raise "Invalid token #{@token.value}, expected \")\"" unless @token.type == Tokenizer::Token::CLOSING_PAREN
        next_token
        raise "Invalid token #{@token.value}, expected \";\"" unless @token.type == Tokenizer::Token::SEMICOLON
        next_token

        return Statement.new do
          value = get_variable(target_name)
          @lookup_scopes << value
          value.call_method(function_name, value_expressions.map(&:evaluate))
          @lookup_scopes.delete(value)
        end
      else
        raise "Invalid token #{@token.type}, expected one of \"(\", \"=\", \".\"."
      end
    end

    # "if", "(", expression, ")", "{", [statement], "}"
    def parse_if
      raise "Invalid token #{@token.type}, expected keyword_if" unless @token.type == Tokenizer::Token::KEYWORD_IF
      next_token
      raise "Invalid token #{@token.value}, expected \"(\"" unless @token.type == Tokenizer::Token::OPENING_PAREN
      next_token

      value_expression = parse_expression

      raise "Invalid token #{@token.value}, expected \")\"" unless @token.type == Tokenizer::Token::CLOSING_PAREN
      next_token
      raise "Invalid token #{@token.value}, expected \"{\"" unless @token.type == Tokenizer::Token::OPENING_CURLY
      next_token

      if_statements = []
      else_statements = []

      while @token.type != Tokenizer::Token::CLOSING_CURLY
        if_statements << parse_statement
      end

      raise "Invalid token #{@token.value}, expected \"}\"" unless @token.type == Tokenizer::Token::CLOSING_CURLY
      next_token

      if @token && @token.type == Tokenizer::Token::KEYWORD_ELSE
        next_token
        raise "Invalid token #{@token.value}, expected \"{\"" unless @token.type == Tokenizer::Token::OPENING_CURLY
        next_token

        while @token.type != Tokenizer::Token::CLOSING_CURLY
          else_statements << parse_statement
        end

        raise "Invalid token #{@token.value}, expected \"}\"" unless @token.type == Tokenizer::Token::CLOSING_CURLY
        next_token
      end

      return Statement.new do
        case value_expression.evaluate
        when "true"
          if_statements.each(&:invoke)
        when "false"
          else_statements.each(&:invoke)
        else
          raise "Invalid value for boolean: `#{value_expression.evaluate}`"
        end
      end
    end

    def parse_function
      raise "Invalid token #{@token.type}, expected \"def\"" unless @token.type == Tokenizer::Token::KEYWORD_DEF
      next_token

      function_name = @token.value
      raise "Invalid token #{@token.type}, expected identifier" unless @token.type == Tokenizer::Token::IDENTIFIER
      next_token

      raise "Invalid token #{@token.value}, expected \"(\"" unless @token.type == Tokenizer::Token::OPENING_PAREN
      next_token

      formal_params = []
      while @token.type == Tokenizer::Token::IDENTIFIER
        formal_params << @token.value
        next_token

        if @token.type == Tokenizer::Token::COMMA
          next_token
        elsif @token.type == Tokenizer::Token::CLOSING_PAREN
          break
        else
          raise "Invalid token #{@token.value}, expected \")\" or \",\"" unless @token.type == Tokenizer::Token::CLOSING_PAREN
        end
      end

      raise "Invalid token #{@token.value}, expected \")\"" unless @token.type == Tokenizer::Token::CLOSING_PAREN
      next_token

      raise "Invalid token #{@token.value}, expected \"{\"" unless @token.type == Tokenizer::Token::OPENING_CURLY
      next_token

      statements = []
      while @token.type != Tokenizer::Token::CLOSING_CURLY
        statements << parse_statement
      end

      raise "Invalid token #{@token.value}, expected \"}\"" unless @token.type == Tokenizer::Token::CLOSING_CURLY
      next_token

      return [function_name, Function.new(@lookup_scopes, formal_params, statements)]
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
      elsif @token.type == Tokenizer::Token::PERIOD
        next_token

        target = expression
        function_name = @token.value
        raise "Invalid token #{@token.type}, expected identifier" unless @token.type == Tokenizer::Token::IDENTIFIER
        next_token
        raise "Invalid token #{@token.value}, expected \"(\"" unless @token.type == Tokenizer::Token::OPENING_PAREN
        next_token

        value_expressions = []
        until @token.type == Tokenizer::Token::CLOSING_PAREN
          value_expressions << parse_expression

          unless @token.type == Tokenizer::Token::CLOSING_PAREN
            raise "Invalid token #{@token.value}, expected \",\"" unless @token.type == Tokenizer::Token::COMMA
            next_token
          end
        end

        raise "Invalid token #{@token.value}, expected \")\"" unless @token.type == Tokenizer::Token::CLOSING_PAREN
        next_token

        expression = Expression.new do
          value = target.evaluate
          @lookup_scopes << value
          result = value.call_method(function_name, value_expressions.map(&:evaluate))
          @lookup_scopes.delete(value)
          result
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
          Types::String.new(value_token.value)
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

