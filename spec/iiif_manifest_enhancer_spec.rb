require 'iiif_manifest_enhancer'
require 'pry'

describe IIIFManifest do
  describe '.process' do
    context 'when a manifest is processed' do
      it 'has a new id host' do
        manifest = IIIFManifest.new
        manifest.process
        expect(manifest.output_manifest['sequences'][0]['@id']).to eq('https://www.wallandbinkley.com/enhancedmanifests/zm715nq6104#sequence-1')
      end
    end
  end
end
