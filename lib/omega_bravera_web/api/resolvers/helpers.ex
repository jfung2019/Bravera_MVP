defmodule OmegaBraveraWeb.Api.Resolvers.Helpers do
  def transform_errors(%Ecto.Changeset{} = changeset),
    do: Ecto.Changeset.traverse_errors(changeset, &format_error/1)

  defp format_error({msg, opts}),
    do:
      Enum.reduce(
        opts,
        msg,
        fn {key, value}, acc ->
          String.replace(acc, "%{#{key}}", to_string(value))
        end
      )
end
