defmodule ExAws.Utils do

  @moduledoc false

  def camelize_keys(opts) do
    camelize_keys(opts, deep: false)
  end

  # This isn't tail recursive. However, given that the structures
  # being worked upon are relatively shallow, this is ok.
  def camelize_keys(opts = %{}, deep: deep) do
    opts |> Enum.reduce(%{}, fn({k ,v}, map) ->
      if deep do
        Map.put(map, camelize_key(k), camelize_keys(v, deep: true))
      else
        Map.put(map, camelize_key(k), v)
      end
    end)
  end
  
  def camelize_keys([%{} | _] = opts, deep: deep) do
    Enum.map(opts, &camelize_keys(&1, deep: deep))
  end

  def camelize_keys(opts, depth) do
    try do
      opts
      |> Enum.into(%{})
      |> camelize_keys(depth)
    rescue
      [Protocol.UndefinedError, ArgumentError] -> opts
    end
  end

  defp camelize_key(key) when is_atom(key) do
    key
    |> Atom.to_string
    |> Mix.Utils.camelize
  end

  defp camelize_key(key) when is_binary(key) do
    key |> Mix.Utils.camelize
  end

  def upcase(value) when is_atom(value) do
    value
    |> Atom.to_string
    |> String.upcase
  end

  def upcase(value) when is_binary(value) do
    String.upcase(value)
  end

  @seconds_0_to_1970 :calendar.datetime_to_gregorian_seconds({{1970, 1, 1}, {0, 0, 0}})

  def iso_z_to_secs(<<date::binary-10, "T", time::binary-8, "Z">>) do
    <<year::binary-4, "-", mon::binary-2, "-", day::binary-2>> = date
    <<hour::binary-2, ":", min::binary-2, ":", sec::binary-2>> = time
    year = year |> String.to_integer
    mon  = mon  |> String.to_integer
    day  = day  |> String.to_integer
    hour = hour |> String.to_integer
    min  = min  |> String.to_integer
    sec  = sec  |> String.to_integer

    # Seriously? Gregorian seconds but not epoch seconds?
    greg_secs = :calendar.datetime_to_gregorian_seconds({{year, mon, day}, {hour, min, sec}})
    greg_secs - @seconds_0_to_1970
  end

  def now_in_seconds do
    greg_secs = :os.timestamp
    |> :calendar.now_to_universal_time
    |> :calendar.datetime_to_gregorian_seconds

    greg_secs - @seconds_0_to_1970
  end
end
