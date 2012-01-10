#Redispy
Hooks into Redis' [monitor](http://redis.io/commands/monitor) command and exposes the parsed information in a usable manner. 

A concrete example of how this can be used is in the works. For now, you can use it like:

	var redispy = require('redispy');
	//0 is the database
	spy = new redispy('localhost', 6379, 0);  
	spy.on('data', function(data) {
		var command = data.command;
		var date = data.date;
		var arguments = data.arguments;
	});
	spy.start();
	...
	spy.stop();

Note that the `monitor` command, which this relies on, is considered a debugging tool. Using it in production will cause performance degradation.