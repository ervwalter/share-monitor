module.exports =
    mode: 'stdin' # stdin, pipe, or tail
    filename: 'shares.log' # only needed for pipe or tail modes
    key: 'secret'
    servers: [
        'http://localhost:3000'
    ]
