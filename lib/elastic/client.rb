require "elasticsearch"

module Elastic
  class Client
    def initialize(connection_options = {})
      @client = Elasticsearch::Client.new(connection_options)
    end
  end
end
