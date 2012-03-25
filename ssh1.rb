#!/usr/bin/env ruby
require 'rubygems'
require 'net/ssh'

Net::SSH.start '192.168.128.159', 'root', :password => 'password',
    :auth_methods => ['password'],
    :verbose => :fatal do |ssh|
  ssh.open_channel do |channel|
    channel.exec("hostname") do |ch, success|
      abort "could not execute command" unless success

      channel.on_data do |ch, data|
        puts "got stdout: #{data}"
        channel.send_data "something for stdin\n"
      end

      channel.on_extended_data do |ch, type, data|
        puts "got stderr: #{data}"
      end

      channel.on_close do |ch|
        puts "channel is closing!"
      end

      channel.on_request 'exit-status' do |ch, data|
        puts "process terminated with exit status: #{data.read_long}"
      end
    end
  end

  ssh.loop
end
