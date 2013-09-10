Tail = require('tail').Tail

tail = new Tail('shares.log')

tail.on 'line', (data) ->
    console.log data
