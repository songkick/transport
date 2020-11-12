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

      context 'when the error is a HttpError with status code 503' do
        let(:error) { Songkick::Transport::HttpError.new(nil, '503', {}, '') }

        it 'should increment the counter for that error' do
          expect(subject).to receive(:increment_error_counter)
          subject.log(error, nil)
        end
      end
    end

    context 'when the supplied error should not be logged' do
      let(:error) { Songkick::Transport::InvalidJSONError.new(nil) }

      it 'should increment the counter for that error' do
        expect(subject).not_to receive(:increment_error_counter)
        subject.log(error, nil)
      end

      context 'when the error is a HttpError not with status code 503' do
        let(:error) { Songkick::Transport::HttpError.new(nil, '400', {}, '') }

        it 'should increment the counter for that error' do
          expect(subject).not_to receive(:increment_error_counter)
          subject.log(error, nil)
        end
      end
    end
  end

  describe '.increment_error_counter' do
    let(:error) { Songkick::Transport::TimeoutError.new(nil) }
    let(:target_host) { 'media-service.songkick.net:9201' }
    let(:request) do
      double(
        Songkick::Transport::Request,
        endpoint: target_host,
        path: '/users',
        verb: 'GET'
      )
    end

    before do
      allow(subject).to receive(:error_counter).and_return(error_counter)
      allow(Songkick::Transport::Service).to receive(:get_endpoints).and_return({
        'media-service' => 'media-service.songkick.net:9201'
      })
    end

    context 'when there is no songkick-instruments counter' do
      let(:error_counter) { nil }

      it 'does not error' do
        subject.increment_error_counter(error, request)
      end
    end

    context 'when there is a songkick-instruments counter' do
      let(:error_counter) { double('Songkick::Instruments.counter') }

      it 'increments it with the request information' do
        expect(error_counter).to receive(:increment).with(labels: hash_including(
          error: 'TimeoutError',
          target_service: 'media-service',
          path: 'users',
          verb: request.verb
        ))

        subject.increment_error_counter(error, request)
      end

      context 'if the request is not to a Songkick service' do
        let(:target_host) { 'api.spotify.com' }

        it 'includes the request target host instead' do
          expect(error_counter).to receive(:increment).with(labels: hash_including(
            error: 'TimeoutError',
            target_service: target_host,
            path: 'users',
            verb: request.verb
          ))

          subject.increment_error_counter(error, request)
        end
      end
    end
  end

  describe '.error_counter' do
    context 'when the containing project does not include songkick-instruments' do
      it 'returns nil' do
        expect(subject.error_counter).to be_nil
      end
    end

    context 'when the containing project includes songkick-instruments' do
      let(:counter) { double('Songkick::Instruments.counter') }
      it 'creates the counter' do
        subject.error_counter
      end
    end
  end

  describe '.service_name' do
    before do
      allow(Songkick::Transport::Service).to receive(:get_endpoints).and_return({
        'media-service' => 'media-service.songkick.net:9201'
      })
    end

    context 'when the endpoint is for a known service' do
      it 'returns the service name' do
        expect(subject.service_name('media-service.songkick.net:9201')).to eq('media-service')
      end
    end

    context 'when the endpoint is not for a known service' do
      it 'returns the endpoint itself' do
        expect(subject.service_name('api.spotify.com')).to eq('api.spotify.com')
      end
    end
  end

  describe '.sanitize_path' do
    context 'when the path includes digits' do
      it 'replaces the digits with a token' do
        expect(subject.sanitize_path('/artists/161083/calendar')).to eq('artists._id.calendar')
      end
    end

    it 'replaces slashes with dots' do
      expect(subject.sanitize_path('/artists/lookup')).to eq('artists.lookup')
    end

    it 'removes the leading namespace dot' do
      expect(subject.sanitize_path('/artists/lookup')).not_to start_with('.')
    end
  end

  describe '.error_name' do
    let(:error) { Songkick::Transport::TimeoutError.new(nil) }
    it 'extracts the class name from a given error' do
      expect(subject.error_name(error)).to eq('TimeoutError')
    end
  end
end
