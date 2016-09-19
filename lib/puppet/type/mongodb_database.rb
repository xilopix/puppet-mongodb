Puppet::Type.newtype(:mongodb_database) do
  @doc = "Manage MongoDB databases."

  ensurable

  newparam(:name, :namevar=>true) do
    desc "The name of the resource database."
    newvalues(/^[\w]+$/)
  end

  newparam(:db_name) do
    desc "The name of the resource database."
    newvalues(/^(\w|-)+$/)
  end

  newparam(:tries) do
    desc "The maximum amount of two second tries to wait MongoDB startup."
    defaultto 10
    newvalues(/^\d+$/)
    munge do |value|
      Integer(value)
    end
  end

  newproperty(:client_hash) do
    desc "The mongod server client configuration."
    validate do |values|
      Hash(values).each do |key, value|
        unless value =~ /.*/
          raise ArgumentError, "%s should respect pattern hostname:port" % value
        end
      end
    end
  end

  autorequire(:package) do
    'mongodb_client'
  end

  autorequire(:service) do
    'mongodb'
  end
end
