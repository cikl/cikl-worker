require 'cikl/worker/base/consumer'
require 'cikl/worker/dns/resolver'
require 'unbound'

module Cikl
  module Worker
    module DNS
      class Consumer < Cikl::Worker::Base::Consumer
        def initialize(config)
          super(config)
          @resolver = Cikl::Worker::DNS::Resolver.new(config)
          @resolver.start
        end

        def stop
          warn "-> Consumer#stop"
          warn "Terminating resolver"
          @resolver.stop
          warn "<- Consumer#stop"
        end

        def handle_payload(payload, amqp, delivery_info)
          query = Unbound::Query.new(payload, 1, 1)
          query.on_finish do |q,r|
            # If the ack fails, it's because the channel_actor has been shutdown
            amqp.ack(delivery_info) rescue nil
          end
          @resolver.send_query(query)
        end
      end

    end
  end
end

