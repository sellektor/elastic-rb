RSpec.describe Elastic::Index do
  let(:client)    { elasticsearch_client }
  let(:namespace) { elasticsearch_namespace }

  let(:implementation) do
    Class.new(described_class) do
      self.client = Elastic.client(:test)
      self.alias_name = "#{Elastic.namespace}-implementation"
      self.settings = {}
      self.mappings = {
        properties: {
          name: { type: 'text' },
          age:  { type: 'integer' }
        }
      }
    end
  end

  let(:docs) do
    [{ "_id" => 1, "_source" => { "name" => "Joe", "age" => 20 } },
     { "_id" => 2, "_source" => { "name" => "Ann", "age" => 10 } },
     { "_id" => 3, "_source" => { "name" => "Tom", "age" => 30 } },
     { "_id" => 4, "_source" => { "name" => "Joe", "age" => 40 } },
     { "_id" => 5, "_source" => { "name" => "Joe", "age" => 50 } }]
  end

  subject { implementation.new("#{namespace}-implementation-index") }

  describe ".resolve" do
    before do
      subject.create
    end

    context "when index is aliased" do
      before do
        subject.promote
      end

      it "returns aliased index" do
        expect(implementation.resolve).to eq(subject)
      end
    end

    context "when index is not aliased" do
      it "returns nil instead of aliased index" do
        expect(implementation.resolve).to be(nil)
      end
    end
  end

  it "initializes with index name" do
    expect(subject.index_name).to eq("#{namespace}-implementation-index")
  end

  it "is not dirty by default" do
    expect(subject.dirty?).to eq(false)
  end

  it "generates index name if not passed as argument" do
    index = implementation.new
    expect(index.index_name).to match(/^#{Elastic.namespace}-implementation-\d+/)
  end

  context "when index does not exist" do
    it "returns false when checking for it's existence" do
      expect(subject.exists?).to be_falsy
    end

    it "creates index" do
      subject.create
      expect(subject.exists?).to be_truthy
    end
  end

  context "when index exists" do
    before do
      subject.create
    end

    it "returns true when checking for it's existence" do
      expect(subject.exists?).to be_truthy
    end

    context "but alias does not exist" do
      it "returns false when checking if it's promoted" do
        expect(subject.promoted?).to be_falsy
      end

      it "gets promoted" do
        subject.promote
        expect(subject.promoted?).to be_truthy
      end
    end

    context "and alias to it exists" do
      before do
        client.alias_index(name: implementation.alias_name, index: subject.index_name)
      end

      it "returns true when checking if it's promoted" do
        expect(subject.promoted?).to be_truthy
      end
    end

    context "and alias to another index exists" do
      let(:another_index) { implementation.new("#{namespace}-another-implementation") }

      before do
        another_index.create
        another_index.promote
      end

      it "returns false when checking if it's promoted" do
        expect(subject.promoted?).to be_falsy
      end

      it "gets promoted and another index gets un-promoted" do
        subject.promote
        expect(subject.promoted?).to be_truthy
        expect(another_index.promoted?).to be_falsy
      end
    end
  end

  describe "#refresh" do
    it "refreshes index" do
      s = spy

      allow(subject).to receive(:client) { s }
      expect(s).to receive(:refresh_index).with(index: subject.index_name)

      subject.refresh
    end

    it "marks index as not dirty" do
      # First, ensure it is marked as dirty
      subject.bulk(:index, '1', data: { 'foo' => 'bar' })
      subject.buffer.flush!

      expect {
        subject.refresh
      }.to change { subject.dirty? }.from(true).to(false)
    end
  end

  describe "#buffer" do
    it "executes operations in bulk" do
      s = spy

      allow(subject).to receive(:client) { s }
      expect(s).to receive(:bulk).once

      subject.bulk(:index, '1', data: { 'foo' => 'bar' })
      subject.bulk(:index, '2', data: { 'abc' => 'xyz' })

      subject.buffer.flush!
    end

    it "marks index as dirty after executing operations" do
      expect {
        subject.bulk(:index, '1', data: { 'foo' => 'bar' })
        subject.buffer.flush!
      }.to change { subject.dirty? }.from(false).to(true)
    end
  end

  describe "#bulk_operation" do
    it "builds delete operation" do
      operation = subject.bulk_operation(:delete, 'id')

      expect(operation).to \
        eq(delete: {
          _index: subject.index_name,
          _id:    'id',
          retry_on_conflict: 3
        })
    end

    it "builds index operation" do
      operation = subject.bulk_operation(:index, 'id', { 'foo' => 'bar' }, { routing: 'foo' })

      expect(operation).to \
        eq(index: {
          _index: subject.index_name,
          _id:    'id',
          retry_on_conflict: 3,
          data:   { 'foo' => 'bar' },
          routing: 'foo'
        })
    end

    it "builds update operation" do
      operation = subject.bulk_operation(:update, 'id', { doc: { 'foo' => 'bar' } }, { routing: 'foo'})

      expect(operation).to \
        eq(update: {
          _index: subject.index_name,
          _id:    'id',
          retry_on_conflict: 3,
          data:   { doc: { 'foo' => 'bar' } },
          routing: 'foo'
        })
    end

    it "builds upsert operation" do
      operation = subject.bulk_operation(:upsert, 'id', { doc: { 'foo' => 'bar' } }, { routing: 'foo' })

      expect(operation).to \
        eq(update: {
          _index: subject.index_name,
          _id:    'id',
          retry_on_conflict: 3,
          data:   { doc_as_upsert: true, doc: { 'foo' => 'bar' } },
          routing: 'foo'
        })
    end
  end

  describe "with documents indexed" do
    before(:each) do
      subject.create
      bulk_index(subject.index_name, docs)
    end

    describe "#count" do
      it "counts all documents" do
        count = subject.count()
        expect(count).to eq(5)
      end

      it "counts documents matching query" do
        count = subject.count(query: { match: { name: "Joe" } })
        expect(count).to eq(3)
      end
    end

    describe "#get" do
      it "gets document by id" do
        document = subject.get("1")
        expect(document).to eq({"_id" => "1", "age" => 20, "name" => "Joe"})
      end

      it "returns nil for wrong id" do
        document = subject.get("batman")
        expect(document).to be(nil)
      end
    end

    describe "#mget" do
      it "gets multiple documents by ids" do
        documents = subject.mget(["1", "2", "batman"])
        expect(documents).to match_array([
          { "_id" => "1", "age" => 20, "name" => "Joe" },
          { "_id" => "2", "age" => 10, "name" => "Ann" }
        ])
      end
    end

    describe "#documents" do
      it "searches documents matching query" do
        documents = subject.documents(query: { match: { name: "Joe" } }).to_a
        expect(documents).to match_array([
          { "_id" => "1", "age" => 20, "name" => "Joe" },
          { "_id" => "4", "age" => 40, "name" => "Joe" },
          { "_id" => "5", "age" => 50, "name" => "Joe" },
        ])
      end
    end

    describe "#document_ids" do
      it "searches ids of documents matching query" do
        document_ids = subject.document_ids(query: { match: { name: "Joe" } }).to_a
        expect(document_ids).to match_array(["1", "4", "5"])
      end
    end
  end
end
