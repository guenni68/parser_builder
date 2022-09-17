defmodule ParserBuilder.Helpers do
  @moduledoc false

  def make_item(rules) do
    {:item, %{}, rules}
  end

  def make_one_of(rules) do
    {:oneOf, %{}, rules}
  end
end
