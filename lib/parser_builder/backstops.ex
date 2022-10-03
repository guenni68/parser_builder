defmodule ParserBuilder.Backstops do
  @moduledoc false

  @input :input
  @alternatives :alternatives

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
    [{@alternatives, alternatives} | backstops]
  end

  def backtrack([], reason) do
    reason
  end

  def backtrack([{@input, newer_input}, {@input, older_input} | rest], reason) do
    backtrack([{@input, older_input <> newer_input} | rest], reason)
  end

  def backtrack([{@input, _input} = input, {@alternatives, []} | rest], reason) do
    backtrack([input | rest], reason)
  end

  def backtrack(
        [
          {@input, next_input} = curr_input,
          {@alternatives, [next_alternative | remaining_alternatives]} | rest
        ],
        _reason
      ) do
    new_backstops = [curr_input, {@alternatives, remaining_alternatives} | rest]
    {new_backstops, next_alternative, next_input}
  end

  def backtrack([{@alternatives, []} | rest], reason) do
    backtrack(rest, reason)
  end

  def backtrack([{@alternatives, [next_alternative | remaining_alternatives]} | rest], _reason) do
    new_backstops = add_new_backstops(rest, remaining_alternatives)
    {new_backstops, next_alternative, ""}
  end
end
