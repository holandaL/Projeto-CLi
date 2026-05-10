defmodule AgendaCli.Store do
  @moduledoc """
  Responsável pela leitura e escrita dos contatos em arquivo JSON.
  """

  @file_path "contacts.json"

  def load do
    case File.read(@file_path) do
      {:ok, content} -> decode_contacts(content)
      {:error, :enoent} -> []
      {:error, _reason} -> []
    end
  end

  def save(contacts) do
    contacts
    |> Enum.map(&stringify_keys/1)
    |> Jason.encode!(pretty: true)
    |> then(&File.write!(@file_path, &1))
  end

  defp decode_contacts(content) do
    case Jason.decode(content) do
      {:ok, contacts} when is_list(contacts) -> Enum.map(contacts, &atomize_contact/1)
      _ -> []
    end
  end

  defp atomize_contact(contact) do
    %{
      id: Map.get(contact, "id"),
      name: Map.get(contact, "name", ""),
      company: Map.get(contact, "company", ""),
      phone: Map.get(contact, "phone", ""),
      email: Map.get(contact, "email", "")
    }
  end

  defp stringify_keys(contact) do
    %{
      "id" => contact.id,
      "name" => contact.name,
      "company" => contact.company,
      "phone" => contact.phone,
      "email" => contact.email
    }
  end
end
