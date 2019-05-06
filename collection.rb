#!/usr/bin/env ruby

require 'json'
require 'pry'

Dir.chdir("output")
files = []
Dir["*.json"].each do |filename|
  if filename == 'collection.json'
    File.delete(filename)
  else
    f = JSON.parse(open(filename).read)
    files << { file: filename, label: f['label'] }
  end
end

files.sort_by! { |f| f[:label] }
manifests = []

files.each do |file|
  manifests << {
    '@id' => 'http://localhost:8000/' + file[:file],
    '@type' => 'sc:Manifest',
    'label' => file[:label]
  }
end

collection = {
  '@context' => 'http://iiif.io/api/presentation/2/context.json',
  '@id' => 'http://localhost:8000/collection.json',
  '@type' => 'sc:Collection',
  'label' => 'Stanford Publications 1915-1930',
  'manifests' => manifests
}

# binding.pry

File.open('collection.json', 'w') do |file|
  file.write(JSON.pretty_generate(collection))
end
