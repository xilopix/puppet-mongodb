#! /usr/bin/ruby

Puppet::Type.newtype(:shard) do
  ensurable

  @doc = %q{Create a shard by connecting through mongo client, with
    a set of server.

    name (string): set the shard name
    replicaset (string): replica name (must match the member's mongod config option)
    members (array): servers to add to the replica as slaves

    Example:
      shard { 'shard_name':
        ensure     => present,
        replicaset => replica_name,
        members    => [
          'shard_member_1.example.com:24019',
          'shard_member_2.example.com:24019',
          'shard_member_3.example.com:24019',
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

  newparam(:replicaset) do
    validate do |value|
      unless value =~ /^[\w\-\d]+/
        raise ArgumentError, "%s should be a string" % value
      end
    end
  end

  newparam(:router) do
    validate do |value|
      unless value =~ /[\w\-\.]+:\d+/
        raise ArgumentError, "%s should respect pattern hostname:port" % value
      end
    end
  end

  newparam(:nodes, :array_matching => :all) do
    validate do |values|
      Array(values).each do |value|
        unless value =~ /[\w\-\.]+:\d+,*/
          raise ArgumentError, "%s should respect pattern hostname:port" % value
        end
      end
    end
  end
end
