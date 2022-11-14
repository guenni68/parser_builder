defmodule ParserBuilder.Streaming do
  @moduledoc false

  def streaming_parser(parser, partial_tag, final_tag) do
    partial_tag =
      partial_tag
      |> String.to_atom()

    final_tag =
      final_tag
      |> String.to_atom()

    reapply_parser(parser, parser, partial_tag, final_tag)
  end

  defp reapply_parser(initial_parser, curr_parser, partial_tag, final_tag)

  defp reapply_parser(initial_parser, curr_parser, partial_tag, final_tag) do
    fn input ->
      case curr_parser.(input) do
        {:done, {:ok, [{^partial_tag, result}], remainder}} ->
          next_parser = fn next_input ->
            reapply_parser(
              initial_parser,
              initial_parser,
              partial_tag,
              final_tag
            ).(remainder <> next_input)
          end

          {:partial_result, result, next_parser}

        {:done, {:ok, [{^final_tag, result}], remainder}} ->
          {:done, {:ok, result, remainder}}

        {:done, {:ok, _result, _remainder}} ->
          {:done, {:error, :conversation_discontinued}}

        {:continue, fun} ->
          next_fun =
            reapply_parser(
              initial_parser,
              fun,
              partial_tag,
              final_tag
            )

          {:continue, next_fun}

        error ->
          error
      end
    end
  end
end
