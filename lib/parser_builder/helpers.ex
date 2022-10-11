defmodule ParserBuilder.Helpers do
  @moduledoc false

  alias ParserBuilder.Backstops

  def make_item(rules) do
    {:item, %{}, rules}
  end

  def make_one_of(rules) do
    {:oneOf, %{}, rules}
  end

  def backtrack(backstops, lookup_fun, reason, continuation) do
    case Backstops.backtrack(backstops, reason) do
      {new_backstops, next_fun, accumulated_input} ->
        continuation.(
          new_backstops,
          lookup_fun,
          fn _ -> next_fun.(accumulated_input) end,
          ""
        )

      _ ->
        {:done, {:error, reason}}
    end
  end
end
