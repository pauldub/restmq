defmodule Restmq.Worker do
  use ExActor.GenServer
  
  alias HTTPoison, as: H

  defrecordp :state, host: "http://localhost", 
    queue: "default", policy: nil, last_message: nil

  defp _set_policy(s, type) when type in [:broadcast, :roundrobin] do
    H.post state(s, :host) <> "/q/#{state(s, :queue)}?#{URI.encode_query [policy: type]}", ""
  end

  defp _init(h, q, policy \\ nil) do
    s = state(host: h, queue: q, policy: policy)
    if policy in [:broadcast, :roundrobin] do
      _set_policy(s, policy)
    end
    s
  end
  
  definit [host: h] do 
    _init(h, "default") |> initial_state
  end

  definit [host: h, policy: p] do 
    _init(h, "default", p) |> initial_state
  end

  definit [host: h, queue: q] do 
    _init(h, q) |> initial_state
  end

  definit [host: h, queue: q, policy: p] do 
    _init(h, q, p) |> initial_state
  end

  defp _stats(s) do
    H.get(state(s, :host) <> "/stats/#{state(s, :queue)}/" ) |> process_res
  end

  defcall length, state: s do
    reply(_stats(s)["len"])
  end
  
  defcall stats, state: s do
    reply(_stats s)
  end

  defcast set_policy(type), state: s do
    _set_policy(s, type)
    state(s, policy: type) |> new_state
  end
  
  defcall policy, state: s, do: state(s, :policy) |> reply
  
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
  
  defcall stream, state: s, from: {caller, _ref} do
    H.get(state(s, :host) <> "/c/#{state(s, :queue)}", [], [stream_to: caller] ) 
        |> reply
  end
  
  defp process_res(res) do
    case JSON.decode(res.body) do
      { :ok, json } -> json
      _             -> [{"value", "null"}]
    end
  end
end 