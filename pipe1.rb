#!/usr/bin/env ruby

class Command
  attr_reader :info
  attr_reader :history
  attr_reader :outdata, :errdata

  def initialize ()
    @info = {}
    @history = []
    @data = []
  end

  def do(*elem)
    line = elem.join(" ")
    time = Time.now

    rp0, wp0 = IO.pipe
    rp1, wp1 = IO.pipe
    rp2, wp2 = IO.pipe
    pid = Process.fork do
      wp0.close
      STDIN.reopen(rp0)
      rp0.close

      rp1.close
      STDOUT.reopen(wp1)
      wp1.close

      rp2.close
      STDERR.reopen(wp2)
      wp2.close

      STDOUT.sync = STDERR.sync = true

      exec *elem
    end

#    wp0.puts "hello!"
    rp0.close
    wp1.close
    wp2.close
    done = false
    until done
      rs, ws = IO.select([rp1, rp2])
      rs.each{|r|
        begin
          ret = r.read_nonblock 4096
          if r == rp1
            on_data self, ret
          elsif r == rp2
            on_extended_data self, ret
          end
        rescue EOFError
          done = true
        end
      }
    end
#    @outdata = rp1.read
#    @errdata = rp2.read
    rp1.close
    rp2.close

    status = Process.waitpid2.last
    status.exitstatus
#    @info = { :line => line, :pid => pid, :status => status,
#      :exitstatus => status.exitstatus, :time => time,
#      :stdout => stdout.chomp, :stderr => stderr.chomp }
#    @history.push(@info)
  end

  def on_data(ch, data)
    puts "stdout: #{data}"
  end

  def on_extended_data(ch, data)
    puts "stderr: #{data}"
  end
end

cmd = Command.new()
ret = cmd.do "./a.sh"
puts "exitcode is #{ret}"

#cmd.do("ls -l", "/etc")
#cmd.do("date")
#cmd.do("ls -l noExistFile")

#print "=== command history ===\n"
#cmd.history.each do |h|
#  print "time => ", h[:time], "\n"
#  print "line => ", h[:line], "\n"
#  print "exitstatus => ", h[:exitstatus], "\n"
#  print "status => ", h[:status], "\n"
#  print "stdout => ", h[:stdout], "\n"
#  print "stderr => ", h[:stderr], "\n"
#  print "-----\n\n"
#end
