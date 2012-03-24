#!/usr/bin/env ruby

class Command
  def do(*elem)
    in_r, in_w = IO.pipe
    out_r, out_w = IO.pipe
    err_r, err_w = IO.pipe
    pid = Process.fork do
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

      exec *elem
    end

    in_r.close
    out_w.close
    err_w.close
    done = false
    until done
      rs, ws = IO.select([out_r, err_r], [], [], 0.01)
      next if rs.nil?
      rs.each{|r|
        begin
          ret = r.read_nonblock 4096
          if r == out_r
            on_data self, ret
          elsif r == err_r
            on_extended_data self, ret
          end
        rescue EOFError
          done = true
        end
      }
    end
    out_r.close
    err_r.close

    status = Process.waitpid2.last
    status.exitstatus
  end

  def on_data(ch, data)
    puts "stdout: #{data}"
    STDOUT.flush
  end

  def on_extended_data(ch, data)
    puts "stderr: #{data}"
    STDOUT.flush
  end
end

cmd = Command.new()
ret = cmd.do "./a.sh"
puts "exitcode is #{ret}"
