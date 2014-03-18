require 'celluloid'
require 'cikl/worker/base/consumer'
require 'cikl/worker/dns/resolver'
require 'unbound'

module Cikl
  module Worker
    module DNS
      class Consumer < Cikl::Worker::Base::Consumer
        include Celluloid
        include Celluloid::Logger

        def initialize(config)
          super(config)
          @resolver = Cikl::Worker::DNS::Resolver.new(config)
        end

        def finalize
          warn "-> Consumer#finalize"
          warn "Terminating resolver"
          @resolver.terminate
          warn "<- Consumer#finalize"
        end

        def handle_payload(payload, amqp, delivery_info)
          query = Unbound::Query.new(payload, 1, 1)
          query.on_finish do |q,r|
            # If the ack fails, it's because the channel_actor has been shutdown
            amqp.async.ack(delivery_info) rescue nil
          end
          @resolver.async.send_query(query)
        end
      end

    end
  end
end

