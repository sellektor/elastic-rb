RSpec.describe Elastic::Client do
  let(:client) { elasticsearch_client }
  let(:namespace) { elasticsearch_namespace }

  context "when index does not exist" do
    it "returns empty list of indices" do
      indices = client.indices(index: "#{namespace}-*")
      expect(indices).to eq([])
    end

    it "returns false when checking for it's existence" do
      expect(client.index_exists?(index: "#{namespace}-index")).to be_falsy
    end

    it "creates index" do
      client.create_index(index: "#{namespace}-index")
      expect(client.index_exists?(index: "#{namespace}-index")).to be_truthy
    end
  end

  context "when index exists" do
    before do
      client.create_index(index: "#{namespace}-index")
    end

    it "returns list of indices" do
      indices = client.indices(index: "#{namespace}-*").map { |index| index['index'] }
      expect(indices).to eq(["#{namespace}-index"])
    end

    it "returns true when checking for it's existence" do
      expect(client.index_exists?(index: "#{namespace}-index")).to be_truthy
    end

    it "deletes index" do
      client.delete_index(index: "#{namespace}-index")
      expect(client.index_exists?(index: "#{namespace}-index")).to be_falsy
    end

    context "but alias does not exist" do
      it "returns false when checking for alias existence" do
        expect(client.alias_exists?(name: "#{namespace}-alias")).to be_falsy
      end

      it "resolves alias to empty index list" do
        expect(client.resolve_alias(name: "#{namespace}-alias")).to eq([])
      end

      it "aliases index" do
        client.alias_index(name: "#{namespace}-alias", index: "#{namespace}-index")
        expect(client.alias_exists?(name: "#{namespace}-alias")).to be_truthy
        expect(client.index_aliased?(name: "#{namespace}-alias", index: "#{namespace}-index")).to be_truthy
      end
    end

    context "and alias to it exists" do
      before do
        client.alias_index(name: "#{namespace}-alias", index: "#{namespace}-index")
      end

      it "returns true when checking for alias existence" do
        expect(client.alias_exists?(name: "#{namespace}-alias")).to be_truthy
      end

      it "returns true when checking if index is aliased" do
        expect(client.index_aliased?(name: "#{namespace}-alias", index: "#{namespace}-index")).to be_truthy
      end

      it "resolves alias to index" do
        expect(client.resolve_alias(name: "#{namespace}-alias")).to eq(["#{namespace}-index"])
      end
    end

    context "and alias to another index exists" do
      before do
        client.create_index(index: "#{namespace}-another-index")
        client.alias_index(name: "#{namespace}-alias", index: "#{namespace}-another-index")
      end

      it "returns true when checking for alias existence" do
        expect(client.alias_exists?(name: "#{namespace}-alias")).to be_truthy
      end

      it "returns false when checking if index is aliased" do
        expect(client.index_aliased?(name: "#{namespace}-alias", index: "#{namespace}-index")).to be_falsy
      end

      it "resolves alias to another index" do
        expect(client.resolve_alias(name: "#{namespace}-alias")).to eq(["#{namespace}-another-index"])
      end

      it "aliases index and removes alias to another index" do
        client.alias_index(name: "#{namespace}-alias", index: "#{namespace}-index")
        expect(client.alias_exists?(name: "#{namespace}-alias")).to be_truthy
        expect(client.index_aliased?(name: "#{namespace}-alias", index: "#{namespace}-index")).to be_truthy
        expect(client.index_aliased?(name: "#{namespace}-alias", index: "#{namespace}-another-index")).to be_falsy
      end
    end
  end

  it "indexes and deletes documents in bulk" do
    index_name = "#{namespace}-index"
    client.create_index(index: index_name)

    index_operations = [
      client.bulk_operation(:index, index_name, 1, { name: 'Product 1' }),
      client.bulk_operation(:index, index_name, 2, { name: 'Product 2' }),
    ]

    client.bulk(index_operations)

    docs = client.mget(index_name, [1, 2])
    expect(docs.size).to eq(2)

    delete_operations = [
      client.bulk_operation(:delete, index_name, 1),
    ]

    client.bulk(delete_operations)

    docs = client.mget(index_name, [1, 2])
    expect(docs.size).to eq(1)
  end

  it "proxies refresh to internal client" do
    index = "#{namespace}-index"

    spy_internal_client = spy

    allow(client).to receive(:client) { spy_internal_client }

    client.refresh_index(index: index)

    expect(spy_internal_client).to have_received(:refresh)
  end

  it "proxies search to internal client" do
    index = "#{namespace}-index"
    body  = { query: { match_all: {} } }

    spy_internal_client = spy

    allow(client).to receive(:client) { spy_internal_client }

    client.search(index: index, body: body)

    expect(spy_internal_client).to have_received(:search).with(index: index, body: body)
  end

  it "proxies count to internal client" do
    index = "#{namespace}-index"
    body  = { query: { match_all: {} } }

    spy_internal_client = spy

    allow(client).to receive(:client) { spy_internal_client }

    client.count(index: index, body: body)

    expect(spy_internal_client).to have_received(:count).with(index: index, body: body)
  end

  it "proxies scroll to internal client" do
    index = "#{namespace}-index"
    body  = { query: { match_all: {} } }

    spy_internal_client = spy

    allow(client).to receive(:client) { spy_internal_client }

    client.scroll(index: index, body: body)

    expect(spy_internal_client).to have_received(:scroll).with(index: index, body: body)
  end

  it "proxies clear_scroll to internal client" do
    index = "#{namespace}-index"
    body  = { query: { match_all: {} } }

    spy_internal_client = spy

    allow(client).to receive(:client) { spy_internal_client }

    client.clear_scroll(index: index, body: body)

    expect(spy_internal_client).to have_received(:clear_scroll).with(index: index, body: body)
  end
end
