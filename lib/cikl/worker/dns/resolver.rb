require 'cikl/worker/base/tracker'
require 'cikl/worker/logger'
require 'unbound'
require 'thread'

module Cikl
  module Worker
    module DNS
      class Resolver
        include Cikl::Worker::Logger

        def initialize(config)
          @ctx = Unbound::Context.new
          @ctx.load_config(config[:dns][:unbound_config_file])
          @ctx.set_option("root-hints:", config[:dns][:root_hints_file])
          
          @running = false
          @resolver = Unbound::Resolver.new(@ctx)
          @resolver_mutex = Mutex.new
          @io = @resolver.io
          @timeout = config[:job_timeout]
          @tracker = Cikl::Worker::Base::Tracker.new(@timeout)
          @resolver.on_finish do |q|
            @tracker.delete(q)
          end

          @processing_thread = nil
          @pruning_thread = nil
        end

        def run_processor
          while @running == true
            begin
              if ::Kernel.select([@io], nil, nil, 1)
                @resolver_mutex.synchronize do
                  @resolver.process
                end
              end
            rescue => e
              # :nocov:
              warn "Caught exception while waiting for io. Resolver probably shutdown: #{e.class} #{e.message}"
              # :nocov:
              break
            end
          end
          debug "Resolver#run_processor finished"
        end
        private :run_processor

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

            old_queries = @tracker.prune_old
            debug "Pruning #{old_queries.count} old queries"

            old_queries.each do |query|
              @resolver_mutex.synchronize do
                @resolver.cancel_query(query)
              end
            end
          end
        end
        private :run_pruner

        def send_query(query)
          @resolver_mutex.synchronize do
            return if @running == false
            @tracker.add(query)
            @resolver.send_query(query)
          end
        end

        def stop
          return if @running == false
          debug "-> Resolver#stop"
          @running = false
          @pruning_thread.wakeup rescue ThreadError
          
          if @pruning_thread.join(2).nil?
            # :nocov:
            warn "Killing pruning thread"
            @pruning_thread.kill
            # :nocov:
          end
          if @processing_thread.join(5).nil?
            # :nocov:
            warn "Killing processing thread"
            @processing_thread.kill
            # :nocov:
          end
          @resolver.close
          @resolver = nil
          debug "<- Resolver#stop"
        end

        def start
          @running = true
          @processing_thread = Thread.new do
            run_processor()
          end
          @pruning_thread = Thread.new do
            run_pruner()
          end
          nil
        end
      end
    end
  end
end

