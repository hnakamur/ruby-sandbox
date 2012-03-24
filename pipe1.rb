#!/usr/bin/env ruby

class Command
  attr_reader :info
  attr_reader :history

  def initialize ()
    @info = {}
    @history = []
  end

  def do(*elem)
    line = elem.join(" ")
    time = Time.now

    rp0, wp0 = IO.pipe
    rp1, wp1 = IO.pipe
    rp2, wp2 = IO.pipe
    pid = Process.fork do
      wp0.close
      rp1.close
      rp2.close
      STDIN.reopen(rp0)
      STDOUT.reopen(wp1)
      STDERR.reopen(wp2)
      exec line
      rp0.close
      wp1.close
      wp2.close
    end

    wp0.puts "hello!"
    wp0.close
    wp1.close
    wp2.close
    stdout = rp1.read
    stderr = rp2.read
    rp1.close
    rp2.close

    status = Process.waitpid2.last
    @info = { :line => line, :pid => pid, :status => status,
      :exitstatus => status.exitstatus, :time => time,
      :stdout => stdout.chomp, :stderr => stderr.chomp }
    @history.push(@info)
  end
end

cmd = Command.new()
cmd.do("./a.sh")
#cmd.do("ls -l", "/etc")
#cmd.do("date")
#cmd.do("ls -l noExistFile")

print "=== command history ===\n"
cmd.history.each do |h|
  print "time => ", h[:time], "\n"
  print "line => ", h[:line], "\n"
  print "exitstatus => ", h[:exitstatus], "\n"
  print "status => ", h[:status], "\n"
  print "stdout => ", h[:stdout], "\n"
  print "stderr => ", h[:stderr], "\n"
  print "-----\n\n"
end
