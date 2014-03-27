require 'cikl/worker/base/job_result_payload'

module Cikl
  module Worker
    module DNS
      module Payloads
        class Base < Cikl::Worker::Base::JobResultPayload
          attr_reader :name, :rr_class, :rr_type, :section 
          def initialize(name, ttl, rr_class, rr_type)
            @name = name
            @rr_class = rr_class
            @rr_type = rr_type
            @section = :answer
          end

          def answer!
            @section = :answer
          end

          def additional!
            @section = :additional
          end

          # @return [Hash] a hash version of the payload.
          def to_hash
            super().merge({
              :name => @name.to_s,
              :rr_class => @rr_class,
              :rr_type => @rr_type,
              :section => @section
            })
          end
        end
      end
    end
  end
end
