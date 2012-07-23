require "spec_helper"

describe Songkick::Transport::Request do
  let :get_request do
    Songkick::Transport::Request.new "www.example.com", "GET", "/", :username => "Louis", :password => "CK", :access => {:token => "foo"}
  end
  
  let :post_request do
    Songkick::Transport::Request.new "www.example.com", "POST", "/", :username => "Louis", :password => "CK", :access => {:token => "foo"}
  end
  
  describe :to_s do
    it "returns the request as a curl command" do
      get_request.to_s.should == "GET 'www.example.com/?username=Louis&password=CK&access[token]=foo'"
      post_request.to_s.should == "POST 'www.example.com/' -H 'Content-Type: application/x-www-form-urlencoded' -d 'username=Louis&password=CK&access[token]=foo'"
    end
    
    describe "with query sanitization" do
      before do
        Songkick::Transport.stub(:sanitized_params).and_return [/password/, "access[token]"]
      end
      
      it "removes the parameter values from the request" do
        get_request.to_s.should == "GET 'www.example.com/?username=Louis&password=[REMOVED]&access[token]=[REMOVED]'"
        post_request.to_s.should == "POST 'www.example.com/' -H 'Content-Type: application/x-www-form-urlencoded' -d 'username=Louis&password=[REMOVED]&access[token]=[REMOVED]'"
      end
    end
  end
end

