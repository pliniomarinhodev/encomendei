defmodule EncomendeiWeb.OrderComponents do
  @moduledoc "Peças visuais de encomenda compartilhadas entre a loja, o painel e os relatórios."

  use Phoenix.Component

  import EncomendeiWeb.Format, only: [status_label: 1]

  attr :status, :atom, required: true

  def status_badge(assigns) do
    ~H"""
    <span class={["badge badge-soft badge-sm", status_tone(@status)]}>{status_label(@status)}</span>
    """
  end

  attr :urgency, :atom, required: true

  def urgency_badge(%{urgency: :overdue} = assigns) do
    ~H"""
    <span class="badge badge-soft badge-error badge-sm">Atrasada</span>
    """
  end

  def urgency_badge(%{urgency: :today} = assigns) do
    ~H"""
    <span class="badge badge-soft badge-warning badge-sm">Hoje</span>
    """
  end

  def urgency_badge(%{urgency: :tomorrow} = assigns) do
    ~H"""
    <span class="badge badge-soft badge-sm">Amanhã</span>
    """
  end

  def urgency_badge(assigns), do: ~H""

  @steps [:pending, :in_production, :delivered]

  attr :status, :atom, required: true

  @doc "Linha do tempo do pedido para o cliente: recebido, em produção e entregue."
  def status_steps(%{status: :canceled} = assigns) do
    ~H"""
    <p class="rounded border border-error/40 p-3 text-sm" role="status">
      Este pedido foi <strong>cancelado</strong>. Fale com a confeiteira se precisar de ajuda.
    </p>
    """
  end

  def status_steps(assigns) do
    assigns =
      assign(assigns, steps: @steps, current: Enum.find_index(@steps, &(&1 == assigns.status)))

    ~H"""
    <ol class="grid grid-cols-3 gap-2 text-sm" aria-label="Andamento do pedido">
      <li
        :for={{step, index} <- Enum.with_index(@steps)}
        aria-current={index == @current && "step"}
        class={[
          "border-t-4 pt-2",
          index <= @current && "border-primary font-semibold",
          index > @current && "border-base-300 text-base-content/75"
        ]}
      >
        {step_label(step)}
      </li>
    </ol>
    """
  end

  defp step_label(:pending), do: "Recebido"
  defp step_label(:in_production), do: "Em produção"
  defp step_label(:delivered), do: "Entregue"

  defp status_tone(:pending), do: "badge-warning"
  defp status_tone(:in_production), do: "badge-info"
  defp status_tone(:delivered), do: "badge-success"
  defp status_tone(:canceled), do: "badge-error"
end
