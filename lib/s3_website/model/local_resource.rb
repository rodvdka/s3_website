require 'tempfile'
require 'zlib'

module S3Website
  class LocalResource
    attr_reader :config, :path, :full_path, :site_dir

    def initialize(path, config, site_dir)
      @path = path
      @full_path = "#{site_dir}/#{path}"
      @config = config
      @site_dir = site_dir
    end

    def details
      resource_desc = path == s3_key ? path : "#{path} as #{s3_key}"
      "#{resource_desc}#{" [gzipped]" if gzip?}#{" [max-age=#{max_age}]" if cache_control?}"
    end

    def s3_key
      s3_key_transformation = (@config['s3_key_transformations'] || []).find { |s3_key_transformation|
        path.match s3_key_transformation['local_filename_regex']
      }
      if s3_key_transformation
        path.gsub(
          Regexp.new(s3_key_transformation['local_filename_regex']),
          s3_key_transformation['s3_key_replacement']
        )
      else
        path
      end
    end

    def gzip?
      return false unless !!config['gzip']

      extensions = config['gzip'].is_a?(Array) ? config['gzip'] : S3Website::DEFAULT_GZIP_EXTENSIONS
      extensions.include?(File.extname(path))
    end

    def upload_options
      opts = {
        :content_type => mime_type,
        :reduced_redundancy => config['s3_reduced_redundancy']
      }

      opts[:content_type] = "text/html; charset=utf-8" if mime_type == 'text/html'
      opts[:content_encoding] = "gzip" if gzip?
      opts[:cache_control] = "max-age=#{max_age}" if cache_control?

      opts
    end

    private

    def cache_control?
      !!config['max_age']
    end

    def max_age
      if config['max_age'].is_a?(Hash)
        max_age_entries_most_specific_first.each do |glob_and_age|
          (glob, age) = glob_and_age
          return age if File.fnmatch(glob, path)
        end
      else
        return config['max_age']
      end

      return 0
    end

    # The most specific max-age glob == the longest glob
    def max_age_entries_most_specific_first
      sorted_by_glob_length = config['max_age'].
        each_pair.
        to_a.
        sort_by do |glob_and_age|
          (glob, age) = glob_and_age
          sort_key = glob.length
        end.
        reverse
    end

    def mime_type
      MIME::Types.type_for(path).first
    end
  end
end
