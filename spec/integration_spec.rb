require 'spec_helper'
require 'open3'

shared_examples("a correct program") do
  it "should give the correct output" do
    begin
      input, output, error, pid = Open3.popen3("ruby bin/crystring examples/#{program_name}")
      if given_input
        input << given_input
      end
      Timeout.timeout(timeout) do
        actual_output = output.read
        actual_error = error.read
        expect(actual_error).to eq("")
        expect(actual_output).to eq(expected_output)
      end
    rescue Timeout::Error => e
      raise "Program took more than maximum #{timeout} seconds to execute"
    end
  end
end

describe "Running programs" do
  let(:given_input) { nil }
  let(:timeout) { 5 }

  describe "Hello world" do
    let(:program_name) { "hello_world.str" }
    let(:expected_output) { "Hello world!\n" }
    it_should_behave_like "a correct program"
  end

  describe "Variables" do
    let(:program_name) { "variables.str" }
    let(:expected_output) { "Hello world!\n" }
    it_should_behave_like "a correct program"
  end

  describe "Function calls" do
    let(:program_name) { "functions.str" }
    let(:expected_output) { "Hello world!\nHello world!\n" }
    it_should_behave_like "a correct program"
  end

  describe "Boolean values" do
    let(:program_name) { "booleans.str" }
    let(:expected_output) { "true\nfalse\ntrue\nfalse\n" }
    it_should_behave_like "a correct program"
  end

  describe "If statements" do
    let(:program_name) { "if_statements.str" }
    let(:expected_output) { "Same value!\n" }
    it_should_behave_like "a correct program"
  end

  describe "If and else statements" do
    let(:program_name) { "else_statements.str" }
    let(:expected_output) { "Same value!\nSame value!\n" }
    it_should_behave_like "a correct program"
  end

  describe "Elsif statements" do
    let(:program_name) { "elsif_statements.str" }
    let(:expected_output) { "0\n1\n2\n3\n4\n" }
    it_should_behave_like "a correct program"
  end

  describe "Functions with arguments" do
    let(:program_name) { "functions_arguments.str" }
    let(:expected_output) { "Yes, hello\nNo, not hello\n" }
    it_should_behave_like "a correct program"
  end

  describe "Functions local scopes" do
    let(:program_name) { "local_scopes.str" }
    let(:expected_output) { "Hi\nHi\nHo\nHi\n" }
    it_should_behave_like "a correct program"
  end

  describe "Functions local scopes" do
    let(:program_name) { "functions_multiple_arguments.str" }
    let(:expected_output) { "Yes, hello\nNo, not hello\n" }
    it_should_behave_like "a correct program"
  end

  describe "Functions local scopes" do
    let(:program_name) { "method_call.str" }
    let(:expected_output) { "Hello world\n" }
    it_should_behave_like "a correct program"
  end

  describe "Methods calls as expressions" do
    let(:program_name) { "method_call_as_expression.str" }
    let(:expected_output) { "HELLO WORLD\n" }
    it_should_behave_like "a correct program"
  end

  describe "Chained method calls" do
    let(:program_name) { "chained_method_calls.str" }
    let(:expected_output) { "HELLO WORLD\nhello world\n" }
    it_should_behave_like "a correct program"
  end

  describe "While statements" do
    let(:program_name) { "while_statements.str" }
    let(:expected_output) { "0\n1\n2\n3\n4\n" }
    it_should_behave_like "a correct program"
  end

  describe "Calling methods on literals" do
    let(:program_name) { "method_call_on_literal.str" }
    let(:expected_output) { "HELLO WORLD\n" }
    it_should_behave_like "a correct program"
  end

  describe "Assignment as expressions" do
    let(:program_name) { "assignment_as_expressions.str" }
    let(:expected_output) { "Hello world\nHello world\n" }
    it_should_behave_like "a correct program"
  end

  describe "Function calls as expressions" do
    let(:program_name) { "function_call_as_expressions.str" }
    let(:expected_output) { "HELLO WORLD\n" }
    it_should_behave_like "a correct program"
  end

  describe "Integer as a type" do
    let(:program_name) { "integer_type.str" }
    let(:expected_output) { "12\n" }
    it_should_behave_like "a correct program"
  end

  describe "Integer addition" do
    let(:program_name) { "integer_addition.str" }
    let(:expected_output) { "18\n" }
    it_should_behave_like "a correct program"
  end

  describe "Read from stdin (gets)" do
    let(:program_name) { "read_from_stdin.str" }
    let(:given_input) { "first line\nsecond line\n" }
    let(:expected_output) { "second line\nfirst line\n" }
    it_should_behave_like "a correct program"
  end

  describe "Custom types" do
    let(:program_name) { "custom_types.str" }
    let(:expected_output) { "HELLO WORLD\n" }
    it_should_behave_like "a correct program"
  end

  describe "Partial class declaration" do
    let(:program_name) { "partial_classes.str" }
    let(:expected_output) { "HELLO\nWORLD\n" }
    it_should_behave_like "a correct program"
  end

  describe "Method inheritance" do
    let(:program_name) { "method_inheritance.str" }
    let(:expected_output) { "HELLO WORLD!\nHELLO WORLD!\nHELLO!\n" }
    it_should_behave_like "a correct program"
  end

  describe "Class extending another" do
    let(:program_name) { "class_extends.str" }
    let(:expected_output) { "hello\n" }
    it_should_behave_like "a correct program"
  end
end

