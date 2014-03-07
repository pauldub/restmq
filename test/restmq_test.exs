defmodule RestmqTest do
  use ExUnit.Case

  {:ok, pid } = Restmq.Worker.start [host: "http://localhost:8089", queue: "test-queue"]
  @q pid
  
  setup do
    Restmq.clear @q
  end

  defmacro handle_msg(id, on_msg) do
    quote do
      receive do
        HTTPoison.AsyncChunk[id: unquote(id), chunk: c] ->
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
    id = res.id
    
    handle_msg(id, fn(val) -> assert val == "test" end)
    handle_msg(id, fn(val) -> assert val == "test" end)
    handle_msg(id, fn(val) -> assert val == "test" end)
  end
end
