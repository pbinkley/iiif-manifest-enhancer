require 'json/ld'
require 'rtesseract'
require 'open-uri'
require 'pry'

# Represents a IIIF Manifest parsed from a json-ld file
class IIIFManifest
  attr_reader :input_manifest
  attr_reader :output_manifest

  REPLACE = { from: 'https://purl.stanford.edu', to: 'https://www.wallandbinkley.com/enhancedmanifests' }.freeze
  IDREGEX = /https\:\/\/purl.stanford.edu\/(.*)\/iiif\/manifest/.freeze

  def initialize(source, unitlist, psm)
    @input_manifest = JSON.parse(open(source).read)
    @original_id = get_original_id(@input_manifest['@id'])
    @source = source
    @unitlist = unitlist
    @psm = psm
    @output_manifest = @input_manifest.dup
    @output_manifests = []
  end

  def get_original_id(manifest_id)
    manifest_id.sub(IDREGEX, '\1')
  end

  def process
    # change uris to use new host/path
    crawl(@output_manifest)

    # each unit generates a separate manifest
    @end = @output_manifest['sequences'][0]['canvases'].count

    @unitlist.each_with_index do |unitlist, i|
      unitlist[:end] = @end if unitlist[:end].nil?
      # TODO adjust tocpages to new canvases indexes
      # i.e. subtract start
      unitlist[:toclist].each do |tocpage|
        tocpage -= unitlist[:start] + 1
      end
      # binding.pry

      output_manifest = Marshal.load(Marshal.dump(@output_manifest))
      # remove canvases that aren't part of this unit
      # i.e. not between start and end
      unitcanvases = output_manifest['sequences'][0]['canvases'].slice(unitlist[:start] - 1, unitlist[:end] - unitlist[:start] + 1)
      output_manifest['sequences'][0]['canvases'] = unitcanvases
      # collect canvas ids for use in range 0
      canvases = []
      output_manifest['sequences'][0]['canvases'].each do |canvas|
        canvases.push canvas['@id']
        # binding.pry if i == 1
        # update canvas label
        if unitlist[:offset] > 0
          oldpagelabel = canvas['label'].sub('Page ', '').to_i
          newpagelabel = oldpagelabel - unitlist[:start] + 1 - unitlist[:offset]
          if newpagelabel >= 1
            canvas['label'] = 'Page ' + (newpagelabel).to_s
          else
            canvas['label'] = 'NP'
          end
        end
        # binding.pry if i == 1
      end

      toctext = []
      # TODO if 'structures' already exists, add new one to it
      # binding.pry
      unitlist[:toclist].each do |page|
        # binding.pry
        imageuri = output_manifest['sequences'][0]['canvases'][page - unitlist[:start]]['images'][0]['resource']['service']['@id'] + '/full/full/0/default.png'
        puts 'Fetching ' + imageuri
        open(imageuri) do |imageblob|
          image = RTesseract.new(imageblob, psm: @psm)
          image.to_s.each_line do |line|
            line.strip!
            next if line == ''
            toctext.push line
          end
        end
      end
      output_manifest['structures'] = [
        {
          '@id' => REPLACE[:to] + '/iiif/book1/range/r0',
          '@type' => 'sc:Range',
          label: 'Table of Contents',
          canvases: canvases
        }
      ]

      output_manifest['structures'].concat tocranges(toctext, unitlist[:offset], unitlist[:start])
      # binding.pry
      @output_manifests << output_manifest
    end
  end

  def output
    @output_manifests.each_with_index do |manifest, i|
      File.open(Dir.pwd + '/output/' + @original_id + '_' + (i + 1).to_s + '.json', 'w') do |file|
        file.write(JSON.pretty_generate(manifest))
      end
    end
  end

  def crawl(o)
    o = @output_manifest unless o
    return if o['@type'] == 'dctypes:image'
    o['@id'] = o['@id'].sub(REPLACE[:from], REPLACE[:to]) if o['@id']
    o['on'] =  o['on'].sub(REPLACE[:from],  REPLACE[:to]) if o['on']

    # recurse
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

  def tocranges(toctext, offset, start)
    toc = []
    rangecounter = 0
    # assume toc entries have title, then row of dots with spaces, then page number
    # OCR may mistake the dots for similar punctuation and may add random
    # marks after the page number
    toctext.each do |line|
      if line =~ /(.+?)[ .,'`\-_:;‘’]*(\d+)[ .,'`\-‘’]*$/
        title = $1 + ' (p.' + $2 + ')'
        pagenum = $2
        rangecounter += 1
        # make a single-canvas range associating this title with this page
        range = {
          '@id' => REPLACE[:to] + '/iiif/book1/range/r' + rangecounter.to_s,
          within: REPLACE[:to] + '/iiif/book1/range/r0',
          '@type' => 'sc:Range',
          label: title,
          canvases: [REPLACE[:to] + '/' + @original_id + '/iiif/canvas/' + @original_id + '_' + (pagenum.to_i + offset + start - 1).to_s]
        }
        toc.push range
      else
        puts 'Line skipped: ' + line
      end
    end
    toc
  end
end
