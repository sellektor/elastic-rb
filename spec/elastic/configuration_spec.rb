RSpec.describe Elastic::Configuration do
  it "has default cluster" do
    configuration = described_class.new
    expect(configuration.clusters).to have_key(:default)
  end

  it "has default namespace" do
    configuration = described_class.new
    expect(configuration.namespace).to eq("elastic")
  end

  it "configures namespace" do
    configuration = described_class.new
    configuration.namespace = 'namespace'
    expect(configuration.namespace).to eq('namespace')
  end

  it "rejects blank namespace" do
    configuration = described_class.new
    expect { configuration.namespace = nil }.to raise_error(ArgumentError)
  end

  it "configures logger" do
    configuration = described_class.new
    configuration.logger = 'logger'
    expect(configuration.logger).to eq('logger')
  end
end
