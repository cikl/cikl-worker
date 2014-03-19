require 'cikl/worker/logging'
require 'unbound'
require 'thread'

module Cikl
  module Worker
    module DNS
      class Resolver
        include Cikl::Worker::Logging

        def initialize(config)
          @ctx = Unbound::Context.new
          @ctx.load_config(config[:dns][:unbound_config_file])
          @ctx.set_option("root-hints:", config[:dns][:root_hints_file])
          
          @running = false
          @resolver = Unbound::Resolver.new(@ctx)
          @resolver_mutex = Mutex.new
          @io = @resolver.io

          @processing_thread = nil
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

        def cancel_query(query)
          @resolver_mutex.lock
          @resolver.cancel_query(query)
        ensure 
          @resolver_mutex.unlock
        end

        def send_query(query)
          @resolver_mutex.synchronize do
            return if @running == false
            @resolver.send_query(query)
          end
        end

        def stop
          return if @running == false
          debug "-> Resolver#stop"
          @running = false
          
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
          nil
        end
      end
    end
  end
end

