#! /usr/bin/ruby

Puppet::Type.type(:replicaset).provide(:ruby) do
  commands :mongo => '/usr/bin/mongo'

  #
  #
  #
  def exists?
    debug = true

    name = resource[:name]
    client_host = "#{Facter.value('fqdn')}:#{resource[:master_port]}"

    replicaset_name = mongo("#{client_host}", "--quiet", "--eval", "rs.status().set")
    Puppet.debug("custom-debug - #{name}:#{replicaset_name}") if debug == true

    name == replicaset_name
  end

  #
  #
  #
  def destroy
    replicaset_members = resource[:members]

    replicaset_members.each do |member|
      mongo("#{client_host}", "--eval", "rs.remove(\"#{member}\")")
    end
  end

  #
  #
  #
  def create
    debug = true
    client_host = "#{Facter.value('fqdn')}:#{resource[:master_port]}"
    replicaset_members = resource[:members]

    # initialisation of the replicaset
    mongo("#{client_host}", "--eval", "rs.initiate()")

    replicaset_members.each do |member|
      mongo("#{client_host}", "--eval", "rs.add(\"#{member}\")")
    end

    output = mongo("#{client_host}", "--eval", "rs.status()")
    Puppet.debug("custom-debug - #{output}") if debug == true
  end
end
