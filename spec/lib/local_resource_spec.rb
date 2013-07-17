require 'spec_helper'

describe S3Website::LocalResource do
  describe 'reduced redundancy setting' do
    let(:config) {
      { 's3_reduced_redundancy' => true }
    }

    it 'allows storing a file under the Reduced Redundancy Storage' do
      local_resource = S3Website::LocalResource.new(
        path = 'a/b/index.html',
        config,
        site_dir = '/opt/website'
      )

      local_resource.upload_options.should include(:reduced_redundancy => true)
    end
  end

  describe 'S3 key transformations' do
    let(:config) {
      {
        's3_key_transformations' => [
          {
            'local_filename_regex' => '(.*)/index.html',
            's3_key_replacement' => '\\1'
          }
        ]
      }
    }

    it 'knows how to infer the S3 key when an S3 key transformation is defined' do
      local_resource = S3Website::LocalResource.new(
        path = 'articles/index.html',
        config,
        site_dir = '/opt/website'
      )

      local_resource.s3_key.should eq('articles')
    end
  end

  describe 'content type resolving' do
    let(:config) {
      {}
    }

    it 'adds the content type of the uploaded CSS file into the S3 object' do
      local_resource = S3Website::LocalResource.new(
        path = 'css/styles.css',
        config,
        site_dir = '/opt/website'
      )

      local_resource.upload_options.should include(:content_type => 'text/css')
    end

    it 'adds the content type of the uploaded HTML file into the S3 object' do
      local_resource = S3Website::LocalResource.new(
        path = 'index.html',
        config,
        site_dir = '/opt/website'
      )

      local_resource.upload_options.should include(
        :content_type => 'text/html; charset=utf-8'
      )
    end
  end

  describe 'cache control' do
    let(:config){
      {
        'max_age' => 300
      }
    }

    let(:local_resource) {
      local_resource = S3Website::LocalResource.new(
        path = 'index.html',
        config,
        site_dir = '/opt/website'
      )
    }

    describe '#cache_control?' do
      it 'should be false if max_age is missing' do
        config.delete 'max_age'
        local_resource.should_not be_cache_control
      end

      it 'should be true if max_age is present' do
        local_resource.should be_cache_control
      end

      it 'should be true if max_age is a hash' do
        config['max_age'] = {'*' => 300}
        local_resource.should be_cache_control
      end
    end

    describe '#gzip?' do
      let(:config){
        {
          'gzip' => true
        }
      }

      it 'should be false if the config does not specify gzip' do
        config.delete 'gzip'
        local_resource.should_not be_gzip
      end

      it 'should be false if gzip is true but does not match a default extension' do
        local_resource.stub(:path).and_return("index.bork")
        local_resource.should_not be_gzip
      end

      it 'should be true if gzip is true and file extension matches' do
        local_resource.should be_gzip
      end

      it 'should be true if gzip is true and file extension matches custom supplied' do
        config['gzip'] = %w(.bork)
        local_resource.stub(:path).and_return('index.bork')
        local_resource.should be_gzip
      end
    end

    describe '#max_age' do
      it 'should be the universal value if one is set' do
        local_resource.send(:max_age).should == 300
      end

      it 'should be the file-specific value if one is set' do
        config['max_age'] = {'*index.html' => 500}
        local_resource.send(:max_age).should == 500
      end

      it 'should be zero if no file-specific value hit' do
        config['max_age'] = {'*.js' => 500}
        local_resource.send(:max_age).should == 0
      end

      context 'overriding the more general setting with the more specific' do
        let(:config){
          {
            'max_age' => {
              '**'        => 150,
              'assets/**' => 86400
            }
          }
        }

        it 'respects the most specific max-age selector' do
          local_resource = S3Website::LocalResource.new(
            path = 'assets/picture.gif',
            config,
            site_dir = '/opt/website'
          )
          local_resource.send(:max_age).should == 86400
        end

        it 'respects the most specific max-age selector' do
          local_resource = S3Website::LocalResource.new(
            path = 'index.html',
            config,
            site_dir = '/opt/website'
          )
          local_resource.send(:max_age).should == 150
        end
      end
    end
  end
end
