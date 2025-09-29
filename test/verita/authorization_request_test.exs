defmodule Verita.AuthorizationRequestTest do
  use ExUnit.Case
  alias Verita.AuthorizationRequest

  describe "new!/1" do
    test "empty string identifier throws argument error" do
      assert_raise ArgumentError, "invalid client_id: must be a non-empty string", fn ->
        AuthorizationRequest.new!("")
      end
    end

    test "a non string identifier throws argument error" do
      assert_raise ArgumentError, "invalid client_id: must be a non-empty string", fn ->
        AuthorizationRequest.new!(1)
      end

      assert_raise ArgumentError, "invalid client_id: must be a non-empty string", fn ->
        AuthorizationRequest.new!(nil)
      end

      assert_raise ArgumentError, "invalid client_id: must be a non-empty string", fn ->
        AuthorizationRequest.new!(1.1)
      end

      assert_raise ArgumentError, "invalid client_id: must be a non-empty string", fn ->
        AuthorizationRequest.new!(:a)
      end
    end

    test "string identifier is valid" do
      assert AuthorizationRequest.new!("a") == %AuthorizationRequest{
               client_id: "a",
               redirect_uri: nil,
               response_type: "code",
               scope: nil,
               state: nil
             }
    end
  end

  describe "new/1" do
    test "empty string identifier returns {:error, :invalid_client_id}" do
      assert AuthorizationRequest.new("") == {:error, :invalid_client_id}
    end

    test "a non string identifier returns {:error, :invalid_client_id}" do
      assert AuthorizationRequest.new(1) == {:error, :invalid_client_id}

      assert AuthorizationRequest.new(nil) == {:error, :invalid_client_id}

      assert AuthorizationRequest.new(1.1) == {:error, :invalid_client_id}

      assert AuthorizationRequest.new(:a) == {:error, :invalid_client_id}
    end

    test "string identifier is valid" do
      assert AuthorizationRequest.new("a") ==
               {:ok,
                %AuthorizationRequest{
                  client_id: "a",
                  redirect_uri: nil,
                  response_type: "code",
                  scope: nil,
                  state: nil
                }}
    end
  end

  describe "new/2" do
    test "scope contains a non binary item returns {:error, :invalid_scope}" do
      assert AuthorizationRequest.new("andimon", scope: ["admin", 1]) == {:error, :invalid_scope}
    end

    test "scope with binary items is valid" do
      assert AuthorizationRequest.new("andimon", scope: ["Notes", "Calender"]) == {
               :ok,
               %AuthorizationRequest{
                 scope: ["Notes", "Calender"],
                 state: nil,
                 client_id: "andimon",
                 redirect_uri: nil,
                 response_type: "code"
               }
             }
    end

    test "binary scope is valid" do
      assert AuthorizationRequest.new("andimon", scope: "Calender") == {
               :ok,
               %AuthorizationRequest{
                 scope: ["Calender"],
                 state: nil,
                 client_id: "andimon",
                 redirect_uri: nil,
                 response_type: "code"
               }
             }
    end

    test "binary scope with spaces is split into list" do
      assert AuthorizationRequest.new("andimon", scope: "read write admin") == {
               :ok,
               %AuthorizationRequest{
                 scope: ["read", "write", "admin"],
                 state: nil,
                 client_id: "andimon",
                 redirect_uri: nil,
                 response_type: "code"
               }
             }
    end

    test "non-string scope returns {:error, :invalid_scope}" do
      assert AuthorizationRequest.new("andimon", scope: 123) == {:error, :invalid_scope}
      assert AuthorizationRequest.new("andimon", scope: :atom) == {:error, :invalid_scope}
    end

    test "valid redirect_uri is accepted" do
      assert AuthorizationRequest.new("andimon", redirect_uri: "https://example.com/callback") ==
               {
                 :ok,
                 %AuthorizationRequest{
                   scope: nil,
                   state: nil,
                   client_id: "andimon",
                   redirect_uri: "https://example.com/callback",
                   response_type: "code"
                 }
               }
    end

    test "http redirect_uri is accepted" do
      assert AuthorizationRequest.new("andimon", redirect_uri: "http://localhost:3000/callback") ==
               {
                 :ok,
                 %AuthorizationRequest{
                   scope: nil,
                   state: nil,
                   client_id: "andimon",
                   redirect_uri: "http://localhost:3000/callback",
                   response_type: "code"
                 }
               }
    end

    test "invalid redirect_uri returns {:error, :invalid_redirect_uri}" do
      assert AuthorizationRequest.new("andimon", redirect_uri: "not-a-url") ==
               {:error, :invalid_redirect_uri}

      assert AuthorizationRequest.new("andimon", redirect_uri: "ftp://example.com") ==
               {:error, :invalid_redirect_uri}

      assert AuthorizationRequest.new("andimon", redirect_uri: 123) ==
               {:error, :invalid_redirect_uri}
    end

    test "valid state is accepted" do
      assert AuthorizationRequest.new("andimon", state: "xyz123") == {
               :ok,
               %AuthorizationRequest{
                 scope: nil,
                 state: "xyz123",
                 client_id: "andimon",
                 redirect_uri: nil,
                 response_type: "code"
               }
             }
    end

    test "non-string state returns {:error, :invalid_state}" do
      assert AuthorizationRequest.new("andimon", state: 123) == {:error, :invalid_state}
      assert AuthorizationRequest.new("andimon", state: :atom) == {:error, :invalid_state}
    end

    test "all valid options together" do
      assert AuthorizationRequest.new("andimon",
               redirect_uri: "https://example.com/callback",
               scope: ["read", "write"],
               state: "abc123"
             ) == {
               :ok,
               %AuthorizationRequest{
                 scope: ["read", "write"],
                 state: "abc123",
                 client_id: "andimon",
                 redirect_uri: "https://example.com/callback",
                 response_type: "code"
               }
             }
    end
  end

  describe "new!/2" do
    test "raises ArgumentError for invalid redirect_uri" do
      assert_raise ArgumentError,
                   "invalid redirect_uri: must be a valid HTTP or HTTPS URL",
                   fn ->
                     AuthorizationRequest.new!("andimon", redirect_uri: "not-a-url")
                   end
    end

    test "raises ArgumentError for invalid scope" do
      assert_raise ArgumentError, "invalid scope: must be a string or list of strings", fn ->
        AuthorizationRequest.new!("andimon", scope: 123)
      end
    end

    test "raises ArgumentError for invalid state" do
      assert_raise ArgumentError, "invalid state: must be a string", fn ->
        AuthorizationRequest.new!("andimon", state: 123)
      end
    end

    test "creates request with all valid options" do
      assert AuthorizationRequest.new!("andimon",
               redirect_uri: "https://example.com/callback",
               scope: ["read", "write"],
               state: "xyz"
             ) == %AuthorizationRequest{
               scope: ["read", "write"],
               state: "xyz",
               client_id: "andimon",
               redirect_uri: "https://example.com/callback",
               response_type: "code"
             }
    end
  end

  describe "to_params/1" do
    test "converts basic request to params" do
      request = AuthorizationRequest.new!("client123")

      assert AuthorizationRequest.to_params(request) == %{
               response_type: "code",
               client_id: "client123"
             }
    end

    test "includes optional fields when present" do
      request =
        AuthorizationRequest.new!("client123",
          redirect_uri: "https://example.com/cb",
          scope: ["read", "write"],
          state: "abc"
        )

      assert AuthorizationRequest.to_params(request) == %{
               response_type: "code",
               client_id: "client123",
               redirect_uri: "https://example.com/cb",
               scope: "read write",
               state: "abc"
             }
    end

    test "formats scope list as space-separated string" do
      request = AuthorizationRequest.new!("client123", scope: ["one", "two", "three"])

      params = AuthorizationRequest.to_params(request)
      assert params.scope == "one two three"
    end
  end

  describe "to_query_string/1" do
    test "converts basic request to query string" do
      request = AuthorizationRequest.new!("client123")
      query = AuthorizationRequest.to_query_string(request)

      assert query =~ "response_type=code"
      assert query =~ "client_id=client123"
    end

    test "includes all parameters in query string" do
      request =
        AuthorizationRequest.new!("client123",
          redirect_uri: "https://example.com/cb",
          scope: ["read", "write"],
          state: "abc"
        )

      query = AuthorizationRequest.to_query_string(request)

      assert query =~ "response_type=code"
      assert query =~ "client_id=client123"
      assert query =~ "redirect_uri=https%3A%2F%2Fexample.com%2Fcb"
      assert query =~ "scope=read+write"
      assert query =~ "state=abc"
    end

    test "properly encodes special characters" do
      request =
        AuthorizationRequest.new!("client123",
          redirect_uri: "https://example.com/callback?foo=bar",
          state: "state with spaces"
        )

      query = AuthorizationRequest.to_query_string(request)

      assert query =~ "redirect_uri=https%3A%2F%2Fexample.com%2Fcallback%3Ffoo%3Dbar"
      assert query =~ "state=state+with+spaces"
    end
  end

  describe "to_url/2" do
    test "builds complete authorization URL" do
      request = AuthorizationRequest.new!("client123", state: "xyz")
      url = AuthorizationRequest.to_url(request, "https://auth.example.com/authorize")

      assert url =~ "https://auth.example.com/authorize?"
      assert url =~ "response_type=code"
      assert url =~ "client_id=client123"
      assert url =~ "state=xyz"
    end

    test "handles base URL without trailing slash" do
      request = AuthorizationRequest.new!("client123")
      url = AuthorizationRequest.to_url(request, "https://auth.example.com/oauth/authorize")

      assert String.starts_with?(url, "https://auth.example.com/oauth/authorize?")
    end

    test "builds URL with all parameters" do
      request =
        AuthorizationRequest.new!("client123",
          redirect_uri: "https://app.example.com/callback",
          scope: ["read", "write", "admin"],
          state: "secure-state-123"
        )

      url = AuthorizationRequest.to_url(request, "https://auth.example.com/authorize")

      assert url =~ "https://auth.example.com/authorize?"
      assert url =~ "client_id=client123"
      assert url =~ "response_type=code"
      assert url =~ "redirect_uri=https%3A%2F%2Fapp.example.com%2Fcallback"
      assert url =~ "scope=read+write+admin"
      assert url =~ "state=secure-state-123"
    end
  end
end
