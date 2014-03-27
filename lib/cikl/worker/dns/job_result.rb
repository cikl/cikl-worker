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
          @records = []
        end

        def push(name, ttl, rr)
          record = { 
            :name => name.to_s ,
            :rr_class => rr.class::ClassValue,
            :rr_type => rr.class::TypeValue
          }
          case rr
          when Resolv::DNS::Resource::IN::A
            record[:ipv4] = rr.address.to_s.downcase
          when Resolv::DNS::Resource::IN::AAAA
            record[:ipv6] = rr.address.to_s.downcase
          when Resolv::DNS::Resource::IN::CNAME
            #:nocov:
            record[:cname] = rr.name.to_s.downcase
            #:nocov:
          when Resolv::DNS::Resource::IN::NS
            record[:ns] = rr.name.to_s.downcase
          when Resolv::DNS::Resource::IN::MX
            record[:mx] = rr.exchange.to_s.downcase
          else 
            #:nocov:
            return
            #:nocov:
          end

          @records << record
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

        def payloads
          @records.map { |record| MultiJson.dump(record) }
        end
      end

    end
  end
end
