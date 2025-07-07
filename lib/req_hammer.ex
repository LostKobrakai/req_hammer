defmodule ReqHammer do
  @moduledoc """
  Documentation for `ReqHammer`.
  """

  defmodule RateLimited do
    defexception [:module, :key, :scale, :limit, :cost, :delay]

    def message(exception) do
      "Hit rate limit on #{inspect(exception.module)} using settings: #{inspect(Map.take(exception, [:key, :scale, :limit, :cost]))}"
    end
  end

  @doc """
  Rate limits requests being made by Req.

  ## Request Options

  * `:rate_limit` - if `true`, prints the headers. Defaults to `false`.

  """
  def attach(%Req.Request{} = request, options \\ []) do
    request
    |> Req.Request.register_options([:rate_limit])
    |> Req.Request.merge_options(options)
    |> Req.Request.append_request_steps(rate_limit: &__MODULE__.apply_rate_limit/1)
  end

  @doc false
  def apply_rate_limit(%Req.Request{} = request) do
    with {:cont, options} <- fetch_options(request),
         {:cont, validated} <- validate_options(request, options) do
      case validated.module.hit(validated.key, validated.scale, validated.limit, validated.cost) do
        {:allow, _current_count} ->
          request

        {:deny, ms_until_next_window} ->
          {request,
           RateLimited.exception(
             module: validated.module,
             key: validated.key,
             scale: validated.scale,
             limit: validated.limit,
             cost: validated.cost,
             delay: ms_until_next_window
           )}
      end
    end
  end

  defp fetch_options(%Req.Request{} = request) do
    if options = request.options[:rate_limit] do
      {:cont, options}
    else
      request
    end
  end

  defp validate_options(%Req.Request{} = request, options) do
    try do
      options = Keyword.validate!(options, [:module, :key, :scale, :limit, cost: 1])
      {:cont, Map.new(options)}
    rescue
      exception in [ArgumentError] -> {request, exception}
    end
  end
end
