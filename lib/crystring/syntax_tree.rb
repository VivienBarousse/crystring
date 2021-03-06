module Crystring
  class SyntaxTree

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

      def get_code_block
        nil
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
      def initialize(syntax_tree, formal_params, statements)
        @syntax_tree = syntax_tree
        @formal_params = formal_params
        @statements = statements
        @variables = {}
      end

      def invoke(actual_params, code_block)
        unless @formal_params.length == actual_params.length
          raise "Invalid cardinality for function: expected #{@formal_params.length} arguments, got #{actual_params.length}"
        end
        @formal_params.length.times do |i|
          @variables[@formal_params[i]] = actual_params[i]
        end
        @code_block = code_block
        @syntax_tree.with_lookup_scope(self) do
          value = nil
          @statements.each do |s|
            value = s.invoke
          end
          value
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

      def get_code_block
        @code_block
      end
    end

    def initialize
      @variables = {}
      @functions = {}
      @lookup_scopes = [DefaultLookupScope.new]

      @functions["puts"] = Function.new(
        self,
        ["value"],
        [Statement.new { puts get_variable("value") }]
      )
      @functions["print"] = Function.new(
        self,
        ["value"],
        [Statement.new { print get_variable("value") }]
      )
      @functions["gets"] = Function.new(
        self,
        [],
        [Statement.new { Types::String.new(STDIN.readline.gsub(/\n$/, '')) }]
      )
      @functions["yield"] = Function.new(
        self,
        [],
        [Statement.new { v = nil; get_code_block.each { |s| v = s.invoke }; v }]
      )

      Types::String.def_method("+", Function.new(
        self,
        ["a"],
        [Statement.new { Types::String.new(get_variable("self").to_s + get_variable("a").to_s) }]
      ))
      Types::String.def_method("==", Function.new(
        self,
        ["a"],
        [Statement.new { Types::String.new(get_variable("self").to_s == get_variable("a").to_s ? "true" : "false") }]
      ))
      Types::String.def_method("upcase", Function.new(
        self,
        [],
        [Statement.new { Types::String.new(get_variable("self").to_s.upcase) }]
      ))
      Types::String.def_method("downcase", Function.new(
        self,
        [],
        [Statement.new { Types::String.new(get_variable("self").to_s.downcase) }]
      ))
      Types::String.def_method("length", Function.new(
        self,
        [],
        [Statement.new { Types::Counter.new("." * get_variable("self").to_s.length) }]
      ))
      Types::String.def_method("get_char", Function.new(
        self,
        ["idx"],
        [Statement.new { Types::String.new(get_variable("self").to_s[get_variable("idx").to_s.length]) }]
      ))
      Types::String.def_method("tr", Function.new(
        self,
        ["sub", "ptn"],
        [Statement.new { Types::String.new(get_variable("self").to_s.tr(get_variable("sub").to_s, get_variable("ptn").to_s)) }]
      ))
      Types::String.def_method("to_s", Function.new(
        self,
        [],
        [Statement.new { Types::String.new(get_variable("self").to_s) }]
      ))

      set_variable("Counter", Types::Counter)
      set_variable("String", Types::String)
    end

    def lookup_type(type_name)
      type = get_variable(type_name)
      unless type.is_a?(Class) && type <= Types::Base
        raise "Unexpected base type `#{type_name}`, is a variable, not a type."
      end
      type
    end

    def with_lookup_scope(scope)
      @lookup_scopes << scope
      result = yield
      @lookup_scopes.pop
      result
    end

    def set_function(expression_name, statements)
      @functions[expression_name] = statements
    end

    def call_function(expression_name, value_expressions, code_block)
      if @functions.has_key?(expression_name)
        params = value_expressions.map(&:evaluate)
        @functions[expression_name].invoke(params, code_block)
      else
        raise "Unknown function #{expression_name}"
      end
    end

    def variable_exists?(name)
      @lookup_scopes.any? { |s| s.variable_exists?(name) }
    end

    def get_variable(name)
      scope = @lookup_scopes.reverse.detect { |s| s.variable_exists?(name) }
      scope.get_variable(name)
    end

    def set_variable(name, value)
      @functions["gets"] = Function.new(
        self,
        [],
        [Statement.new { Types::String.new(STDIN.readline.gsub(/\n$/, '')) }]
      )
      @functions["yield"] = Function.new(
        self,
        [],
        [Statement.new { v = nil; get_code_block.each { |s| v = s.invoke }; v }]
      )

      Types::String.def_method("+", Function.new(
        self,
        ["a"],
        [Statement.new { Types::String.new(get_variable("self").to_s + get_variable("a").to_s) }]
      ))
      Types::String.def_method("==", Function.new(
        self,
        ["a"],
        [Statement.new { Types::String.new(get_variable("self").to_s == get_variable("a").to_s ? "true" : "false") }]
      ))
      Types::String.def_method("upcase", Function.new(
        self,
        [],
        [Statement.new { Types::String.new(get_variable("self").to_s.upcase) }]
      ))
      Types::String.def_method("downcase", Function.new(
        self,
        [],
        [Statement.new { Types::String.new(get_variable("self").to_s.downcase) }]
      ))
      Types::String.def_method("length", Function.new(
        self,
        [],
        [Statement.new { Types::Counter.new("." * get_variable("self").to_s.length) }]
      ))
      Types::String.def_method("get_char", Function.new(
        self,
        ["idx"],
        [Statement.new { Types::String.new(get_variable("self").to_s[get_variable("idx").to_s.length]) }]
      ))
      Types::String.def_method("tr", Function.new(
        self,
        ["sub", "ptn"],
        [Statement.new { Types::String.new(get_variable("self").to_s.tr(get_variable("sub").to_s, get_variable("ptn").to_s)) }]
      ))
      Types::String.def_method("to_s", Function.new(
        self,
        [],
        [Statement.new { Types::String.new(get_variable("self").to_s) }]
      ))

      set_variable("Counter", Types::Counter)
      set_variable("String", Types::String)
    end

    def lookup_type(type_name)
      type = get_variable(type_name)
      unless type.is_a?(Class) && type <= Types::Base
        raise "Unexpected base type `#{type_name}`, is a variable, not a type."
      end
      type
    end

    def with_lookup_scope(scope)
      @lookup_scopes << scope
      result = yield
      @lookup_scopes.pop
      result
    end

    def set_function(expression_name, statements)
      @functions[expression_name] = statements
    end

    def call_function(expression_name, value_expressions, code_block)
      if @functions.has_key?(expression_name)
        params = value_expressions.map(&:evaluate)
        @functions[expression_name].invoke(params, code_block)
      else
        raise "Unknown function #{expression_name}"
      end
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

    def get_code_block
      scope = @lookup_scopes.reverse.detect { |s| s.get_code_block }
      scope.get_code_block
    end
  end
end
