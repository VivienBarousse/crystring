require 'spec_helper'

shared_examples("a correct program") do
  it "should give the correct output" do
    actual_output = `ruby bin/crystring examples/#{program_name}`
    expect(actual_output).to eq(expected_output)
  end
end

describe "Running programs" do
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
end
