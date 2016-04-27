
module Tokenizer
  #(add 2 (subtract 4 2)) => [{type:'paren', value:'('},{type:'name',value:'add'}, ...]
  def self.tokenize(input)
    current = 0
    tokens = []
    while current < input.size
      char = input[current]
      if char == "("
        tokens << {kind:"paren",value:"("}
        current += 1
        next
      end

      if char == ")"
        tokens << {kind:"paren",value:")"}
        current += 1
        next
      end

      if char == " "
        current += 1
        next
      end

      if char =~ /[0-9]/
        value = ""
        while char =~ /[0-9]/
          value << char
          current+=1
          char = input[current]
        end
        tokens << {kind:"number",value:value}
        next
      end 

      if char =~ /[a-z]/
        value = ""
        while char =~ /[a-z]/
          value << char
          current += 1
          char = input[current]
        end
        tokens << {kind:'name', value:value}
        next
      end

      break
    end

    return tokens
  end
end



# For our parser we're going to take our array of tokens
# and turn it into an AST
#[{type:"paren", value:"("}, ...] => {type:"Program",body:[...]}

class Parser
  attr_accessor :parser_counter,:tokens

  def initialize(tokens)
    @tokens = tokens
    @parser_counter = 0
  end

  def parser
    ast = {kind:"Program", body:[]}
    while parser_counter < tokens.size
      ast[:body] << walk()
    end
    return ast
  end

  def walk
    token = @tokens[@parser_counter]
    if token[:kind] == "number"
      @parser_counter += 1
      return({
        kind:"NumberLiteral",
        value: token[:value]
      })
    end

    if token[:kind] == "paren" && token[:value] == "("
      @parser_counter += 1
      token = @tokens[@parser_counter]
      node = {kind:"CallExpression", name:token[:value], params:[]}
      @parser_counter += 1
      token = @tokens[@parser_counter]

      # And now we want to loop through each token that will be the 'params' of
      # our CallExpression until we encounter a closing parenthesis.
      while token[:kind] != "paren" || (token[:kind] == "paren" && token[:value] != ")")
        node[:params] << walk()
        token = @tokens[@parser_counter]
      end 
      @parser_counter += 1
      return node
    end

    raise ParserError.new("Parser err")
  end

  class ParserError < StandardError; end
end

module Transformer
  def self.transform(ast)
    nast = {kind:"Program",body:[]}

    #the context is a reference *from* the old ast *to* the new ast.
    ast[:context] = nast[:body]

    traverser(ast)

    return nast
  end

  def self.traverser(ast)
    traverse_node(ast, {})
  end

  def self.traverse_array(nodes, parent_node)
    nodes.each do |node|
      traverse_node(node, parent_node)
    end
  end

  def self.visitor(node, parent_node)
    node_kind = node[:kind]
    case node_kind
    when "NumberLiteral"
      parent_node[:context] << {kind:"NumberLiteral", value: node[:value]}
    when "CallExpression"
        expression = {
          kind:"CallExpression",
          callee:{
            kind:"Identifier",
            name:node[:name]
          },
          arguments:[]
        }
        node[:context] = expression[:arguments]
        if parent_node[:kind] != "CallExpression"
          expression_statement  = {kind:"ExpressionStatement", expression:expression}
          parent_node[:context] << expression_statement
        else
          parent_node[:context] << expression
        end
    end
  end

  def self.traverse_node(node, parent_node)
    visitor(node, parent_node)
    case node[:kind]
    when "Program"
      traverse_array(node[:body], node)
    when "CallExpression"
      traverse_array(node[:params], node)
    when "NumberLiteral"
    else
      raise NotRecognizdeNodeError.new("haven't recognized the node")
    end
  end

  class NotRecognizdeNodeError < StandardError; end
end


module CodeGenerator

  #recursively call itself to print each node in
  #the tree into one big string
  def self.generate(node)
    
    case node[:kind]
    when "Program"
      r = []
      node[:body].each do |n|
        r << generate(n)
      end
      return r.join("\n")
    when "ExpressionStatement"
      return generate(node[:expression]) << ";"
    when "CallExpression"
      r = []
      c = generate(node[:callee])
      node[:arguments].each do |n|
        r << generate(n)
      end
      return  "#{c}(#{r.join(", ")})"
    when "Identifier"
      return node[:name]
    when "NumberLiteral"
        return node[:value]
    else
        raise CodeGeneratorError("code_generator err")
    end
  end

  class CodeGeneratorError < StandardError; end
end

module Compiler
  def self.compile(input)
    tokens = Tokenizer.tokenize(input)
    ast  = Parser.new(tokens).parser  
    nast = Transformer.transform(ast)
    out  = CodeGenerator.generate(nast) 
    return out
  end
end


def main
  program = "(add 10 (subtract 10 6))"
  out = Compiler.compile(program)
  puts out
end









