# Elastic

Elasticsearch utilities built on top of official `elasticsearch` gem.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'elastic'
```

## Configuration

Configure the lib in your application's initializers:

```ruby
Elastic.configure do |config|
  config.namespace = "#{ENV['ELASTICSEARCH_NAMESPACE'] || "myapp-#{Rails.env}"

  config.logger =
    if !!(ENV['ELASTICSEARCH_LOGGER'] || Rails.env.development?)
      (ENV['ELASTICSEARCH_LOGGER'] || Rails.logger)
    end

  config.clusters = {
    default: ENV['ELASTICSEARCH_URL'],

    # Optional, additional clusters
    analytics: ENV['ELASTICSEARCH_ANALYTICS_CLUSTER_URL'],
    search: ENV['ELASTICSEARCH_SEARCH_CLUSTER_URL']
  }
end
```

## Elasticsearch compatibility

This library is compatible with Elasticsearch 7 and higher.

## Multi-cluster support

You can connect to any cluster defined in configuration by specifying its name, e.g. `Elastic.client(:search)`, or connect to a default one with `Elastic.client`.

## Documentation

TBD

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

See LICENSE.txt file.
