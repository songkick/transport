require "spec_helper"

describe Songkick::Transport::Service do
  let(:http) { double(described_class::DEFAULT_TRANSPORT) }

  before do
    described_class.set_endpoints 'foo' => 'nonsuch:1111'
    described_class.user_agent described_class.to_s

    allow(described_class::DEFAULT_TRANSPORT).to receive(:new).and_return(http)
    allow(http).to receive(:with_headers).and_return(http)
  end

  class TestService < Songkick::Transport::Service
    endpoint :foo
  end

  class TestServiceWithoutEndpointName < Songkick::Transport::Service
  end

  class TestServiceWithoutEndpoint < Songkick::Transport::Service
    endpoint :bar
  end

  describe '#get_endpoint' do
    it 'returns the endpoint for the given endpoint name' do
      expect(TestService.get_endpoint).to eq('nonsuch:1111')
    end

    it 'raises an error if the endpoint does not exist in the given config' do
      expect { TestServiceWithoutEndpoint.get_endpoint }.to raise_error(StandardError)
    end
  end

  describe '#get_endpoint_name' do
    it 'returns the endpoint name' do
      expect(TestService.get_endpoint_name).to eq('foo')
    end

    it 'raises an error if the endpoint is not given' do
      expect { TestServiceWithoutEndpointName.get_endpoint_name }.to raise_error(StandardError)
    end
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
      let(:global_options) { {:foo => 'bar'} }
      let(:upper_options)  { {:bar => 'baz'} }
      let(:lower_options)  { {:bar => 'qux'} }

      before do
        Songkick::Transport::Service.transport_layer_options global_options
        A.transport_layer_options upper_options
        B.transport_layer_options lower_options
      end

      it "global options can be specified and are passed to the transport initializer" do
        expect(described_class::DEFAULT_TRANSPORT).to receive(:new).with(anything, hash_including(global_options))
        B.new.http
      end

      it "options can be specified per-class and are passed to the transport initializer" do
        expect(described_class::DEFAULT_TRANSPORT).to receive(:new).with(anything, hash_including(upper_options))
        A.new.http
      end

      it "options can be overridden per-class and are passed to the transport initializer" do
        expect(described_class::DEFAULT_TRANSPORT).not_to receive(:new).with(anything, hash_including(upper_options))
        expect(described_class::DEFAULT_TRANSPORT).to receive(:new).with(anything, hash_including(lower_options))
        B.new.http
      end
    end
  end
end
