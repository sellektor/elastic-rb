RSpec.describe Elastic do
  it "has a version number" do
    expect(Elastic::VERSION).not_to be nil
  end

  it "provides configuration" do
    configuration = described_class.configuration
    expect(configuration).to be_instance_of(Elastic::Configuration)
  end

  it "can be configured with a block" do
    described_class.configure do |config|
      config.namespace = 'namespace'
      config.logger    = 'logger'
      config.clusters  = { foo: 'bar' }
    end

    expect(described_class.namespace).to eq('namespace')
    expect(described_class.configuration.logger).to eq('logger')
    expect(described_class.configuration.clusters).to eq({ foo: 'bar' })
  end

  it "provides clients" do
    described_class.configure do |config|
      config.clusters = {
        default: 'default',
        foo: 'bar'
      }
    end

    expect(described_class.client(:default)).to eq(described_class.client)
    expect(described_class.client(:default)).to be_instance_of(Elastic::Client)
    expect(described_class.client(:foo)).to be_instance_of(Elastic::Client)
    expect(described_class.client(:unknown)).to be_instance_of(Elastic::Client)
  end
end
