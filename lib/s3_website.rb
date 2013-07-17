require 'rubygems'
require 'yaml'
require 'erubis'
require 'aws-sdk'
require 'simple-cloudfront-invalidator'
require 'filey-diff'
require 'mime/types'
require 'thor'

module S3Website
  DEFAULT_GZIP_EXTENSIONS = %w(.html .css .js .svg .txt)
end

%w{
  config_loader
  diff_helper
  errors
  jekyll
  keyboard
  model/endpoint
  model/local_resource
  nanoc
  parallelism
  paths
  retry
  tasks
  upload
  uploader
}.each do |file|
  require File.dirname(__FILE__) + "/s3_website/#{file}"
end

%w{invalidator}.each do |file|
  require File.dirname(__FILE__) + "/cloudfront/#{file}"
end

%w{local_resources_ds}.each do |file|
  require File.dirname(__FILE__) + "/filey/#{file}"
end
