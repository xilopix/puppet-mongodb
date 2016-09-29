#! /usr/bin/ruby

Puppet::Type.newtype(:replicaset) do
  ensurable

  @doc = %q{Create a replicaset by connecting through mongo client, with
    a set of server slaves. The current node will be the master of the replica.

    members (array): servers to add to the replica as slaves
    router: node from which replicaset should be set

    Example:
      replicaset { 'replica_name':
        ensure => present,
        master => master1.example.com:24019,
        members => [
          slave1.example.com:24019,
          slave2.example.com:24019,
        ]
      }
    }

  newparam(:name, :namevar => true) do
    validate do |value|
      unless value =~ /^[\w\-\d]+/
        raise ArgumentError, "%s should be a string" % value
      end
    end
  end

  newparam(:master) do
    validate do |value|
      unless value =~ /[\w\-\.]+:\d+,*/
        raise ArgumentError, "%s should respect pattern hostname:port" % value
      end
    end
  end

  newparam(:members, :array_matching => :all) do
    validate do |values|
      Array(values).each do |value|
        unless value =~ /[\w\-\.]+:\d+,*/
          raise ArgumentError, "%s should respect pattern hostname:port" % value
        end
      end
    end
  end
end
