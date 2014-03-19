require 'cikl/worker/base/job_result_handler'
module Cikl
  module Worker
    module Base
      # Simple handler for AMQP publishing
      class JobResultAMQPProducer
        include JobResultHandler

        # @param [AMQP::Exchange] exchange The exchange through which results
        #   will be published
        # @param [String] routing_key The routing key for where results will
        #   be destined
        def initialize(exchange, routing_key)
          @exchange = exchange
          @routing_key = routing_key
        end

        # Process a job result, publishing it to an exchange
        # @param [Cikl::Worker::Base::JobResult] job_result
        def handle_job_result(job_result)
          @exchange.publish(job_result.to_payload, :routing_key => @routing_key)
        end
      end
    end
  end
end

