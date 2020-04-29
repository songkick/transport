require 'spec_helper'

describe Songkick::Transport::Metrics do
  subject { described_class }

  describe '.log' do
    context 'when the supplied error should be logged' do
      let(:error) { Songkick::Transport::HostResolutionError.new(nil) }

      it 'should increment the counter for that error' do
        expect(subject).to receive(:increment_error_counter)
        subject.log(error, nil)
      end
    end

    context 'when the supplied error should not be logged' do
      let(:error) { Songkick::Transport::InvalidJSONError.new(nil) }

      it 'should increment the counter for that error' do
        expect(subject).not_to receive(:increment_error_counter)
        subject.log(error, nil)
      end
    end
  end

  describe '.increment_error_counter' do
    let(:error) { double(Songkick::Transport::TimeoutError) }
    let(:request) do
      double(
        Songkick::Transport::Request,
        endpoint: 'media-service',
        path: '/',
        verb: 'GET'
      )
    end

    before do
      allow(subject).to receive(:error_counter).and_return(error_counter)
    end

    context 'when there is no prometheus counter' do
      let(:error_counter) { nil }

      it 'does not error' do
        subject.increment_error_counter(error, request)
      end
    end

    context 'when there is a prometheus counter' do
      let(:error_counter) { double('Prometheus::Client::Counter') }

      it 'increments it with the request information' do
        expect(error_counter).to receive(:increment).with(labels: hash_including(
          error: error.class,
          endpoint: request.endpoint,
          path: request.path,
          verb: request.verb
        ))

        subject.increment_error_counter(error, request)
      end
    end
  end

  describe '.error_counter' do
    context 'when the containing project does not include the Prometheus Client library' do
      it 'returns nil' do
        expect(subject.error_counter).to be_nil
      end
    end

    context 'when the containing project includes the Prometheus Client library' do
      let(:registry) { double('Prometheus::Client::Registry') }
      let(:counter) { double('Prometheus::Client::Counter') }
      let(:client_class) { class_double('Prometheus::Client').as_stubbed_const(transfer_nested_constants: true) }
      let(:counter_class) { class_double('Prometheus::Client::Counter').as_stubbed_const(transfer_nested_constants: true) }
      before do
        allow(client_class).to receive(:registry).and_return(registry)
      end

      it 'creates the counter and registers it' do
        expect(counter_class).to receive(:new).and_return(counter)
        expect(registry).to receive(:register).with(counter)

        subject.error_counter
      end

      it 'does not recreate the counter when subsequent metrics are logged' do
        subject.error_counter

        expect(counter_class).not_to receive(:new)
        expect(registry).not_to receive(:register)

        subject.error_counter
      end
    end
  end
end
