require "spec_helper"

describe Songkick::Transport::Request do
  let :get_request do
    Songkick::Transport::Request.new "www.example.com", "GET", "/", :username => "Louis", :password => "CK", :access => {:token => "foo"}
  end
  
  let :post_request do
    Songkick::Transport::Request.new "www.example.com", "POST", "/", :username => "Louis", :password => "CK", :access => {:token => "foo"}
  end
  
  describe :to_s do
    context "with a get request" do
      it "returns the request as a curl command" do
        ["GET 'www.example.com/?", "username=Louis", "password=CK", "access[token]=foo"].each{|string| get_request.to_s.should include(string)}
      end
    end
    context "with a post request" do
      it "returns the request as a curl command" do
        ["POST 'www.example.com/' -H 'Content-Type: application/x-www-form-urlencoded' -d '",
          "username=Louis",
          "password=CK",
          "access[token]=foo"].each{|string| post_request.to_s.should include(string) }
      end
    end
    
    describe "with query sanitization" do
      before do
        Songkick::Transport.stub(:sanitized_params).and_return [/password/, "access[token]"]
      end

      context "with a get request" do
        it "removes the parameter values from the request" do
          ["GET 'www.example.com/?", "username=Louis", "password=[REMOVED]", "access[token]=[REMOVED]"].each{|string| get_request.to_s.should include(string)}
        end
      end
      context "with a post request" do
        it "removes the parameter values from the request" do
          ["POST 'www.example.com/' -H 'Content-Type: application/x-www-form-urlencoded' -d '",
           "username=Louis",
           "password=[REMOVED]",
           "access[token]=[REMOVED]"].each{|string| post_request.to_s.should include(string)}
        end
      end
    end
  end
end

