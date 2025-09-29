defmodule Verita.AuthorizationRequest do
  @moduledoc """
  An authorization request struct for OAuth 2.0 Authorization Code Grant.

  Per [RFC 6749 Section 4.1.1](https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.1),
  the authorization request can be constructed using the following parameters:

  1. `response_type` - REQUIRED. Value MUST be set to "code"
  2. `client_id` - REQUIRED. The client identifier as described in
     [Section 2.2](https://datatracker.ietf.org/doc/html/rfc6749#section-2.2)
  3. `redirect_uri` - OPTIONAL. As described in
     [Section 3.1.2](https://datatracker.ietf.org/doc/html/rfc6749#section-3.1.2)
  4. `scope` - OPTIONAL. The scope of the access request as described in
     [Section 3.3](https://datatracker.ietf.org/doc/html/rfc6749#section-3.3)
  5. `state` - RECOMMENDED. An opaque value used by the client to maintain state
     between the request and callback. Should be used for preventing CSRF attacks
     as described in [Section 10.12](https://datatracker.ietf.org/doc/html/rfc6749#section-10.12)

  """

  @enforce_keys [:response_type, :client_id]
  defstruct [
    :response_type,
    :client_id,
    :redirect_uri,
    :scope,
    :state
  ]

  @type t :: %__MODULE__{
          response_type: String.t(),
          client_id: String.t(),
          redirect_uri: String.t() | nil,
          scope: String.t() | list(String.t()) | nil,
          state: String.t() | nil
        }

  @doc """
  Creates a new authorization request.

  ## Parameters

    * `client_id` - Required. The client identifier
      ([RFC 6749 Section 2.2](https://datatracker.ietf.org/doc/html/rfc6749#section-2.2))
    * `opts` - Optional keyword list with:
      * `:redirect_uri` - The redirect URI
        ([Section 3.1.2](https://datatracker.ietf.org/doc/html/rfc6749#section-3.1.2))
      * `:scope` - The requested scope (string or list of strings)
        ([Section 3.3](https://datatracker.ietf.org/doc/html/rfc6749#section-3.3))
      * `:state` - An opaque value for CSRF protection
        ([Section 10.12](https://datatracker.ietf.org/doc/html/rfc6749#section-10.12))

  ## Examples

      iex> Verita.AuthorizationRequest.new("my_client_id")
      {:ok, %Verita.AuthorizationRequest{
        response_type: "code",
        client_id: "my_client_id",
        redirect_uri: nil,
        scope: nil,
        state: nil
      }}

      iex> Verita.AuthorizationRequest.new("my_client_id",
      ...>   redirect_uri: "https://example.com/callback",
      ...>   scope: ["read", "write"],
      ...>   state: "xyz"
      ...> )
      {:ok, %Verita.AuthorizationRequest{
        response_type: "code",
        client_id: "my_client_id",
        redirect_uri: "https://example.com/callback",
        scope: ["read", "write"],
        state: "xyz"
      }}

      iex> Verita.AuthorizationRequest.new("")
      {:error, :invalid_client_id}

  ## References

  - [RFC 6749 Section 4.1.1 - Authorization Request](https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.1)
  """
  @spec new(String.t(), keyword()) :: {:ok, t()} | {:error, atom()}
  def new(client_id, opts \\ []) do
    with :ok <- validate_client_id(client_id),
         {:ok, redirect_uri} <- validate_redirect_uri(opts[:redirect_uri]),
         {:ok, scope} <- validate_scope(opts[:scope]),
         {:ok, state} <- validate_state(opts[:state]) do
      {:ok,
       %__MODULE__{
         response_type: "code",
         client_id: client_id,
         redirect_uri: redirect_uri,
         scope: normalize_scope(scope),
         state: state
       }}
    end
  end

  @doc """
  Creates a new authorization request, raising on error.

  ## Examples

      iex> Verita.AuthorizationRequest.new!("my_client_id")
      %Verita.AuthorizationRequest{response_type: "code", client_id: "my_client_id"}

      iex> Verita.AuthorizationRequest.new!("")
      ** (ArgumentError) invalid client_id: must be a non-empty string
  """
  @spec new!(String.t(), keyword()) :: t()
  def new!(client_id, opts \\ []) do
    case new(client_id, opts) do
      {:ok, request} ->
        request

      {:error, reason} ->
        raise ArgumentError, format_error(reason)
    end
  end

  @doc """
  Converts the authorization request to a query string.

  The query string is formatted according to
  [RFC 6749 Section 4.1.1](https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.1).

  ## Examples

      iex> request = Verita.AuthorizationRequest.new!("client123",
      ...>   redirect_uri: "https://example.com/cb",
      ...>   scope: ["read", "write"],
      ...>   state: "abc"
      ...> )
      iex> Verita.AuthorizationRequest.to_query_string(request)
      "scope=read+write&state=abc&response_type=code&client_id=client123&redirect_uri=https%3A%2F%2Fexample.com%2Fcb"
  """
  @spec to_query_string(t()) :: String.t()
  def to_query_string(%__MODULE__{} = request) do
    request
    |> to_params()
    |> URI.encode_query()
  end

  @doc """
  Converts the authorization request to a map of parameters.

  ## Examples

      iex> request = Verita.AuthorizationRequest.new!("client123")
      iex> Verita.AuthorizationRequest.to_params(request)
      %{response_type: "code", client_id: "client123"}
  """
  @spec to_params(t()) :: map()
  def to_params(%__MODULE__{} = request) do
    %{response_type: request.response_type, client_id: request.client_id}
    |> maybe_put(:redirect_uri, request.redirect_uri)
    |> maybe_put(:scope, format_scope(request.scope))
    |> maybe_put(:state, request.state)
  end

  @doc """
  Builds the full authorization URL.

  Constructs the authorization endpoint URL as described in
  [RFC 6749 Section 4.1.1](https://datatracker.ietf.org/doc/html/rfc6749#section-4.1.1).

  ## Examples

      iex> request = Verita.AuthorizationRequest.new!("client123", state: "xyz")
      iex> Verita.AuthorizationRequest.to_url(request, "https://auth.example.com/authorize")
      "https://auth.example.com/authorize?state=xyz&response_type=code&client_id=client123"
  """
  @spec to_url(t(), String.t()) :: String.t()
  def to_url(%__MODULE__{} = request, base_url) do
    query_string = to_query_string(request)
    "#{base_url}?#{query_string}"
  end

  # Private functions

  defp validate_client_id(client_id) when is_binary(client_id) and byte_size(client_id) > 0,
    do: :ok

  defp validate_client_id(_), do: {:error, :invalid_client_id}

  defp validate_redirect_uri(nil), do: {:ok, nil}

  defp validate_redirect_uri(uri) when is_binary(uri) do
    case URI.parse(uri) do
      %URI{scheme: scheme, host: host} when scheme in ["http", "https"] and not is_nil(host) ->
        {:ok, uri}

      _ ->
        {:error, :invalid_redirect_uri}
    end
  end

  defp validate_redirect_uri(_), do: {:error, :invalid_redirect_uri}

  defp validate_scope(nil), do: {:ok, nil}
  defp validate_scope(scope) when is_binary(scope), do: {:ok, scope}

  defp validate_scope(scope) when is_list(scope) do
    if Enum.all?(scope, &is_binary/1) do
      {:ok, scope}
    else
      {:error, :invalid_scope}
    end
  end

  defp validate_scope(_), do: {:error, :invalid_scope}

  defp validate_state(nil), do: {:ok, nil}
  defp validate_state(state) when is_binary(state), do: {:ok, state}
  defp validate_state(_), do: {:error, :invalid_state}

  defp normalize_scope(scope) when is_list(scope), do: scope
  defp normalize_scope(scope) when is_binary(scope), do: String.split(scope, " ", trim: true)
  defp normalize_scope(nil), do: nil

  defp format_scope(nil), do: nil
  defp format_scope(scope) when is_list(scope), do: Enum.join(scope, " ")
  defp format_scope(scope) when is_binary(scope), do: scope

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp format_error(:invalid_client_id),
    do: "invalid client_id: must be a non-empty string"

  defp format_error(:invalid_redirect_uri),
    do: "invalid redirect_uri: must be a valid HTTP or HTTPS URL"

  defp format_error(:invalid_scope),
    do: "invalid scope: must be a string or list of strings"

  defp format_error(:invalid_state),
    do: "invalid state: must be a string"
end
