# tokenizer -> parser -> code generator

class Tokenizer
  TOKEN_TYPES = [
    [:def, /\bdef\b/],
    [:end, /\bend\b/],
    [:indentifier, /\b[a-zA-Z]+\b/],
    [:integer, /\b[0-9]\b/],
    [:oparen, /\(/],
    [:cparen, /\)/],
    [:comma, /\,/],
  ]

  def initialize(code)
    @code = code
  end

  def tokenize
    tokens = []
    until @code.empty?
      tokens << tokenize_one
      @code = @code.strip
    end

    tokens
  end

  def tokenize_one
    TOKEN_TYPES.each do |type, re|
      re = /\A(#{re})/
      if @code =~ re
        value = $1
        @code = @code[value.length..-1]

        return Token.new(type, value)
      end
    end

    raise RuntimeError.new("Cant match token #{@code.inspect}")
  end
end

Token = Struct.new(:type, :value)

class Parser
  def initialize(tokens)
    @tokens = tokens
  end

  def parse
    parser_def
  end

  def parser_def
    consume(:def)
    name     = consume(:indentifier).value
    arg_list = parse_arguments
    body     = parse_expresion
    consume(:end)

    DefNode.new(name, arg_list, body)
  end

  def parse_arguments
    arg_list = []
    consume(:oparen)
    if peek(:indentifier)
      arg_list << consume(:indentifier).value
      while peek(:comma)
        consume(:comma)
        arg_list << consume(:indentifier).value
      end
    end
    consume(:cparen)

    arg_list
  end

  def parse_expresion
    if peek(:integer)
      parse_integer
    elsif peek(:indentifier) && peek(:oparen, 1)
      parse_call
    else
      parse_ref_var
    end
  end

  def parse_ref_var
    RefVarNode.new(consume(:indentifier).value)
  end

  def parse_integer
    IntegerNode.new(consume(:integer).value.to_i)
  end

  def parse_call
    name = consume(:indentifier).value
    express_args = parse_express_args
    CallNode.new(name, express_args)
  end

  def parse_express_args
    express_args = []
    consume(:oparen)

    if !peek(:cparen)
      express_args << parse_expresion
      while peek(:comma)
        consume(:comma)
        express_args << parse_expresion
      end
    end

    consume(:cparen)
    express_args
  end

  def consume(expected_token)
    current_token = @tokens.shift
    if current_token.type == expected_token
      current_token
    else
      raise RuntimeError.new("Expected token #{expected_token} but got token #{current_token.inspect}")
    end
  end

  def peek(expected_type, offset=0)
    @tokens.fetch(offset).type == expected_type
  end
end

DefNode = Struct.new(:name, :args, :body)
IntegerNode = Struct.new(:value)
CallNode = Struct.new(:name, :express_args)
RefVarNode = Struct.new(:value)


class Generator
  def generate(node)
    case node
    when DefNode
      "function %s(%s) { return %s };" % [
        node.name,
        node.args.join(','),
        generate(node.body)
      ]
    when CallNode
      "%s(%s)" % [
        node.name,
        node.express_args.map{|ar| generate(ar) }.join(',')
      ]
    when RefVarNode
      node.value
    when IntegerNode
      node.value
    else
      raise RuntimeError.new("Unexpected node type #{node.inspect}")
    end
  end
end


tokens = Tokenizer.new(File.read("test.src")).tokenize
# puts tokens

tree = Parser.new(tokens).parse
# puts tree

puts Generator.new.generate(tree)
s Tokenizer.new(File.read('./test.src')).tokens
