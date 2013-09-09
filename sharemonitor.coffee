require('buffertools')
readline = require('readline')
os = require('os')
request = require('request-json')
fs = require('fs')
config = require('config')

bitcoin = require('./bitcoin')

sharePattern = /^\d+\,/
hostname = os.hostname()

clients = []
clients.push request.newClient(server) for server in config.servers

start = ->
    console.log "Listening on #{__dirname + '/sharelog.pipe'}..."

    rl = readline.createInterface {
        input: fs.createReadStream(__dirname + '/sharelog.pipe')
        output: process.stdout,
        terminal: false
    }

    rl.on 'line', (line) ->
        if line.match(sharePattern)
            try
                pieces = line.split(',')
                target = pieces[2]
                targetBuffer = bitcoin.decodeHex(target).reverse()
                targetDifficulty = bitcoin.calcDifficulty(targetBuffer)
                shareHash = pieces[6]
                shareBuffer = bitcoin.decodeHex(shareHash).reverse()
                shareDifficulty = bitcoin.calcDifficulty(shareBuffer)
                share = {
                    hostname: hostname,
                    timestamp: Number(pieces[0]),
                    result: pieces[1],
                    target: target,
                    targetDifficulty: targetDifficulty,
                    pool: pieces[3],
                    device: pieces[4],
                    thread: pieces[5],
                    shareHash: shareHash,
                    shareDifficulty: shareDifficulty,
                    shareData: pieces[7]
                }
                console.log "Submitting share diff #{share.shareDifficulty}/#{share.targetDifficulty} for pool #{share.pool}"
                for client in clients
                    client.post "/submitshare?key=#{config.key}", share, ->
            catch e
            #absorb
            return

    rl.on 'close', ->
        console.log 'Connection to sharelog.pipe closed.'
        # start another listener
        setTimeout start

start()

