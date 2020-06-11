class Tokenizer
  TOKEN_TYPES = [
    [:def, /\bdef\b/],
    [:end, /\bend\b/],
    [:indentifier, /\b[a-zA-Z]\b/],
    [:integer, /\b[0-9]\b/],
    [:oparen, /\(/],
    [:cparen, /\)/]
  ]

  def initialize(code)
    @code = code
  end

  def tokens
    tokens = []
    until @code.empty?
      tokens.push(tokenize_one)
      @code = @code.strip
    end

    tokens
  end

  private

  def tokenize_one
    TOKEN_TYPES.each do |type, re|
      re = /\A(#{re})/

      if @code =~ re
        value = $1
        @code = @code[value.length...-1]

        return Token.new(type, value)
      end
    end

    raise RuntimeError.new("Palabra no reconocida") 
  end
end

Token = Struct.new(:type, :value)

# def f(x) x end


# Tokenizer -> Parser -> Code generator
# def f(x)
#   x
# end

puts Tokenizer.new(File.read('./test.src')).tokens
