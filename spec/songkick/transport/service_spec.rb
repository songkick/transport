require "spec_helper"

describe Songkick::Transport::Service do
  let(:http) { double(described_class::DEFAULT_TRANSPORT) }

  before do
    described_class.set_endpoints 'foo' => 'nonsuch:1111'
    described_class.user_agent described_class.to_s

    allow(described_class::DEFAULT_TRANSPORT).to receive(:new).and_return(http)
    allow(http).to receive(:with_headers).and_return(http)
  end

  describe "given a Service class hierarchy" do
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

      expect(http).to receive(:with_headers).with("S" => "sss", "B" => "bbb", "A" => "aaa")
      B.new.http
    end

    it "can change headers" do
      Songkick::Transport::Service.with_headers "S" => "sss"
      Songkick::Transport::Service.with_headers "STS" => "sts"
      B.with_headers "B" => "bbb"
      A.with_headers "A" => "aaa"

      expect(http).to receive(:with_headers).with("STS" => "sts", "B" => "bbb", "A" => "aaa")
      B.new.http
    end

    context 'with transport layer options' do
      let(:given_options) { {:foo => 'bar'} }

      before { A.transport_layer_options given_options }

      it "can pass arbitrary options to the underlying transport adapter" do
        expect(described_class::DEFAULT_TRANSPORT).to receive(:new).with(anything, hash_including(given_options))
        B.new.http
      end
    end
  end
end
