#!/usr/bin/env ruby

require './lib/iiif_manifest_enhancer.rb'
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: run.rb [options]"

  opts.on('-s', '--source val', String, 'Source manifest url') do |s|
    options[:source] = s
  end

  opts.on('-t', '--toc x,y,z', Array, 'List of image numbers of TOC pages') do |toclist|
    options[:toclist] = toclist.map(&:to_i)
  end

end.parse!

p options
p ARGV


x = IIIFManifest.new(options[:source], options[:toclist])
x.process
x.output