module RSpecSupport
  module ElasticsearchHelpers
    def elasticsearch_client
      @elasticsearch_client ||= Elastic.client(:test)
    end

    def elasticsearch_namespace
      @elasticsearch_namespace ||= Elastic.namespace
    end

    def cleanup_elasticsearch
      elasticsearch_client.indices(index: index_pattern).each do |index|
        elasticsearch_client.delete_index(index: index['index'])
      end
    end

    def ensure_clean_elasticsearch
      indices = elasticsearch_client.indices(index: index_pattern)
      if indices.size > 0
        raise StandardError, "Elasticsearch indices in '#{elasticsearch_namespace}' exist. Clean up the state first."
      end
    end

    def bulk_index(index_name, type, docs)
      data =
        docs.map do |doc|
          elasticsearch_client.bulk_operation(:index, index_name, type, doc['_id'], doc['_source'])
        end

      elasticsearch_client.bulk(data, refresh: true)
    end

    def index_pattern
      [elasticsearch_namespace, '*'].join('-')
    end
  end
end

RSpec.configure do |config|
  config.include RSpecSupport::ElasticsearchHelpers

  config.before(:all) do
    ensure_clean_elasticsearch
  end

  config.after(:each) do
    cleanup_elasticsearch
  end
end
