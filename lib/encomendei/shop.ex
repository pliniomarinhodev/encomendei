defmodule Encomendei.Shop do
  @moduledoc """
  Dados da loja que usa o sistema: nome e logo, mostrados no cabeçalho do cardápio.

  Existe uma única configuração (linha `id = 1`). Enquanto ninguém salvar nada,
  vale o nome padrão "Encomendei" e não há logo.
  """

  import Ecto.Query, warn: false
  alias Encomendei.Repo
  alias Encomendei.Shop.Setting

  @id 1
  @default_name "Encomendei"

  @doc "Configuração atual da loja (a padrão, não salva, se ainda não houver)."
  @spec get_settings() :: Setting.t()
  def get_settings, do: Repo.get(Setting, @id) || %Setting{id: @id, name: @default_name}

  @doc "Changeset para o formulário de configuração."
  @spec change_settings(Setting.t(), map()) :: Ecto.Changeset.t()
  def change_settings(%Setting{} = setting, attrs \\ %{}), do: Setting.changeset(setting, attrs)

  @doc """
  Salva nome e logo. `logo_data` recebe os bytes da imagem (o tipo é descoberto pelo
  conteúdo) e `remove_logo: true` apaga o logo atual.
  """
  @spec update_settings(map()) :: {:ok, Setting.t()} | {:error, Ecto.Changeset.t()}
  def update_settings(attrs) do
    get_settings()
    |> Setting.changeset(attrs)
    |> Repo.insert_or_update()
  end

  @doc "Tipo e bytes do logo, ou `nil` se a loja não tem logo."
  @spec get_logo() :: {String.t(), binary()} | nil
  def get_logo do
    Repo.one(
      from s in Setting,
        where: s.id == ^@id and not is_nil(s.logo_type),
        select: {s.logo_type, s.logo_data}
    )
  end

  @doc "Endereço do logo para usar em `<img>`, com versão para renovar o cache ao trocar."
  @spec logo_src(Setting.t()) :: String.t() | nil
  def logo_src(%Setting{logo_type: type, updated_at: %DateTime{} = updated_at})
      when is_binary(type),
      do: "/imagens/logo?v=#{DateTime.to_unix(updated_at)}"

  def logo_src(%Setting{}), do: nil
end
