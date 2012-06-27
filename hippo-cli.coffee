HTTP = require 'http'

OPT = require 'optimist'
BUN = require 'bunyan'

HIP = require './'

exports.main = ->
    opts = OPT.usage("Run the Hippo File Server")
        .options({'basepath': {alias: 'b', demand: yes}})
        .describe('basepath', "The root path of the file directory to serve.")
        .options({'address': {alias: 'a', 'default': '127.0.0.1'}})
        .describe('address', "The hostname address to run the server on.")
        .options({'port': {alias: 'p', 'default': 8080}})
        .describe('port', "The port to run the server on.")
        .argv

    exports.runServer(opts)
    return

# aOpts.basepath
exports.runServer = (aOpts) ->
    log = BUN.createLogger({name: 'hippo'})
    address = aOpts.address
    port = aOpts.port

    handler = HIP.createHandler(aOpts)
    server = HTTP.createServer(handler)

    server.on 'error', ->
        return log.error.apply(log, arguments)

    server.on 'warn', ->
        return log.warn.apply(log, arguments)

    server.on 'info', ->
        return log.info.apply(log, arguments)

    server.listen port, address, ->
        {address, port} = server.address()
        server.emit('info', "file server running on #{address}:#{port}")
        return

    return

if require.main is module.main
    exports.main()
