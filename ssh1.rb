#!/usr/bin/env ruby
require 'rubygems'
require 'net/ssh'


connections = [
  Net::SSH.start('192.168.128.159', 'root', :password => 'password',
    :auth_methods => ['password']),
  # Net::SSH does use configs in ~/.ssh/config!
  Net::SSH.start('naruh', 'hnakamur', :auth_methods => ['publickey'])
]

connections.each do |ssh|
  ssh.open_channel do |channel|
    channel.exec("vmstat 3 3") do |ch, success|
      abort "could not execute command" unless success

      channel.on_data do |ch, data|
        puts "#{ch.connection.host} stdout: #{data}"
        channel.send_data "something for stdin\n"
      end

      channel.on_extended_data do |ch, type, data|
        puts "#{ch.connection.host} stderr: #{data}"
      end

      channel.on_close do |ch|
        puts "#{ch.connection.host}: channel is closing!"
      end

      channel.on_request 'exit-status' do |ch, data|
        puts "#{ch.connection.host}: exit status: #{data.read_long}"
      end
    end
  end
end

def run_and_wait(connections)
  condition = Proc.new {|s| s.busy?}
  cs = connections.clone
  loop do
    cs.delete_if {|ssh| !ssh.process(0.1, &condition)}
    break if cs.empty?
  end
end

run_and_wait connections

connections.each do |ssh|
  ssh.exec!("hostname").tap {|r|
    puts "#{ssh.host} tapped: #{r}"
  }
end
run_and_wait connections
