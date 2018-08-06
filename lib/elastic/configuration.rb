module Elastic
  class Configuration
    attr_accessor :namespace, :logger, :clusters

    def initialize
      @namespace = "elastic"
      @clusters = {
        default: ENV['ELASTICSEARCH_URL']
      }
    end

    def namespace=(namespace)
      raise ArgumentError.new("Namespace can't be blank") if namespace.to_s.empty?
      @namespace = namespace
    end
  end
end
