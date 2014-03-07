defmodule Restmq.Worker do
  use ExActor.GenServer
  
  alias HTTPoison, as: H

  defrecordp :state, host: "http://localhost", queue: "default", last_message: nil

  definit [host: h, queue: q] do 
    state(host: h, queue: q) |> initial_state
  end
  
  defcast post(message), state: s do
    { :ok, json_msg } = JSON.encode(message)
    res = H.post state(s, :host) <> "/q/#{state(s, :queue)}?#{URI.encode_query [value: json_msg]}", ""
    state(s, last_message: res.body |> String.strip)
        |> new_state
  end
  
  defcast clear, state: s do
    H.delete state(s, :host) <> "/q/#{state(s, :queue)}"
    noreply
  end
  
  defcall get, state: s do
    res =  H.get(state(s, :host) <> "/q/#{state(s, :queue)}" ) |> process_res
    { :ok, value } = JSON.decode(res["value"])
    reply(value)
  end
  
  defcall stream, state: s, from: {caller, ref} do
    H.get(state(s, :host) <> "/c/#{state(s, :queue)}", [], [stream_to: caller] ) 
        |> reply
  end
  
  defp process_res(res) do
    case JSON.decode(res.body) do
      { :ok, json }            -> json
      { :unexpected_token, _ } -> [{"value", "null"}]
    end
  end
end 