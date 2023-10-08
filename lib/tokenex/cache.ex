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
  def init(%{adapter: adapter, auto: true} = state) do
    case refresh_token(adapter) do
      {:ok, %Token{expires_in: expires_in} = token} ->
        schedule_refresh(expires_in)
        {:ok, %{state | token: token}}

      {:error, _reason} ->
        {:ok, state}
    end
  end

  @impl GenServer
  def init(%{adapter: adapter} = state) do
    case refresh_token(adapter) do
      {:ok, token} -> {:ok, %{state | token: token}}
      {:error, _reason} -> {:ok, state}
    end
  end

  @spec get_access_token(adapter :: module()) :: binary()
  def get_access_token(adapter) do
    server = Registry.via(adapter)
    GenServer.call(server, :get_access_token)
  end

  @impl GenServer
  def handle_call(:get_access_token, _from, %{auto: true} = state) do
    %{token: token, adapter: adapter} = state
    %Token{access_token: access_token, expires_in: expires_in} = token

    if has_expired?(expires_in) do
      case refresh_token(adapter) do
        {:ok, %Token{access_token: access_token, expires_in: expires_in} = token} ->
          schedule_refresh(expires_in)
          response = {:ok, access_token}
          {:reply, response, %{state | token: token}}

        error ->
          {:reply, error, state}
      end
    else
      response = {:ok, access_token}
      {:reply, response, state}
    end
  end

  @impl GenServer
  def handle_call(:get_access_token, _from, state) do
    %{token: token, adapter: adapter} = state
    %Token{access_token: access_token, expires_timestamp: expires_timestamp} = token

    if has_expired?(expires_timestamp) do
      case refresh_token(adapter) do
        {:ok, %Token{access_token: access_token} = token} ->
          response = {:ok, access_token}
          {:reply, response, %{state | token: token}}

        error ->
          {:reply, error, state}
      end
    else
      response = {:ok, access_token}
      {:reply, response, state}
    end
  end

  @impl GenServer
  def handle_info(:refresh_token, state) do
    %{adapter: adapter, attempt: attempt, opts: opts} = state

    case refresh_token(adapter) do
      {:ok, %Token{expires_in: expires_in} = token} ->
        schedule_refresh(expires_in)
        new_state = %{state | token: token, attempt: 1}
        {:noreply, new_state}

      {:error, _reason} ->
        backoff = exponential(attempt, opts)
        schedule_refresh(backoff)
        new_state = %{state | attempt: attempt + 1}
        {:noreply, new_state}
    end
  end

  defp refresh_token(adapter) do
    case adapter.refresh_token() do
      {:ok, %Token{expires_in: expires_in} = token} ->
        now = :os.system_time(:second)
        token = %Token{token | expires_timestamp: now + expires_in}
        {:ok, token}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp exponential(attempt, opts) do
    max_pow = Keyword.get(opts, :max_pow, 10)
    min_pad = Keyword.get(opts, :min_pad, 0)
    mult = Keyword.get(opts, :mult, 1)

    min_pad + mult * Integer.pow(2, min(attempt, max_pow))
  end

  defp has_expired?(expires_timestamp) do
    now = :os.system_time(:second)
    expires_timestamp < now + 1
  end

  defp schedule_refresh(refresh_in) do
    dest = self()
    Process.send_after(dest, :refresh_token, refresh_in * 1000)
  end
end
