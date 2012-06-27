PATH = require 'path'

REQ = require 'request'
PROC = require 'proctools'

FIXTURES = PATH.join(__dirname, 'fixtures')
ROOTDIR = PATH.dirname(__dirname)
EXPATH = PATH.join(ROOTDIR, 'dist', 'bin', 'hippo.js')

describe 'server', ->
    gServerProc = null

    startServer = (opts, callback) ->
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

    afterEach (done) ->
        if gServerProc is null then return done()
        gServerProc.kill()
        gServerProc = null
        return done()


    it 'should exit if no basepath is provided', (done) ->
        @expectCount(3)
        opts = {}
        startServer opts, (err, proc) ->
            expect(err.message).toBe("process timeout: #{EXPATH}")
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
    return


getLogs = (proc) ->
    lines = proc.buffer.stdout.split('\n').map (line) ->
        try
            return JSON.parse(line)
        catch err
            return line

    return lines
