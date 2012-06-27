HTTP = require 'http'

OPT = require 'optimist'

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
    address = 'localhost'
    port = 8080

    handler = HIP.createHandler(aOpts)
    server = HTTP.createServer(handler)

    server.listen port, address, ->
        {address, port} = server.address()
        console.log("Hippo File Server running on #{address}:#{port}")
        return

    return

if require.main is module.main
    exports.main()
