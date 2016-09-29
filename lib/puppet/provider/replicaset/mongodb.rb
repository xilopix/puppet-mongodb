#! /usr/bin/ruby

require 'json'

Puppet::Type.type(:replicaset).provide(:mongodb) do
  commands :mongo => '/usr/bin/mongo'

  #
  # Check existence
  #
  def exists?
    debug = true
    client_host = resource[:master]

    primary = mongo("#{client_host}", "--quiet", "--eval", "rs.isMaster().primary")
    hosts   = mongo("#{client_host}", "--quiet", "--eval", "rs.isMaster().hosts")

    if primary.empty?
      Puppet.debug("custom-debug - No primary found - no existing replica") if debug == true
      return false
    elsif hosts.empty?
      Puppet.debug("custom-debug - No hosts found - no existing replica") if debug == true
      return false
    else
      primary.gsub! /"/, ''
      hosts = hosts.split(",").map!{|x| x.tr("\n", '')}
    end

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
    false
  end

  #
  # Create a replica set
  #
  def create
    debug = true

    client_host = resource[:master]
    status = mongo("#{client_host}", "--quiet", "--eval", "rs.status().ok")
    replica_members = {}

    # has replica already been initialized ?
    if Integer(status) == 1
      nb_members = mongo("#{client_host}", "--quiet", "--eval", "rs.status().members.length")
      # retrieve existing replica informations
      for i in 0..(Integer(nb_members) - 1)
        key_member = mongo("#{client_host}", "--quiet", "--eval", "rs.status().members[#{i}].name").tr("\n", '')
        value_health = mongo("#{client_host}", "--quiet", "--eval", "rs.status().members[#{i}].health").tr("\n", '')

        replica_members[key_member] = value_health
      end
    else
      Puppet.debug("custom-debug - Replica initialisation...") if debug == true
      mongo("#{client_host}", "--quiet", "--eval", "rs.initiate()")
    end

    resource[:members].each do |member|
      if !replica_members.has_key?(member)
        Puppet.debug("custom-debug - Add node #{member} in the replica") if debug == true
        mongo("#{client_host}", "--quiet", "--eval", "rs.add(\"#{member}\")")
      end
    end
  end
end
