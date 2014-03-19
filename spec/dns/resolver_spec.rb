require 'spec_helper'
require 'cikl/worker/dns/resolver'
require 'cikl/worker/dns/config'
require 'unbound'

describe Cikl::Worker::DNS::Resolver do
  include WorkerHelper
  let(:config) {
    ret = Cikl::Worker::DNS::Config.create_config(WorkerHelper::PROJECT_ROOT)
    ret[:dns][:unbound_config_file] = unbound_config_file("local_zone.conf")
    ret
  }

  context "a runing resolver" do
    before :each do
      @resolver = Cikl::Worker::DNS::Resolver.new(config)
      @resolver.start
    end

    after :each do
      @resolver.stop
    end

    it "should be able to get an answer for a query" do
      query = Unbound::Query.new('fakedomain.local.', 1, 1)

      result = nil
      latch = Thread.new { sleep }

      query.on_finish do 
        latch.wakeup
      end
      query.on_answer do |q, r|
        result = r
      end

      @resolver.send_query(query)

      latch.join(2)

      expect(result).not_to be_nil
    end
  end

end


