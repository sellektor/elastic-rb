require "elastic/client"
require "elastic/client/error"
require "elastic/configuration"
require "elastic/helpers"
require "elastic/index"
require "elastic/scroll"
require "elastic/version"

module Elastic extend self
  attr_reader :configuration
  @configuration = Configuration.new

  def configure
    @configuration = Configuration.new
    yield(configuration)
  end

  def client(cluster = :default)
    @clients ||= {}

    unless @clients[cluster]
      @clients[cluster] = Client.new(host: host(cluster), log: !!logger, logger: logger)
    end

    @clients[cluster]
  end

  def namespace
    configuration.namespace
  end

  private

  def logger
    configuration.logger
  end

  def host(cluster)
    configuration.clusters[cluster] || configuration.clusters[:default]
  end
end
