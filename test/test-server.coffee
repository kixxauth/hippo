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
            timeout: 100

        gServerProc = PROC.start cmd, (err, proc) ->
            return callback(err, proc)
        return

    afterEach (done) ->
        if gServerProc is null then return done()
        gServerProc.kill()
        gServerProc = null
        return done()

    it 'should', (done) ->
        @expectCount(3)
        startServer {}, (err, proc) ->
            expect(err.message).toBe("process timeout: #{EXPATH}")
            expect(err.code).toBe('TIMEOUT')
            expect(err.buffer.stderr.length).toBeTruthy()
            return done()
        return
    return
