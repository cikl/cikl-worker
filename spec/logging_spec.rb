require 'spec_helper'
require 'cikl/worker/logging'

describe Cikl::Worker::Logging do

  class TestLogging
    include Cikl::Worker::Logging
  end
  before :all do
    @original_logger = Cikl::Worker.logger
  end
  after :all do
    Cikl::Worker.logger = @original_logger
  end
  let(:logger) {double('logger') }

  before :each do
    @obj = TestLogging.new
    Cikl::Worker.logger = logger
  end

  specify "#error should call Cikl::Worker.logger.error" do
    expect(logger).to receive(:error).with("this is an error")
    @obj.error("this is an error")
  end
  specify "#warn should call Cikl::Worker.logger.warn" do
    expect(logger).to receive(:warn).with("this is an warn")
    @obj.warn("this is an warn")
  end
  specify "#info should call Cikl::Worker.logger.info" do
    expect(logger).to receive(:info).with("this is an info")
    @obj.info("this is an info")
  end
  specify "#debug should call Cikl::Worker.logger.debug" do
    expect(logger).to receive(:debug).with("this is an debug")
    @obj.debug("this is an debug")
  end


end



