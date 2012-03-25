require './local_channel'

class LocalConnection
  attr_reader :channels

  def initialize
    @channel_id_counter = -1
    @channels = {}
  end

  def open_channel(&block)
    local_id = get_next_channel_id
    channel = LocalChannel.new self, local_id
    channels[local_id] = channel
    if block
      block.call channel
    end
  end

  def close
    channels.each { |id, channel| channel.close }
    loop(0) { channels.any? }
  end

  def busy?
    channels.any?
  end

  def loop(wait=nil, &block)
    running = block || Proc.new { busy? }
    Kernel.loop { break unless process wait, &running }
  end

  def process(wait=nil, &block)
    return false unless preprocess &block
    r = channels.map { |_, c| c.readers }.flatten
    readers, writers = IO.select r, [], nil, wait
    return true if readers.nil?
    readers.each { |reader|
      channel = get_channel_by_reader reader
      next unless channel
      begin
        data = reader.read_nonblock 4096
        if reader == channel.stdout
          channel.do_data data
        elsif reader == channel.stderr
          channel.do_extended_data :stderr, data
        end
      rescue EOFError
        reader.close
        if channel.readers.empty?
          channels.delete channel.local_id
        end
      end
    }
    return true
  end

  def preprocess
    return false if block_given? && !yield(self)
    return true
  end

  private
    def get_next_channel_id
      @channel_id_counter += 1
    end

    def get_channel_by_reader(reader)
      channels.values.find { |c| c.readers.include? reader }
    end
end
