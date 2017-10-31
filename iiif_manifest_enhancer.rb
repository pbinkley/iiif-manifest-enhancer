require 'json/ld'

input = JSON.parse(File.read(Dir.pwd + '/manifest/manifest.json'))
output = input
File.open(Dir.pwd + '/output/output.json', 'w') do |file|
  file.write(JSON.pretty_generate(output))
end
