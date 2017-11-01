require './lib/iiif_manifest_enhancer.rb'

x = IIIFManifest.new
x.process
x.output