defmodule AgendaCli.Contacts do
  @moduledoc """
  Funções puras para manipulação da lista de contatos.
  """

  @required_fields [:name, :company, :phone, :email]
  @editable_fields [:name, :company, :phone, :email]

  def add(contacts, fields) do
    with :ok <- validate_required(fields),
         :ok <- validate_phone(Map.get(fields, :phone)),
         :ok <- validate_email(Map.get(fields, :email)) do
      contact = %{
        id: current_timestamp_ms(),
        name: String.trim(fields.name),
        company: String.trim(fields.company),
        phone: String.trim(fields.phone),
        email: String.trim(fields.email)
      }

      {:ok, contacts ++ [contact], contact}
    end
  end

  def delete(contacts, id) do
    if exists?(contacts, id) do
      updated_contacts = Enum.reject(contacts, &(&1.id == id))
      {:ok, updated_contacts}
    else
      {:error, "Contato não encontrado."}
    end
  end

  def edit(contacts, id, fields) when map_size(fields) == 0,
    do: {:error, "Informe ao menos um campo para edição."}

  def edit(contacts, id, fields) do
    with :ok <- validate_editable_fields(fields),
         :ok <- validate_optional_phone(fields),
         :ok <- validate_optional_email(fields),
         true <- exists?(contacts, id) do
      updated_contacts =
        Enum.map(contacts, fn contact ->
          if contact.id == id do
            fields
            |> normalize_fields()
            |> then(&Map.merge(contact, &1))
          else
            contact
          end
        end)

      {:ok, updated_contacts}
    else
      false -> {:error, "Contato não encontrado."}
      {:error, reason} -> {:error, reason}
    end
  end

  def find_by_id(contacts, id) do
    case Enum.find(contacts, &(&1.id == id)) do
      nil -> {:error, "Contato não encontrado."}
      contact -> {:ok, contact}
    end
  end

  def search(contacts, field, value) when field in [:name, :phone, :email] do
    searched_value = normalize(value)

    contacts
    |> Enum.filter(fn contact ->
      contact
      |> Map.get(field, "")
      |> normalize()
      |> String.contains?(searched_value)
    end)
  end

  def search(_contacts, _field, _value), do: []

  defp exists?(contacts, id), do: Enum.any?(contacts, &(&1.id == id))

  defp validate_required(fields) do
    missing_fields =
      @required_fields
      |> Enum.reject(fn field -> present?(Map.get(fields, field)) end)

    case missing_fields do
      [] -> :ok
      _ -> {:error, "Campos obrigatórios ausentes: #{Enum.map_join(missing_fields, ", ", &Atom.to_string/1)}."}
    end
  end

  defp validate_editable_fields(fields) do
    invalid_fields =
      fields
      |> Map.keys()
      |> Enum.reject(&(&1 in @editable_fields))

    case invalid_fields do
      [] -> :ok
      _ -> {:error, "Campos inválidos para edição."}
    end
  end

  defp validate_optional_phone(%{phone: phone}), do: validate_phone(phone)
  defp validate_optional_phone(_fields), do: :ok

  defp validate_optional_email(%{email: email}), do: validate_email(email)
  defp validate_optional_email(_fields), do: :ok

  defp validate_phone(phone) do
    phone = to_string(phone || "")

    if Regex.match?(~r/^\d{10,11}$/, phone) do
      :ok
    else
      {:error, "Telefone inválido. Use apenas DDD + número, com 10 ou 11 dígitos."}
    end
  end

  defp validate_email(email) do
    email = to_string(email || "")

    if Regex.match?(~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/, email) do
      :ok
    else
      {:error, "E-mail inválido."}
    end
  end

  defp normalize_fields(fields) do
    fields
    |> Enum.map(fn {key, value} -> {key, String.trim(value)} end)
    |> Map.new()
  end

  defp present?(value), do: is_binary(value) and String.trim(value) != ""
  defp normalize(value), do: value |> to_string() |> String.downcase()
  defp current_timestamp_ms, do: System.system_time(:millisecond)
end
