require 'celluloid'
require 'cikl/worker/dns/resolver'
require 'unbound'

module Cikl
  module Worker
    module Base
      class Consumer
        include Celluloid
        include Celluloid::Logger

        finalizer :finalize
        attr_reader :routing_key, :prefetch

        def initialize(config)
          @routing_key = config[:jobs_routing_key]
          @prefetch = config[:job_channel_prefetch]
        end

        def finalize
        end

        def handle_payload(payload, amqp, delivery_info)
        end
      end

    end
  end
end


