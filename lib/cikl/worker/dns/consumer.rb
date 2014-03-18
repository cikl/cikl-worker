require 'celluloid'
require 'cikl/worker/dns/resolver'
require 'unbound'

module Cikl
  module Worker
    module DNS
      class Consumer
        include Celluloid
        include Celluloid::Logger

        finalizer :finalize
        attr_reader :routing_key, :prefetch

        def initialize(config)
          @resolver = Cikl::Worker::DNS::Resolver.new(config)

          @routing_key = config[:jobs_routing_key]
          @prefetch = config[:job_channel_prefetch]
        end

        def finalize
          warn "-> Consumer#finalize"
          warn "Terminating resolver"
          @resolver.terminate
          warn "<- Consumer#finalize"
        end

        #execute_block_on_receiver :handle_payload

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

