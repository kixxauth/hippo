PATH = require 'path'
EventEmitter = require('events').EventEmitter

REQ = require 'request'
PROC = require 'proctools'

FIXTURES = PATH.join(__dirname, 'fixtures')
ROOTDIR = PATH.dirname(__dirname)
EXPATH = PATH.join(ROOTDIR, 'dist', 'bin', 'hippo.js')


createServerRunner = ->
    self = {}
    gServerProc = null

    self.startServer = (opts, callback) ->
        args = []
        for own p, v of opts
            args.push("--#{p}")
            args.push(v)

        cmd =
            command: EXPATH
            args: args
            timeout: 1000

        gServerProc = PROC.start cmd, (err, proc) ->
            if proc
                log = getLogs(proc)[0]
                if log.err and log.err.code is 'EADDRINUSE'
                    msg = "EADDRINUSE: Check for running server processes"
                    return callback(new Error(msg))
            return callback(err, proc)
        return

    self.killServer = (done) ->
        if gServerProc is null then return done()
        gServerProc.kill()
        gServerProc = null
        return done()

    return self


describe 'server start', ->
    {startServer, killServer} = createServerRunner()

    afterEach(killServer)


    it 'should exit if no basepath is provided', (done) ->
        @expectCount(3)
        opts = {timeout: 100}
        startServer opts, (err, proc) ->
            expect(err.message).toBe("process timeout: #{EXPATH} --timeout 100")
            expect(err.code).toBe('TIMEOUT')
            expect(err.buffer.stderr.length).toBeTruthy()
            return done()
        return


    it 'should start on default address and port', (done) ->
        @expectCount(2)
        opts =
            basepath: PATH.join(FIXTURES, 'default-pub')

        startServer opts, (err, proc) ->
            if err then return done(err)
            log = getLogs(proc)[0]
            expect(log.level).toBe(30)
            expect(log.msg).toBe("file server running on 127.0.0.1:8080")
            return done()
        return

    
    it 'should start on given address', (done) ->
        @expectCount(2)
        opts =
            basepath: PATH.join(FIXTURES, 'default-pub')
            address: 'example.com' # This address will not be available
            port: 8181

        startServer opts, (err, proc) ->
            if err then return done(err)
            log = getLogs(proc)[0]
            expect(log.level).toBe(50)
            expect(log.err.code).toBe('EADDRNOTAVAIL')
            return done()
        return

    
    it 'should start on given port', (done) ->
        @expectCount(2)
        opts =
            basepath: PATH.join(FIXTURES, 'default-pub')
            address: 'localhost'
            port: 8181

        startServer opts, (err, proc) ->
            if err then return done(err)
            log = getLogs(proc)[0]
            expect(log.level).toBe(30)
            expect(log.msg).toBe('file server running on 127.0.0.1:8181')
            return done()
        return

    return


describe 'default pub', ->
    emitter = new EventEmitter()
    {startServer, killServer} = createServerRunner()

    beforeRun (done) ->
        opts =
            basepath: PATH.join(FIXTURES, 'default-pub')

        startServer opts, (err, proc) ->
            if err then return done(err)
            proc.stdout.on 'data', (chunk) ->
                return emitter.emit('stdout', chunk)
            proc.stderr.on 'data', (chunk) ->
                return emitter.emit('stderr', chunk)
            return done()
        return

    afterRun(killServer)


    it 'should list the root directory', (done) ->
        @expectCount(2)

        REQ.get 'http://localhost:8080/', (err, res, body) ->
            expect(res.statusCode).toBe(200)
            body = JSON.parse(body)
            expect(Array.isArray(body.result)).toBeTruthy()
            return done()
        return


    it 'should return 404 for not found', (done) ->
        @expectCount(2)

        REQ.get 'http://localhost:8080/not-found', (err, res, body) ->
            expect(res.statusCode).toBe(404)
            body = JSON.parse(body)
            expect(body.error).toBe("path not found: /not-found")
            return done()
        return

    return


getLogs = (proc) ->
    lines = proc.buffer.stdout.split('\n').map (line) ->
        try
            return JSON.parse(line)
        catch err
            return line

    return lines
