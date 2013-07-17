require 'spec_helper'

describe S3Website::Upload do
  describe 'gzip compression' do
    let(:config) {
      { 'gzip' => true }
    }

    let(:local_resource) {
      S3Website::LocalResource.new(
        path = 'index.html',
        config,
        site_dir = 'features/support/test_site_dirs/my.blog.com/_site'
      )
    }

    describe '#gzipped_file' do
      it 'should return a gzipped version of the file' do
        gz = Zlib::GzipReader.new(
          S3Website::Upload.send(:gzipped_file, local_resource)
        )
        gz.read.should == File.read(
          'features/support/test_site_dirs/my.blog.com/_site/index.html'
        )
      end
    end
  end
end
