require 'spec_helper'
require 'cikl/worker/base/job_result_amqp_producer'

describe Cikl::Worker::Base::JobResultAMQPProducer do
  describe "#handle_job_result" do
    let(:job_result) { 
      double("job_result") 
    }
    let(:exchange) { double("exchange") }
    let(:routing_key) { double("some.routing.key") }
    let(:job_result_producer) { 
      Cikl::Worker::Base::JobResultAMQPProducer.new(exchange, routing_key)
    } 

    it "should publish the result payload to the exchange" do
      expect(job_result).to receive(:to_payload).and_return("some payload")
      expect(exchange).to receive(:publish).with("some payload", :routing_key => routing_key)
      job_result_producer.handle_job_result(job_result)
    end
  end
end
