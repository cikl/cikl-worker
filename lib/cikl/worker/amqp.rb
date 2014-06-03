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
        info "Starting Cikl::Worker::AMQP"
        @bunny = start_bunny(config)
        @job_result_handler = 
          Cikl::Worker::Base::JobResultAMQPProducer.new(
            @bunny.default_channel.default_exchange, 
            config[:results_routing_key],
            config[:worker_name]
        )
        @consumers = []
        @ack_queue = Queue.new
        @acker_thread = start_acker()
        @mutex = Mutex.new
      end

      def start_bunny(config)
        amqp_config = config[:amqp]
        bunny_config = {
          :host => amqp_config[:host],
          :port => amqp_config[:port],
          :username => amqp_config[:username],
          :password => amqp_config[:password],
          :vhost => amqp_config[:vhost],
          :ssl => amqp_config[:ssl],
          :recover_from_connection_close => amqp_config[:recover_from_connection_close],
          :network_recovery_interval => amqp_config[:network_recovery_interval]
        }
        bunny = Bunny.new(bunny_config)
        max_reconnects = amqp_config[:max_recovery_attempts]
        reconnect_counter = 0
        begin
          bunny.start
        rescue Bunny::TCPConnectionFailed => e
          error "Failed to connect to RabbitMQ service: #{e.message}"
          reconnect_counter += 1

          if (config[:amqp][:recover_from_connection_close] == true) && (max_reconnects.nil? or (reconnect_counter <= max_reconnects))
            info "Retrying connection in #{config[:amqp][:network_recovery_interval]} seconds"
            sleep config[:amqp][:network_recovery_interval]
            retry
          else 
            raise e
          end
        end
        info "RabbitMQ connection established"
        bunny
      end
      private :start_bunny

      def start_acker
        Thread.new do
          while msg = @ack_queue.pop
            op = msg[0]
            case op
            when :stop
              break
            when :ack
              delivery_info = msg[1]
              delivery_info.channel.ack(delivery_info.delivery_tag)
            when :nack
              delivery_info = msg[1]
              delivery_info.channel.nack(delivery_info.delivery_tag, false)
            end
          end
        end
      end

      def stop
        info "Stopping Cikl::Worker::AMQP"
        @mutex.synchronize do
          @consumers.each do |consumer, subscription|
            debug "Canceling Subscription"
            subscription.cancel
            debug "Canceled Subscription"
            debug "Terminating Consumer"
            consumer.stop
            debug "Terminated Consumer"
          end
          @consumers.clear
          @ack_queue.push([:stop])
          if @acker_thread.join(2).nil?
            # :nocov:
            @acker_thread.kill
            # :nocov:
          end

          @bunny.close
          @bunny = nil
        end
        info "Cikl::Worker::AMQP done"
      end

      def ack(delivery_info)
        @ack_queue.push([:ack, delivery_info])
      end

      def nack(delivery_info)
        @ack_queue.push([:nack, delivery_info])
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
