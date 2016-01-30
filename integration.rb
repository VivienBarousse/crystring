
def test_program(name, expected_output)
  program = File.expand_path('../' + name, __FILE__)
  actual_output = `bin/crystring #{program}`
  unless actual_output == expected_output
    raise "Program #{name} failed, expected #{expected_output.inspect}, got #{actual_output.inspect}"
  end
end

test_program("examples/hello_world.str", "Hello world!\n")
test_program("examples/variables.str", "Hello world!\n")
test_program("examples/functions.str", "Hello world!\nHello world!\n")

