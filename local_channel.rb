class LocalChannel
  attr_reader :local_id, :pid, :stdin, :stdout, :stderr, :exitstatus

  def initialize(connection, local_id)
    @connection = connection
    @local_id = local_id
    @on_data = @on_extended_data = @on_process = nil
  end

  def exec(command, &block)
    in_r, in_w = IO.pipe
    out_r, out_w = IO.pipe
    err_r, err_w = IO.pipe
    @pid = Process.fork do
      in_w.close
      STDIN.reopen in_r
      in_r.close

      out_r.close
      STDOUT.reopen out_w
      out_w.close
      STDOUT.sync = true

      err_r.close
      STDERR.reopen err_w
      err_w.close
      STDERR.sync = true

      Process.exec command
    end
    in_r.close
    out_w.close
    err_w.close

    @stdin = in_w
    @stdout = out_r
    @stderr = err_r

    success = true
    if block
      block.call self, success
    else
      success
    end
  end

  def close
    stdin.close unless stdin.closed?
    stdout.close unless stdout.closed?
    stderr.close unless stderr.closed?
  end

  def process
    @on_process.call self if @on_process
  end

  def do_data(data)
    @on_data.call self, data if @on_data
  end

  def do_extended_data(type, data)
    @on_extended_data.call self, type, data if @on_extended_data
  end

  def on_data(&block)
    old, @on_data = @on_data, block
    old
  end

  def on_extended_data(&block)
    old, @on_extended_data = @on_extended_data, block
    old
  end

  def readers
    r = []
    r << @stdout unless @stdout.closed?
    r << @stderr unless @stderr.closed?
    r
  end
end
