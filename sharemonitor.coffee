require('buffertools')
readline = require('readline')
os = require('os')
bignum = require('bignum')
request = require('request-json')

servers = [
  'http://bitcoin-command/',
]

rl = readline.createInterface {
  input: process.stdin
  output: process.stdout,
  terminal: false
}

sharePattern = /^\d+\,/
hostname = os.hostname()

key = process.argv[2] || ""

clients = []
clients.push request.newClient(server) for server in servers

rl.on 'line', (line) ->
  if line.match(sharePattern)
    try
      pieces = line.split(',')
      target = pieces[2]
      targetBuffer = decodeHex(target).reverse()
      targetDifficulty = calcDifficulty(targetBuffer)
      shareHash = pieces[6]
      shareBuffer = decodeHex(shareHash).reverse()
      shareDifficulty = calcDifficulty(shareBuffer)
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

encodeHex = (buffer) ->
  buffer.slice(0).toHex().toString('ascii')

decodeHex = (hex) ->
  #Note that we copy (slice) at the end to convert from SlowBuffer to Buffer
  new Buffer(hex, 'ascii').fromHex().slice(0)

#
# Decode difficulty bits.
#
# This function calculates the difficulty target given the difficulty bits.
#
decodeDiffBits = (diffBits, asBigInt = false) ->
  diffBits = +diffBits;
  target = bignum(diffBits & 0xffffff)
  target = target.shiftLeft(8 * ((diffBits >>> 24) - 3))

  if asBigInt
    return target

  # Convert to buffer
  diffBuf = target.toBuffer()
  targetBuf = new Buffer(32).clear()
  diffBuf.copy(targetBuf, 32 - diffBuf.length)
  targetBuf

#
# Calculate "difficulty".
#
# This function calculates the maximum difficulty target divided by the given
# difficulty target.
#
calcDifficulty = (target) ->
  unless Buffer.isBuffer(target)
    target = decodeDiffBits target

  targetBigint = bignum.fromBuffer target, order: 'forward'
  maxBigint = bignum.fromBuffer MAX_TARGET, order: 'forward'
  maxBigint.div(targetBigint).toNumber()

MAX_TARGET = decodeHex('00000000FFFF0000000000000000000000000000000000000000000000000000')
