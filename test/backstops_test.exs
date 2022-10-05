defmodule ParserBuilder.BackstopsTest do
  use ExUnit.Case

  alias ParserBuilder.Backstops

  test "empty backstops" do
    backstops = Backstops.new()
    reason = "some failure"

    assert ^reason = Backstops.backtrack(backstops, reason)
  end

  test "no change when adding input on empty backstops" do
    backstops = Backstops.new()

    assert backstops == Backstops.add_new_input(backstops, "some input")
  end

  test "consecutive input gets concatenated" do
    input1 = "first input"
    input2 = "second input"
    concatenated_input = input1 <> input2

    backstops =
      Backstops.new()
      |> Backstops.add_new_backstops([fn x -> x end])
      |> Backstops.add_new_input(input1)
      |> Backstops.add_new_input(input2)

    assert {_new_backstops, next_fun, new_input} = Backstops.backtrack(backstops, "no reason")

    assert ^concatenated_input = next_fun.(new_input)
    #    assert ^concatenated_input = next_fun.("disregards any input")
  end

  test "adding empty input changes nothing" do
    backstops =
      Backstops.new()
      |> Backstops.add_new_backstops([fn x -> x end])

    assert ^backstops = Backstops.add_new_input(backstops, "")
    assert backstops != Backstops.add_new_input(backstops, "non empty")
  end

  test "buildup and playback" do
    input1 = "Erster Input"
    input2 = "Zweiter Input"
    input3 = "Dritter Input"

    backstops =
      Backstops.new()
      |> Backstops.add_new_input(input1)
      |> Backstops.add_new_backstops(make_alternatives(1..3, input1))
      |> Backstops.add_new_input(input2)
      |> Backstops.add_new_backstops(make_alternatives(4..6, input2))
      |> Backstops.add_new_input(input3)

    assert {backstops, next_fun, in1} = Backstops.backtrack(backstops, :reason)
    assert {4, input2 <> input3} == next_fun.(in1)
    assert {backstops, next_fun, in2} = Backstops.backtrack(backstops, :reason)
    assert {5, input2 <> input3} == next_fun.(in2)
    assert {backstops, next_fun, in3} = Backstops.backtrack(backstops, :reason)
    assert {6, input2 <> input3} == next_fun.(in3)
    assert {backstops, next_fun, in4} = Backstops.backtrack(backstops, :reason)
    assert {1, input1 <> input2 <> input3} == next_fun.(in4)
    assert {backstops, next_fun, in5} = Backstops.backtrack(backstops, :reason)
    assert {2, input1 <> input2 <> input3} == next_fun.(in5)
    assert {backstops, next_fun, in6} = Backstops.backtrack(backstops, :reason)
    assert {3, input1 <> input2 <> input3} == next_fun.(in6)
    assert :reason = Backstops.backtrack(backstops, :reason)
  end

  defp make_alternatives(enum, input) do
    enum
    |> Enum.map(fn number ->
      fn new_input -> {number, input <> new_input} end
    end)
  end
end
