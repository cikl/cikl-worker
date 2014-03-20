require 'bunny'
require 'cikl/worker/logging'
require 'cikl/worker/base/job_result_amqp_producer'
require 'thread'

module Cikl
  module Worker
    class AMQP
      include Cikl::Worker::Logging
      attr_reader :job_result_handler

      def initialize(config)
        @bunny = Bunny.new(config[:amqp])
        @bunny.start
        @job_result_handler = 
          Cikl::Worker::Base::JobResultAMQPProducer.new(
            @bunny.default_channel.default_exchange, config[:results_routing_key])
        @consumers = []
        @ack_queue = Queue.new
        @acker_thread = start_acker()
        @mutex = Mutex.new
      end

      def start_acker
        Thread.new do
          while delivery_info = @ack_queue.pop
            break if delivery_info == :stop
            delivery_info.channel.ack(delivery_info.delivery_tag)
          end
        end
      end

      def stop
        @mutex.synchronize do
          @consumers.each do |consumer, subscription|
            warn "Canceling Subscription"
            subscription.cancel
            warn "Canceled Subscription"
            warn "Terminating Consumer"
            consumer.stop
            warn "Terminated Consumer"
          end
          @consumers.clear
          @ack_queue.push(:stop)
          if @acker_thread.join(2).nil?
            # :nocov:
            @acker_thread.kill
            # :nocov:
          end

          @bunny.close
          @bunny = nil
        end
      end

      def ack(delivery_info)
        @ack_queue.push(delivery_info)
      end

      def register_consumer(consumer)
        @mutex.synchronize do
          return if @bunny.nil?
          channel = @bunny.channel
          channel.prefetch(consumer.prefetch)
          queue = channel.queue(consumer.routing_key, :auto_delete => false)

          subscription = queue.subscribe(:blocking => false, :ack => true) do |delivery_info, properties, payload|
            consumer.handle_payload(payload, self, delivery_info)
          end
          @consumers << [consumer, subscription]
          nil
        end
      end
    end

  end
end
