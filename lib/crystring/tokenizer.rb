module Crystring
  class Tokenizer
    def initialize(input)
      @input = input
      next_char
    end

    def next_token
      while @char <= ' '
        next_char
      end

      if @char >= 'a' && @char <= 'z'
        literal = ""
        while @char >= 'a' && @char <= 'z'
          literal << @char
          next_char
        end
        return literal
      elsif @char == '('
        next_char
        return '('
      elsif @char == ')'
        next_char
        return ')'
      elsif @char == '"'
        str = ""
        next_char
        while @char != '"'
          str << @char
          next_char
        end
        next_char
        return "#{str}"
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

