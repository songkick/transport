require 'spec_helper'

module Songkick
  module Transport

    describe Curb do
      after { Songkick::Transport::Curb.clear_thread_connection }

      subject{ Curb.new('localhost', :connection => @fake_curl) }
      let(:request){ Request.new('http://localhost', 'get', '/', {}) }

      def self.it_should_raise(exception)
        it "should raise error #{exception}" do
          begin
            subject.execute_request(request)
          rescue => e
            expect(e.class).to eq(exception)
          end
        end
      end

      def self.when_request_raises_the_exception(raised_exception, &block)
        describe "when request raises a #{raised_exception}" do
          before(:each) do
            @fake_curl = FakeCurl.new(:error => raised_exception)
          end

          class_exec(&block)
        end
      end

      describe "handling errors" do
        when_request_raises_the_exception(Curl::Err::HostResolutionError)  { it_should_raise(Transport::HostResolutionError)   }
        when_request_raises_the_exception(Curl::Err::ConnectionFailedError){ it_should_raise(Transport::ConnectionFailedError) }
        when_request_raises_the_exception(Curl::Err::TimeoutError)         { it_should_raise(Transport::TimeoutError)          }
        when_request_raises_the_exception(Curl::Err::GotNothingError)      { it_should_raise(Transport::UpstreamError)         }
      end
    end

  end
end
