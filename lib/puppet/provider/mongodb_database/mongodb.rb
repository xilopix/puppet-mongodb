require File.expand_path(File.join(File.dirname(__FILE__), '..', 'mongodb'))
Puppet::Type.type(:mongodb_database).provide(:mongodb, :parent => Puppet::Provider::Mongodb) do

  desc "Manages MongoDB database."

  defaultfor :kernel => 'Linux'

  attr_accessor :args

  def self.instances
    require 'json'
    dbs = JSON.parse mongo_eval('printjson(db.getMongo().getDBs())')

    dbs['databases'].collect do |db|
      new(:name   => db['name'],
          :ensure => :present)
    end
  end

  # Assign prefetched dbs based on name.
  def self.prefetch(resources)
    resources.keys.each do |name|
      #
      # set authentication data
      #
      Puppet::Provider::Mongodb.class_variable_set(:@@configuration, resources[name][:client_hash])

      #
      # to avoid not master error for read operations
      #
      dbs = instances

      if provider = dbs.find { |db| db.name == name }
        if ! resources[name].provider
          resources[name].provider = provider
        end
      end
    end
  end

  def create
    @resource[:name] = resource[:db_name]

    if db_ismaster
      if @resource[:name] == 'admin'
        mongo_eval('db.system.version.save({_id: "authSchema", currentVersion: 3})', @resource[:name])
      end

      mongo_eval('db.dummyData.insert({"created_by_puppet": 1})', @resource[:name])
    else
      Puppet.warning 'Database creation is available only from master host'
    end
  end

  def destroy
    if db_ismaster
      mongo_eval('db.dropDatabase()', @resource[:name])
    else
      Puppet.warning 'Database removal is available only from master host'
    end
  end

  def exists?
    !(@property_hash[:ensure] == :absent or @property_hash[:ensure].nil?)
  end

end
