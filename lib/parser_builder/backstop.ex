defmodule ParserBuilder.Backstop do
  @moduledoc false

  alias ParserBuilder.Helpers
  require Logger

  def new() do
    []
  end

  def add_backstop(backstops, fun, input_string) do
    Logger.debug("adding backstop with: \"#{input_string}\"")
    [{fun, input_string} | backstops]
  end

  def backtrack([]) do
    Helpers.done_error()
  end

  def backtrack([{[alternative | alternatives], input_string} | backstops]) do
    new_backstops = [{alternatives, input_string} | backstops]
    {new_backstops, alternative, input_string}
  end

  def backtrack([{[], input_string} | backstops]) do
    backtrack(merge_input_strings(backstops, input_string))
  end

  defp merge_input_strings([{alternatives, input_string} | backstops], following_input_string) do
    [{alternatives, input_string <> following_input_string} | backstops]
  end

  defp merge_input_strings([] = backstops, _input_string) do
    backstops
  end
end
