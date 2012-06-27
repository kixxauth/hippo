FS = require 'fs'
PATH = require 'path'
URL = require 'url'
CRYP = require 'crypto'
EventEmitter = require('events').EventEmitter

ALLOWED_METHODS = ['HEAD', 'GET', 'PUT', 'DELETE']

class Handler extends EventEmitter
    constructor: (aSpec) ->
        @request = aSpec.request
        @response = aSpec.response
        @url = aSpec.url
        @basepath = aSpec.basepath

    init: ->
        abspath = @route()
        if abspath instanceof Error and abspath.code is 403
            return @respond403()

        switch @request.method
            when 'HEAD', 'GET'
                return @serveGet(abspath)
            when 'PUT'
                return @servePut(abspath)
            when 'DELETE'
                return @serveDelete(abspath)
            else
                return @respond405()
        return

    route: ->
        safepath = @url.pathname.replace(/^\//, '')
        abspath = PATH.resolve(@basepath, safepath)

        if abspath.indexOf(@basepath) isnt 0
            err = new Error("insecure path resolution for '#{@url.pathname}'")
            err.code = 403
            return err
        return abspath

    respond403: ->
        err = new Error("forbidden path: #{@url.pathname}")
        body = Handler.stringifyJSON(err)
        return @respondJSON(403, body)

    respond404: ->
        err = new Error("path not found: #{@url.pathname}")
        body = Handler.stringifyJSON(err)
        return @respondJSON(404, body)

    respond405: ->
        headers =
            'allow': ALLOWED_METHODS.join(', ')

        err = new Error("method '#{@request.method}' not allowed")
        body = Handler.stringifyJSON(err)
        return @respondJSON(405, body, headers)

    respond500: ->
        err = new Error("unexpected server error (check server logs)")
        body = Handler.stringifyJSON(err)

    respondJSON: (aCode, aBody, aHeaders) ->
        headers =
            'content-type': 'application/json; charset=utf-8'
            'content-length': Buffer.byteLength(aBody, 'utf8')

        if aHeaders
            for own p, v of aHeaders
                headers[p] = v

        return @respond(aCode, headers, aBody)

    respond: (aCode, aHeaders, aBody) ->
        @response.writeHead(aCode, aHeaders)
        if not aBody or @request.method is 'HEAD'
            return @response.end()
        return @response.end(aBody)

    serveGet: (aPath) ->
        endpoint = @
        FS.stat aPath, (err, stats) ->
            if err
                if err.code is 'ENOENT'
                    return endpoint.respond404()
                return endpoint.failure(err)

            if stats.isDirectory() then return serveDirectory()
            FS.readFile aPath, (err, buff) ->
                if err then return endpoint.failure(err)
                return serveFile(stats, buff)
            return

        serveFile = (stats, buff) ->
            headers =
                etag: Handler.etag(buff)
                'content-type': 'application/octet-stream'
                'content-length': stats.size

            endpoint.response.writeHead(200, headers)
            if endpoint.request.method is 'HEAD'
                return endpoint.response.end()
            return endpoint.response.end(buff)

        serveDirectory = ->
            FS.readdir aPath, (err, list) ->
                if err then return endpoint.failure(err)
                basepath = endpoint.url.pathname.replace(/\/$/, '')

                list = list.map (filename) ->
                    urlpath = "#{basepath}/#{filename}"
                    abspath = PATH.join(aPath, filename)
                    stats = FS.statSync(abspath)
                    if stats.isDirectory()
                        return urlpath + '/'
                    else
                        return urlpath

                body = Handler.stringifyJSON(null, list)

                headers =
                    etag: Handler.etag(body, 'utf8')

                endpoint.respondJSON(200, body, headers)
                return
            return

        return

    servePut: (aPath) ->
        fstream = null
        pathExists = yes

        @request.on 'end', =>
            status = if pathExists then 204 else 201
            return @respond(status)

        parts = aPath.split('/')
        parts.shift()
        abspath = '/'
        last = parts.length - 1
        parts.forEach (part, i) ->
            part or= '/'
            abspath = PATH.join(abspath, part)
            pathExists = PATH.existsSync(abspath)
            if not pathExists and (i isnt last or part is '/')
                FS.mkdirSync(abspath)
            return

        if abspath.charAt(abspath.length - 1) isnt '/'
            fstream = FS.createWriteStream(abspath)
            @request.pipe(fstream)
        return

    serveDelete: (aPath) ->
        return

    failure: (aError) ->
        @emit('error', aError)
        @respond500()
        return

    @stringifyJSON = (aError, aResult) ->
        if aError
            return JSON.stringify({error: aError.message})
        else
            return JSON.stringify({result: aResult})

    @etag = (aContent, aEncoding) ->
        shasum = CRYP.createHash('sha1')
        shasum.update(aContent, aEncoding)
        return shasum.digest('hex')

exports.Handler = Handler


exports.createHandler = (aOpts) ->
    basepath = aOpts.basepath

    handler = (req, res) ->
        endpoint = new Handler({
            request: req
            response: res
            url: URL.parse(req.url)
            basepath: basepath
        }).init()
        return

    return handler
