#! /usr/bin/ruby

Puppet::Type.type(:shard).provide(:ruby) do
  commands :mongo => '/usr/bin/mongo'

  #
  # test shard existence
  #
  def exists?
    debug = true
    output = mongo_command('sh.status()', "#{resource[:router]}")

    for i in 0..Integer(output['shards'].length)
      if output['shards'][i].nil?
        return false
      end

      match = /([^\/].+)\/(.+)/.match(output['shards'][i]['host'])
      replica = output['shards'][i]['_id']

      nodes = $2.split(",")

      if replica.eql? resource[:replicaset]
        if nodes.sort != resource[:nodes].sort
          Puppet.warning("custom-debug - Missing nodes into the shard, please add them manually")
        end
        Puppet.debug("custom-debug - The shard already exists") if debug == true
        return true
        break
      end
    end

    false
  end

  #
  # the shards won't be deleted through puppet
  #
  def destroy
    true
  end

  #
  # add shards
  #
  def create
    begin
      count = 3

      nodes_str = resource[:nodes].join(",")
      command = "sh.addShard(\"#{resource[:replicaset]}/#{nodes_str}\")"
      result = mongo_command(command, "#{resource[:router]}")

      shard_not_added = ((!result['shardAdded'].eql? resource[:replicaset]) or (result['ok'] != 1))

      while (shard_not_added and (count > 0))
        count = (count - 1)

        nodes_str = resource[:nodes].join(",")
        command = "sh.addShard(\"#{resource[:replicaset]}/#{nodes_str}\")"
        result = mongo_command(command, "#{resource[:router]}")
        shard_not_added = ((!result['shardAdded'].eql? resource[:replicaset]) or (result['ok'] != 1))

        sleep 5

        if !shard_not_added then
          return result
        end
      end

      if shard_not_added
        raise Puppet::Error, "The shard creation failed"
      end
    rescue Puppet::ExecutionFailure => e
      Puppet.warning "Got an exception: #{e}"
    end
  end

  #
  # command wrapper
  #
  def mongo_command(command, host, retries=4)
    self.class.mongo_command(command,host,retries)
  end

  #
  # result command parser
  #
  def self.mongo_command(command, host=nil, retries=4)
    debug = true
    # Allow waiting for mongod to become ready
    # Wait for 2 seconds initially and double the delay at each retry
    wait = 20
    begin
      args = Array.new
      args << '--quiet'
      args << ['--host',host] if host
      args << ['--eval', "printjson(#{command})"]
      output = mongo(args.flatten)
      puts output
    rescue Puppet::ExecutionFailure => e
      if e =~ /Error: couldn't connect to server/ and wait <= 2**max_wait
        info("Waiting #{wait} seconds for mongod to become available")
        sleep wait
        wait *= 2
        retry
      else
        raise
      end
    end

    # NOTE (spredzy) : sh.status()
    # does not return a json stream
    # we jsonify it so it is easier
    # to parse and deal with it
    if command == 'sh.status()'
      myarr = output.split("\n")
      myarr.shift
      myarr.pop
      myarr.pop
      final_stream = []
      prev_line = nil
      in_shard_list = 0
      in_chunk = 0
      myarr.each do |line|
        line.gsub!(/sharding version:/, '{ "sharding version":')
        line.gsub!(/shards:/, ',"shards":[')
        line.gsub!(/databases:/, '], "databases":[')
        line.gsub!(/"clusterId" : ObjectId\("(.*)"\)/, '"clusterId" : "ObjectId(\'\1\')"')
        line.gsub!(/\{  "_id" :/, ",{  \"_id\" :") if /_id/ =~ prev_line
        # Modification for shard
        line = '' if line =~ /on :.*Timestamp/
        if line =~ /_id/ and in_shard_list == 1
          in_shard_list = 0
          last_line = final_stream.pop.strip
          proper_line = "#{last_line}]},"
          final_stream << proper_line
        end
        if line =~ /shard key/ and in_shard_list == 1
          shard_name = final_stream.pop.strip
          proper_line = ",{\"#{shard_name}\":"
          final_stream << proper_line
        end
        if line =~ /shard key/ and in_shard_list == 0
          in_shard_list = 1
          shard_name = final_stream.pop.strip
          id_line = "#{final_stream.pop[0..-2]}, \"shards\": "
          proper_line = "[{\"#{shard_name}\":"
          final_stream << id_line
          final_stream << proper_line
        end
        if in_chunk == 1
          in_chunk = 0
          line = "\"#{line.strip}\"}}"
        end
        if line =~ /chunks/ and in_chunk == 0
          in_chunk = 1
        end
        line.gsub!(/shard key/, '{"shard key"')
        line.gsub!(/chunks/, ',"chunks"')
        final_stream << line if line.size > 0
        prev_line = line
      end

      final_stream << ' ] }' if in_shard_list == 1
      final_stream << ' ] }'

      output = final_stream.join("\n")
    elsif command =~ /sh\.addShard.*/
      output.gsub!(/ => /, ':')
    end

    #Hack to avoid non-json empty sets
    output = "{}" if output == "null\n"
    output.gsub!(/\s*/, '')

    match = /(balancer:.*)"databases":/.match(output)
    if !$1.nil?
      output.sub!($1, '],')
    end

    return JSON.parse(output)
  end
end
