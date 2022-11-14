defmodule ParserBuilder.LeftRecursive do
  @moduledoc false

  alias ParserBuilder.LeftRecursive.{
    LeadsWith,
    RuleRelations
  }

  def left_recursive_rules(rules) do
    leading =
      rules
      |> rules_with_leading_consuming_parsers()

    relations =
      rules
      |> rule_relations()
      |> Enum.to_list()

    find_left_recursive_rules(relations, leading)
  end

  defp rules_with_leading_consuming_parsers(rules) do
    rules
    |> Enum.flat_map(fn {name, body} ->
      if LeadsWith.leads_with_consuming_parser?(body) do
        [name]
      else
        []
      end
    end)
    |> MapSet.new()
  end

  defp rule_relations(rules) do
    rules
    |> Enum.map(fn {name, body} ->
      {name, RuleRelations.collect_relations(body)}
    end)
    |> Enum.into(%{})
  end

  defp find_left_recursive_rules(relations, leading) do
    case iterate(relations, leading) do
      {^relations, ^leading} ->
        relations
        |> Enum.into(%{})

      {r, l} ->
        find_left_recursive_rules(r, l)
    end
  end

  defp iterate(remaining \\ [], relations, leading)

  defp iterate(remaining, [], leading) do
    {Enum.reverse(remaining), leading}
  end

  defp iterate(remaining, [{rule, refs} | rest], leading) do
    new_refs = MapSet.difference(refs, leading)

    if Enum.empty?(new_refs) do
      new_leading = MapSet.put(leading, rule)
      iterate(remaining, rest, new_leading)
    else
      iterate([{rule, new_refs} | remaining], rest, leading)
    end
  end
end
