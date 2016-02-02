#! /usr/bin/ruby

require 'json'

Puppet::Type.type(:replicaset).provide(:ruby) do
  commands :mongo => '/usr/bin/mongo'

  #
  # Check existence
  #
  def exists?
    debug = true

    client_host = "#{Facter.value('fqdn')}:#{resource[:master_port]}"
    primary = mongo("#{client_host}", "--quiet", "--eval", "rs.isMaster().primary")
    hosts   = mongo("#{client_host}", "--quiet", "--eval", "rs.isMaster().hosts")

    primary.gsub! /"/, ''
    hosts   = hosts.split(",").map!{|x| x.tr("\n", '')}

    if ((primary <=> client_host) && (resource[:members].sort == hosts.sort))
      Puppet.debug("custom-debug - The replicaset already exists") if debug == true
      true
    else
      Puppet.debug("custom-debug - The replicaset does not exists") if debug == true
      false
    end
  end

  #
  # Destroy current replica set
  # NOTICE: Primary node can not be destroyed
  #
  def destroy
    replicaset_members = resource[:members]

    replicaset_members.each do |member|
      mongo("#{client_host}", "--quiet", "--eval", "rs.remove(\"#{member}\")")
    end
  end

  #
  # Create a replica set
  #
  def create
    debug = true
    client_host = "#{Facter.value('fqdn')}:#{resource[:master_port]}"
    replicaset_members = resource[:members]

    # initialisation of the replicaset
    mongo("#{client_host}", "--quiet", "--eval", "rs.initiate()")

    replicaset_members.each do |member|
      mongo("#{client_host}", "--quiet", "--eval", "rs.add(\"#{member}\")")
    end
  end
end
