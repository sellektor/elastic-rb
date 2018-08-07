RSpec.describe Elastic::Scroll do
  let(:client) { elasticsearch_client }
  let(:index_name) { "#{elasticsearch_namespace}-scroll" }

  let(:docs) do
    [{ "_id" => 1, "_source" => { "name" => "Joe", "age" => 20 } },
     { "_id" => 2, "_source" => { "name" => "Ann", "age" => 10 } },
     { "_id" => 3, "_source" => { "name" => "Tom", "age" => 30 } },
     { "_id" => 4, "_source" => { "name" => "Joe", "age" => 40 } },
     { "_id" => 5, "_source" => { "name" => "Joe", "age" => 50 } }]
  end

  before(:each) {
    bulk_index(index_name, 'person', docs)
  }

  it "enumerates the scrolled docs" do
    scroll  = described_class.new(client, index_name, size: 2)
    sources = scroll.map { |doc| doc['_source'] }

    expect(sources).to match_array(docs.map { |doc| doc['_source'] })
  end

  it "scrolls through the index" do
    scroll = described_class.new(client, index_name, size: 2)

    hits = scroll.next_page
    expect(hits.size).to eq(2)

    hits = scroll.next_page
    expect(hits.size).to eq(2)

    hits = scroll.next_page
    expect(hits.size).to eq(1)
  end

  it "scrolls through the index with query" do
    body = {
      query: { ids: { type: 'person', values: [1, 2, 3] } },
      sort: { age: "asc" }
    }

    scroll = described_class.new(client, index_name, size: 2, body: body)

    hits = scroll.next_page
    expect(hits.map { |hit| hit['_source'] }).to eq([docs[1]['_source'], docs[0]['_source']])

    hits = scroll.next_page
    expect(hits.map { |hit| hit['_source'] }).to eq([docs[2]['_source']])
  end

  it "clears the scroll" do
    expect(client).to receive(:clear_scroll)

    scroll = described_class.new(client, index_name)
    scroll.next_page
    scroll.next_page
  end
end
