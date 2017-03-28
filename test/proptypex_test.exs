defmodule PropTypexTest.Helpers do
  defmacro test_valid_type(type, invalid_type_value) do
    test_name = "#{type} fields are valid when value type is #{PropTypex.Typer.get_type(invalid_type_value)}"
    type_prop = :"#{type}_prop"
    quote do
      test(unquote(test_name)) do
        schema = Map.put(%{}, unquote(type_prop), PropTypex.PropTypes.unquote(type))
        data = Map.put(%{}, unquote(type_prop), unquote(invalid_type_value))
        {:ok, _} = PropTypex.verify(schema, data)
      end
    end
  end

  defmacro test_invalid_type(type, invalid_type_value) do
    test_name = "#{type} fields are invalid when value type is #{PropTypex.Typer.get_type(invalid_type_value)}"
    type_prop = :"#{type}_prop"
    regex = "reason =~ ~r/#{type_prop}/"
    quote do
      test(unquote(test_name)) do
        schema = Map.put(%{}, unquote(type_prop), PropTypex.PropTypes.unquote(type))
        data = Map.put(%{}, unquote(type_prop), unquote(invalid_type_value))
        {:error, reason} = PropTypex.verify(schema, data)
        assert unquote(regex)
      end
    end
  end
end

defmodule PropTypexTest do
  alias PropTypex.PropTypes
  import PropTypexTest.Helpers
  use ExUnit.Case
  doctest PropTypex

  test_invalid_type(:string, 123)
  test_valid_type(:string, "123")

  test_invalid_type(:atom, "")
  test_valid_type(:atom, :my_atom)

  test_invalid_type(:number, "")
  test_valid_type(:number, 123.3)
  test_valid_type(:number, 123)

  test_invalid_type(:float, 1)
  test_valid_type(:float, 1.2)

  test_invalid_type(:integer, 1.2)
  test_valid_type(:integer, 42)

  test_invalid_type(:boolean, "false")
  test_valid_type(:boolean, true)

  test_invalid_type(:map, "")
  test_valid_type(:map, %{})

  test_invalid_type(:list, "")
  test_valid_type(:list, [])

  test "returned data is correct" do
    input_data = %{ string_prop: "hello" }
    schema = %{ string_prop: PropTypes.string }
    {:ok, output_data } = PropTypex.verify(schema, input_data)
    assert output_data.string_prop == "hello"
  end

  test "required props are verified" do
    input_data = %{}
    schema = %{ required_prop: PropTypes.string :required }
    {:error, reason} = PropTypex.verify(schema, input_data)
    assert reason =~ ~r/required_prop/
  end

  test "non-required props are ignored if not present" do
    input_data = %{}
    schema = %{ non_required_prop: PropTypes.string }
    {:ok, _} = PropTypex.verify(schema, input_data)
  end

  test "multiple props are verified" do
    input_data = %{ number_prop: "123", string_prop: 123 }
    schema = %{ number_prop: PropTypes.number, string_prop: PropTypes.string }
    {:error, reason} = PropTypex.verify(schema, input_data)
    assert reason =~ ~r/number_prop/ and reason =~ ~r/string_prop/
  end

  test "error message includes both types" do
    input_data = %{ number_prop: "123", string_prop: 123 }
    schema = %{ number_prop: PropTypes.number, string_prop: PropTypes.string }
    {:error, reason} = PropTypex.verify(schema, input_data)
    assert reason =~ ~r/number_prop/ and reason =~ ~r/string_prop/
    assert reason =~ ~r/number/
    assert reason =~ ~r/string/
  end

  test "list_of validates correctly" do
    schema = %{ list_of_prop: PropTypes.list_of(PropTypes.number) }
    {:ok, _} = PropTypex.verify(schema, %{ list_of_prop: [2, 5]})
    {:error, reason} = PropTypex.verify(schema, %{ list_of_prop: [2, :atom_baby] })
    assert reason =~ ~r/list_of_prop/
    assert reason =~ ~r/list_of\(number\)/
    assert reason =~ ~r/atom/

    {:error, reason} = PropTypex.verify(schema, %{ list_of_prop: ""})
    assert reason =~ ~r/list_of_prop/
    assert reason =~ ~r/list_of\(number\)/
    assert reason =~ ~r/string/
  end

  test "list_of gives proper error-messages when composed" do
    schema = %{ list_of_complextype: PropTypes.list_of(PropTypes.one_of(["hello", 123]), :required) }

    {:error, _} = PropTypex.verify(schema, %{})

    {:ok, _} = PropTypex.verify(schema, %{ list_of_complextype: ["hello", 123] })
    {:error, reason} = PropTypex.verify(schema, %{ list_of_complextype: ["hello", :lol] })
    assert reason =~ ~r/list_of\(one_of\(/
    assert reason =~ ~r/string, atom/

    {:error, reason} = PropTypex.verify(schema, %{ list_of_complextype: ["hello", %{ lol: "hat"}]})
    assert reason =~ ~r/list_of\(one_of\(/
  end

  test "one_of validates correctly" do
    schema = %{ one_of_prop: PropTypes.one_of(["hello", 123]) }
    {:ok, _} = PropTypex.verify(schema, %{ one_of_prop: "hello" })
    {:ok, _} = PropTypex.verify(schema, %{ one_of_prop: 123 })
    {:error, reason} = PropTypex.verify(schema, %{ one_of_prop: :atom })
    assert reason =~ ~r/one_of_prop/
    assert reason =~ ~r/one_of\("hello", 123\)/
    assert reason =~ ~r/atom/
  end

  test "one_of composes" do
    schema = %{ one_of_prop: PropTypes.one_of(["hello", PropTypes.number]) }
    {:ok, _} = PropTypex.verify(schema, %{ one_of_prop: "hello" })
    {:ok, _} = PropTypex.verify(schema, %{ one_of_prop: 789 })
    {:error, _} = PropTypex.verify(schema, %{ one_of_prop: :atom })
  end

  test "map_of value can be empty" do
    schema = %{ map_of_prop: PropTypes.map_of(%{
        map_of_prop: PropTypes.map_of(%{ string_prop: PropTypes.string }),
        bool_prop: PropTypes.boolean
      })
    }
    {:ok, _ } = PropTypex.verify(schema, %{ map_of_prop: %{} })
  end

  test "map_of validates correctly" do
    schema = %{ map_of_prop: PropTypes.map_of(%{
        map_of_prop: PropTypes.map_of(%{ string_prop: PropTypes.string }),
        bool_prop: PropTypes.boolean
      }, :required)
    }
    {:ok, _ } = PropTypex.verify(schema, %{ map_of_prop: %{ map_of_prop: %{} } })
    {:ok, _ } = PropTypex.verify(schema, %{ map_of_prop: %{ map_of_prop: %{ string_prop: "" } } })
    {:ok, _ } = PropTypex.verify(schema, %{ map_of_prop: %{ map_of_prop: %{ string_prop: "" }, bool_prop: true } })
    {:error, _ } = PropTypex.verify(schema, %{ map_of_prop: %{ map_of_prop: %{ string_prop: "" }, bool_prop: "" } })
    {:error, _ } = PropTypex.verify(schema, %{ map_of_prop: %{ map_of_prop: %{ string_prop: [] }, bool_prop: true } })
    {:error, _ } = PropTypex.verify(schema, %{ })
  end

  test "pred validates correctly" do
    schema = %{ pred_prop: PropTypes.pred(&(:valid == &1)) }
    {:ok, _ } = PropTypex.verify(schema, %{ pred_prop: :valid })
    {:error, error } = PropTypex.verify(schema, %{ pred_prop: :invalid })
    assert error =~ "predicate was false"
  end

  test "pred can have custom error description" do
    schema = %{ pred_prop: PropTypes.pred(&(:valid == &1), false, "my error description") }
    {:error, error } = PropTypex.verify(schema, %{ pred_prop: :invalid })
    assert error =~ "my error description"
  end

  test "verify! throws on error" do
    schema = %{ string_prop: PropTypes.string }
    assert_raise PropTypex.ValidationError, fn -> PropTypex.verify!(schema, %{ string_prop: 123 }) end
  end

end
