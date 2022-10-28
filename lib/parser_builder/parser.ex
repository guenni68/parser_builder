defmodule ParserBuilder.Parser do
  @moduledoc false

  alias ParserBuilder.{
    Helpers
  }

  @callback_fun :callback_fun
  @result_and_stack_callback_fun :result_and_stack_callback_fun
  @count_down :count_down
  @ci_char :ci_char
  @cs_char :cs_char

  def create_initial_parser_fun(rules) do
    fn input_chars -> iterate(rules, input_chars) end
  end

  defp iterate(results \\ [], rules, input_chars)

  # result manipulators
  defp iterate(results, [{@callback_fun, callback} | rest], input_string) do
    iterate(callback.(results), rest, input_string)
  end

  defp iterate(results, [{@result_and_stack_callback_fun, fun} | rest], input_string) do
    {new_result, new_stack} = fun.(results, rest)
    iterate(new_result, new_stack, input_string)
  end

  defp iterate(results, [{:tag, %{name: name}, kids} | rest], input_string) do
    tag =
      name
      |> String.to_atom()

    callback =
      fn new_result ->
        [{tag, Enum.reverse(new_result)} | results]
      end
      |> wrap_callback()

    iterate([], kids ++ [callback | rest], input_string)
  end

  defp iterate(result, [{:ignore, _atts, ignored} | rest], input_string) do
    callback =
      fn _new_result ->
        result
      end
      |> wrap_callback()

    iterate([], ignored ++ [callback | rest], input_string)
  end

  defp iterate(result, [{:replace, %{value: value}, kids} | rest], input_string) do
    callback =
      fn _new_result ->
        [value | result]
      end
      |> wrap_callback()

    iterate([], kids ++ [callback | rest], input_string)
  end

  defp iterate(results, [{:untagAndFlatten, _atts, kids} | rest], input_string) do
    callback =
      fn new_results ->
        flattened =
          new_results
          |> untag_and_flatten()

        [flattened | results]
      end
      |> wrap_callback()

    iterate([], kids ++ [callback | rest], input_string)
  end

  defp iterate(results, [{:empty, _atts, []} | rest], input_string) do
    iterate(results, rest, input_string)
  end

  # combinators
  defp iterate(results, [{:cs_literal, %{value: value}, []} | rest], input_string) do
    callback =
      collect_result(results)
      |> wrap_callback()

    parsers =
      value
      |> :binary.bin_to_list()
      |> Enum.map(&make_cs_char/1)

    iterate([], parsers ++ [callback | rest], input_string)
  end

  defp iterate(results, [{:ci_literal, %{value: value}, []} | rest], input_string) do
    callback =
      collect_result(results)
      |> wrap_callback()

    parsers =
      value
      |> :binary.bin_to_list()
      |> Enum.map(&make_ci_char/1)

    iterate([], parsers ++ [callback | rest], input_string)
  end

  defp iterate(results, [{:literal, %{value: _value} = atts, [] = kids} | rest], input_string) do
    iterate(results, [{:ci_literal, atts, kids} | rest], input_string)
  end

  defp iterate(results, [{:ruleRef, %{uri: uri}, []} | rest], input_string) do
    fn lookup_fun ->
      rules = lookup_fun.(uri)

      fn _input_chars ->
        iterate(results, rules ++ rest, input_string)
      end
    end
    |> wrap_lookup()
  end

  defp iterate(results, [{:oneOf, _atts, items} | rest], input_string) do
    items
    |> Enum.map(fn item ->
      fn accumulated_input ->
        iterate(results, [item | rest], input_string <> accumulated_input)
      end
    end)
    |> wrap_backstops()
  end

  defp iterate(results, [{:item, _atts, kids} | rest], input_string) do
    iterate(results, kids ++ rest, input_string)
  end

  defp iterate(results, [{:many, _atts, kids} | rest] = rules, input_string) do
    rewrite =
      Helpers.make_one_of([
        Helpers.make_item(kids ++ rules),
        Helpers.make_item(rest)
      ])

    iterate(results, [rewrite], input_string)
  end

  defp iterate(results, [{:manyOne, atts, kids} | rest], input_string) do
    iterate(results, kids ++ [{:many, atts, kids} | rest], input_string)
  end

  defp iterate(results, [{:optional, _atts, kids} | rest], input_string) do
    rewrite =
      Helpers.make_one_of([
        Helpers.make_item(kids ++ rest),
        Helpers.make_item(rest)
      ])

    iterate(results, [rewrite], input_string)
  end

  defp iterate(results, [{:atLeast, %{count: count}, kids} | rest], input_string) do
    with {count_down, ""} <- Integer.parse(count) do
      parsers = [make_count_down(abs(count_down), kids), make_many(kids) | rest]
      iterate(results, parsers, input_string)
    else
      _ ->
        fatal_error("parse error for count in an atLeast instruction")
    end
  end

  defp iterate(results, [{:atMost, %{count: count}, kids} | rest], input_string) do
    with {count_down, ""} <- Integer.parse(count) do
      iterate(results, [{:upTo, abs(count_down), kids} | rest], input_string)
    end
  end

  defp iterate(results, [{:upTo, 0, _kids} | rest], input_string) do
    iterate(results, rest, input_string)
  end

  defp iterate(results, [{:upTo, count_down, kids} | rest], input_string) do
    rewrite =
      Helpers.make_one_of([
        Helpers.make_item(kids ++ [{:upTo, count_down - 1, kids} | rest]),
        Helpers.make_item(rest)
      ])

    iterate(results, [rewrite], input_string)
  end

  defp iterate(results, [{:exactly, %{count: count}, kids} | rest], input_string) do
    with {count_down, ""} <- Integer.parse(count) do
      parsers = [make_count_down(abs(count_down), kids) | rest]
      iterate(results, parsers, input_string)
    else
      _ ->
        fatal_error("parse error for count in an exactly instruction")
    end
  end

  defp iterate(results, [{:repeat, %{min: min, max: max}, kids} | rest], input_string) do
    with {min_int, ""} <- Integer.parse(min),
         {max_int, ""} <- Integer.parse(max),
         true <- min_int >= 0 and max_int >= min_int do
      at_most = (max_int - min_int) |> to_string()

      rewrite = [
        {:exactly, %{count: min}, kids},
        {:atMost, %{count: at_most}, kids} | rest
      ]

      iterate(results, rewrite, input_string)
    else
      _error ->
        fatal_error("there is an error in a repeat clause: min: #{min}, max: #{max}")
    end
  end

  defp iterate(results, [{@count_down, 0, _kids} | rest], input_string) do
    iterate(results, rest, input_string)
  end

  defp iterate(results, [{@count_down, count, kids} | rest], input_string) do
    parsers = kids ++ [make_count_down(count - 1, kids) | rest]
    iterate(results, parsers, input_string)
  end

  defp iterate(results, [{:hexValue, %{value: value}, []} | rest], input_string) do
    with {integer, ""} <- Integer.parse(value, 16) do
      if integer >= 0 and integer <= 255 do
        iterate(results, [make_cs_char(integer) | rest], input_string)
      else
        fatal_error("there was an issue with a hexValue instruction: #{value}")
      end
    else
      _ ->
        fatal_error("there was an issue with a hexValue instruction: #{value}")
    end
  end

  # processing instructions
  defp iterate(results, [{:exactlyPi, _atts, kids} | rest], input_string) do
    callback =
      fn [parser, count], rules ->
        {results, [make_exactly(count, parser) | rules]}
      end
      |> wrap_result_and_stack_callback_fun()

    iterate(kids ++ [callback | rest], input_string)
  end

  defp iterate(results, [{:count, _atts, kids} | rest], input_string) do
    callback =
      fn [new_result] ->
        [new_result | results]
      end
      |> wrap_callback()

    iterate(kids ++ [callback | rest], input_string)
  end

  defp iterate(results, [{:applyTo, _atts, kids} | rest], input_string) do
    iterate([kids | results], rest, input_string)
  end

  # consuming parsers
  defp iterate(results, [], remainder) do
    done_ok(Enum.reverse(results), remainder)
  end

  defp iterate(results, rules, "") do
    fn input_chars ->
      iterate(results, rules, input_chars)
    end
    |> wrap_continuation()
  end

  defp iterate(
         results,
         [{:hexRange, %{start: start, end: stop}, []} | rest],
         <<char, chars::binary>>
       ) do
    with {start_int, ""} <- Integer.parse(start, 16),
         {stop_int, ""} <- Integer.parse(stop, 16),
         true <- stop_int >= start_int do
      if char in start_int..stop_int do
        iterate([<<char>> | results], rest, chars)
      else
        done_error("could not match hexRange on #{<<char::utf8>>}")
      end
    else
      _ ->
        fatal_error("there is a problem with a hexRange instruction: #{start}, #{stop}")
    end
  end

  defp iterate(results, [{@cs_char, char} | rest], <<char, chars::binary>>) do
    iterate([<<char>> | results], rest, chars)
  end

  defp iterate(results, [{@ci_char, left} | rest], <<right, chars::binary>>) do
    if match_case(left) == match_case(right) do
      iterate([<<right>> | results], rest, chars)
    else
      done_error("could not match #{<<left>>} with #{<<right>>}")
    end
  end

  defp iterate(_results, [{tag, value} | _rest], _input_chars) when tag in [@ci_char, @cs_char] do
    done_error("could not match '#{<<value>>}'")
  end

  defp iterate(_results, [{tag, _atts, _kids} | _rules], _input_chars) do
    fatal_error("Could not apply instruction #{tag}")
  end

  # helpers
  defp done_ok(result, remainder) do
    {:done, {:ok, result, remainder}}
  end

  defp done_error(msg \\ :parse_failed) do
    {:done, {:error, msg}}
  end

  defp fatal_error(msg \\ :fatal) do
    {:error, msg}
  end

  defp wrap_callback(fun) do
    {@callback_fun, fun}
  end

  defp wrap_continuation(fun) do
    {:continue, fun}
  end

  defp wrap_lookup(fun) do
    {:lookup, fun}
  end

  defp wrap_backstops(alternatives) do
    {:backstops, alternatives}
  end

  defp wrap_result_and_stack_callback_fun(fun) do
    {@result_and_stack_callback_fun, fun}
  end

  defp match_case(char) do
    if char >= 65 && char <= 90 do
      char + 32
    else
      char
    end
  end

  defp collect_result(old_result) do
    fn
      [] ->
        old_result

      new_result ->
        new_result =
          new_result
          |> Enum.reverse()
          |> to_string()

        [new_result | old_result]
    end
  end

  defp make_count_down(count_down, parsers) do
    {@count_down, count_down, parsers}
  end

  defp make_many(parsers) do
    {:many, %{}, parsers}
  end

  def make_ci_char(code_point) do
    {@ci_char, code_point}
  end

  def make_cs_char(code_point) do
    {@cs_char, code_point}
  end

  def make_exactly(count, rules) do
    {:exactly, %{count: count}, rules}
  end

  defp untag_and_flatten(result \\ [], ast)

  defp untag_and_flatten(result, []) do
    result
    |> Enum.join()
  end

  defp untag_and_flatten(result, [{_tag, kids} | rest]) when is_list(kids) do
    kids =
      kids
      |> Enum.reverse()

    untag_and_flatten(result, kids ++ rest)
  end

  defp untag_and_flatten(result, [{_tag, kid} | rest]) do
    untag_and_flatten([kid | result], rest)
  end

  defp untag_and_flatten(result, [kid | rest]) do
    untag_and_flatten([kid | result], rest)
  end
end
