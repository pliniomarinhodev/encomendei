defmodule Encomendei.Images do
  @moduledoc "Regras comuns das imagens enviadas (fotos de produtos e logo da loja)."

  @max_bytes 2_000_000

  @doc "Tamanho máximo de uma imagem enviada, em bytes."
  def max_bytes, do: @max_bytes

  @doc """
  Descobre o tipo da imagem pelos primeiros bytes do arquivo (JPEG, PNG ou WebP).

  O tipo nunca vem do nome do arquivo nem do navegador, que podem mentir.
  """
  @spec detect_type(binary()) :: String.t() | nil
  def detect_type(<<0xFF, 0xD8, 0xFF, _::binary>>), do: "image/jpeg"
  def detect_type(<<0x89, "PNG\r\n", 0x1A, "\n", _::binary>>), do: "image/png"
  def detect_type(<<"RIFF", _size::binary-size(4), "WEBP", _::binary>>), do: "image/webp"
  def detect_type(_other), do: nil
end
