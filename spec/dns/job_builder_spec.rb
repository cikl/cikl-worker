require 'spec_helper'
require 'cikl/worker/dns/job_builder'
require 'shared_examples/job_builder'

describe Cikl::Worker::DNS::JobBuilder do
  it_should_behave_like "a job builder" do
    let(:payload) { "google.com" }
  end
end
