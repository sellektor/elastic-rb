RSpec.describe Elastic::Helpers do
  describe '#to_alias_name' do
    it 'generates index alias name for class' do
      alias_name = described_class.to_alias_name("Foo::BarBaz")
      expect(alias_name).to eq("bar_baz")
    end
  end
end
