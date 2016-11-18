defmodule Canary.Action.SpreadAsync do
  defstruct [:callback, :rate, :interval]

  @type rate :: non_neg_integer
  @type time :: non_neg_integer

  @type t :: %__MODULE__{rate: rate, interval: time}
end

defimpl Canary.Actionable, for: Canary.Action.SpreadAsync do
  def run(action, session) do
    # TODO
    {:ok, session}
  end

  def abort(action, session) do
    # TODO
    {:ok, session}
  end

  def retry(action, session) do
    Canary.Action.Any.retry(action, session)
  end
end
