require "spec_helper"

shared_examples_for "Songkick::Transport" do
  before(:all) { TestApp.listen(4567) }
  after(:all)  { TestApp.stop }

  describe "#get" do
    it "retrieves data using GET" do
      expect(transport.get("/artists/99").data).to eq({"id" => 99})
    end

    it "exposes the response headers" do
      expect(transport.get("/artists/99").headers["content-type"]).to eq("application/json")
    end

    it "can send array params" do
      expect(transport.get("/", :list => %w[a b]).data).to eq({"list" => ["a", "b"]})
    end

    it "can send hash params" do
      expect(transport.get("/", :list => {:a => "b"}).data).to eq({"list" => {"a" => "b"}})
    end

    it "can send nested data structures" do
      structure = {
        "hash" => {"a" => {"b" => ["c", "d"], "e" => "f"}},
        "lisp" => ["define", {"square" => ["x", "y"]}, "*", "x", "x"]
      }
      expect(transport.get("/", structure).data).to eq(structure)
    end

    it "raises an UpstreamError for a nonexistent resource" do
      expect { transport.get("/nothing") }.to raise_error(Songkick::Transport::UpstreamError)
    end

    it "raises an UpstreamError for a POST resource" do
      expect { transport.get("/artists") }.to raise_error(Songkick::Transport::UpstreamError)
    end

    it "raises an UpstreamError for invalid JSON" do
      expect { transport.get("/invalid") }.to raise_error(Songkick::Transport::InvalidJSONError)
    end

  end

  describe "#with_headers" do
    it "adds the given headers to requests" do
      data = transport.with_headers("Authorization" => "correct password").get("/authenticate").data
      expect(data).to eq({"successful" => true})
    end

    it "reformats Rack-style headers" do
      data = transport.with_headers("HTTP_AUTHORIZATION" => "correct password").get("/authenticate").data
      expect(data).to eq({"successful" => true})
    end

    it "does not affect requests made directly on the transport object" do
      transport.with_headers("Authorization" => "correct password").get("/authenticate")
      data = transport.get("/authenticate").data
      expect(data).to eq({"successful" => false})
    end

    it "can set Content-Type" do
      data = transport.with_headers("Content-Type" => "application/json").post("/content").data
      expect(data).to eq({"type" => "application/json"})
    end
  end

  describe "#options" do
    it "sends an OPTIONS request" do
      response = transport.options("/.well-known/host-meta")
      expect(response.headers["Access-Control-Allow-Methods"]).to eq("GET, PUT, DELETE")
    end
  end

  describe "#post" do
    it "sends data using POST" do
      data = transport.post("/artists", :name => "Amon Tobin").data
      expect(data).to eq({"id" => "new", "name" => "AMON TOBIN"})
    end

    it "can send array params" do
      expect(transport.post("/", :list => %w[a b]).data).to eq({"list" => ["a", "b"]})
    end

    it "can send hash params" do
      expect(transport.post("/", :list => {:a => "b"}).data).to eq({"list" => {"a" => "b"}})
    end

    it "can send a raw body" do
      response = transport.with_headers("Content-Type" => "text/plain").post("/process", "Hello, world!")
      expect(response.data).to eq({"body" => "Hello, world!", "type" => "text/plain"})
    end

    it "raises an UpstreamError for a PUT resource" do
      expect { transport.post("/artists/64") }.to raise_error(Songkick::Transport::UpstreamError)
    end
  end

  describe "#put" do
    it "sends data using PUT" do
      data = transport.put("/artists/64", :name => "Amon Tobin").data
      expect(data).to eq({"id" => 64, "name" => "amon tobin"})
    end

    it "raises an UpstreamError for a POST resource" do
      expect{transport.put("/artists")}.to raise_error(Songkick::Transport::UpstreamError)
    end
  end

  describe "file uploads" do
    after { file.close }

    let(:file)   { File.open(File.expand_path("../../songkick.png", __FILE__)) }
    let(:upload) { Songkick::Transport::IO.new(file, "image/jpeg", "songkick.png") }

    let :params do
      {:concert => {:file => upload, :foo => "me@thing.com"}}
    end

    let :expected_response do
      {
        "filename" => "songkick.png",
        "method"   => @http_method,
        "size"     => 6694,
        "foo"      => "me@thing.com"
      }
    end

    it "uploads files using POST" do
      if Songkick::Transport::RackTest === transport
      else
        @http_method = "post"
        response = transport.post('/upload', params)
        expect(response.status).to eq(200)
        expect(response.data).to eq(expected_response)
      end
    end

    it "uploads files using PUT" do
      if Songkick::Transport::RackTest === transport
      else
        @http_method = "put"
        response = transport.put('/upload', params)
        expect(response.status).to eq(200)
        expect(response.data).to eq(expected_response)
      end
    end
  end

  describe 'instrumentation' do
    let(:events) { [] }
    let(:options) { { :instrumenter => ActiveSupport::Notifications } }

    around do |example|
      label = options[:instrumentation_label] || Songkick::Transport::Base::DEFAULT_INSTRUMENTATION_LABEL
      options[:instrumenter].subscribed(subscriber, label) do
        example.run
      end
    end

    let(:subscriber) do
      lambda { |*args| events << options[:instrumenter]::Event.new(*args) }
    end

    context 'for a successful request' do
      let(:path) { '/artists/123' }

      let(:expected_payload) do
        hash_including(:adapter => /#{described_class.to_s}/,
                       :path => path, :endpoint => transport.endpoint,
                       :params => {}, :verb => 'get', :status => 200,
                       :request_headers => an_instance_of(Hash),
                       :response_headers => an_instance_of(Hash))
      end


      it 'instruments the request' do
        transport.get(path)
        expect(events.last.payload).to match(expected_payload)
      end
    end

    context 'for an unsuccessful request' do
      let(:path) { '/nothing' }

      let(:expected_payload) do
        hash_including(:adapter => /#{described_class.to_s}/,
                       :path => path, :endpoint => transport.endpoint,
                       :params => {}, :verb => 'post', :status => 404,
                       :request_headers => an_instance_of(Hash),
                       :response_headers => an_instance_of(Hash))
      end

      it 'instruments the request' do
        expect { transport.post(path) }.to raise_error(Songkick::Transport::UpstreamError)
        expect(events.last.payload).to match(expected_payload)
      end
    end

  end

  describe "reporting" do
    before do
      Songkick::Transport::Reporting.start
      @report = Songkick::Transport.report
    end

    it "executes a block and returns its value" do
      expect(@report.execute { transport.get("/artists/99").data }).to eq({"id" => 99})
    end

    it "reports a successful request" do
      @report.execute { transport.get("/artists/99") }
      expect(@report.size).to eq(1)

      request = @report.first
      expect(request.endpoint).to eq(endpoint)
      expect(request.http_method).to eq("get")
      expect(request.path).to eq("/artists/99")
      expect(request.response.data).to eq({"id" => 99})
    end

    it "reports a failed request" do
      @report.execute { transport.get("/invalid") } rescue nil
      expect(@report.size).to eq(1)

      request = @report.first
      expect(request.http_method).to eq("get")
      expect(request.path).to eq("/invalid")
      expect(request.response).to eq(nil)
      expect(request.error).to be_a(Songkick::Transport::InvalidJSONError)
    end

    it "reports the total duration" do
      @report.execute { transport.get("/artists/99") }
      request = @report.first
      allow(request).to receive(:duration).and_return 3.14
      expect(@report.total_duration).to eq(3.14)
    end
  end

  describe "error_status_codes" do
    let(:codes) { [409, 422] }

    it "can be provided on initialization" do
      transport = described_class.new(endpoint, :user_error_codes => codes)
      expect(transport.user_error_codes).to eq(codes)
    end

    it "default to 409" do
      expect(transport.user_error_codes).to eq([409])
    end
  end

