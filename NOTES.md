#
# Import and sharding processus for dumps
#

wget -qO- -O dump.tar.xz http://oueb.xilopix.net/dumps/prod/crawl-dump-100k-22092016.tar.xz && tar xvf dump.tar.xz && rm dump.tar.xz
mongorestore --host 10.5.100.244 --port 27017 mongo.dump

mongo admin --host 10.5.100.244:27017 --eval 'printjson(sh.enableSharding( "xilopix" ))'
mongo xilopix --host 10.5.100.244:27017 --eval 'printjson(db.dump.createIndex( { url : 1 } ))'
mongo xilopix --host 10.5.100.244:27017 --eval 'printjson(sh.shardCollection( "xilopix.dump", { "url" : 1 } ))'
