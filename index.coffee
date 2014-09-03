fs = require 'fs-extra'
path = require 'path'
async = require 'async'
_ = require 'lodash'
md5 = require 'MD5'
program = require 'commander'

program.version('0.0.1')
  .option('-s, --srcDir [srcDir]', 'src dir')
  .option('-b, --benchmark [benchmark]', 'benchmark dir')
  .option('-e, --ext [extension]', 'excluding file extension')
  .option('-o, --out [out]', 'output dir')
  .parse(process.argv)
{srcDir, benchmark, ext, out } = program
if ext? and ext.indexOf('.') is -1
  ext = ".#{ext}"


isExcluded = (file, ext) ->
  return false unless ext?
  path.extname(file) is ext

walkDir = (dir, callback) ->
  fs.readdir dir, (err, files) ->
    if err
      return callback err
    src = []
    console.log ext
    for file in files
      fPath = path.join dir, file
      stat = fs.statSync fPath
      #only deal with flat dir now
      if stat.isFile() and not isExcluded(file, ext)
        src.push {fPath: fPath, size: stat.size}
    callback null, src

isHashEqual = (src, desc) ->
  buf = fs.readFileSync src
  srcHash = md5(buf)
  buf = fs.readFileSync desc
  destHash = md5(buf)
  return srcHash is destHash
    
async.parallel [
  (callback)->
    walkDir srcDir, callback
  (callback)->
    walkDir benchmark, callback
  ], (error, results) ->
    return console.log "Opps, some error happend: #{error}" if error
    srcFiles = results[0]
    benchFiles = results[1]

    for item in srcFiles
      same = _.where(benchFiles, {'size': item.size})
      console.log same if same.length > 0
      item.repeated = false
      for candidate in same
        if isHashEqual(item.fPath, candidate.fPath)
          item.repeated = true
          break

    for item in srcFiles when item.repeated is false
      console.log item.fPath
      console.log item.size
      if out?
        fs.mkdirsSync(out)
        fName = path.basename(item.fPath)
        fs.copySync(item.fPath, path.join(out, fName))


