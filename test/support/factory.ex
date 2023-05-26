defmodule Tokenex.Support.Factory do
  use ExMachina

  def token_attrs_factory do
    %{
      "access_token" => "access_token",
      "expires_in" => 1200,
      "token_type" => "bearer"
    }
  end
end
