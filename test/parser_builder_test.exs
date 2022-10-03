defmodule ParserBuilderTest do
  use ExUnit.Case
  doctest ParserBuilder

  defp parse_string(rule, string) do
    ParserBuilderModule.parse_string(rule, string)
  end

  defp from_rule(rule_name) do
    fn input -> parse_string(rule_name, input) end
  end

  test "simple cs literal" do
    result = parse_string("cs_string", "strings and more")
    assert {:done, {:ok, ["strings"], " and more"}} = result
  end

  test "two strings" do
    result = parse_string("twoStrings", "meyou")
    assert {:done, {:ok, ["me", "you"], ""}} = result
  end

  test "ci string" do
    result = parse_string("caseInsensitive", "mEyOu")
    assert {:done, {:ok, ["mE", "yOu"], ""}} = result
  end

  test "ignore1" do
    result = parse_string("ignore1", "doignorethis")
    assert {:done, {:ok, ["do", "this"], ""}} = result
  end

  test "tagged1" do
    result = parse_string("tagged1", "thisistagged")
    assert {:done, {:ok, ["this", "is", {:tag1, ["tagged"]}], ""}} = result
  end

  test "replace1" do
    result = parse_string("replace1", "youshouldreplacethis")
    assert {:done, {:ok, ["you", "should", "replace", "that"], ""}} = result
  end

  test "continuation" do
    result = parse_string("cs_string", "string")
    assert {:continue, continuation} = result
    assert {:done, {:ok, ["strings"], ""}} = continuation.("s")
  end

  test "error1" do
    result = parse_string("cs_string", "something else")
    assert {:done, {:error, _reason}} = result
  end

  test "ruleRef1" do
    result = parse_string("ruleRef1", "strings and more")
    assert {:done, {:ok, ["strings"], " and more"}} = result
  end

  test "choice1" do
    fun = from_rule("choice1")

    assert {:done, {:ok, ["me", "and", "you"], ""}} = fun.("meandyou")
    assert {:done, {:ok, ["me", "or", "you"], ""}} = fun.("meoryou")
  end

  test "choice2" do
    assert {:continue, continuation} = parse_string("choice2", "meand")

    assert {:done, {:ok, ["me", "and", "you", "or", "us"], ""}} = continuation.("youorus")
    assert {:done, {:ok, ["me", "and", "him", "or", "us"], ""}} = continuation.("himorus")
    assert {:done, {:ok, ["me", "and", "you", "or", "them"], ""}} = continuation.("youorthem")
    assert {:done, {:ok, ["me", "and", "him", "or", "them"], ""}} = continuation.("himorthem")
  end

  test "many1" do
    assert {:done, {:ok, [], "you"}} = parse_string("many1", "you")

    assert {:done, {:ok, ["me", "me"], "you"}} = parse_string("many1", "memeyou")
  end

  test "manyOne1" do
    assert {:done, {:error, _reason}} = parse_string("manyOne1", "you")
    assert {:done, {:ok, ["me", "me"], "you"}} = parse_string("manyOne1", "memeyou")
  end

  test "literal1" do
    assert {:done, {:ok, ["dummY"], "s"}} = parse_string("literal1", "dummYs")
  end

  test "optional1" do
    assert {:done, {:ok, ["me", "us"], ""}} = parse_string("optional1", "meus")
    assert {:done, {:ok, ["me", "you", "us"], ""}} = parse_string("optional1", "meyouus")
  end

  test "atLeast1" do
    parse = from_rule("atLeast1")

    assert {:done, {:ok, ["me", "me", "you"], ""}} = parse.("memeyou")
    assert {:done, {:error, _reason}} = parse.("meyou")
  end

  test "exactly1" do
    parse = from_rule("exactly1")

    assert {:done, {:ok, ["me", "me", "you"], ""}} = parse.("memeyou")
    assert {:done, {:error, _reason}} = parse.("mememeyou")
    assert {:done, {:error, _reason}} = parse.("meyou")
  end

  test "atMost1" do
    parse = from_rule("atMost1")

    assert {:done, {:ok, ["you"], ""}} = parse.("you")
    assert {:done, {:ok, ["me", "you"], ""}} = parse.("meyou")
    assert {:done, {:ok, ["me", "you"], ""}} = parse.("meyou")
    assert {:done, {:ok, ["me", "me", "you"], ""}} = parse.("memeyou")
    assert {:done, {:error, _reason}} = parse.("mememeyou")
  end

  test "repeat1" do
    parse = from_rule("repeat1")

    assert {:done, {:ok, ["me", "you"], ""}} = parse.("meyou")
    assert {:done, {:ok, ["me", "me", "you"], ""}} = parse.("memeyou")
    assert {:done, {:ok, ["me", "me", "me", "you"], ""}} = parse.("mememeyou")
    assert {:done, {:error, _reason}} = parse.("mememememeyou")
  end

  test "hex1" do
    parse = from_rule("hex1")

    assert {:done, {:ok, ["ü", "ber"], ""}} = parse.("über")
  end

  test "hexRange1" do
    parse = from_rule("hexRange1")

    assert {:done, {:ok, ["a"], ""}} = parse.("a")
    assert {:done, {:error, _reason}} = parse.("A")
  end

  test "untag1" do
    parse = from_rule("untag1")

    assert {:done, {:ok, ["thisistagged"], ""}} = parse.("thisistagged")
  end
end
