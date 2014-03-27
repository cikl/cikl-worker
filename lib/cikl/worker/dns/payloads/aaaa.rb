require 'cikl/worker/dns/payloads/base'

module Cikl
  module Worker
    module DNS
      module Payloads
        class AAAA < Base
          attr_reader :ipv6
          def initialize(name, ttl, rr)
            super(name, ttl, :IN, :AAAA)
            @ipv6 = rr.address
          end

          # @return [Hash] a hash version of the payload.
          def to_hash
            super().merge({
              :ipv6 => @ipv6.to_s.downcase
            })
          end
        end
      end
    end
  end
end


