module Crystring
  class Tokenizer
    class Token
      STRING_LITERAL = 1
      OPENING_PAREN = 2
      CLOSING_PAREN = 3
      SEMICOLON = 4
      IDENTIFIER = 5
      ASSIGN = 6

      attr_reader :type
      attr_reader :value

      def initialize(type, value)
        @type = type
        @value = value
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

      if @char && @char >= 'a' && @char <= 'z'
        literal = ""
        while @char >= 'a' && @char <= 'z'
          literal << @char
          next_char
        end
        return Token.new(Token::IDENTIFIER, literal)
      elsif @char == '('
        next_char
        return Token.new(Token::OPENING_PAREN, '(')
      elsif @char == ')'
        next_char
        return Token.new(Token::CLOSING_PAREN, ')')
      elsif @char == ';'
        next_char
        return Token.new(Token::SEMICOLON, ';')
      elsif @char == "="
        next_char
        return Token.new(Token::ASSIGN, '=')
      elsif @char == '"'
        str = ""
        next_char
        while @char != '"'
          str << @char
          next_char
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

