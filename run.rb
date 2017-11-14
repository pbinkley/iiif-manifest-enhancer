#!/usr/bin/env ruby

require './lib/iiif_manifest_enhancer.rb'
require 'optparse'

options = { unitlist: [], psm: 6 }

OptionParser.new do |opts|
  opts.banner = 'Usage: run.rb [options]'

  opts.on('-s', '--source val', String, 'Source manifest url') do |s|
    options[:source] = s
  end

  opts.on('-u', '--unit <start>|<offset>|<toclist>|<title>', String, 'Settings for an output manifest') do |unitopts|
    unit = {}
    # expect start|offset|tocpages|title
    a, b, c, d = unitopts.split('|')
    unit[:start] = a != '' ? a.to_i : 1
    unit[:offset] = b != '' ? b.to_i : 0
    unit[:toclist] = c != '' ? c.split(',').map(&:to_i) : []
    unit[:title] = d
    options[:unitlist] << unit
  end

  opts.on('-p', '--psm val', Integer, 'Tesseract PSM (default : 6)') do |psm|
    options[:psm] = psm
  end
end.parse!

if options[:unitlist].count == 0
  options[:unitlist] << { start: 1, offset: 0, toclist: [] }
else
  # add end to each unit; last unit can be nil
  options[:unitlist].each_with_index do |unit, i|
    if options[:unitlist].count == i + 1
      unit[:end] = nil
    else
      unit[:end] = options[:unitlist][i + 1][:start] - 1
    end
  end
end

x = IIIFManifest.new(options[:source], options[:unitlist], options[:psm])
x.process
x.output