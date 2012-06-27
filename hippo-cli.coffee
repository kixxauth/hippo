HTTP = require 'http'

OPT = require 'optimist'
BUN = require 'bunyan'

HIP = require './'

exports.main = ->
    opts = OPT.usage("Run the Hippo File Server")
        .options({'basepath': {alias: 'b', demand: yes}})
        .describe('basepath', "The root path of the file directory to serve.")
        .argv

    exports.runServer(opts)
    return

# aOpts.basepath
exports.runServer = (aOpts) ->
    log = BUN.createLogger({name: 'hippo'})
    address = 'localhost'
    port = 8080

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
