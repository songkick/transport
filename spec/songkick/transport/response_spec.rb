require "spec_helper"

describe Songkick::Transport::Response do
  def process(*args)
    Songkick::Transport::Response.process(*args)
  end
  
  describe "200 with a body" do
    let(:response) { process("", 200, {"Content-Type" => "application/json; charset=utf-8"}, '{"hello":"world"}') }
    
    it "is an OK" do
      response.should be_a(Songkick::Transport::Response::OK)
    end
    
    it "exposes its data" do
      response.data.should == {"hello" => "world"}
    end
  end
  
  describe "200 with a body with an empty line in it" do
    let(:response) { process("", 200, {"Content-Type" => "application/json"}, "{\"hello\":\"world\"\n\n}") }
    
    it "is an OK" do
      response.should be_a(Songkick::Transport::Response::OK)
    end
    
    it "exposes its data" do
      response.data.should == {"hello" => "world"}
    end
  end
  
  describe "200 with a parsed body" do
    let(:response) { process("", 200, {"Content-Type" => "application/json"}, {"hello" => "world"}) }
    
    it "exposes its data" do
      response.data.should == {"hello" => "world"}
    end
  end
  
  describe "200 with an empty body" do
    let(:response) { process("", 200, {}, "") }
    
    it "exposes its data" do
      response.data.should be_nil
    end
  end
  
  describe "201 with an empty body" do
    let(:response) { process("", 201, {}, "") }
    
    it "is a Created" do
      response.should be_a(Songkick::Transport::Response::Created)
    end
  end
  
  describe "204 with an empty body" do
    let(:response) { process("", 204, {}, "") }
    
    it "is a NoContent" do
      response.should be_a(Songkick::Transport::Response::NoContent)
    end
  end
  
  describe "409 with a body" do
    let(:response) { process("", 409, {"Content-Type" => "application/json"}, '{"errors":[]}') }
    
    it "is a UserError" do
      response.should be_a(Songkick::Transport::Response::UserError)
    end
    
    it "exposes the errors" do
      response.errors.should == []
    end
  end

  describe "422 with customer user error codes" do
    let(:response) { process("", 422, {"Content-Type" => "application/json"}, '{"errors":[]}', [409, 422]) }
    
    it "is a UserError" do
      response.should be_a(Songkick::Transport::Response::UserError)
    end
    
    it "exposes the errors" do
      response.errors.should == []
    end
  end
end

