require 'celluloid'
require 'bunny'

module Cikl
  module Worker
    class AMQP
      include Celluloid
      include Celluloid::Logger

      finalizer :finalize

      def initialize()
        @bunny = Bunny.new(
          :host => 'bigboy', 
          :username => 'guest',
          :password => 'guest',
          :vhost => '/'
        )
        @bunny.start
        @consumers = []
      end

      def finalize
        @consumers.each do |consumer, subscription|
          warn "Canceling Subscription"
          subscription.cancel
          warn "Canceled Subscription"
          warn "Terminating Consumer"
          consumer.terminate
          Actor.join(consumer)
          warn "Terminated Consumer"
        end
        @consumers.clear
        @bunny.close
      end

      def ack(delivery_info)
        delivery_info.channel.ack(delivery_info.delivery_tag)
      end

      def register_consumer(consumer)
        channel = @bunny.channel
        channel.prefetch(consumer.prefetch)
        queue = channel.queue(consumer.routing_key, :auto_delete => false)
        amqp_actor = Actor.current

        subscription = queue.subscribe(:blocking => false, :ack => true) do |delivery_info, properties, payload|
          consumer.handle_payload(payload, amqp_actor, delivery_info)
        end
        @consumers << [consumer, subscription]
        nil
      end
    end

  end
end
