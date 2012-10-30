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
