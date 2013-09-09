bignum = require('bignum')

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

module.exports =
    decodeHex: decodeHex
    calcDifficulty: calcDifficulty