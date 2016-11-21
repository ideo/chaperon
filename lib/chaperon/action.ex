defprotocol Chaperon.Actionable do
  alias Chaperon.Session
  alias Chaperon.Action.Error

  @type result :: Session.t | {:ok, Session.t} | {:error, Error.t}

  @spec run(Chaperon.Actionable.t, Session.t) :: result
  def run(action, session)

  @spec abort(Chaperon.Actionable.t, Session.t) :: result
  def abort(action, session)

  @spec retry(Chaperon.Actionable.t, Session.t) :: result
  def retry(action, session)
end

defmodule Chaperon.Action do
  def retry(action, session) do
    with {:ok, session} <- Chaperon.Actionable.abort(action, session) do
      Chaperon.Actionable.run(action, session)
    end
  end

  def error(action, session, reason) do
    %Chaperon.Action.Error{
      reason: reason,
      action: action,
      session: session
    }
  end
end

defmodule Chaperon.Action.Function do
  defstruct func: nil

  @type callback :: (Chaperon.Actionable -> Chaperon.Session.t)
  @type t :: %Chaperon.Action.Function{func: callback}
end

defimpl Chaperon.Actionable, for: Chaperon.Action.Function do
  def run(%{func: f}, session), do: f.(session)
  def abort(_, session),        do: session
  def retry(action, session),   do: run(action, session)
end


defmodule Chaperon.Action.Loop do
  defstruct action: nil,
            duration: nil,
            started: nil,
            running: true

  @type duration :: non_neg_integer
  @type t :: %Chaperon.Action.Loop{
    action: Chaperon.Actionable,
    duration: duration,
    started: DateTime.t,
    running: true | false
  }
end

defimpl Chaperon.Actionable, for: Chaperon.Action.Loop do
  use Calendar

  def run(loop = %{started: nil}, session) do
    %{loop | started: DateTime.utc_now, running: true}
    |> run(session)
  end

  def run(%{running: false}, session), do: session

  def run(loop = %{action: a, duration: d, running: true}, session) do
    now = DateTime.utc_now |> DateTime.to_unix(:milliseconds)
    s = loop.started |> DateTime.utc_now |> DateTime.to_unix(:milliseconds)
    if (s + d) > now do
      loop
      |> abort(session)
    else
      Canaray.Actionable.run(a, session)
    end
  end

  def abort(loop, session) do
     session
     |> Session.update_action(loop, %{loop | running: false})
   end

  def retry(action, session) do
    %{action | running: true, started: DateTime.utc_now}
    |> run(session)
  end
end