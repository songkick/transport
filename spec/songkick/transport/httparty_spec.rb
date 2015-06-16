require 'spec_helper'

module Songkick
  module Transport

    describe HttParty do
      class FakeJSONException < Exception; end

      let(:request){ Request.new('http://localhost', 'get', '/', {}) }

      describe "handling errors" do
        class FakeHttparty < Songkick::Transport::HttParty::Adapter
          class << self
            attr_accessor :error
          end

          def self.get(path, args)
            raise(error, "bang") if error
          end

        end

        def self.it_should_raise(exception)
          it "should raise error #{exception}" do
            begin
              @httparty.execute_request(request)
            rescue => e
              expect(e.class).to eq(exception)
            end
          end
        end

        def self.when_request_raises_the_exception(raised_exception, &block)
          describe "when request raises a #{raised_exception}" do
            before(:each) do
              FakeHttparty.error = raised_exception
              @httparty = Songkick::Transport::HttParty.new('localhost', {:adapter => FakeHttparty})
            end

            class_exec(&block)
          end
        end

        describe "handling errors" do
          when_request_raises_the_exception(FakeJSONException) { it_should_raise(Transport::InvalidJSONError)      }
          when_request_raises_the_exception(SocketError)       { it_should_raise(Transport::ConnectionFailedError) }
          when_request_raises_the_exception(Timeout::Error)    { it_should_raise(Transport::TimeoutError)          }
          when_request_raises_the_exception(UpstreamError)     { it_should_raise(Transport::UpstreamError)         }
          when_request_raises_the_exception(Exception)         { it_should_raise(Transport::UpstreamError)         }
        end
      end
    end

  end
end
