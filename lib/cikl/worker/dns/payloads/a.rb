require 'cikl/worker/dns/payloads/base'

module Cikl
  module Worker
    module DNS
      module Payloads
        class A < Base
          attr_reader :ipv4
          def initialize(name, ttl, rr)
            super(name, ttl, :IN, :A)
            @ipv4 = rr.address
          end

          # @return [Hash] a hash version of the payload.
          def to_hash
            super().merge({
              :ipv4 => @ipv4.to_s
            })
          end
        end
      end
    end
  end
end

