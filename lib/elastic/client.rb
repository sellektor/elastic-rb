require "elasticsearch"

module Elastic
  class Client
    attr_reader :client

    def initialize(connection_options = {})
      @client = Elasticsearch::Client.new(connection_options)
    end

    def indices(options = {})
      options = options.merge(format: 'json')
      execute { cat.indices(options) }
    rescue => ex
      ex.status == 404 ? [] : raise
    end

    def create_index(options)
      execute { indices.create(options) }
    end

    def delete_index(options)
      execute { indices.delete(options) }
    end

    def refresh_index(options)
      execute { indices.refresh(options) }
    end

    def index_exists?(options)
      execute { indices.exists?(options) }
    end

    def alias_exists?(options)
      execute { indices.exists_alias?(options) }
    end

    def get_alias(options)
      execute { indices.get_alias(options) }
    end

    def resolve_alias(options)
      if alias_exists?(options)
        index_alias = get_alias(name: options[:name])
        index_alias.keys
      else
        []
      end
    end

    def alias_index(options)
      if alias_exists?(name: options[:name])
        index_names = resolve_alias(name: options[:name])

        actions = index_names.map do |index|
          { remove: { alias: options[:name], index: index } }
        end
        actions << { add: { alias: options[:name], index: options[:index] } }

        execute { indices.update_aliases(body: { actions: actions }) }
      else
        execute { indices.put_alias(options) }
      end
    end

    def index_aliased?(options)
      if alias_exists?(options)
        index_alias = get_alias(options)
        index_alias.has_key?(options[:index])
      else
        false
      end
    end

    def bulk(data, options = {})
      options = options.merge(body: data)
      execute { bulk(options) }
    end

    def bulk_operation(action, index, type, id, data = {})
      metadata = {
        _index: index,
        _type:  type,
        _id:    id,
      }

      metadata[:data] = data if data && !data.empty?

      { action.to_sym => metadata }
    end

    def mget(index, ids, type)
      ids = Array(ids)
      return [] if ids.empty?

      docs = ids.map { |id| { _index: index, _type: type, _id: id } }

      options = {
        index: index,
        type: type,
        body: {
          docs: docs
        }
      }

      results = execute { mget(options) }
      results['docs'].select { |doc| doc['found'] }
    end

    def search(*args)
      execute { search(*args) }
    end

    def count(*args)
      execute { count(*args) }
    end

    def scroll(*args)
      execute { scroll(*args) }
    end

    def clear_scroll(*args)
      execute { clear_scroll(*args) }
    rescue
      nil
    end

    private

    def execute(&blk)
      begin
        client.instance_eval(&blk)
      rescue => ex
        raise ex.extend(Error)
      end
    end
  end
end
