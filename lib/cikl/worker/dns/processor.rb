require 'cikl/worker/logging'
require 'cikl/worker/dns/resolver'
require 'cikl/worker/base/tracker'
require 'thread'

module Cikl
  module Worker
    module DNS
      class Processor 
        include Cikl::Worker::Logging

        def initialize(config)
          @resolver = Cikl::Worker::DNS::Resolver.new(config)
          @resolver.start
          @timeout = config[:job_timeout]
          @tracker = Cikl::Worker::Base::Tracker.new(@timeout)
          @running = true
          @pruning_thread = Thread.new do
            run_pruner()
          end
        end

        def job_finished(job, result)
          @tracker.delete(job)
        end

        def run_pruner
          while @running == true
            next_prune = @tracker.next_prune
            sleep_time = nil
            now = Time.now
            if next_prune.nil?
              sleep_time = @timeout
            elsif next_prune > now
              sleep_time = next_prune - now
            end

            if sleep_time
              debug "Sleeping #{sleep_time} seconds"
              sleep sleep_time
              next
            end

            old_jobs = @tracker.prune_old
            debug "Pruning #{old_jobs.count} old jobs"

            old_jobs.each do |job|
              job.each_remaining_query do |query|
                @resolver.cancel_query(query)
              end
            end
          end
        end
        private :run_pruner

        def stop
          debug "-> Processor#stop"

          @running = false
          debug "Pruner: stopping"
          @pruning_thread.wakeup rescue ThreadError # in case it's already stopped
          if @pruning_thread.join(2).nil?
            # :nocov:
            warn "Killing pruning thread"
            @pruning_thread.kill
            # :nocov:
          end
          debug "Pruner: stopped"
          debug "Resolver: stopping"
          @resolver.stop
          debug "Resolver: stopped"
          debug "<- Processor#stop"
        end

        def process_job(job)
          @tracker.add(job)
          job.each_remaining_query do |query|
            @resolver.send_query(query)
          end
        end
      end

    end
  end
end


