require 'celluloid'
require 'cikl/worker/base/tracker'
require 'cikl/worker/logger'
require 'unbound'

module Cikl
  module Worker
    module DNS
      class Resolver
        include Celluloid
        include Cikl::Worker::Logger

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
              # Use's ruby's native select because we're not looking to do
              # anything more than check to see if there's any data sitting 
              # around for us. We'd use Celluloid::IO, but nio4r in Jruby 
              # doesn't like Native file descriptors. 
              if ::Kernel.select([@io], nil, nil, 0)
                exclusive do
                  @resolver.process
                end
              else 
                # This is really celluloid's implementation of sleep. It simply
                # allows for the processing of stuff that's waiting for the actor.
                sleep 0.1
              end
            rescue => e
              warn "Caught exception while waiting for io. Resolver probably shutdown: #{e.class} #{e.message}"
              break
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

