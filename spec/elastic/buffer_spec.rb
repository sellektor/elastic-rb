describe Elastic::Buffer do
  it 'buffers elements' do
    s = spy

    buffer =
      described_class.new(size: 3) do |elements|
        s.process(elements)
      end

    buffer << 1
    buffer << 2

    expect(s).to_not have_received(:process)
  end

  it 'is flushed after reaching size' do
    s = spy

    buffer =
      described_class.new(size: 3) do |elements|
        s.process(elements)
      end

    buffer << 1
    buffer << 2
    buffer << 3

    expect(s).to have_received(:process).with([1, 2, 3])
  end

  it 'can be flushed manually' do
    s = spy

    buffer =
      described_class.new(size: 3) do |elements|
        s.process(elements)
      end

    buffer << 1
    buffer << 2

    buffer.flush!

    expect(s).to have_received(:process).with([1, 2])
  end
end
