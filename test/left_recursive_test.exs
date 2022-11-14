defmodule ParserBuilder.LeftRecursiveTest do
  use ExUnit.Case

  alias ParserBuilder.LeftRecursiveTestParser

  alias ParserBuilder.LeftRecursive.{
    LeadsWith,
    RuleRelations
  }

  defp rule_body_from_rule_name(rule_name) do
    LeftRecursiveTestParser.get_rules()
    |> Map.get(rule_name, [])
  end

  test "lr1" do
    rb = rule_body_from_rule_name("lr1")
    assert false == LeadsWith.leads_with_consuming_parser?(rb)
  end

  test "lr2" do
    rb = rule_body_from_rule_name("lr2")
    assert true == LeadsWith.leads_with_consuming_parser?(rb)
  end

  test "lr3" do
    rb = rule_body_from_rule_name("lr3")
    assert false == LeadsWith.leads_with_consuming_parser?(rb)
  end

  test "lr4" do
    rb = rule_body_from_rule_name("lr4")
    assert false == LeadsWith.leads_with_consuming_parser?(rb)
  end

  test "lr5" do
    rb = rule_body_from_rule_name("lr5")
    assert true == LeadsWith.leads_with_consuming_parser?(rb)
  end

  test "lr6" do
    rb = rule_body_from_rule_name("lr6")
    assert false == LeadsWith.leads_with_consuming_parser?(rb)
  end

  test "lr7" do
    rb = rule_body_from_rule_name("lr7")
    assert false == LeadsWith.leads_with_consuming_parser?(rb)
  end

  test "lr8" do
    rb = rule_body_from_rule_name("lr8")
    assert true == LeadsWith.leads_with_consuming_parser?(rb)
  end

  test "lr9" do
    rb = rule_body_from_rule_name("lr9")
    assert false == LeadsWith.leads_with_consuming_parser?(rb)
  end

  test "rel1" do
    rb = rule_body_from_rule_name("rel1")
    rels = RuleRelations.collect_relations(rb)
    assert true == MapSet.member?(rels, "rel1")
  end

  test "rel2" do
    rb = rule_body_from_rule_name("rel2")
    rels = RuleRelations.collect_relations(rb)
    assert true == MapSet.member?(rels, "rel1")
    assert true == MapSet.member?(rels, "rel2")
  end
end
