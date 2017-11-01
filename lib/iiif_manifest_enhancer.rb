require 'json/ld'
require 'pry'

# Represents a IIIF Manifest parsed from a json-ld file
class IIIFManifest
  attr_reader :input_manifest
  attr_reader :output_manifest

  @@replace = ['https://purl.stanford.edu', 'https://www.wallandbinkley.com/enhancedmanifests']

  def initialize
    @input_manifest = JSON.parse(File.read(Dir.pwd + '/manifest/manifest.json'))
  end

  def process
    @output_manifest = @input_manifest.dup
    crawl(@output_manifest)
  end

  def output
    File.open(Dir.pwd + '/output/output.json', 'w') do |file|
      file.write(JSON.pretty_generate(@output_manifest))
    end
  end

  def crawl(o)
    return if o['@type'] == 'dctypes:image'
    #binding.pry
    o['@id'] = o['@id'].sub(@@replace[0], @@replace[1]) if o['@id']
    o['on'] =  o['on'].sub(@@replace[0],  @@replace[1]) if o['on']
    o.keys.each do |key|
      if o[key].instance_of? Hash
        crawl(o[key])
      elsif o[key].instance_of? Array
        o[key].each do |item|
          if item.instance_of? Hash
            crawl(item)
          end
        end
      end          
    end
  end
end
