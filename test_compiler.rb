
require 'minitest/autorun'
require_relative 'compiler'

class TestMiniCompiler < Minitest::Test
  def setup
    @test_input = "(add 2 (subtract 4 2))"
    @test_out = "add(2, subtract(4, 2));"  
    @test_ast = {:kind=>"Program", 
      :body=>[
        {:kind=>"CallExpression", 
          :name=>"add", 
          :params=>[
            {:kind=>"NumberLiteral", :value=>"2"}, 
            {:kind=>"CallExpression", :name=>"subtract",
             :params=>[
              {:kind=>"NumberLiteral", :value=>"4"}, 
              {:kind=>"NumberLiteral", :value=>"2"}]
            } ]
          }]
     }
     @test_tokens = [
      {:kind=>"paren", :value=>"("},
      {:kind=>"name", :value=>"add"},
      {:kind=>"number", :value=>"2"},
      {:kind=>"paren", :value=>"("},
      {:kind=>"name", :value=>"subtract"},
      {:kind=>"number", :value=>"4"},
      {:kind=>"number", :value=>"2"},
      {:kind=>"paren", :value=>")"},
      {:kind=>"paren", :value=>")"}]

     @test_nast = {:kind=>"Program", 
      :body=>[
       {:kind=>"ExpressionStatement", 
         :expression=>{:kind=>"CallExpression", 
          :callee=>{:kind=>"Identifier", :name=>"add"}, 
         :arguments=>[
           {:kind=>"NumberLiteral", :value=>"2"}, 
           {:kind=>"CallExpression", 
             :callee=>{:kind=>"Identifier", :name=>"subtract"}, 
             :arguments=>[
               {:kind=>"NumberLiteral", :value=>"4"},
               {:kind=>"NumberLiteral", :value=>"2"}
               ]}
        ]}}]}  

  end
end

class TestTokinizer < TestMiniCompiler
  def test_tokinize
    tokens = Tokenizer.tokenize(@test_input)
    assert_equal(tokens ,@test_tokens)
  end
end


class TestParser < TestMiniCompiler
  def test_parser
    ast  = Parser.new(@test_tokens).parser 
    assert_equal(ast, @test_ast)
  end
end

class TestTransformer < TestMiniCompiler
  def test_transform
    nast = Transformer.transform(@test_ast)
    assert_equal(nast, @test_nast)
  end
end

class TestCodeGenerator < TestMiniCompiler
  def test_generate
    out = CodeGenerator.generate(@test_nast)
    assert_equal @test_out, out
  end
end

class TestCompiler < TestMiniCompiler
  def test_compile
    test_program =  "(add 10 (subtract 10 6))"
    expected_out = "add(10, subtract(10, 6));"
    out = Compiler.compile(test_program)
    assert_equal(expected_out, out)
  end
end


