defmodule ParserBuilder.LeftRecursive.RuleRelations do
  @moduledoc false

  def collect_relations(relations \\ MapSet.new(), rule_body)

  def collect_relations(relations, []) do
    relations
  end

  def collect_relations(relations, [{:ruleRef, %{uri: uri}, []} | rest]) do
    collect_relations(MapSet.put(relations, uri), rest)
  end

  def collect_relations(relations, [{_tag, _atts, kids} | rest]) do
    collect_relations(relations, kids ++ rest)
  end
end
