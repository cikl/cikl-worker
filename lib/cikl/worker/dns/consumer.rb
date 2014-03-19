require 'cikl/worker/base/consumer'
require 'cikl/worker/dns/resolver'
require 'cikl/worker/dns/job'
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
          on_finish_cb = Proc.new { 
            warn "Finished: #{payload}"
            amqp.ack(delivery_info) rescue nil
          }
          job = Cikl::Worker::DNS::Job.new(payload, :on_finish => on_finish_cb)
          job.each_remaining_query do |query|
            @resolver.send_query(query)
          end
        end
      end

    end
  end
end

