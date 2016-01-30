module Crystring
  class Parser
    def initialize(tokenizer)
      @tokenizer = tokenizer
      next_token
    end

    def parse
      while @token
        parse_statement
      end
    end

    # identifier, "(", value, ")"
    def parse_statement
      method_name = @token
      next_token
      raise "Invalid token #{@token}, expected \"(\"" unless @token == "("
      next_token
      param = @token
      next_token
      raise "Invalid token #{@token}, expected \")\"" unless @token == ")"
      next_token

      if method_name == "puts"
        puts param
      else
        raise "Unknown method #{method_name}"
      end
    end

    private

    def next_token
      @token = @tokenizer.next_token
    end
  end
end

