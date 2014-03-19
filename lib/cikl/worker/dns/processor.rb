require 'cikl/worker/dns/resolver'
require 'cikl/worker/base/processor'
require 'thread'

module Cikl
  module Worker
    module DNS
      class Processor < Cikl::Worker::Base::Processor

        def initialize(job_result_handler, config)
          @resolver = Cikl::Worker::DNS::Resolver.new(config)
          @resolver.start
          super(job_result_handler, config)
        end

        def handle_pruned_job(job)
          job.each_remaining_query do |query|
            @resolver.cancel_query(query)
          end
        end

        def stop
          super()
          debug "Resolver: stopping"
          @resolver.stop
          debug "Resolver: stopped"
        end

        def process_job(job)
          super(job)
          job.each_remaining_query do |query|
            @resolver.send_query(query)
          end
        end
      end

    end
  end
end


