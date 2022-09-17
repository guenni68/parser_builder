defmodule ParserBuilder.Runner do
  @moduledoc false

  alias ParserBuilder.{
    Result,
    Helpers
  }

  @callback_fun :callback_fun

  def create_initial_parser_fun(rules) do
    fn input_chars -> iterate(rules, input_chars) end
  end

  defp iterate(results \\ [], rules, input_chars)

  # result manipulators
  defp iterate(results, [{@callback_fun, callback} | rest], input_chars) do
    iterate(callback.(results), rest, input_chars)
  end

  defp iterate(results, [{:tag, %{name: name}, kids} | rest], input) do
    tag =
      name
      |> String.to_atom()

    callback =
      fn new_result ->
        [{tag, new_result} | results]
      end
      |> wrap_callback()

    iterate([], kids ++ [callback | rest], input)
  end

  defp iterate(result, [{:ignore, _atts, ignored} | rest], input_chars) do
    callback =
      fn _new_result ->
        result
      end
      |> wrap_callback()

    iterate([], ignored ++ [callback | rest], input_chars)
  end

  defp iterate(result, [{:replace, %{value: value}, kids} | rest], input_chars) do
    callback =
      fn _new_result ->
        [value | result]
      end
      |> wrap_callback()

    iterate([], kids ++ [callback | rest], input_chars)
  end

  # combinators
  defp iterate(results, [{:cs_literal, %{value: value}, []} | rest], input_chars) do
    callback =
      fn new_result ->
        new_result =
          new_result
          |> Enum.reverse()
          |> to_string()

        [new_result | results]
      end
      |> wrap_callback()

    parsers =
      value
      |> String.to_charlist()
      |> Enum.map(fn char -> {:cs_char, char} end)

    iterate([], parsers ++ [callback | rest], input_chars)
  end

  defp iterate(results, [{:ci_literal, %{value: value}, []} | rest], input_chars) do
    callback =
      fn new_result ->
        new_result =
          new_result
          |> Enum.reverse()
          |> to_string()

        [new_result | results]
      end
      |> wrap_callback()

    parsers =
      value
      |> String.to_charlist()
      |> Enum.map(fn char -> {:ci_char, char} end)

    iterate([], parsers ++ [callback | rest], input_chars)
  end

  # consuming parsers
  defp iterate(results, [], remainder) do
    done_ok(Enum.reverse(results), to_string(remainder))
  end

  defp iterate(results, rules, []) do
    fn input_chars ->
      iterate(results, rules, input_chars)
    end
    |> wrap_continuation()
  end

  defp iterate(results, [{:cs_char, char} | rest], [char | chars]) do
    iterate([char | results], rest, chars)
  end

  defp iterate(results, [{:ci_char, left} | rest], [right | chars]) do
    if match_case(left) == match_case(right) do
      iterate([right | results], rest, chars)
    else
      done_error()
    end
  end

  defp iterate(_results, _rules, _input_chars) do
    done_error()
  end

  # helpers
  def done_ok(result, remainder) do
    {:done, {:ok, result, remainder}}
  end

  def done_error(msg \\ :parse_failed) do
    {:done, {:error, msg}}
  end

  defp wrap_callback(fun) do
    {@callback_fun, fun}
  end

  defp wrap_continuation(fun) do
    {:continue, fun}
  end

  defp match_case(char) do
    if char >= 65 && char <= 90 do
      char + 32
    else
      char
    end
  end
end
