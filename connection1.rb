#!/usr/bin/env ruby
require './local_connection'

conn = LocalConnection.new
conn.open_channel { |channel|
  channel.exec('./a.sh') { |ch, success|
    abort 'could not execute command' unless success
    channel.on_data { |ch, data|
      puts "stdout: #{data}"
    }
    channel.on_extended_data { |ch, type, data|
      puts "stderr: #{data}"
    }
  }
}
conn.open_channel { |channel|
  channel.exec('hostname') { |ch, success|
    abort 'could not execute command' unless success
    channel.on_data { |ch, data|
      puts "hostname stdout: #{data}"
    }
    channel.on_extended_data { |ch, type, data|
      puts "hostname stderr: #{data}"
    }
  }
}

conn.loop
