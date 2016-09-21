#! /usr/bin/ruby

require 'socket'
require 'timeout'

Puppet::Type.type(:start_detector).provide(:ruby) do
  #
  # mocked method to always create resource
  #
  def exists?
    false
  end

  #
  # mocked method
  #
  def destroy
    true
  end

  #
  # test mandatory servers connectivity
  #
  def create
    debug = true
    servers = resource[:servers]

    # if array has a single element, its strangely becomes a string
    if ! servers.is_a?(Array)
      servers = servers.split(",")
    end

    # allow to fill hash with joined servers
    servers_checked = Hash[servers.map{ |k| [k, false] }]

    Integer(resource[:timeout]).times do
      servers.each do |server|
        begin
          ip, port = server.split(":")

          # avoid to re-test already detected servers
          next if servers_checked[server] == true

          Puppet.debug("#{resource[:name]} Searching connectivity for: #{ip}:#{port}") if debug

          socket = TCPSocket.new(ip, port)
          socket.close

          servers_checked[server] = true
          Puppet.debug("Server #{ip}:#{port} has been reached") if debug

          if resource[:policy] == :one or ! servers_checked.has_value?(false)
            Puppet.debug("All servers have been reached") if debug
            return true
          end
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
          # Do nothing more
        end
      end
      sleep 1
    end

    raise Puppet::Error, "Failed to reach required servers"
  end
end
