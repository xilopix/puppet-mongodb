#! /usr/bin/ruby

require 'json'

Puppet::Type.type(:replicaset).provide(:mongodb) do
  commands :mongo => '/usr/bin/mongo'

  def active_debug
    true
  end

  def get_client
    resource[:master]
  end

  #
  # Check existence
  #
  def exists?
    primary = mongo("#{get_client}", "--quiet", "--eval", "rs.isMaster().primary")
    hosts   = mongo("#{get_client}", "--quiet", "--eval", "rs.isMaster().hosts")

    if primary.empty?
      Puppet.debug("REPLICASET-DEBUG: No primary found - no existing replica") if active_debug
      return false
    elsif hosts.empty?
      Puppet.debug("REPLICASET-DEBUG: No hosts found - no existing replica") if active_debug
      return false
    else
      primary.gsub! /"/, ''
      hosts = hosts.split(",").map!{|x| x.tr("\n", '')}
    end

    if ((primary <=> get_client) && (resource[:members].sort == hosts.sort))
      Puppet.debug("REPLICASET-DEBUG: The replicaset already exists") if active_debug
      true
    else
      Puppet.debug("REPLICASET-DEBUG: The replicaset does not exists") if active_debug
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
  # Add a member to replicaset
  #
  def add_member_to_replicaset(replica_members, member)
    if !replica_members.has_key?(member)
      Puppet.debug("REPLICASET-DEBUG: Add node #{member} in the replica") if active_debug
      mongo("#{get_client}", "--quiet", "--eval", "rs.add(\"#{member}\")")
    end
  end

  #
  # Create a replica set
  #
  def create
    status = mongo("#{get_client}", "--quiet", "--eval", "rs.status().ok")
    replica_members = {}

    # has replica already been initialized ?
    if Integer(status) == 1
      nb_members = mongo("#{get_client}", "--quiet", "--eval", "rs.status().members.length")
      # retrieve existing replica informations
      for i in 0..(Integer(nb_members) - 1)
        key_member = mongo("#{get_client}", "--quiet", "--eval", "rs.status().members[#{i}].name").tr("\n", '')
        value_health = mongo("#{get_client}", "--quiet", "--eval", "rs.status().members[#{i}].health").tr("\n", '')

        replica_members[key_member] = value_health
      end
    else
      Puppet.debug("REPLICASET-DEBUG: Replica initialisation...") if active_debug
      mongo("#{get_client}", "--quiet", "--eval", "rs.initiate()")
    end

    if resource[:members].is_a? Array
      resource[:members].each do |member|
        self.add_member_to_replicaset(replica_members, resource[:members])
      end
    else
      self.add_member_to_replicaset(replica_members, resource[:members])
    end
  end
end
