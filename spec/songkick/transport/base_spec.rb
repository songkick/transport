require "spec_helper"

describe Songkick::Transport::Base do
  let(:host) { 'base' }
  subject { described_class.new(host) }


  describe 'Instrumentation' do
    subject { described_class.new(host, options) }

    let(:options) do
      { :instrumenter => ActiveSupport::Notifications }
    end

    context 'given a custom instrumentation label' do
      before { options[:instrumentation_label] = 'a.custom.label' }

      it 'instruments the request with the custom label' do
        allow(subject).to receive(:execute_request)
        expect(options[:instrumenter]).to receive(:instrument).with(options[:instrumentation_label], anything)
        subject.get('/')
      end
    end
  end

  describe "Decoration" do

    it "should let you add headers" do
      decorated_http = subject.with_headers("A" => "B")

      expect(subject).to receive(:do_verb).with("get", "/", {}, Songkick::Transport::Headers.new("A" => "B"), nil)

      decorated_http.get("/")
    end

    it "should let you add headers but then override them" do
      decorated_http = subject.with_headers("A" => "B")

      expect(subject).to receive(:do_verb).with("get", "/", {}, Songkick::Transport::Headers.new("A" => "A2", "C" => "D"), nil)

      decorated_http.get("/", {}, {"A" => "A2", "C" => "D"})
    end

    it "should let you add headers multiple times and combine them" do
      decorated_http = subject.with_headers("A" => "B").with_headers("C" => "D")

      expect(subject).to receive(:do_verb).with("get", "/", {}, Songkick::Transport::Headers.new("A" => "B", "C" => "D"), nil)

      decorated_http.get("/")
    end

    it "should let you add timeouts" do
      decorated_http = subject.with_timeout(10)

      expect(subject).to receive(:do_verb).with("get", "/", {}, {}, 10)

      decorated_http.get("/")
    end

    it "should let you add a timeout but then override it" do
      decorated_http = subject.with_timeout(10)

      expect(subject).to receive(:do_verb).with("get", "/", {}, {}, 20)

      decorated_http.get("/", {}, {}, 20)
    end

    it "should let you add timeouts multiple times and take the last" do
      decorated_http = subject.with_timeout(10).with_timeout(20).with_timeout(30)

      expect(subject).to receive(:do_verb).with("get", "/", {}, {}, 30)

      decorated_http.get("/")
    end

    it "should let you add headers and timeouts" do
      decorated_http = subject.with_headers("A" => "B").with_timeout(10)

      expect(subject).to receive(:do_verb).with("get", "/", {}, Songkick::Transport::Headers.new("A" => "B"), 10)

      decorated_http.get("/")
    end

    it "should let you add params" do
      decorated_http = subject.with_params("admin" => "true")

      expect(subject).to receive(:do_verb).with("get", "/", {"admin" => "true"}, {}, nil)

      decorated_http.get("/")
    end

    it "should let you add params multiple times and merge them" do
      decorated_http = subject.with_params("admin" => "true").with_params("foo" => "123")

      expect(subject).to receive(:do_verb).with("get", "/", {"admin" => "true", "foo" => "123"}, {}, nil)

      decorated_http.get("/")
    end

    it "should let you add basic authorization" do
      decorated_http = subject.with_basic_auth({:username => "foo", :password => "bar"})
      expected_auth_headers = {"Authorization" => "Basic Zm9vOmJhcg=="}

      expect(subject).to receive(:do_verb).with("get", "/", {}, Songkick::Transport::Headers.new(expected_auth_headers), nil)

      decorated_http.get("/")
    end

    it "should let you add basic authorization and merge them with other headers created by HeaderDecorator" do
      decorated_http = subject.with_headers({"hello" => "world"}).with_basic_auth({:username => "foo", :password => "bar"})
      expected_headers = {"Authorization" => "Basic Zm9vOmJhcg==", "hello" => "world"}

      expect(subject).to receive(:do_verb).with("get", "/", {}, Songkick::Transport::Headers.new(expected_headers), nil)

      decorated_http.get("/")
    end

    it "THE LOT" do
      decorated_http = subject.with_basic_auth({:username => "foo", :password => "bar"}).with_headers("Version" => "3.0").with_params("foo" => "123").with_timeout(10)

      expect(subject).to receive(:do_verb).with("get", "/", {"foo" => "123"}, Songkick::Transport::Headers.new("Version" => "3.0", "Authorization" => "Basic Zm9vOmJhcg=="), 10)

      decorated_http.get("/")
    end

  end
end
