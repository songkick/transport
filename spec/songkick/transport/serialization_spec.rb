require "spec_helper"

describe Songkick::Transport::Serialization do
  def subject
    Songkick::Transport::Serialization
  end
  
  it "should build query strings" do
    subject.build_query_string(:foo => "bar").should == "foo=bar"
  end
  
  it "shouldn't scrub passwordy param elements by default" do
    subject.build_query_string({:foo => "bar", :password => "lol"}).should == "foo=bar&password=lol"
  end
  
  it "should scrub passwordy param elements when asked" do
    subject.build_query_string({:foo => "bar", :password => "lol"}, true, true).should == "foo=bar&password=******"
  end
end
