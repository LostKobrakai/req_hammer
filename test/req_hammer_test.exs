defmodule ReqHammerTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  test "works" do
    key = "key"
    scale = :timer.minutes(10)
    limit = 2

    Req.Test.stub(ReqHammer.Stub, fn conn ->
      Plug.Conn.send_resp(conn, 200, "")
    end)

    req =
      Req.new(plug: {Req.Test, ReqHammer.Stub})
      |> ReqHammer.attach()
      |> Req.merge(
        rate_limit: [
          module: ReqHammer.TestHammer,
          key: key,
          scale: scale,
          limit: limit
        ]
      )

    assert {:ok, %Req.Response{status: 200}} = Req.get(req, url: "http://example.com/")
    assert {:ok, %Req.Response{status: 200}} = Req.get(req, url: "http://example.com/")

    assert {:error,
            %ReqHammer.RateLimited{
              cost: 1,
              delay: _,
              key: "key",
              limit: 2,
              module: ReqHammer.TestHammer,
              scale: 600_000
            }} = Req.get(req, url: "http://example.com/")
  end

  test "can be retried" do
    key = "key"
    scale = :timer.seconds(2)
    limit = 2

    Req.Test.stub(ReqHammer.Stub, fn conn ->
      Plug.Conn.send_resp(conn, 200, "")
    end)

    req =
      Req.new(plug: {Req.Test, ReqHammer.Stub})
      |> ReqHammer.attach()
      |> Req.merge(
        rate_limit: [
          module: ReqHammer.TestHammer,
          key: key,
          scale: scale,
          limit: limit
        ],
        retry: fn
          _req, %ReqHammer.RateLimited{delay: delay} -> {:delay, delay}
          _, _ -> false
        end
      )

    assert {:ok, %Req.Response{status: 200}} = Req.get(req, url: "http://example.com/")
    assert {:ok, %Req.Response{status: 200}} = Req.get(req, url: "http://example.com/")

    {result, log} =
      with_log(fn ->
        Req.get(req, url: "http://example.com/")
      end)

    assert {:ok, %Req.Response{status: 200}} = result

    assert log =~ "retry: got exception, will retry in"
    assert log =~ "(ReqHammer.RateLimited) Hit rate limit on ReqHammer.TestHammer"
  end
end
