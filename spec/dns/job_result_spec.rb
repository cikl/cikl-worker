require 'spec_helper'
require 'cikl/worker/dns/job_result'
require 'unbound'
require 'multi_json'

describe Cikl::Worker::DNS::JobResult do
  DNS_GOOGLE_NS = WorkerHelper.hex2bin 'd7cf8180000100040000000406676f6f676c6503636f6d0000020001c00c00020001000545e80006036e7333c00cc00c00020001000545e80006036e7334c00cc00c00020001000545e80006036e7331c00cc00c00020001000545e80006036e7332c00cc02800010001000545e80004d8ef240ac03a00010001000545e80004d8ef260ac04c00010001000545e80004d8ef200ac05e00010001000545e80004d8ef220a'
  DNS_GOOGLE_A = WorkerHelper.hex2bin 'facd81800001000b0000000006676f6f676c6503636f6d0000010001c00c000100010000009d0004adc22e23c00c000100010000009d0004adc22e29c00c000100010000009d0004adc22e27c00c000100010000009d0004adc22e25c00c000100010000009d0004adc22e2ec00c000100010000009d0004adc22e21c00c000100010000009d0004adc22e26c00c000100010000009d0004adc22e28c00c000100010000009d0004adc22e24c00c000100010000009d0004adc22e20c00c000100010000009d0004adc22e22'
  DNS_GOOGLE_AAAA = WorkerHelper.hex2bin '4fd98180000100010000000006676f6f676c6503636f6d00001c0001c00c001c00010000012c00102607f8b0400908030000000000001004'
  DNS_GOOGLE_MX = WorkerHelper.hex2bin '425e8180000100050000000506676f6f676c6503636f6d00000f0001c00c000f000100000258000c000a056173706d78016cc00cc00c000f0001000002580009003204616c7434c02ac00c000f0001000002580009002804616c7433c02ac00c000f0001000002580009001404616c7431c02ac00c000f0001000002580009001e04616c7432c02ac02a000100010000012500044a7d8e1ac04200010001000001250004adc2411ac05700010001000001250004adc2431ac06c00010001000001250004adc2441ac081000100010000012500044a7d831a'

  def create_answer(str)
    ret = double("answer")
    ret.stub(:to_resolv).and_return(Resolv::DNS::Message.decode(str))
    ret
  end

  def create_query(name, rrtype, rrclass = 1)
    unless name.end_with?(".")
      name << '.'
    end
    name.downcase!
    Unbound::Query.new(name, rrtype, rrclass)
  end

  let(:query_ns) {create_query('google.com', Resolv::DNS::Resource::IN::NS::TypeValue)}
  let(:query_a) {create_query('google.com', Resolv::DNS::Resource::IN::A::TypeValue)}
  let(:query_aaaa) {create_query('google.com', Resolv::DNS::Resource::IN::AAAA::TypeValue)}
  let(:query_mx) {create_query('google.com', Resolv::DNS::Resource::IN::MX::TypeValue)}

  let(:answer_ns) {create_answer(DNS_GOOGLE_NS)}
  let(:answer_a) {create_answer(DNS_GOOGLE_A)}
  let(:answer_aaaa) {create_answer(DNS_GOOGLE_AAAA)}
  let(:answer_mx) {create_answer(DNS_GOOGLE_MX)}


  context "handling a response for google.com" do
    let(:job_result) { Cikl::Worker::DNS::JobResult.new("google.com") }

    context "an NS query" do
      before :each do
        job_result.handle_query_answer(query_ns, answer_ns)
      end
      describe "#payloads" do
        before :each do
          @payloads = job_result.payloads
        end

        specify "there should be 8 payloads, total" do
          expect(@payloads.length).to eq(8)
        end

        specify "the decoded payloads should match the proper NS records" do
          decoded = @payloads.map {|payload| MultiJson.decode(payload) }
          expect(decoded).to match_array(
            [
              { "name" => 'google.com', 'fqdn' => 'ns1.google.com', "rr_class" => "IN", "rr_type" => "NS", "section" => "answer" },
              { "name" => 'google.com', 'fqdn' => 'ns2.google.com', "rr_class" => "IN", "rr_type" => "NS", "section" => "answer" },
              { "name" => 'google.com', 'fqdn' => 'ns3.google.com', "rr_class" => "IN", "rr_type" => "NS", "section" => "answer" },
              { "name" => 'google.com', 'fqdn' => 'ns4.google.com', "rr_class" => "IN", "rr_type" => "NS", "section" => "answer" },

              { "name" => 'ns3.google.com', 'ipv4' => '216.239.36.10', "rr_class" => "IN", "rr_type" => "A", "section" => "additional" },
              { "name" => 'ns4.google.com', 'ipv4' => '216.239.38.10', "rr_class" => "IN", "rr_type" => "A", "section" => "additional" },
              { "name" => 'ns1.google.com', 'ipv4' => '216.239.32.10', "rr_class" => "IN", "rr_type" => "A", "section" => "additional" },
              { "name" => 'ns2.google.com', 'ipv4' => '216.239.34.10', "rr_class" => "IN", "rr_type" => "A", "section" => "additional" },
            ]
          )
        end
      end

    end

    context "an A query" do
      before :each do
        job_result.handle_query_answer(query_a, answer_a)
      end
      describe "#payloads" do
        before :each do
          @payloads = job_result.payloads
        end

        specify "there should be 11 payloads, total" do
          expect(@payloads.length).to eq(11)
        end

        specify "the decoded payloads should match the proper A records" do
          decoded = @payloads.map {|payload| MultiJson.decode(payload) }
          expect(decoded).to match_array(
            [
              {"name" => "google.com", "ipv4" => "173.194.46.35", "rr_class" => "IN", "rr_type" => "A", "section" => "answer" },
              {"name" => "google.com", "ipv4" => "173.194.46.41", "rr_class" => "IN", "rr_type" => "A", "section" => "answer" },
              {"name" => "google.com", "ipv4" => "173.194.46.39", "rr_class" => "IN", "rr_type" => "A", "section" => "answer" },
              {"name" => "google.com", "ipv4" => "173.194.46.37", "rr_class" => "IN", "rr_type" => "A", "section" => "answer" },
              {"name" => "google.com", "ipv4" => "173.194.46.46", "rr_class" => "IN", "rr_type" => "A", "section" => "answer" },
              {"name" => "google.com", "ipv4" => "173.194.46.33", "rr_class" => "IN", "rr_type" => "A", "section" => "answer" },
              {"name" => "google.com", "ipv4" => "173.194.46.38", "rr_class" => "IN", "rr_type" => "A", "section" => "answer" },
              {"name" => "google.com", "ipv4" => "173.194.46.40", "rr_class" => "IN", "rr_type" => "A", "section" => "answer" },
              {"name" => "google.com", "ipv4" => "173.194.46.36", "rr_class" => "IN", "rr_type" => "A", "section" => "answer" },
              {"name" => "google.com", "ipv4" => "173.194.46.32", "rr_class" => "IN", "rr_type" => "A", "section" => "answer" },
              {"name" => "google.com", "ipv4" => "173.194.46.34", "rr_class" => "IN", "rr_type" => "A", "section" => "answer" }
            ]
          )
        end
      end
    end

    context "an AAAA query" do
      before :each do
        job_result.handle_query_answer(query_aaaa, answer_aaaa)
      end
      describe "#payloads" do
        before :each do
          @payloads = job_result.payloads
        end

        specify "there should be 1 payloads, total" do
          expect(@payloads.length).to eq(1)
        end

        specify "the decoded payloads should match the proper AAAA records" do
          decoded = @payloads.map {|payload| MultiJson.decode(payload) }
          expect(decoded).to match_array(
            [
              {"name" => "google.com", "ipv6" => "2607:f8b0:4009:803::1004", "rr_class" => "IN", "rr_type" => "AAAA", "section" => "answer" }
            ]
          )
        end
      end

    end

    context "an MX query" do
      before :each do
        job_result.handle_query_answer(query_mx, answer_mx)
      end
      describe "#payloads" do
        before :each do
          @payloads = job_result.payloads
        end

        specify "there should be 10 payloads, total" do
          expect(@payloads.length).to eq(10)
        end

        specify "the decoded payloads should match the proper MX records" do
          decoded = @payloads.map {|payload| MultiJson.decode(payload) }
          expect(decoded).to match_array(
            [
              {"name" => "google.com", "fqdn" =>  "aspmx.l.google.com", "rr_class" => "IN", "rr_type" => "MX", "section" => "answer" },
              {"name" => "google.com", "fqdn" =>  "alt4.aspmx.l.google.com", "rr_class" => "IN", "rr_type" => "MX", "section" => "answer" },
              {"name" => "google.com", "fqdn" =>  "alt3.aspmx.l.google.com", "rr_class" => "IN", "rr_type" => "MX", "section" => "answer" },
              {"name" => "google.com", "fqdn" =>  "alt1.aspmx.l.google.com", "rr_class" => "IN", "rr_type" => "MX", "section" => "answer" },
              {"name" => "google.com", "fqdn" =>  "alt2.aspmx.l.google.com", "rr_class" => "IN", "rr_type" => "MX", "section" => "answer" },

              {"name" =>  "aspmx.l.google.com", "ipv4" => "74.125.142.26", "rr_class" => "IN", "rr_type" => "A", "section" => "additional" },
              {"name" =>  "alt4.aspmx.l.google.com", "ipv4" => "173.194.65.26", "rr_class" => "IN", "rr_type" => "A", "section" => "additional" },
              {"name" =>  "alt3.aspmx.l.google.com", "ipv4" => "173.194.67.26", "rr_class" => "IN", "rr_type" => "A", "section" => "additional" },
              {"name" =>  "alt1.aspmx.l.google.com", "ipv4" => "173.194.68.26", "rr_class" => "IN", "rr_type" => "A", "section" => "additional" },
              {"name" =>  "alt2.aspmx.l.google.com", "ipv4" => "74.125.131.26", "rr_class" => "IN", "rr_type" => "A", "section" => "additional" },
            ]
          )
        end
      end
    end

  end

end