end

# Curb always times out talking to the web server in the other thread when run on 1.8
unless RUBY_VERSION =~ /^1.8/
  describe Songkick::Transport::Curb do
    let(:options)   { {} }
    let(:endpoint)  { "http://localhost:4567" }
    let(:transport) { described_class.new(endpoint, options) }
    it_should_behave_like "Songkick::Transport"
  end
end

describe Songkick::Transport::HttParty do
  let(:options)   { {} }
  let(:endpoint)  { "http://localhost:4567" }
  let(:transport) { described_class.new(endpoint, options) }
  it_should_behave_like "Songkick::Transport"
end

describe Songkick::Transport::RackTest do
  let(:options)   { {} }
  let(:endpoint)  { TestApp }
  let(:transport) { described_class.new(endpoint, options) }
  it_should_behave_like "Songkick::Transport"
end

describe Songkick::Transport do
  describe "registering parsers" do
    context "for JSON" do
      it 'should use the JSON parser' do
        expect(described_class.parser_for('application/json')).to eq(Yajl::Parser)
      end
    end

    context "for anything else" do
      context 'when there is no registered parser' do
        it 'should raise an error' do
          expect { described_class.parser_for('application/xml') }.to raise_error(TypeError)
        end
      end

      context 'when there is a registered parser' do
        before do
          described_class.register_parser('application/xml', :my_parser)
        end

        it 'should return that parser' do
          expect(described_class.parser_for('application/xml')).to eq(:my_parser)
        end

        context 'when there is no registered parser' do
          it 'should raise an error' do
            expect { described_class.parser_for('application/x-something-else') }.to raise_error(TypeError)
          end
        end

        context 'when there is a default registered parser' do
          before do
            described_class.register_default_parser(:my_default_parser)
          end

          it 'should return that parser' do
            expect(described_class.parser_for('application/x-something-else')).to eq(:my_default_parser)
          end

          it 'should return the already defined parser if specified' do
            expect(described_class.parser_for('application/xml')).to eq(:my_parser)
            expect(described_class.parser_for('application/json')).to eq(Yajl::Parser)
          end
        end
      end
    end
  end
end
