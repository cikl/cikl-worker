require 'spec_helper'
require 'celluloid'
require 'cikl/worker/dns/resolver'
require 'cikl/worker/dns/config'
require 'unbound'
require 'timeout'

describe Cikl::Worker::DNS::Resolver do
  include WorkerHelper
  let(:config) {
    ret = Cikl::Worker::DNS::Config.create_config(WorkerHelper::PROJECT_ROOT)
    ret[:dns][:unbound_config_file] = unbound_config_file("local_zone.conf")
    ret
  }

  class LatchActor
    include Celluloid
  end

  before :each do
    Celluloid.shutdown
    Celluloid.boot
  end

  after :each do
    Celluloid.shutdown
  end

  it "should be able to get an answer for a query" do
    query = Unbound::Query.new('fakedomain.local.', 1, 1)

    result = nil
    latch = LatchActor.new

    query.on_finish do 
      latch.async.terminate
    end
    query.on_answer do |q, r|
      result = r
    end
    resolver = Cikl::Worker::DNS::Resolver.new(config)
    resolver.send_query(query)

    timeout(2) do
      Celluloid::Actor.join(latch)
    end

    expect(result).not_to be_nil
  end
end



