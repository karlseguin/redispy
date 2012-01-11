net = require('net')
EventEmitter = require("events").EventEmitter
Reader = require('./reader')

# 1 = key, 2 = N keys, 3 = N Keys + 1 Value, 4 = Key,Value,Key,Value,...
commandKeyRules = {
  'APPEND':1,'BLPOP':3,'BRPOP':3,'DEBUG OBJECT':1,'DECR':1,'DECRBY':1,'DEL':2,
  'EXISTS':1,'EXPIRE':1,'GET':1,'GETBIT':1,'GETRANGE':1,'GETSET':1,
  'HDEL':1,'HEXISTS':1,'HGET':1,'HGETALL':1,'HINCRBY':1,'HKEYS':1,'HLEN':1,
  'HMGET':1,'HMSET':1,'HSET':1,'HSETNX':1,'HVALS':1,'INCR':1,'INCRBY':1,
  'LINDEX':1,'LINSERT':1,'LLEN':1,'LPOP':1,'LPUSH':1,'LPUSHX':1,'LRANGE':1,
  'LREM':1,'LSET':1,'LTRIM':1,'MGET':2,'MOVE':1,'MSET':4,'MSETNX':4,'PERSIST':1,
  'RENAME':1,'RENAMENX':1,'RPOP':1,'RPUSH':1,'RPUSHX':1,'SADD':1,'SCARD':1,'SDIFF':2,
  'SET':1,'SETBIT':1,'SETEX':1,'SETNX':1,'SETRANGE':1,'SINTER':2,'SISMEMBER':1,'SMEMBERS':1,
  'SORT':1,'SPOP':1,'SRANDMEMBER':1,'SREM':1,'STRLEN':1,'SUNION':2,'TTL':1,'TYPE':1,'WATCH':2,
  'ZADD':1,'ZCARD':1,'ZCOUNT':1,'ZINCRBY':1,'ZRANGE':1,'ZRANGEBYSCORE':1,'ZRANK':1,'ZREM':1,
  'ZREMRANGEBYRANK':1,'ZREMRANGEBYSCORE':1,'ZREVRANGE':1,'ZREVRANGEBYSCORE':1,'ZREVRANK':1,'ZSCORE':1
}

class Redispy extends EventEmitter
  constructor: (@host, @port, @database) ->
    @reader = new Reader(this.command)
    
  start: ->
    this.stop()
    console.log('Connecting to on %s:%d db: %d', @host, @port, @database);
    @stream = net.connect @port, @host, =>
      this.connected()
      @stream.on 'data', this.data

  stop: (cb) ->
    if @stream?
      @stream.end('QUIT\r\n', cb) 
    else if cb?
      cb()

  connected: ->
    @stream.write('*2\r\n$6\r\nSELECT\r\n$1\r\n' + @database + '\r\n')  if @database != 0
    @stream.write('MONITOR\r\n')
    
  data: (data) =>
    @reader.read(data)
    
  command: (raw) =>
    return if raw.length == 2 && raw[0] == 79 && raw[1] == 75
    this.emit 'data', this.parse(raw)
    
  parse: (raw) ->
    line = raw.toString()
    arguments = this.parseArguments(line.substring(19))
    arguments.pop()
    command = arguments.shift().toUpperCase()
    [keys, args] = this.extractKeys(command, arguments)
    instruction = 
      date: new Date(line.substring(0, 17)*1000)
      command: command
      keys: keys
      arguments: args
      
  parseArguments: (line) ->
    escaping = false
    for value, index in line
      if value == '\\'
        escaping = true
      else if !escaping && value == '"'
        return [line.substring(0, index).replace(/\\"/g, '\"')].concat(this.parseArguments(line.substring(index+3)))
      else
        escaping = false
        
  extractKeys: (command, arguments) ->
    type = commandKeyRules[command]
    if type == 1
      keys =  [arguments.shift()]
    else if type == 2
      keys = arguments
      arguments = []
    else if type == 3
      length = arguments.length
      keys = arguments.slice(0, length - 1)
      arguments = [arguments[length - 1]]
    else if type == 4
      args = []
      keys = []
      for value, index in arguments
        if index % 2 == 0  then keys.push(value) else args.push(value)
      arguments = args
    else
      keys = []
    return [keys, arguments]

module.exports = Redispy