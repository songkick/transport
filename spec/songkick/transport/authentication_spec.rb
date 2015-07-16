require 'spec_helper'

describe Songkick::Transport::Authentication do
  def basic_auth_headers(*args)
    Songkick::Transport::Authentication.basic_auth_headers(*args)
  end

  def strict_encode64(*args)
    Songkick::Transport::Authentication.strict_encode64(*args)
  end

  describe "given basic auth credentials" do
    let(:credentials) { {:username => "foo", :password => "baz"} } 
    let(:headers) { basic_auth_headers(credentials) }
    let(:encoded_credendials) { strict_encode64 "#{credentials[:username]}:#{credentials[:password]}"}

    it "encodes the credentials correctly" do
      expected_encoded_credentials = "Zm9vOmJheg=="
      expect(encoded_credendials).to eq(expected_encoded_credentials)
    end

    it "gets correct headers" do
      expected_auth_headers = Songkick::Transport::Headers.new({"Authorization" => "Basic Zm9vOmJheg=="})
      expect(headers).to eq(expected_auth_headers)
    end

  end
end
