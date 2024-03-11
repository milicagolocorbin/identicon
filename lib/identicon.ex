defmodule Identicon do
  alias Identicon.Image

  def main(input) do
    input
    |> hash_input()
    |> pick_color()
    |> build_grid()
    |> build_pixel_map()
    |> draw_image()
    |> save_image(input)
  end

  def hash_input(input) do
    hex =
      :crypto.hash(:md5, input)
      |> :binary.bin_to_list()

    %Image{hex: hex}
  end

  def pick_color(%Image{hex: [r, g, b | _tail]} = image) do
    %Image{image | color: {r, g, b}}
  end

  def build_grid(%Image{hex: hex} = image) do
    grid =
      Enum.chunk_every(hex, 3, 3, :discard)
      |> Enum.map(&mirror_row/1)
      |> List.flatten()
      |> Enum.with_index()
      |> filter_odd()

    %Image{image | grid: grid}
  end

  defp mirror_row(row) do
    [first, second, _third] = row
    Enum.concat(row, [second, first])
  end

  defp filter_odd(grid) do
    Enum.filter(grid, fn {value, _idx} -> rem(value, 2) == 0 end)
  end

  def build_pixel_map(%Identicon.Image{grid: grid} = image) do
    pixel_map =
      Enum.map(grid, fn {_value, idx} ->
        horizontal = rem(idx, 5) * 50
        vertical = div(idx, 5) * 50

        top_left = {horizontal, vertical}
        bottom_right = {horizontal + 50, vertical + 50}

        {top_left, bottom_right}
      end)

    %Identicon.Image{image | pixel_map: pixel_map}
  end

  def draw_image(%Identicon.Image{color: color, pixel_map: pixel_map} = _image) do
    image = :egd.create(250, 250)
    fill = :egd.color(color)

    Enum.each(pixel_map, fn {start, stop} ->
      :egd.filledRectangle(image, start, stop, fill)
    end)

    :egd.render(image)
  end

  def save_image(image, input) do
    File.write("#{input}.png", image)
  end
end
