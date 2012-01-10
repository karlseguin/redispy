class Reader  
  constructor: (@callback) ->
    
  read: (buffer) ->
    end = this.findEnd(buffer)
    if end?
      if @partial 
        message = new Buffer(@partial.length + end)
        @partial.copy(message)
        buffer.copy(message, @partial.length, 0, end)
      else
        message = buffer.slice(0, end)
      
      @partial = null
      @callback(message.slice(1, message.length - 2))
      this.read(buffer.slice(end)) if end < buffer.length
    else
      if @partial
        @temp = new Buffer(@partial.length + buffer.length)
        @partial.copy(@temp)
        buffer.copy(@temp, @partial.length)
        @partial = @temp
      else
        @partial = buffer
      
  
  findEnd: (buffer) ->
    for value,index in buffer
      if value == 10
        if (index > 0 && buffer[index-1] == 13) || (@partial? && @partial[@partial.length - 1] == 13)
          return index+1
    null
      
module.exports = Reader