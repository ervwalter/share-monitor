require('buffertools')
readline = require('readline')
os = require('os')
request = require('request-json')
fs = require('fs')
config = require('config')

bitcoin = require('./bitcoin')

sharePattern = /^\d+\,/
hostname = os.hostname()

key = process.argv[2] || ""

clients = []
clients.push request.newClient(server) for server in config.servers

start = ->
    rl = readline.createInterface {
      input: fs.createReadStream('sharelog.pipe')
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
          for client in clients
            console.log "submitting share to #{client.host}"
            client.post "/submitshare?key=#{key}", share, ->
        catch e
          #absorb
        return

    rl.on 'close', ->
        # start another listener
        setTimeout start

start()

