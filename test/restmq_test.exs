defmodule RestmqTest do
  use ExUnit.Case
  
  {:ok, pid } = Restmq.Worker.start [host: "http://127.0.0.1:8089", queue: "test-queue"]
  @q pid
  
  setup do
    Restmq.clear @q
  end

  defmacro handle_msg(res, on_msg) do
    quote do
      id = unquote(res).id
      receive do
        HTTPoison.AsyncChunk[id: id, chunk: c] ->
          { :ok, json } = JSON.decode c
          { :ok, val }  = JSON.decode json["value"]
          unquote(on_msg).(val)
      after
        20 -> :timeout
      end
    end
  end

  test "it can post a message" do
    assert :ok = Restmq.post @q, [job: "upload-key", user: "foo"]
  end
  
  test "it can clear the queue" do
    assert :ok = Restmq.post @q, [job: "upload-key", user: "foo"]
    assert :ok = Restmq.clear @q
    assert nil = Restmq.get @q 
  end
  
  test "it can get a message" do
    Restmq.post @q, [job: "upload-key", user: "foo"]

    msg = Restmq.get @q

    assert msg["user"] == "foo"
    assert msg["job"] == "upload-key"
  end
  
  test "it can stream messages" do
    Restmq.post @q, "test"
    Restmq.post @q, "test"
    Restmq.post @q, "test"

    res = Restmq.stream @q
    
    handle_msg(res, fn(val) -> assert val == "test" end)
    handle_msg(res, fn(val) -> assert val == "test" end)
    handle_msg(res, fn(val) -> assert val == "test" end)
  end
  
  test "it can set policy" do
    assert :ok = Restmq.set_policy @q, :broadcast
    assert :ok = Restmq.set_policy @q, :roundrobin
  end
  
  test "it can set policy on init" do
    assert { :ok, _queue } = Restmq.Worker.start [host: "http://127.0.0.1:8089", policy: :broadcast]
    assert { :ok, _queue } = Restmq.Worker.start [host: "http://127.0.0.1:8089", policy: :roundrobin]
  end
  
  test "it can get the current policy" do
    { :ok, queue } = Restmq.Worker.start [host: "http://127.0.0.1:8089", policy: :broadcast]
    assert :broadcast = Restmq.policy queue
  end

  test "it correctly set the policy when it after initialization" do
    { :ok, queue } = Restmq.Worker.start [host: "http://127.0.0.1:8089", queue: "test-policy"]
    assert nil = Restmq.policy queue
    
    Restmq.set_policy queue, :roundrobin
    
    assert :roundrobin = Restmq.policy queue
  end
  
  test "it can get a queue lenght" do
    Restmq.clear @q
    assert 0 = Restmq.length @q
  end
end