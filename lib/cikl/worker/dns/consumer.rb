require 'cikl/worker/base/consumer'
require 'cikl/worker/dns/processor'
require 'cikl/worker/dns/job_builder'

module Cikl
  module Worker
    module DNS
      class Consumer < Cikl::Worker::Base::Consumer
        def initialize(config)
          super(Cikl::Worker::DNS::Processor.new(config), 
                Cikl::Worker::DNS::JobBuilder.new,
                config)
        end

      end

    end
  end
end

