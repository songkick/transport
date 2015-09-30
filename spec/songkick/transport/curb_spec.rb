require 'spec_helper'

module Songkick
  module Transport

    describe Curb do
      after { described_class.clear_thread_connection }

      subject { described_class.new('localhost', :connection => curl) }
      let(:request) { Request.new('http://localhost', 'get', '/', {}) }

      def self.it_should_raise(exception)
        it "should raise error #{exception}" do
          expect { subject.execute_request(request) }.to raise_error(exception)
        end
      end

      def self.when_request_raises_the_exception(raised_exception, &block)
        describe "when request raises a #{raised_exception}" do
          let(:curl) { instance_double(Curl::Easy, :headers => {}).as_null_object }

          before { allow(curl).to receive(:http).and_raise(raised_exception) }

          class_exec(&block)
        end
      end

      describe 'handling errors' do
        when_request_raises_the_exception(Curl::Err::HostResolutionError)   { it_should_raise(Transport::HostResolutionError)   }
        when_request_raises_the_exception(Curl::Err::ConnectionFailedError) { it_should_raise(Transport::ConnectionFailedError) }
        when_request_raises_the_exception(Curl::Err::TimeoutError)          { it_should_raise(Transport::TimeoutError)          }
        when_request_raises_the_exception(Curl::Err::GotNothingError)       { it_should_raise(Transport::UpstreamError)         }
        when_request_raises_the_exception(Curl::Err::RecvError)             { it_should_raise(Transport::UpstreamError)         }
      end

      describe 'headers parsing' do
        let(:curl) { instance_double(Curl::Easy, :response_code => 200, :headers => {}).as_null_object }

        it 'should join multiple headers to one' do
          allow(curl).to receive(:on_header).and_yield('Set-Cookie: a').and_yield('Set-Cookie: b')

          response = subject.execute_request(request)
          expect(response.headers['Set-Cookie']).to eq 'a, b'
        end
      end
    end

  end
end
