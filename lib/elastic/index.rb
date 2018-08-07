module Elastic
  class Index
    class << self
      attr_accessor :client, :alias_name, :document_type, :settings, :mappings

      def inherited(klass)
        klass.alias_name    = Elastic::Helpers.to_alias_name(klass)
        klass.document_type = 'document'
        klass.settings      = {}
        klass.mappings      = {}
      end

      def resolve
        index_name = client.resolve_alias(name: alias_name).first
        new(index_name)
      end

      def generate_index_name
        "#{alias_name}-#{Time.now.to_i}".downcase
      end
    end

    attr_reader :index_name

    def initialize(index_name = nil)
      @index_name = (index_name || self.class.generate_index_name).downcase
    end

    def create
      body = {
        settings: self.class.settings,
        mappings: self.class.mappings,
      }

      client.create_index(index: index_name, body: body)
    end

    def delete
      client.delete_index(index: index_name)
    end

    def exists?
      client.index_exists?(index: index_name)
    end

    def promote
      client.alias_index(name: alias_name, index: index_name)
    end

    def promoted?
      client.index_aliased?(name: alias_name, index: index_name)
    end

    def refresh
      client.refresh_index(index: index_name)
    end

    def count(query = {})
      response = client.count(index: index_name, body: query)
      response['count']
    end

    def get(id)
      mget([id]).first
    end

    def mget(ids)
      docs = client.mget(index_name, ids, self.class.document_type)
      docs.map { |doc| source_with_id(doc) }
    end

    def documents(query = {}, options = {})
      defaults       = { body: query }
      scroll_options = defaults.merge(options)
      scroll         = Scroll.new(client, index_name, scroll_options)
      docs           = scroll.each

      docs.lazy.map { |doc| source_with_id(doc) }
    end

    def document_ids(query = {}, options = {})
      defaults       = {}
      scroll_options = defaults.merge(options).merge(stored_fields: ['_id'])
      docs           = documents(query, scroll_options)

      docs.lazy.map { |doc| doc['_id'] }
    end

    def bulk(action, id, data = {})
      buffer << bulk_operation(action, id, data)
    end

    def bulk_operation(action, id, data = {})
      metadata = {
        _index: index_name,
        _type:  self.class.document_type,
        _id:    id,
        _retry_on_conflict: 3
      }

      if action.to_sym == :upsert
        data ||= {}
        data[:doc_as_upsert] = true

        action = :update
      end

      metadata[:data] = data if data.present?

      { action.to_sym => metadata }
    end

    def buffer
      @buffer ||=
        Buffer.new do |operations|
          client.bulk(operations)
        end
    end

    def alias_name
      self.class.alias_name
    end

    private

    def source_with_id(doc)
      (doc['_source'] || {}).merge('_id' => doc['_id'])
    end

    def client
      self.class.client
    end
  end
end
