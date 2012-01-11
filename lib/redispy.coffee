net = require('net')
EventEmitter = require("events").EventEmitter
Reader = require('./reader')

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
    instruction = 
      date: new Date(line.substring(0, 17)*1000)
      command: arguments.shift()
      arguments: arguments
      
  parseArguments: (line) ->
    escaping = false
    for value, index in line
      if value == '\\'
        escaping = true
      else if !escaping && value == '"'
        return [line.substring(0, index).replace(/\\"/g, '\"')].concat(this.parseArguments(line.substring(index+3)))
      else
        escaping = false

module.exports = Redispy