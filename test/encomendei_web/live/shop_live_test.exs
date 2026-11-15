defmodule EncomendeiWeb.ShopLiveTest do
  use EncomendeiWeb.ConnCase

  import Phoenix.LiveViewTest

  alias Encomendei.Shop

  @png <<0x89, "PNG\r\n", 0x1A, "\n", 0, 0, 0, 13, "IHDR">>

  defp logo(name, content, type \\ "image/png"), do: %{name: name, content: content, type: type}

  test "exige login", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/entrar"}}} = live(conn, ~p"/admin/loja")
  end

  describe "tela de configuração" do
    setup %{conn: conn}, do: {:ok, conn: admin_conn(conn)}

    test "salva o nome e ele aparece no cardápio e no painel", %{conn: conn} do
      {:ok, view, html} = live(conn, ~p"/admin/loja")
      assert html =~ "Nome da loja"

      view
      |> form("#shop-form", setting: %{name: "Confeitaria da Michele"})
      |> render_submit()

      assert Shop.get_settings().name == "Confeitaria da Michele"

      {:ok, _view, menu} = live(build_conn(), ~p"/")
      assert menu =~ "Confeitaria da Michele"
    end

    test "envia o logo e ele passa a aparecer no topo do cardápio", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/loja")

      upload = file_input(view, "#shop-form", :logo, [logo("logo.png", @png)])
      assert render_upload(upload, "logo.png") =~ "Pré-visualização do logo escolhido"

      view |> form("#shop-form", setting: %{name: "Loja"}) |> render_submit()

      assert {"image/png", @png} = Shop.get_logo()

      {:ok, _view, menu} = live(build_conn(), ~p"/")
      assert menu =~ "/imagens/logo?v="
    end

    test "recusa arquivo que não é imagem mesmo com extensão de imagem", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/loja")

      upload = file_input(view, "#shop-form", :logo, [logo("falso.png", "<html>oi</html>")])
      render_upload(upload, "falso.png")

      html = view |> form("#shop-form", setting: %{name: "Loja"}) |> render_submit()

      assert html =~ "envie uma imagem JPG, PNG ou WebP"
      assert Shop.get_logo() == nil
    end

    test "recusa extensão não aceita", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/loja")

      upload =
        file_input(view, "#shop-form", :logo, [logo("a.pdf", "%PDF", "application/pdf")])

      assert {:error, [[_ref, :not_accepted]]} = render_upload(upload, "a.pdf")
    end

    test "remove o logo salvo", %{conn: conn} do
      {:ok, _} = Shop.update_settings(%{name: "Loja", logo_data: @png})

      {:ok, view, html} = live(conn, ~p"/admin/loja")
      assert html =~ "Logo atual da loja"

      view |> form("#shop-form", setting: %{remove_logo: "true"}) |> render_submit()

      assert Shop.get_logo() == nil
    end

    test "não aceita nome em branco", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/admin/loja")

      html = view |> form("#shop-form", setting: %{name: ""}) |> render_submit()

      assert html =~ "can&#39;t be blank" or html =~ "can't be blank"
    end
  end
end
