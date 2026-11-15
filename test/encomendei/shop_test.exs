defmodule Encomendei.ShopTest do
  use Encomendei.DataCase, async: true

  alias Encomendei.Shop

  @png <<0x89, "PNG\r\n", 0x1A, "\n", 0, 0, 0, 13, "IHDR">>

  test "sem configuração salva, vale o nome padrão e não há logo" do
    settings = Shop.get_settings()
    assert settings.name == "Encomendei"
    assert Shop.logo_src(settings) == nil
    assert Shop.get_logo() == nil
  end

  test "salva o nome e atualiza a mesma linha nas vezes seguintes" do
    assert {:ok, _} = Shop.update_settings(%{name: "Confeitaria da Michele"})
    assert {:ok, _} = Shop.update_settings(%{name: "Michele Lazari Bolos"})

    assert Shop.get_settings().name == "Michele Lazari Bolos"
    assert Repo.aggregate(Encomendei.Shop.Setting, :count) == 1
  end

  test "exige nome e limita o tamanho" do
    assert {:error, cs} = Shop.update_settings(%{name: ""})
    assert %{name: ["can't be blank"]} = errors_on(cs)

    assert {:error, cs} = Shop.update_settings(%{name: String.duplicate("a", 61)})
    assert %{name: [_]} = errors_on(cs)
  end

  test "salva o logo, descobre o tipo pelo conteúdo e gera o endereço com versão" do
    {:ok, settings} = Shop.update_settings(%{name: "Loja", logo_data: @png})

    assert {"image/png", @png} = Shop.get_logo()
    assert Shop.logo_src(settings) =~ ~r{^/imagens/logo\?v=\d+$}
  end

  test "recusa logo que não é imagem ou é grande demais" do
    assert {:error, cs} = Shop.update_settings(%{name: "Loja", logo_data: "<html></html>"})
    assert %{logo_data: ["envie uma imagem JPG, PNG ou WebP"]} = errors_on(cs)

    big = @png <> :binary.copy(<<0>>, Encomendei.Images.max_bytes())
    assert {:error, cs} = Shop.update_settings(%{name: "Loja", logo_data: big})
    assert %{logo_data: ["o logo deve ter até 2 MB"]} = errors_on(cs)
  end

  test "remove o logo salvo sem mexer no nome" do
    {:ok, _} = Shop.update_settings(%{name: "Loja", logo_data: @png})

    assert {:ok, settings} = Shop.update_settings(%{remove_logo: true})

    assert settings.name == "Loja"
    assert Shop.get_logo() == nil
    assert Shop.logo_src(Shop.get_settings()) == nil
  end
end
