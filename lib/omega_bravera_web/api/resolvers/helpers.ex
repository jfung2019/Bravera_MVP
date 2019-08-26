defmodule OmegaBraveraWeb.Api.Resolvers.Helpers do
  def transform_errors(%Ecto.Changeset{} = changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(&format_error/1)
    |> Enum.map(fn
      {key, value} ->
        %{key: key, message: value}
    end)
  end

  def transform_errors(errors), do: Enum.map(errors, fn {key, value} -> %{key: key, message: value} end)

  defp format_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
