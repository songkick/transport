require "spec_helper"

shared_examples_for "transport" do
  let(:transport) { described_class.new(endpoint) }
  
  before { TestApp.listen(4567) }
  after  { TestApp.stop }
  
  describe :get do
    it "retrieves data using GET" do
      transport.get("/artists/99").data.should == {"id" => 99}
    end
    
    it "exposes the response headers" do
      transport.get("/artists/99").headers["content-type"].should == "application/json"
    end
    
    it "can send array params" do
      transport.get("/", :list => %w[a b]).data.should == {"list" => ["a", "b"]}
    end
    
    it "can send hash params" do
      transport.get("/", :list => {:a => "b"}).data.should == {"list" => {"a" => "b"}}
    end
    
    it "can send nested data structures" do
      structure = {
        "hash" => {"a" => {"b" => ["c", "d"], "e" => "f"}},
        "lisp" => ["define", {"square" => ["x", "y"]}, "*", "x", "x"]
      }
      transport.get("/", structure).data.should == structure
    end
    
    it "raises an UpstreamError for a nonexistent resource" do
      lambda { transport.get("/nothing") }.should raise_error(Songkick::Transport::UpstreamError)
    end
    
    it "raises an UpstreamError for a POST resource" do
      lambda { transport.get("/artists") }.should raise_error(Songkick::Transport::UpstreamError)
    end
    
    it "raises an UpstreamError for invalid JSON" do
      lambda { transport.get("/invalid") }.should raise_error(Songkick::Transport::InvalidJSONError)
    end
  end
  
  describe :with_headers do
    it "adds the given headers to requests" do
      data = transport.with_headers("Authorization" => "correct password").get("/authenticate").data
      data.should == {"successful" => true}
    end
    
    it "reformats Rack-style headers" do
      data = transport.with_headers("HTTP_AUTHORIZATION" => "correct password").get("/authenticate").data
      data.should == {"successful" => true}
    end
    
    it "does not affect requests made directly on the transport object" do
      transport.with_headers("Authorization" => "correct password").get("/authenticate")
      data = transport.get("/authenticate").data
      data.should == {"successful" => false}
    end
    
    it "can set Content-Type" do
      data = transport.with_headers("Content-Type" => "application/json").post("/content").data
      data.should == {"type" => "application/json"}
    end
  end
  
  describe :options do
    it "sends an OPTIONS request" do
      response = transport.options("/.well-known/host-meta")
      response.headers["Access-Control-Allow-Methods"].should == "GET, PUT, DELETE"
    end
  end

  describe :post do
    it "sends data using POST" do
      data = transport.post("/artists", :name => "Amon Tobin").data
      data.should == {"id" => "new", "name" => "AMON TOBIN"}
    end
    
    it "can send array params" do
      transport.post("/", :list => %w[a b]).data.should == {"list" => ["a", "b"]}
    end
    
    it "can send hash params" do
      transport.post("/", :list => {:a => "b"}).data.should == {"list" => {"a" => "b"}}
    end

    it "can send a raw body" do
      response = transport.with_headers("Content-Type" => "text/plain").post("/process", "Hello, world!")
      response.data.should == {"body" => "Hello, world!", "type" => "text/plain"}
    end
    
    it "raises an UpstreamError for a PUT resource" do
      lambda { transport.post("/artists/64") }.should raise_error(Songkick::Transport::UpstreamError)
    end
  end
  
  describe :put do
    it "sends data using PUT" do
      data = transport.put("/artists/64", :name => "Amon Tobin").data
      data.should == {"id" => 64, "name" => "amon tobin"}
    end
    
    it "raises an UpstreamError for a POST resource" do
      lambda{transport.put("/artists")}.should raise_error(Songkick::Transport::UpstreamError)
    end
  end
  
  describe "file uploads" do
    before do
      pending if Songkick::Transport::RackTest === transport
    end
    
    after { file.close }
          
    let(:file)   { File.open(File.expand_path("../../songkick.png", __FILE__)) }
    let(:upload) { Songkick::Transport::IO.new(file, "image/jpeg", "songkick.png") }
    
    let :params do
      {:concert => {:file => upload, :foo => :bar}}
    end
    
    let :expected_response do
      {
        "filename" => "songkick.png",
        "method"   => @http_method,
        "size"     => 6694,
        "foo"      => "bar"
      }
    end
    
    it "uploads files using POST" do
      @http_method = "post"
      response = transport.post('/upload', params)
      response.status.should == 200
      response.data.should == expected_response
    end
    
    it "uploads files using PUT" do
      @http_method = "put"
      response = transport.put('/upload', params)
      response.status.should == 200
      response.data.should == expected_response
    end
  end
  
  describe "reporting" do
    before do
      @report = Songkick::Transport.report
    end
    
    it "executes a block and returns its value" do
      @report.execute { transport.get("/artists/99").data }.should == {"id" => 99}
    end
    
    it "reports a successful request" do
      @report.execute { transport.get("/artists/99") }
      @report.size.should == 1
      
      request = @report.first
      request.endpoint.should == endpoint
      request.http_method.should == "get"
      request.path.should == "/artists/99"
      request.response.data.should == {"id" => 99}
    end
    
    it "reports a failed request" do
      @report.execute { transport.get("/invalid") } rescue nil
      @report.size.should == 1
      
      request = @report.first
      request.http_method.should == "get"
      request.path.should == "/invalid"
      request.response.should == nil
      request.error.should be_a(Songkick::Transport::InvalidJSONError)
    end
    
    it "reports the total duration" do
      @report.execute { transport.get("/artists/99") }
      request = @report.first
      request.stub(:duration).and_return 3.14
      @report.total_duration.should == 3.14
    end
  end
  
  describe "error_status_codes" do
    let(:codes) { [409, 422] }
    
    it "can be provided on initialization" do
      transport = described_class.new(endpoint, error_status_codes: codes)
      transport.error_status_codes.should == codes
    end
    
    it "default to 409" do
      transport.error_status_codes.should == [409]
    end
  end
  
  describe "#process" do
    let(:args) { [:a,:b,:c, :d] }
    
    it "delegates to Response.process" do
      Songkick::Transport::Response.should_receive(:process).once
      transport.send(:process, *args)
    end 
    
    it "adds error_status_codes" do
      Songkick::Transport::Response.should_receive(:process).with(*args, [409])
      transport.send(:process, *args)
    end
  end
end
  
describe Songkick::Transport::Curb do
  let(:endpoint)  { "http://localhost:4567" }
  it_should_behave_like "transport"
end

describe Songkick::Transport::HttParty do
  let(:endpoint)  { "http://localhost:4567" }
  it_should_behave_like "transport"
end

describe Songkick::Transport::RackTest do
  let(:endpoint)  { TestApp }
  it_should_behave_like "transport"
end