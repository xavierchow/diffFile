fs = require 'fs'
path = require 'path'
async = require 'async'
_ = require 'lodash'
md5 = require 'MD5'

srcDir = process.argv[2]
benchmark = process.argv[3]
if process.argv[4]? and process.argv[4] is '-o'
  out = process.argv[5]

walkDir = (dir, callback) ->
  fs.readdir dir, (err, files) ->
    if err
      return callback err
    src = []
    for file in files
      fPath = path.join dir, file
      stat = fs.statSync fPath
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
      console.log same
      item.repeated = same.length > 0 and isHashEqual(item.fPath, same[0].fPath)

    for item in srcFiles when item.repeated is not true
      console.log item.fPath
      console.log item.size
