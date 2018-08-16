RSpec.describe Elastic::Index do
  let(:client)    { elasticsearch_client }
  let(:namespace) { elasticsearch_namespace }

  let(:implementation) do
    Class.new(described_class) do
      self.client = Elastic.client(:test)
      self.alias_name = "#{Elastic.namespace}-implementation"
      self.document_type = "person"
      self.settings = {}
      self.mappings = {
        person: {
          properties: {
            name: { type: 'text' },
            age:  { type: 'integer' }
          }
        }
      }
    end
  end

  subject { implementation.new("#{namespace}-implementation-index") }

  it "initializes with index name" do
    expect(subject.index_name).to eq("#{namespace}-implementation-index")
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

  describe "#bulk_operation" do
    it "builds delete operation" do
      operation = subject.bulk_operation(:delete, 'id')

      expect(operation).to \
        eq(delete: {
          _index: subject.index_name,
          _type:  subject.class.document_type,
          _id:    'id',
          _retry_on_conflict: 3
        })
    end

    it "builds index operation" do
      operation = subject.bulk_operation(:index, 'id', { 'foo' => 'bar' })

      expect(operation).to \
        eq(index: {
          _index: subject.index_name,
          _type:  subject.class.document_type,
          _id:    'id',
          _retry_on_conflict: 3,
          data:   { 'foo' => 'bar' }
        })
    end

    it "builds update operation" do
      operation = subject.bulk_operation(:update, 'id', doc: { 'foo' => 'bar' })

      expect(operation).to \
        eq(update: {
          _index: subject.index_name,
          _type:  subject.class.document_type,
          _id:    'id',
          _retry_on_conflict: 3,
          data:   { doc: { 'foo' => 'bar' } }
        })
    end

    it "builds upsert operation" do
      operation = subject.bulk_operation(:upsert, 'id', doc: { 'foo' => 'bar' })

      expect(operation).to \
        eq(update: {
          _index: subject.index_name,
          _type:  subject.class.document_type,
          _id:    'id',
          _retry_on_conflict: 3,
          data:   { doc_as_upsert: true, doc: { 'foo' => 'bar' } }
        })
    end
  end
end
