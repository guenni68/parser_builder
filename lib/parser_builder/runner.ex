defmodule ParserBuilder.Runner do
  @moduledoc false

  alias ParserBuilder.Result

  @continue :continue
  @done :done
  @callback_fun :callback
  @backtrack :backtrack
  @add_backstop :add_backstop

  def create_initial_parser_fun(lookup_fun, rules) do
    fn input_chars -> run_parser(lookup_fun, rules, input_chars) end
  end

  defp run_parser(results \\ Result.new(), lookup_fun, rules, input_chars)

  # result modifiers
  defp run_parser(results, lookup_fun, [{:untagAndFlatten, _atts, kids} | rules], input_chars) do
    results =
      results
      |> Result.add_untag_and_flatten_capture()

    rules =
      rules
      |> Result.add_untag_and_flatten_collect_rule()

    run_parser(results, lookup_fun, kids ++ rules, input_chars)
  end

  defp run_parser(
         results,
         lookup_fun,
         [{:replace, %{value: replacement}, kids} | rules],
         input_chars
       ) do
    results =
      results
      |> Result.add_replace_capture()

    rules =
      rules
      |> Result.add_replace_collect_rule(replacement)

    run_parser(results, lookup_fun, kids ++ rules, input_chars)
  end

  defp run_parser(
         results,
         lookup_fun,
         [{:ignore, _atts, kids} | rules],
         input_chars
       ) do
    results =
      results
      |> Result.add_ignore_capture()

    rules =
      rules
      |> Result.add_ignore_collect_rule()

    run_parser(results, lookup_fun, kids ++ rules, input_chars)
  end

  defp run_parser(
         results,
         lookup_fun,
         [{:tag, %{name: tag}, kids} | rules],
         input_chars
       ) do
    results =
      results
      |> Result.add_tagged_capture(tag)

    rules =
      rules
      |> Result.add_tagged_collect_rule(tag)

    run_parser(results, lookup_fun, kids ++ rules, input_chars)
  end

  defp run_parser(
         results,
         lookup_fun,
         [{@callback_fun, callback} | rules],
         input_chars
       ) do
    run_parser(
      callback.(results),
      lookup_fun,
      rules,
      input_chars
    )
  end

  # parser combinators
  defp run_parser(
         results,
         lookup_fun,
         [{:oneOf, _atts, [item | items]} | rules],
         input_chars
       ) do
    alternatives =
      items
      |> Enum.map(fn new_item ->
        fn new_input_chars ->
          run_parser(
            results,
            lookup_fun,
            [new_item | rules],
            input_chars ++ new_input_chars
          )
        end
      end)

    next_fun = fn new_input_chars ->
      run_parser(results, lookup_fun, [item | rules], input_chars ++ new_input_chars)
    end

    add_backstop(alternatives, next_fun)
  end

  defp run_parser(
         results,
         lookup_fun,
         [{:item, _atts, kids} | rules],
         input_chars
       ) do
    run_parser(results, lookup_fun, kids ++ rules, input_chars)
  end

  defp run_parser(
         results,
         lookup_fun,
         [{:ruleRef, %{uri: rule_name}, _kids} | rules],
         input_chars
       ) do
    new_rules = lookup_fun.(rule_name)
    run_parser(results, lookup_fun, new_rules ++ rules, input_chars)
  end

  defp run_parser(
         results,
         lookup_fun,
         [{:cs_literal, %{value: literal}, []} | rules],
         input_chars
       ) do
    new_rules =
      literal
      |> String.to_charlist()
      |> Enum.map(fn char -> {:cs_elem, char} end)

    run_parser(
      Result.add_simple_capture(results),
      lookup_fun,
      new_rules ++ Result.add_simple_collect_rule(rules),
      input_chars
    )
  end

  defp run_parser(
         results,
         lookup_fun,
         [{:ci_literal, %{value: literal}, []} | rules],
         input_chars
       ) do
    new_rules =
      literal
      |> String.to_charlist()
      |> Enum.map(fn char -> {:ci_elem, char} end)

    run_parser(
      Result.add_simple_capture(results),
      lookup_fun,
      new_rules ++ Result.add_simple_collect_rule(rules),
      input_chars
    )
  end

  defp run_parser(
         results,
         lookup_fun,
         [{:literal, %{value: literal}, []} | rules],
         input_chars
       ) do
    run_parser(
      results,
      lookup_fun,
      [{:ci_literal, %{value: literal}, []} | rules],
      input_chars
    )
  end

  # consuming parsers
  defp run_parser(results, _lookup_fun, [], input_chars) do
    wrap_done_ok(results, input_chars)
  end

  defp run_parser(results, lookup_fun, rules, []) do
    fn input_chars ->
      run_parser(results, lookup_fun, rules, input_chars)
    end
    |> wrap_continue()
  end

  defp run_parser(results, lookup_fun, [{:cs_elem, char} | rules], [char | chars]) do
    results =
      results
      |> Result.add_result(char)

    run_parser(results, lookup_fun, rules, chars)
  end

  defp run_parser(_results, _lookup_fun, [{:cs_elem, _char} | _rules], _input_chars) do
    @backtrack
  end

  defp run_parser(results, lookup_fun, [{:ci_elem, l} | rules], [r | chars]) do
    if match_case(l) == match_case(r) do
      results =
        results
        |> Result.add_result(r)

      run_parser(results, lookup_fun, rules, chars)
    else
      @backtrack
    end
  end

  # helpers
  defp wrap_continue(fun) do
    {@continue, fun}
  end

  defp wrap_done_ok(result, remainder) do
    {@done, {:ok, result, to_string(remainder)}}
  end

  defp match_case(char) do
    if char >= 65 && char <= 90 do
      char + 32
    else
      char
    end
  end

  defp add_backstop(alternatives, next_fun) do
    {@add_backstop, alternatives, next_fun}
  end
end
