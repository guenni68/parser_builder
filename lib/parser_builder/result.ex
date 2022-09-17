defmodule ParserBuilder.Result do
  @moduledoc false

  @ignore :ignore
  @tagged :tagged
  @replace :replace
  @callback_fun :callback
  @capture :capture
  @wrapped :wrapped
  @untag_and_flatten :untag_and_flatten

  def new() do
    [{@tagged, :root, []}]
  end

  # TODO add more cases
  def add_result([@ignore | _] = result, _value) do
    result
  end

  def add_result([@replace | _] = result, _value) do
    result
  end

  def add_result([{@tagged, tag, values} | results], value) do
    [{@tagged, tag, [value | values]} | results]
  end

  def add_result([{@capture, chars} | results], char) do
    [{@capture, [char | chars]} | results]
  end

  def add_result([{@untag_and_flatten, values} | results], value) do
    [{@untag_and_flatten, [value, values]} | results]
  end

  # TODO implement
  def add_simple_capture(results) do
    [{@capture, []} | results]
  end

  def add_tagged_capture(results, tag) do
    [{@tagged, tag, []} | results]
  end

  def add_ignore_capture(results) do
    [@ignore | results]
  end

  def add_replace_capture(results) do
    [@replace | results]
  end

  def add_wrap_capture(results) do
    [{@wrapped, []} | results]
  end

  # TODO implement
  def add_untag_and_flatten_capture(results) do
    [{@untag_and_flatten, []} | results]
  end

  # TODO implement
  def add_simple_collect_rule(rules) do
    callback =
      fn [{@capture, chars} | results] ->
        result =
          chars
          |> Enum.reverse()
          |> to_string()

        results
        |> add_result(result)
      end
      |> wrap_callback()

    [callback | rules]
  end

  def add_tagged_collect_rule(rules, tag) do
    callback =
      fn [{@tagged, ^tag, result} | results] ->
        results
        |> add_result({tag, Enum.reverse(result)})
      end
      |> wrap_callback()

    [callback | rules]
  end

  def add_ignore_collect_rule(rules) do
    callback =
      fn [@ignore | results] ->
        results
      end
      |> wrap_callback()

    [callback | rules]
  end

  def add_replace_collect_rule(rules, value) do
    callback =
      fn [@replace | results] ->
        results
        |> add_result(value)
      end
      |> wrap_callback

    [callback | rules]
  end

  # TODO implement
  def add_untag_and_flatten_collect_rule(rules) do
    callback =
      fn [{@untag_and_flatten, new_result} | new_results] ->
        new_result =
          new_result
          |> untag_and_flatten()

        new_results
        |> add_result(new_result)
      end
      |> wrap_callback()

    [callback | rules]
  end

  # helpers
  defp wrap_callback(fun) do
    {@callback_fun, fun}
  end

  # TODO check implementation
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

  defp untag_and_flatten(result, [kid | rest]) when is_integer(kid) do
    untag_and_flatten([<<kid::utf8>> | result], rest)
  end

  defp untag_and_flatten(result, [kid | rest]) do
    untag_and_flatten([kid | result], rest)
  end
end
