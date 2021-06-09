module Elastic
  class Scroll
    include Enumerable

    def initialize(client, index_name, options = {})
      options = {
        size: 1_000,
        scroll: '5m',
        body: {},
        stored_fields: []
      }.merge(options)

      @client        = client
      @index_name    = index_name
      @size          = options[:size]
      @scroll        = options[:scroll]
      @body          = options[:body]
      @stored_fields = options[:stored_fields]
    end

    def each
      if block_given?
        while (docs = next_page) && docs.any?
          docs.each do |doc|
            begin
              yield(doc) if block_given?
            rescue => ex
              if defined?(Raven)
                Raven.extra_context(document: doc)
              end
              raise ex
            end
          end
        end
      else
        to_enum(:each)
      end
    end

    def next_page
      response =
        if @scroll_id
          @client.scroll(scroll_params)
        else
          @client.search(initial_params)
        end

      if response
        @scroll_id = response['_scroll_id']
        hits       = response['hits']['hits']

        clear! if !hits || hits.empty?

        hits
      else
        clear!
      end

    rescue
      clear!
    end

    private

    def initial_params
      {
        index:  @index_name,
        size:   @size,
        scroll: @scroll,
        body:   @body,
        stored_fields: @stored_fields
      }.delete_if { |_, v| !v || (v.respond_to?(:empty?) && v.empty?) }
    end

    def scroll_params
      {
        body: {
          scroll_id: @scroll_id,
          scroll:    @scroll
        }
      }
    end

    def clear!
      @client.clear_scroll(scroll_id: @scroll_id) if @scroll_id
    end
  end
end
