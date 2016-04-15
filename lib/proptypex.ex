defmodule PropTypex do
  alias PropTypex.Typer

  defmodule ValidationError do
    @moduledoc """
    Exception raised when validation had errors
    """
    defexception message: "validation error"
  end


  def run_verification(prop_descriptions, data) do
    Enum.reduce(prop_descriptions, {[], data}, fn {k, [type: prop_type, required: required, prop_validator: prop_validator]}, acc = {errors, data} ->
      value = Map.get(data, k, :missing_prop_value)
      cond do
        value == :missing_prop_value and required -> { [{:missing, k, prop_type} | errors], data }
        value == :missing_prop_value -> acc
        true ->
          case prop_validator.(value) do
            true -> acc
            false -> {[{:invalid, k, prop_type, value} | errors], data}
          end
      end
    end)
  end

  def verify(prop_descriptions, data) do
    case run_verification(prop_descriptions, data) do
      {[], data} -> {:ok, data}
      {errors, _} -> {:error, Enum.join(Enum.map(errors, &create_error_message/1), "\n")}
    end
  end

  def verify!(prop_descriptions, data) do
    case verify(prop_descriptions, data) do
      {:ok, data} -> data
      {:error, error_msg} -> raise ValidationError, message: error_msg
    end
  end

  defp get_value_type(list) when is_list(list) do
    "[#{Enum.map(list, &get_value_type/1) |> Enum.join(", ")}]"
  end

  defp get_value_type(map) when is_map(map) do
    "%{#{Enum.map(map, fn {k, v} -> "#{get_key_type(k)} => #{get_value_type(v)}" end) |> Enum.join(", ")}}"
  end

  defp get_value_type(value), do: Typer.get_type(value)

  defp get_key_type(key) when is_atom(key), do: ":#{key}"
  defp get_key_type(key) when is_binary(key), do: "\"#{key}\""
  defp get_key_type(key), do: Typer.get_type(key)

  defp create_error_message({:missing, k, type}), do: "Required property #{k} with type #{type} was missing"
  defp create_error_message({:invalid, k, type, value}), do: "Property #{k} expected type #{type} but got invalid type '#{get_value_type(value)}'"
end
