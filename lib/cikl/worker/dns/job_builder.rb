require 'cikl/worker/base/job_builder'
require 'cikl/worker/dns/job'

module Cikl
  module Worker
    module DNS
      # Builds DNS jobs
      class JobBuilder < Cikl::Worker::Base::JobBuilder
        # @param [String] payload A string payload that contains data a job
        # @param [Hash] opts Options to pass to the job instance.
        # @return job [Cikl::Worker::DNS::Job] A job
        def build(payload, opts = {})
          return Cikl::Worker::DNS::Job.new(payload, opts)
        end
      end
    end
  end
end
