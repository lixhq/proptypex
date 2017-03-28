defmodule PropTypex.PropTypes do

  def atom(required \\ false) do
    create_validator(:atom, required, fn
      v when is_atom(v) -> true
      _ -> false
    end)
  end

  def string(required \\ false) do
    create_validator(:string, required, fn
      v when is_binary(v) -> true
      _ -> false
    end)
  end

  def number(required \\ false) do
    create_validator(:number, required, fn
      v when is_number(v) -> true
      _ -> false
    end)
  end

  def float(required \\ false) do
    create_validator(:float, required, fn
      v when is_float(v) -> true
      _ -> false
    end)
  end

  def integer(required \\ false) do
    create_validator(:integer, required, fn
      v when is_integer(v) -> true
      _ -> false
    end)
  end

  def boolean(required \\ false) do
    create_validator(:boolean, required, fn
      v when is_boolean(v) -> true
      _ -> false
    end)
  end

  def map(required \\ false) do
    create_validator(:map, required, fn
      v when is_map(v) -> true
      _ -> false
    end)
  end

  def map_of(prop_descriptions, required \\ false) do
    type_description = "%{ #{prop_descriptions |> Enum.map(fn { k, prop_descriptor } -> "#{k} => #{Keyword.fetch!(prop_descriptor, :type)}" end) |> Enum.join(", ")} }"

    create_validator("map_of(#{type_description})", required, fn
      v ->
        case PropTypex.run_verification(prop_descriptions, v) do
          {[], _} -> true
          _ -> false
        end
    end)
  end

  def list(required \\ false) do
    create_validator(:list, required, fn
      v when is_list(v) -> true
      _ -> false
    end)
  end

  def list_of(prop_descriptor, required \\ false) do
    prop_type = prop_descriptor[:type]
    prop_validator = prop_descriptor[:prop_validator]
    create_validator("list_of(#{prop_type})", required, fn
      values when is_list(values) ->
        res = Enum.all?(values, fn (v) -> prop_validator.(v) == true end)
        _ -> false
    end)
  end

  def one_of(valid_values, required \\ false) do
    strict_values = Enum.reject(valid_values, &is_validator/1)
    complex_values = Enum.filter(valid_values, &is_validator/1)
    create_validator(
    "one_of(#{Enum.map(strict_values ++ Enum.map(complex_values, &Keyword.fetch!(&1, :type)), &inspect/1) |> Enum.join(", ")})})",
  required, fn value -> value in strict_values or Enum.any?(complex_values, &Keyword.fetch!(&1, :prop_validator).(value)) end)
  end

  def pred(p, required \\ false, description \\ nil) do
    create_validator(description || "predicate was false", required, &p.(&1))
  end

  defp create_validator(type, required, validator) do
    [type: type, required: required, prop_validator: validator]
  end

  defp is_validator(v) when is_list(v) do
    Keyword.has_key?(v, :prop_validator) and Keyword.has_key?(v, :type) and Keyword.has_key?(v, :required)
  end

  defp is_validator(_), do: false
end


