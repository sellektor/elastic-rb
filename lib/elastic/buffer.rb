module Elastic
  class Buffer
    DEFAULT_SIZE = 1_000

    attr_reader :size, :queue

    def initialize(size: DEFAULT_SIZE, &blk)
      @size = size
      @callback = blk
      @queue = []
      @lock = Mutex.new
    end

    def <<(object)
      @lock.synchronize do
        @queue << object
        flush! if @queue.size >= size
      end
      self
    end

    def flush!
      if @queue.any?
        @callback.call(@queue) if @callback.is_a? Proc
        @queue = []
      end
    end

    def any?
      @queue.any?
    end
  end
end
