module Crystring
  class Tokenizer

    class UnfinishedLiteral < StandardError
    end

    class Token
      STRING_LITERAL = :string_literal
      OPENING_PAREN = :opening_paren
      CLOSING_PAREN = :closing_paren
      OPENING_CURLY = :opening_curly
      CLOSING_CURLY = :closing_curly
      SEMICOLON = :semicolon
      IDENTIFIER = :identifier
      ASSIGN = :assign
      EQUALS = :equals
      NOT_EQUALS = :not_equals
      LOWER_THAN = :lower_than
      GREATER_THAN = :greater_than
      COMMA = :comma
      PERIOD = :period
      PLUS = :plus
      MINUS = :minus
      TIMES = :times
      DIVIDES = :divides
      MODULUS = :modulus
      KEYWORD_CLASS = :keyword_class
      KEYWORD_DEF = :keyword_def
      KEYWORD_ELSE = :keyword_else
      KEYWORD_ELSIF = :keyword_elsif
      KEYWORD_EXTENDS = :keyword_extends
      KEYWORD_IF = :keyword_if
      KEYWORD_REQUIRE = :keyword_require
      KEYWORD_WHILE = :keyword_while

      attr_reader :type
      attr_reader :value

      def initialize(type, value)
        @type = type
        @value = value
      end

      def ==(other)
        other.type == self.type &&
          other.value == self.value
      end
    end

    def initialize(input)
      @input = input
      next_char
    end

    def next_token
      while @char && @char <= ' '
        next_char
      end

      if @char && (@char >= 'a' && @char <= 'z' || @char >= 'A' && @char <= 'Z')
        identifier = ""
        while @char && ((@char >= 'a' && @char <= 'z' || @char >= 'A' && @char <= 'Z') || @char == '_')
          identifier << @char
          next_char
        end

        if identifier == "def"
          return Token.new(Token::KEYWORD_DEF, identifier)
        elsif identifier == "if"
          return Token.new(Token::KEYWORD_IF, identifier)
        elsif identifier == "elsif"
          return Token.new(Token::KEYWORD_ELSIF, identifier)
        elsif identifier == "else"
          return Token.new(Token::KEYWORD_ELSE, identifier)
        elsif identifier == "class"
          return Token.new(Token::KEYWORD_CLASS, identifier)
        elsif identifier == "extends"
          return Token.new(Token::KEYWORD_EXTENDS, identifier)
        elsif identifier == "while"
          return Token.new(Token::KEYWORD_WHILE, identifier)
        elsif identifier == "require"
          return Token.new(Token::KEYWORD_REQUIRE, identifier)
        end

        return Token.new(Token::IDENTIFIER, identifier)
      elsif @char == '('
        next_char
        return Token.new(Token::OPENING_PAREN, '(')
      elsif @char == ')'
        next_char
        return Token.new(Token::CLOSING_PAREN, ')')
      elsif @char == '{'
        next_char
        return Token.new(Token::OPENING_CURLY, '{')
      elsif @char == '}'
        next_char
        return Token.new(Token::CLOSING_CURLY, '}')
      elsif @char == ';'
        next_char
        return Token.new(Token::SEMICOLON, ';')
      elsif @char == ','
        next_char
        return Token.new(Token::COMMA, ',')
      elsif @char == '.'
        next_char
        return Token.new(Token::PERIOD, '.')
      elsif @char == '+'
        next_char
        return Token.new(Token::PLUS, '+')
      elsif @char == '-'
        next_char
        return Token.new(Token::MINUS, '-')
      elsif @char == '*'
        next_char
        return Token.new(Token::TIMES, '*')
      elsif @char == '/'
        next_char
        return Token.new(Token::DIVIDES, '/')
      elsif @char == '%'
        next_char
        return Token.new(Token::MODULUS, '%')
      elsif @char == "="
        next_char
        if @char == "="
          next_char
          return Token.new(Token::EQUALS, '==')
        end
        return Token.new(Token::ASSIGN, '=')
      elsif @char == '!'
        next_char
        if @char == '='
          next_char
          return Token.new(Token::NOT_EQUALS, '!=')
        end
        raise "Invalid character `!`"
      elsif @char == '<'
        next_char
        return Token.new(Token::LOWER_THAN, '<')
      elsif @char == '>'
        next_char
        return Token.new(Token::GREATER_THAN, '>')
      elsif @char == '"'
        str = ""
        next_char
        while @char && @char != '"'
          str << @char
          next_char
        end
        unless @char == '"'
          raise UnfinishedLiteral.new
        end
        next_char
        return Token.new(Token::STRING_LITERAL, str)
      elsif @char.nil?
        return
      else
        raise "Unexpected character `#{@char}`"
      end
    end

    private

    def next_char
      @char = @input.readchar
    rescue EOFError
      @char = nil
    end
  end
end

