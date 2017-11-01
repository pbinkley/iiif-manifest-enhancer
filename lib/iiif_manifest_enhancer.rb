require 'json/ld'
require 'rtesseract'
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

    canvases = []
    @output_manifest['sequences'][0]['canvases'].each do |canvas|
      canvases.push canvas['@id']
    end

    rangecounter = 0
    toc = [
      {
        "@id" => "https://www.wallandbinkley.com/enhancedmanifests/iiif/book1/range/r0",
        "@type" => "sc:Range",
        label: "Table of Contents",
        canvases: canvases
      }
    ]

    # for now we'll fetch the toc images from local dir
    ['p3', 'p4'].each do |page|
      image = RTesseract.new('./pageimages/' + page + '.jpg')
      image.to_s.each_line do |line|
        line.strip!
        next if line == ''
        if line =~ /(.+?)[ .,'`\-‘’]*(\d+)[ .,'`\-‘’]*$/
          title = $1 + ' (p.' + $2 + ')'
          pagenum = $2
          rangecounter += 1
          range = {
            "@id" => "https://www.wallandbinkley.com/enhancedmanifests/iiif/book1/range/r" + rangecounter.to_s,
            within: "https://www.wallandbinkley.com/enhancedmanifests/iiif/book1/range/r0",
            "@type" => "sc:Range",
            label: title,
            canvases: ["https://www.wallandbinkley.com/enhancedmanifests/zm715nq6104/iiif/canvas/zm715nq6104_" + pagenum]
          }
          toc.push range
        else
          puts "Line skipped: " + line
        end
      end
    end

@output_manifest['structures'] = toc   
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
