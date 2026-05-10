defmodule AgendaCli do
  @moduledoc """
  Aplicação de linha de comando para gerenciamento de contatos pessoais.
  """

  alias AgendaCli.{Contacts, Store}

  def main(_args \\ []) do
    contacts = Store.load()

    IO.puts("Agenda CLI iniciada.")
    IO.puts("Digite help para ver os comandos disponíveis.")

    loop(contacts)
  end

  defp loop(contacts) do
    command =
      "agenda> "
      |> IO.gets()
      |> normalize_input()

    case handle_command(command, contacts) do
      {:continue, updated_contacts} -> loop(updated_contacts)
      :exit -> IO.puts("Aplicação encerrada.")
    end
  end

  defp normalize_input(:eof), do: "exit"
  defp normalize_input(input), do: String.trim(input)

  defp handle_command("", contacts), do: {:continue, contacts}
  defp handle_command("help", contacts), do: show_help(contacts)
  defp handle_command("exit", _contacts), do: :exit
  defp handle_command("test", contacts), do: run_test(contacts)

  defp handle_command(command, contacts) do
    command
    |> String.split(" ", trim: true)
    |> parse_command(contacts)
  end

  defp parse_command(["add" | tokens], contacts) do
    tokens
    |> parse_contact_flags()
    |> add_contact(contacts)
  end

  defp parse_command(["edit", id_text | tokens], contacts) do
    with {:ok, id} <- parse_id(id_text),
         {:ok, fields} <- parse_contact_flags(tokens) do
      edit_contact(contacts, id, fields)
    else
      {:error, reason} -> print_error(reason, contacts)
    end
  end

  defp parse_command(["del", id_text], contacts) do
    with {:ok, id} <- parse_id(id_text) do
      delete_contact(contacts, id)
    else
      {:error, reason} -> print_error(reason, contacts)
    end
  end

  defp parse_command(["show", id_text], contacts) do
    with {:ok, id} <- parse_id(id_text) do
      show_contact(contacts, id)
    else
      {:error, reason} -> print_error(reason, contacts)
    end
  end

  defp parse_command(["list"], contacts), do: list_contacts(contacts)

  defp parse_command(["search" | tokens], contacts) do
    tokens
    |> parse_search()
    |> search_contacts(contacts)
  end

  defp parse_command(_tokens, contacts) do
    IO.puts("Comando inválido. Digite help para ver os comandos disponíveis.")
    {:continue, contacts}
  end

  defp parse_id(id_text) do
    case Integer.parse(id_text) do
      {id, ""} -> {:ok, id}
      _ -> {:error, "ID inválido."}
    end
  end

  defp parse_contact_flags(tokens), do: parse_contact_flags(tokens, %{})

  defp parse_contact_flags([], fields), do: {:ok, fields}

  defp parse_contact_flags(["--name" | rest], fields),
    do: parse_flag_value(rest, fields, :name)

  defp parse_contact_flags(["--company" | rest], fields),
    do: parse_flag_value(rest, fields, :company)

  defp parse_contact_flags(["--phone" | rest], fields),
    do: parse_flag_value(rest, fields, :phone)

  defp parse_contact_flags(["--email" | rest], fields),
    do: parse_flag_value(rest, fields, :email)

  defp parse_contact_flags([invalid | _rest], _fields),
    do: {:error, "Flag inválida: #{invalid}"}

  defp parse_flag_value(tokens, fields, key) do
    {value_tokens, remaining_tokens} = Enum.split_while(tokens, &not_flag?/1)

    case value_tokens do
      [] -> {:error, "A flag #{format_flag(key)} precisa de um valor."}
      _ -> parse_contact_flags(remaining_tokens, Map.put(fields, key, Enum.join(value_tokens, " ")))
    end
  end

  defp not_flag?(token), do: not String.starts_with?(token, "--")

  defp parse_search(["--name" | value]), do: parse_single_search_flag(:name, value)
  defp parse_search(["--phone" | value]), do: parse_single_search_flag(:phone, value)
  defp parse_search(["--email" | value]), do: parse_single_search_flag(:email, value)
  defp parse_search([]), do: {:error, "Informe uma flag de busca: --name, --phone ou --email."}
  defp parse_search([invalid | _]), do: {:error, "Flag de busca inválida: #{invalid}"}

  defp parse_single_search_flag(key, value_tokens) do
    cond do
      value_tokens == [] ->
        {:error, "A flag #{format_flag(key)} precisa de um valor."}

      Enum.any?(value_tokens, &String.starts_with?(&1, "--")) ->
        {:error, "O comando search aceita apenas uma flag por vez."}

      true ->
        {key, Enum.join(value_tokens, " ")}
    end
  end

  defp add_contact({:ok, fields}, contacts) do
    case Contacts.add(contacts, fields) do
      {:ok, updated_contacts, contact} ->
        Store.save(updated_contacts)
        IO.puts("Contato adicionado com sucesso. ID: #{contact.id}")
        {:continue, updated_contacts}

      {:error, reason} ->
        print_error(reason, contacts)
    end
  end

  defp add_contact({:error, reason}, contacts), do: print_error(reason, contacts)

  defp edit_contact(contacts, id, fields) do
    case Contacts.edit(contacts, id, fields) do
      {:ok, updated_contacts} ->
        Store.save(updated_contacts)
        IO.puts("Contato atualizado com sucesso.")
        {:continue, updated_contacts}

      {:error, reason} ->
        print_error(reason, contacts)
    end
  end

  defp delete_contact(contacts, id) do
    case Contacts.delete(contacts, id) do
      {:ok, updated_contacts} ->
        Store.save(updated_contacts)
        IO.puts("Contato removido com sucesso.")
        {:continue, updated_contacts}

      {:error, reason} ->
        print_error(reason, contacts)
    end
  end

  defp show_contact(contacts, id) do
    case Contacts.find_by_id(contacts, id) do
      {:ok, contact} -> print_contact(contact)
      {:error, reason} -> IO.puts("Erro: #{reason}")
    end

    {:continue, contacts}
  end

  defp list_contacts(contacts) do
    case contacts do
      [] ->
        IO.puts("Nenhum contato cadastrado.")

      _ ->
        Enum.each(contacts, &print_contact_line/1)
    end

    {:continue, contacts}
  end

  defp search_contacts({:error, reason}, contacts), do: print_error(reason, contacts)

  defp search_contacts({field, value}, contacts) do
    results = Contacts.search(contacts, field, value)

    case results do
      [] -> IO.puts("Nenhum contato encontrado.")
      _ -> Enum.each(results, &print_contact_line/1)
    end

    {:continue, contacts}
  end

  defp run_test(_contacts) do
    contacts =
      []
      |> elem_from_add(%{name: "Ana Lima", company: "Acme", phone: "85912345678", email: "ana@acme.com"})
      |> elem_from_add(%{name: "José Silva", company: "Beta", phone: "85988887777", email: "jose@gmail.com"})

    Store.save(contacts)
    IO.puts("Base de teste criada com 2 contatos em contacts.json.")
    {:continue, contacts}
  end

  defp elem_from_add(contacts, fields) do
    {:ok, updated_contacts, _contact} = Contacts.add(contacts, fields)
    updated_contacts
  end

  defp show_help(contacts) do
    IO.puts("""

    Comandos disponíveis:
      add --name Ana Lima --company Acme --phone 85912345678 --email ana@acme.com
      edit <id> --phone 85912345678
      edit <id> --name Ana Silva --company Acme LTDA
      del <id>
      show <id>
      list
      search --name ana
      search --phone 85
      search --email gmail
      test
      exit
    """)

    {:continue, contacts}
  end

  defp print_contact(contact) do
    IO.puts("""

    ID: #{contact.id}
    Nome: #{contact.name}
    Empresa: #{contact.company}
    Telefone: #{contact.phone}
    E-mail: #{contact.email}
    """)
  end

  defp print_contact_line(contact) do
    IO.puts("#{contact.id} | #{contact.name} | #{contact.company} | #{contact.phone} | #{contact.email}")
  end

  defp print_error(reason, contacts) do
    IO.puts("Erro: #{reason}")
    {:continue, contacts}
  end

  defp format_flag(:name), do: "--name"
  defp format_flag(:company), do: "--company"
  defp format_flag(:phone), do: "--phone"
  defp format_flag(:email), do: "--email"
end
