require 'cikl/worker/base/job_result'
require 'multi_json'
require 'resolv'

module Cikl
  module Worker
    module DNS
      class JobResult
        include Cikl::Worker::Base::JobResult

        def initialize(name)
          @name = name
          @start = Time.now
          @rr = []
        end

        def push(name, ttl, rr)
          ret = [
            name.to_s,
            rr.class::ClassValue,
            rr.class::TypeValue,
            ttl
          ]
          case rr
          when Resolv::DNS::Resource::IN::A
            ret << rr.address.to_s.downcase
          when Resolv::DNS::Resource::IN::AAAA
            ret << rr.address.to_s.downcase
          when Resolv::DNS::Resource::IN::CNAME
            #:nocov:
            ret << rr.name.to_s.downcase
            #:nocov:
          when Resolv::DNS::Resource::IN::NS
            ret << rr.name.to_s.downcase
          when Resolv::DNS::Resource::IN::MX
            ret << rr.exchange.to_s.downcase
          else 
            #:nocov:
            return
            #:nocov:
          end

          @rr << ret
        end
        private :push

        def handle_query_answer(query, answer)
          message = answer.to_resolv rescue nil
          return if message.nil?
          rrtype = query.rrtype 
          rrclass = query.rrclass
          n = Resolv::DNS::Name.create(query.name)

          klass = Resolv::DNS::Resource.get_class(query.rrtype, query.rrclass)

          message.each_answer do |name, ttl, rr|
            next unless name == n 
            case rr
            when klass
              push(name, ttl, rr)
            when Resolv::DNS::Resource::IN::CNAME
              #:nocov:
              push(name, ttl, rr)
              n = name
              #:nocov:
            end
          end
        end

        def to_payload
          MultiJson.dump({
            name: @name,
            time: @start.to_i,
            rr: @rr
          })
        end
      end

    end
  end
end
