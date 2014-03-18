require 'celluloid'
require 'celluloid/io'
require 'cikl/worker/base/tracker'
require 'unbound'

module Cikl
  module Worker
    module DNS
      class Resolver
        include Celluloid::IO
        include Celluloid::Logger

        finalizer :finalize
        def initialize(config)
          @ctx = Unbound::Context.new
          @ctx.load_config(config[:dns][:unbound_config_file])
          @ctx.set_option("root-hints:", config[:dns][:root_hints_file])
          
          @resolver = Unbound::Resolver.new(@ctx)
          @io = @resolver.io
          @tracker = Cikl::Worker::Base::Tracker.new(config[:job_timeout])
          @resolver.on_finish do |q|
            @tracker.delete(q)
          end
          async.start_pruner
          async.run
        end

        def start_pruner
          every(1) do
            @tracker.prune_old do |query|
              exclusive do
                @resolver.cancel_query(query)
              end
            end
          end
        end

        def run
          loop do
            begin
              ::Celluloid::IO.wait_readable(@io)
            rescue => e
              warn "Caught exception while waiting for io. Resolver probably shutdown: #{e.class} #{e.message}"
              break
            end
            exclusive do
              @resolver.process
            end
          end
        end

        def send_query(query)
          @tracker.add(query)
          exclusive do
            @resolver.send_query(query)
          end
        end

        def finalize
          warn "-> Resolver#finalize"
          exclusive do
            @resolver.close
            warn "-> real resolver terminated"
            @resolver = nil
            warn "<- Resolver#finalize"
          end
        end
      end
    end
  end
end

