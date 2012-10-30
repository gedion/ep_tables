author:
  name: ['Gedion Woldeselassie', 'Tenzin Tsetan']
  email: 'gwy321@gmail.com'
name: 'ep_tables'
description: 'Adds tables to etherpad-lite'
version: '0.1.1'
repository:
  type: 'git'
  url: 'git://github.com/gedion/ep_tables.git'
scripts:
  prepublish: """
    ./node_modules/.bin/livescript -j package.ls > package.tmp &&
    mv package.tmp package.json &&
    ./node_modules/.bin/livescript -bc -o static/js src/js
  """
engines: {node: '*'}
dependencies: {}
devDependencies:
  LiveScript: \1.1.x
optionalDependencies: {}
_id: 'ep_tables@0.1.1'
_engineSupported: true
_npmVersion: '1.1.24'
_nodeVersion: 'v0.6.16'
_defaultsLoaded: true
_from: 'ep_tables'
_npmUser:
  name: \gedion
  email: \gwy321@gmail.com
