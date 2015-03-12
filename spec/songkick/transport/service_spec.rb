require "spec_helper"

describe Songkick::Transport::Service do
  before do
    Songkick::Transport::Service.set_endpoints 'foo' => "nonsuch:1111"
    Songkick::Transport::Service.user_agent "fest"
  end

  describe "headers on class hierarchy" do
    class A < Songkick::Transport::Service
      endpoint :foo
    end

    class B < A
      endpoint :foo
    end


    it "should inherit headers all the way down the class hierarchy" do
      Songkick::Transport::Service.with_headers "S" => "sss"
      B.with_headers "B" => "bbb"
      A.with_headers "A" => "aaa"

      http = double("http")
      B.stub_transport(http)

      http.should_receive(:with_headers).with("S" => "sss", "B" => "bbb", "A" => "aaa")
      B.new.http
    end

    it "can change headers" do
      Songkick::Transport::Service.with_headers "S" => "sss"
      Songkick::Transport::Service.with_headers "STS" => "sts"
      B.with_headers "B" => "bbb"
      A.with_headers "A" => "aaa"

      http = double("http")
      B.stub_transport(http)

      http.should_receive(:with_headers).with("STS" => "sts", "B" => "bbb", "A" => "aaa")
      B.new.http
    end
  end
end

