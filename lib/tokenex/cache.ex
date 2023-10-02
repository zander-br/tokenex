defmodule Tokenex.Cache do
  use GenServer

  alias Tokenex.{Registry, Token}
  alias __MODULE__

  def start_link(opts) do
    adapter = opts[:adapter]
    auto = Keyword.get(opts, :auto, false)
    state = %{adapter: adapter, attempt: 1, auto: auto, token: nil, opts: opts}
    GenServer.start_link(Cache, state, name: opts[:name])
  end

  @impl GenServer
  def init(state) do
    state = refresh_token(state)
    {:ok, state}
  end

  @spec get_access_token(adapter :: module()) :: binary()
  def get_access_token(adapter) do
    server = Registry.via(adapter)
    GenServer.call(server, :get_access_token)
  end

  @impl GenServer
  def handle_call(:get_access_token, _from, state) do
    new_state = %{token: %Token{access_token: access_token}} = get_token(state)
    response = {:ok, access_token}
    {:reply, response, new_state}
  end

  @impl GenServer
  def handle_info(:refresh_token, state) do
    %{adapter: adapter, attempt: attempt, opts: opts} = state

    case adapter.refresh_token() do
      {:ok, %Token{expires_in: expires_in} = token} ->
        now = :os.system_time(:second)
        schedule_refresh(expires_in)
        token = %Token{token | expires_in: now + expires_in}
        new_state = %{state | token: token, attempt: 1}
        {:noreply, new_state}

      {:error, _reason} ->
        backoff = exponential(attempt, opts)
        schedule_refresh(backoff)
        new_state = %{state | attempt: attempt + 1}
        {:noreply, new_state}
    end
  end

  def exponential(attempt, opts \\ []) do
    max_pow = Keyword.get(opts, :max_pow, 10)
    min_pad = Keyword.get(opts, :min_pad, 0)
    mult = Keyword.get(opts, :mult, 1)

    min_pad + mult * Integer.pow(2, min(attempt, max_pow))
  end

  defp get_token(%{token: token} = state) do
    %Token{expires_in: expires_in} = token

    if has_expired?(expires_in) do
      refresh_token(state)
    else
      state
    end
  end

  defp has_expired?(expires_in) do
    now = :os.system_time(:second)
    expires_in < now + 1
  end

  defp refresh_token(%{adapter: adapter, auto: true} = state) do
    {:ok, token} = adapter.refresh_token()
    now = :os.system_time(:second)
    schedule_refresh(token.expires_in)
    token = %Token{token | expires_in: now + token.expires_in}
    %{state | token: token}
  end

  defp refresh_token(%{adapter: adapter} = state) do
    {:ok, token} = adapter.refresh_token()
    now = :os.system_time(:second)
    token = %Token{token | expires_in: now + token.expires_in}
    %{state | token: token}
  end

  defp schedule_refresh(refresh_in) do
    dest = self()
    Process.send_after(dest, :refresh_token, refresh_in * 1000)
  end
end
