module Crystring
  class Tokenizer

    class UnfinishedLiteral < StandardError
    end

    class Token
      STRING_LITERAL = 1
      OPENING_PAREN = 2
      CLOSING_PAREN = 3
      SEMICOLON = 4
      IDENTIFIER = 5
      ASSIGN = 6
      KEYWORD_DEF = 7
      OPENING_CURLY = 8
      CLOSING_CURLY = 9
      EQUALS = 10
      NOT_EQUALS = 11
      KEYWORD_IF = 12
      KEYWORD_ELSE = 13
      COMMA = 14
      PERIOD = 15
      KEYWORD_CLASS = 16
      KEYWORD_WHILE = 17

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
        while @char && (@char >= 'a' && @char <= 'z' || @char >= 'A' && @char <= 'Z')
          identifier << @char
          next_char
        end

        if identifier == "def"
          return Token.new(Token::KEYWORD_DEF, identifier)
        elsif identifier == "if"
          return Token.new(Token::KEYWORD_IF, identifier)
        elsif identifier == "else"
          return Token.new(Token::KEYWORD_ELSE, identifier)
        elsif identifier == "class"
          return Token.new(Token::KEYWORD_CLASS, identifier)
        elsif identifier == "while"
          return Token.new(Token::KEYWORD_WHILE, identifier)
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

