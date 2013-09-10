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

startPipe = ->
    console.log "Listening on named pipe #{config.logFile}..."

    rl = readline.createInterface {
        input: fs.createReadStream(config.logFile)
        output: process.stdout,
        terminal: false
    }

    rl.on 'line', parseLine

    rl.on 'close', ->
        console.log 'Named pipe connection closed.'
        # start another listener
        setTimeout startPipe

errorTail = ->
    # most likely the file doesn't exist. try again in 1 second.
    # Note, this only works at initial startup.  If the file is deleted while this is running,
    # there will be an unhandled exception and this script will exit, so the script should
    # probably be run with 'forever'
    console.log "File doesn't exist. Retrying in 1s..."
    setTimeout startTail, 1000

startTail = ->
    console.log "Tailing file #{config.logFile}..."

    try
        tail = new Tail(config.logFile)
        tail.on 'line', parseLine
        tail.on 'error', errorTail
    catch e

if config.pipe
    startPipe()
else
    startTail()
