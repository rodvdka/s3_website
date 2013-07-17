require 'spec_helper'

describe S3Website::FileyDataSources::LocalResources do
  context 'when there are no S3 key transformations' do
    it 'works like ' + Filey::DataSources::FileSystem.to_s do
      site_dir = 'spec/sample_files/hyde_site/_site'
      local_resources_ds = S3Website::FileyDataSources::LocalResources.new(
        site_dir,
        config = {}
      )

      file_system_ds = Filey::DataSources::FileSystem.new(
        site_dir
      )

      local_resources_ds.get_fileys.map(&:full_path).should eq(
        file_system_ds.get_fileys.map(&:full_path)
      )

      local_resources_ds.get_fileys.map(&:name).should eq(
        file_system_ds.get_fileys.map(&:name)
      )

      local_resources_ds.get_fileys.map(&:path).should eq(
        file_system_ds.get_fileys.map(&:path)
      )

      local_resources_ds.get_fileys.map(&:md5).should eq(
        file_system_ds.get_fileys.map(&:md5)
      )

      local_resources_ds.get_fileys.map(&:last_modified).should eq(
        file_system_ds.get_fileys.map(&:last_modified)
      )
    end
  end

  context 'when the config contains S3 key transformations' do
    it 'honors the S3 key transformations' do
      local_resources_ds = S3Website::FileyDataSources::LocalResources.new(
        site_dir = 'spec/sample_files/s3_key_transformations/_site',
        config = {
          's3_key_transformations' => [{
            'local_filename_regex' => '(.*)/index.html',
            's3_key_replacement' => '\\1',
          }]
        }
      )

      local_resources_ds.get_fileys.map(&:full_path).first.should eq('./articles')
    end
  end
end
