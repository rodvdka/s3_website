module S3Website
  module FileyDataSources
    class LocalResources
      def initialize(site_dir, config)
        @fs = Filey::DataSources::FileSystem.new(site_dir)
        @config = config
        @site_dir = site_dir
      end

      def get_fileys
        @fileys ||= adapt_with_local_resources
      end

      private

      def adapt_with_local_resources
        @fs.get_fileys.map do |filey|
          local_resource = LocalResource.new(filey.full_path, @config, @site_dir)
          s3_key_elements = /(?<path>.*\/)(?<name>.*)/.match(local_resource.s3_key)
          Filey::Filey.new(
            s3_key_elements[:path],
            s3_key_elements[:name],
            filey.last_modified,
            filey.md5
          )
        end
      end
    end
  end
end
