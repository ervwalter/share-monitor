require('buffertools')
readline = require('readline')
os = require('os')
request = require('request-json')
fs = require('fs')
Tail = require('tail').Tail
config = require('config')

bitcoin = require('./bitcoin')

sharePattern = /^\d+\,/
hostname = os.hostname()

clients = []
clients.push request.newClient(server) for server in config.servers

parseLine = (line) ->
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

rl = null

startPipe = ->

    if config.mode == 'pipe'
        console.log "Listening on named pipe #{config.filename}..."
        input = fs.createReadStream(config.filename)
    else
        console.log "Reading from stdin..."
        input = process.stdin


    rl = readline.createInterface {
        input: input
        output: process.stdout,
        terminal: false
    }

    rl.on 'line', parseLine

    rl.on 'close', ->
        if config.mode == 'pipe'
            console.log 'Named pipe connection closed.'
            setTimeout startPipe

startTail = ->
    console.log "Tailing file #{config.filename}..."
    tail = new Tail(config.filename)
    tail.on 'line', parseLine

if config.mode == 'tail'
    startTail()
else
    startPipe()
