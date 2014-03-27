require 'spec_helper'

shared_examples_for "a dns payload" do
  # Expacts :payload
  # Expacts :payload_clone
  # Expacts :payload_diff
  subject { payload }
  its(:name) { should be_a(Resolv::DNS::Name) }
  its(:rr_class) { should eq(rr_class) }
  its(:rr_type) { should eq(rr_type) }

  describe "#==" do
    it "should == itself" do
      expect(subject).to eq(subject)
    end
    it "should == an identical object" do
      expect(subject).to eq(payload_clone)
    end
    it "should not == an different object" do
      expect(subject).not_to eq(payload_diff)
    end
  end
  context "#to_hash" do
    let(:payload) { 
      described_class.new(Resolv::DNS::Name.create("google.com."), 1234, Resolv::IPv4.create("1.2.3.4"))
    }

    subject {payload.to_hash}
    its([:name]) {should == name }
    its([:rr_class]) {should == rr_class}
    its([:rr_type]) {should == rr_type}

  end
end
