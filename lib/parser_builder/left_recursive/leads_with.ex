defmodule ParserBuilder.LeftRecursive.LeadsWith do
  @moduledoc false

  # TODO make this tail recursive
  def leads_with_consuming_parser?(rule_body)

  def leads_with_consuming_parser?([{tag, _atts, kids} | rest])
      when tag in [
             :optional,
             :atMost,
             :many
           ] do
    leads_with_consuming_parser?(kids) and leads_with_consuming_parser?(rest)
  end

  def leads_with_consuming_parser?([]) do
    false
  end

  def leads_with_consuming_parser?([{:ruleRef, _atts, []} | _rest]) do
    false
  end

  def leads_with_consuming_parser?([{tag, _atts, []} | _rest])
      when tag in [
             :literal,
             :cs_literal,
             :ci_literal,
             :hexLiteral,
             :hexRange
           ] do
    true
  end

  def leads_with_consuming_parser?([{:oneOf, _atts, items} | _rest]) do
    items
    |> Enum.map(fn x -> [x] end)
    |> Enum.map(&leads_with_consuming_parser?/1)
    |> Enum.reduce(true, fn bool, acc -> acc and bool end)
  end

  def leads_with_consuming_parser?([{_tag, _atts, kids} | rest]) do
    leads_with_consuming_parser?(kids ++ rest)
  end
end
