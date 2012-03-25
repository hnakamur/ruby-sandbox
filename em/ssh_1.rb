#!/usr/bin/env ruby
require 'rubygems'
require 'eventmachine'
require 'em-ssh'

EM.run {
  EM::Ssh.start('192.168.128.159', 'root', :password => 'password',
      :auth_methods => ['password']) do |ssh|
    ssh.exec 'vmstat 2 3'
    ssh.close
    EM.stop
  end
}
