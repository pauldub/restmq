defmodule Restmq do
  use Application.Behaviour
  
  alias Restmq.Worker, as: W

  # See http://elixir-lang.org/docs/stable/Application.Behaviour.html
  # for more information on OTP Applications
  def start(_type, _args) do
    HTTPoison.start
    Restmq.Supervisor.start_link
  end
  
  def post(w, message) do
    W.post w, message
  end

  def clear(w) do
    W.clear w
  end

  def get(w) do
    W.get w
  end

  def stream(w) do
    W.stream w
  end
end
