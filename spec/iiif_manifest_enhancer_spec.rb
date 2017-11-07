require 'iiif_manifest_enhancer'
require 'pry'

describe IIIFManifest do
  describe '.process' do
    context 'processed manifest' do
      let(:manifest) { IIIFManifest.new('./manifest/manifest.json', '11', 2) }
      it 'has a new id host' do
        manifest.crawl(nil)
        expect(manifest.output_manifest['sequences'][0]['@id']).to eq('https://www.wallandbinkley.com/enhancedmanifests/zm715nq6104#sequence-1')
      end
      it 'has a table of contents' do
        manifest.output_manifest['structures'] = []
        manifest.tocranges(['OFFICE DIRECTORY . . . . 5'])
        expect(manifest.output_manifest['structures'][0][:label]).to eq('OFFICE DIRECTORY (p.5)')
      end
      it 'has an original id' do
        expect(manifest.get_original_id(manifest.output_manifest['@id'])).to eq('zm715nq6104')
      end
    end
  end
end
