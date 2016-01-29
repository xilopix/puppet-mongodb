#! /usr/bin/ruby

Puppet::Type.type(:shard).provide(:ruby) do
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
    Puppet.debug("test")
  end
end
