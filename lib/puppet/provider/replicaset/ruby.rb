#! /usr/bin/ruby

Puppet::Type.type(:replicaset).provide(:ruby) do
  #
  #
  #
  def exists?
    false
  end

  #
  #
  #
  def destroy
    true
  end

  #
  #
  #
  def create
    debug = true

    Puppet.debug("custom-debug - #{resource[:router]}") if debug == true
  end
end
