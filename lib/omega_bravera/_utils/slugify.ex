defmodule OmegaBravera.Slugify do
  def gen_slug(string) do
    string
    |> String.downcase()
    |> String.trim()
    |> String.replace(" ", "-")
    |> String.replace(~r/[!.?']/, "")
  end

  def gen_random_slug(string) do
    slug = string |> gen_slug
    slug <> "-" <> to_string(:rand.uniform(1000))
  end

  def gen_random_slug(string, n) do
    slug = string |> gen_slug
    slug <> "-" <> to_string(:rand.uniform(n))
  end
end
