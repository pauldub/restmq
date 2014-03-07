defmodule Restmq do
  use Application.Behaviour
  
  alias Restmq.Worker, as: W

  # See http://elixir-lang.org/docs/stable/Application.Behaviour.html
  # for more information on OTP Applications
  def start(_type, _args) do
    HTTPoison.start
    Restmq.Supervisor.start_link
  end
  
  def set_policy(w, policy), do: W.set_policy(w, policy)
  def policy(w), do: W.policy w

  def stats(w), do: W.stats w
  def length(w), do: W.length w
  def clear(w), do: W.clear w

  def post(w, message), do: W.post(w, message)
  def get(w), do: W.get w
  def stream(w), do: W.stream w
end
