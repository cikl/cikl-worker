require 'cikl/worker/base/job_result'
require 'multi_json'
require 'resolv'
require 'set'

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

        def parse(name, ttl, rr)
          record = { 
            :name => name.to_s ,
            :rr_class => :IN,
          }
          case rr
          when Resolv::DNS::Resource::IN::A
            record[:ipv4] = rr.address.to_s.downcase
            record[:rr_type] = :A
          when Resolv::DNS::Resource::IN::AAAA
            record[:ipv6] = rr.address.to_s.downcase
            record[:rr_type] = :AAAA
          when Resolv::DNS::Resource::IN::CNAME
            #:nocov:
            record[:fqdn] = rr.name.to_s.downcase
            record[:rr_type] = :CNAME
            #:nocov:
          when Resolv::DNS::Resource::IN::NS
            record[:fqdn] = rr.name.to_s.downcase
            record[:rr_type] = :NS
          when Resolv::DNS::Resource::IN::MX
            record[:fqdn] = rr.exchange.to_s.downcase
            record[:rr_type] = :MX
          else 
            #:nocov:
            return nil
            #:nocov:
          end

          record
        end
        private :parse

        def handle_query_answer(query, answer)
          message = answer.to_resolv rescue nil
          return if message.nil?
          rrtype = query.rrtype 
          rrclass = query.rrclass
          n = Resolv::DNS::Name.create(query.name)

          klass = Resolv::DNS::Resource.get_class(query.rrtype, query.rrclass)

          in_scope_rrs = []
          message.each_answer do |name, ttl, rr|
            next unless name == n 
            case rr
            when klass
              in_scope_rrs << [name, ttl, rr]
            when Resolv::DNS::Resource::IN::CNAME
              #:nocov:
              in_scope_rrs << [name, ttl, rr]
              n = name
              #:nocov:
            end
          end

          get_additional_a_for_names = Set.new
          in_scope_rrs.each do |name, ttl, rr|
            record = parse(name, ttl, rr)
            next if record.nil?
            @records << record
            case rr
            when Resolv::DNS::Resource::IN::NS
              get_additional_a_for_names << rr.name
            when Resolv::DNS::Resource::IN::MX
              get_additional_a_for_names << rr.exchange
            end
          end

          return if get_additional_a_for_names.count == 0

          # Now look for additional records that match the gathered names.
          message.each_additional do |name, ttl, rr|
            if get_additional_a_for_names.include?(name)
              record = parse(name, ttl, rr)
              @records << record
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
