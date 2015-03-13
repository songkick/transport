require "spec_helper"

describe Songkick::Transport::Base do
  subject{ Songkick::Transport::Base.new }

  describe "Decoration" do

    it "should let you add headers" do
      headered_http = subject.with_headers("A" => "B")

      expect(subject).to receive(:do_verb).with("get", "/", {}, Songkick::Transport::Headers.new("A" => "B"), nil)

      headered_http.get("/")
    end

    it "should let you add headers but then override them" do
      headered_http = subject.with_headers("A" => "B")

      expect(subject).to receive(:do_verb).with("get", "/", {}, Songkick::Transport::Headers.new("A" => "A2", "C" => "D"), nil)

      headered_http.get("/", {}, {"A" => "A2", "C" => "D"})
    end

    it "should let you add headers multiple times and combine them" do
      headered_http = subject.with_headers("A" => "B").with_headers("C" => "D")

      expect(subject).to receive(:do_verb).with("get", "/", {}, Songkick::Transport::Headers.new("A" => "B", "C" => "D"), nil)

      headered_http.get("/")
    end

    it "should let you add timeouts" do
      headered_http = subject.with_timeout(10)

      expect(subject).to receive(:do_verb).with("get", "/", {}, {}, 10)

      headered_http.get("/")
    end

    it "should let you add a timeout but then override it" do
      headered_http = subject.with_timeout(10)

      expect(subject).to receive(:do_verb).with("get", "/", {}, {}, 20)

      headered_http.get("/", {}, {}, 20)
    end

    it "should let you add timeouts multiple times and take the last" do
      headered_http = subject.with_timeout(10).with_timeout(20).with_timeout(30)

      expect(subject).to receive(:do_verb).with("get", "/", {}, {}, 30)

      headered_http.get("/")
    end

    it "should let you add headers and timeouts" do
      headered_http = subject.with_headers("A" => "B").with_timeout(10)

      expect(subject).to receive(:do_verb).with("get", "/", {}, Songkick::Transport::Headers.new("A" => "B"), 10)

      headered_http.get("/")
    end

  end
end
