require 'tempfile'
require 'zlib'

module S3Website
  class Upload
    def self.perform(local_resource, s3, config)
      upload_file = if local_resource.gzip?
                      gzipped_file(local_resource)
                    else
                      File.open(local_resource.full_path)
                    end
      begin
        success =
          s3.
          buckets[config['s3_bucket']].
          objects[local_resource.s3_key].
          write(upload_file, local_resource.upload_options)
      ensure
        upload_file.close
      end
    end

    private

    def self.gzipped_file(local_resource)
      tempfile = Tempfile.new(File.basename(local_resource.path))

      gz = Zlib::GzipWriter.new(tempfile, Zlib::BEST_COMPRESSION, Zlib::DEFAULT_STRATEGY)

      gz.mtime = File.mtime(local_resource.full_path)
      gz.orig_name = File.basename(local_resource.path)

      File.open(local_resource.full_path) { |f|
        gz.write f.read
      }

      gz.flush
      tempfile.flush

      gz.close
      tempfile.open

      tempfile
    end
  end
end
