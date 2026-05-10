defmodule AgendaCli.Application do
  @moduledoc """
  Inicializa a aplicação para que ela possa ser executada diretamente com mix run.
  """

  use Application

  @impl true
  def start(_type, _args) do
    AgendaCli.main([])
    {:ok, self()}
  end
end
