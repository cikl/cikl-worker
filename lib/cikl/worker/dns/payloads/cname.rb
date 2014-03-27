require 'cikl/worker/dns/payloads/base'

module Cikl
  module Worker
    module DNS
      module Payloads
        class CNAME < Base
          attr_reader :fqdn
          def initialize(name, ttl, rr)
            super(name, ttl, :IN, :CNAME)
            @fqdn = rr.name
          end

          # @return [Hash] a hash version of the payload.
          def to_hash
            super().merge({
              :fqdn => @fqdn.to_s.downcase
            })
          end
        end
      end
    end
  end
end


