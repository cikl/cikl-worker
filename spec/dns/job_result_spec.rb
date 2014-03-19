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
      describe "#to_payload" do
        before :each do
          @payload = job_result.to_payload
        end
        subject {@payload} 
        it {should be_a(::String)}
        context "when json decoded" do
          before :each do
            @decoded= MultiJson.load(@payload)
          end
          subject {@decoded}
          its(["name"]) { should eq('google.com') }
          its(["time"]) { should be_a(Integer) }
          its(["rr"]) { should be_a(Array) }
          context "rr" do
            subject {@decoded["rr"]}
            its([0]) { should eq(["google.com", 1, 2, 345576, "ns3.google.com"]) }
            its([1]) { should eq(["google.com", 1, 2, 345576, "ns4.google.com"]) }
            its([2]) { should eq(["google.com", 1, 2, 345576, "ns1.google.com"]) }
            its([3]) { should eq(["google.com", 1, 2, 345576, "ns2.google.com"]) }
          end
        end

      end
    end

    context "an A query" do
      before :each do
        job_result.handle_query_answer(query_a, answer_a)
      end
      describe "#to_payload" do
        before :each do
          @payload = job_result.to_payload
        end
        subject {@payload} 
        it {should be_a(::String)}
        context "when json decoded" do
          before :each do
            @decoded= MultiJson.load(@payload)
          end
          subject {@decoded}
          its(["name"]) { should eq('google.com') }
          its(["time"]) { should be_a(Integer) }
          its(["rr"]) { should be_a(Array) }
          context "rr" do
            subject {@decoded["rr"]}
            its([0]) { should eq(["google.com", 1, 1, 157, "173.194.46.35"]) }
            its([1]) { should eq(["google.com", 1, 1, 157, "173.194.46.41"]) }
            its([2]) { should eq(["google.com", 1, 1, 157, "173.194.46.39"]) }
            its([3]) { should eq(["google.com", 1, 1, 157, "173.194.46.37"]) }
            its([4]) { should eq(["google.com", 1, 1, 157, "173.194.46.46"]) }
            its([5]) { should eq(["google.com", 1, 1, 157, "173.194.46.33"]) }
            its([6]) { should eq(["google.com", 1, 1, 157, "173.194.46.38"]) }
            its([7]) { should eq(["google.com", 1, 1, 157, "173.194.46.40"]) }
            its([8]) { should eq(["google.com", 1, 1, 157, "173.194.46.36"]) }
            its([9]) { should eq(["google.com", 1, 1, 157, "173.194.46.32"]) }
            its([10]) { should eq(["google.com", 1, 1, 157, "173.194.46.34"]) }
          end
        end

      end
    end

    context "an AAAA query" do
      before :each do
        job_result.handle_query_answer(query_aaaa, answer_aaaa)
      end
      describe "#to_payload" do
        before :each do
          @payload = job_result.to_payload
        end
        subject {@payload} 
        it {should be_a(::String)}
        context "when json decoded" do
          before :each do
            @decoded= MultiJson.load(@payload)
          end
          subject {@decoded}
          its(["name"]) { should eq('google.com') }
          its(["time"]) { should be_a(Integer) }
          its(["rr"]) { should be_a(Array) }
          context "rr" do
            subject {@decoded["rr"]}
            its([0]) { should eq(["google.com", 1, 0x1c, 300, "2607:f8b0:4009:803::1004"]) }
          end
        end

      end
    end

    context "an MX query" do
      before :each do
        job_result.handle_query_answer(query_mx, answer_mx)
      end
      describe "#to_payload" do
        before :each do
          @payload = job_result.to_payload
        end
        subject {@payload} 
        it {should be_a(::String)}
        context "when json decoded" do
          before :each do
            @decoded= MultiJson.load(@payload)
          end
          subject {@decoded}
          its(["name"]) { should eq('google.com') }
          its(["time"]) { should be_a(Integer) }
          its(["rr"]) { should be_a(Array) }
          context "rr" do
            subject {@decoded["rr"]}
            its([0]) { should eq(["google.com", 1, 0xf, 600, "aspmx.l.google.com"]) }
            its([1]) { should eq(["google.com", 1, 0xf, 600, "alt4.aspmx.l.google.com"]) }
            its([2]) { should eq(["google.com", 1, 0xf, 600, "alt3.aspmx.l.google.com"]) }
            its([3]) { should eq(["google.com", 1, 0xf, 600, "alt1.aspmx.l.google.com"]) }
            its([4]) { should eq(["google.com", 1, 0xf, 600, "alt2.aspmx.l.google.com"]) }
          end
        end

      end
    end

  end

end
