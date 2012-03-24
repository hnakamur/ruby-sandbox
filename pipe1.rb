#!/usr/bin/env ruby

class Command
  attr_reader :pid, :stdin, :stdout, :stderr, :exitstatus

  def exec(*elem)
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

      Process.exec *elem
    end
    in_r.close
    out_w.close
    err_w.close

    @stdin = in_w
    @stdout = out_r
    @stderr = err_r
    @pid
  end

  def loop
    done = false
    until done
      rs, ws = IO.select([stdout, stderr], [], [], 0.01)
      next if rs.nil?
      rs.each{|r|
        begin
          ret = r.read_nonblock 4096
          if r == stdout
            on_data self, ret
          elsif r == stderr
            on_extended_data self, ret
          end
        rescue EOFError
          done = true
        end
      }
    end
    stdout.close
    stderr.close

    status = Process.waitpid2(@pid).last
    @exitstatus = status.exitstatus
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

cmd = Command.new
cmd.exec "./a.sh"
cmd.loop
puts "exitcode is #{cmd.exitstatus}"
