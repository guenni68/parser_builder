defmodule ParserBuilder.Backstops do
  @moduledoc false

  @input :input
  @alternative :alternative

  def new() do
    []
  end

  def add_new_input([] = backstops, _new_input) do
    backstops
  end

  def add_new_input(backstops, "") do
    backstops
  end

  def add_new_input([{@input, input_string} | rest], new_input_string) do
    [{@input, input_string <> new_input_string} | rest]
  end

  def add_new_input(backstops, new_input_string) do
    [{@input, new_input_string} | backstops]
  end

  def add_new_backstops(backstops, alternatives) do
    new_alternatives =
      alternatives
      |> Enum.map(fn alternative -> {@alternative, alternative} end)

    new_alternatives ++ backstops
  end

  def backtrack([], reason) do
    reason
  end

  def backtrack([{@input, input}, {@alternative, alternative} | rest], _reason) do
    new_backstops =
      rest
      |> add_new_input(input)

    {new_backstops, alternative, input}
  end

  def backtrack([{@alternative, alternative} | rest], _reason) do
    {rest, alternative, ""}
  end
end
