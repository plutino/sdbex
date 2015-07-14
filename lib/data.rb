require 'aws-sdk-v1'

module SdbEx
  class Data
    
    AWS_REGIONS=['us-east-1', 'us-west-1', 'us-west-2']
  
    attr_reader :active_domain
  
    def initialize **options
      @page_size = options.delete(:page_size) || 100
      @aws_opts = options || {}
      @sdb = nil
      @active_domain = nil  
      @query = nil        
    end

    def aws_regions
      AWS_REGIONS
    end

    # return true if connection changed
    # return false if nothing changed
    # return exception if throws
    def connect key:, secret:, region: 'us-east-1'
      unless @sdb.nil?
        return false if key == @aws_opts[:access_key_id] && secret == @aws_opts[:secret_access_key] && region == @aws_opts[:region]
      end
    
      @aws_opts.merge!({
        access_key_id: key,
        secret_access_key: secret,
        region: region
      }) 
    
      begin
        @sdb = AWS::SimpleDB.new @aws_opts
        domains
      rescue Exception => ex
        @sdb = nil
        @active_domain = nil
        @query = nil
        return ex
      end
      true
    end
  
    def domains
      return [] if @sdb.nil?
      @sdb.domains.map(&:name).sort
    end

    def set_domain domain
      unless @sdb.nil?
        @active_domain = domain
      end
    end
    
    def attr_ct
      if @active_domain.nil?
        0
      else
        @sdb.domains[@active_domain].metadata.attribute_name_count
      end
    end
      
    def set_query query
      return if @sdb.nil? || @active_domain.nil?
      if query.empty?
        @query = nil
      else
        @query = query
      end
    end
      
    def items
      return [] if @active_domain.nil? 
      header = []
      data = []
      @sdb.domains[@active_domain].items.select(:all).each do |item|
        line = [item.name]
        attrs = item.attributes.dup
        line += header.map { |key| strip_value(attrs.delete(key)) } 
        attrs.each do |k, v| 
          header << k
          line << strip_value(v)
        end
        data << line
      end
      return [] if data.empty?
      [[''] + header] + data
    end
    
    private
    
    def strip_value value
      if !value.nil? && value.size == 1
        value.first
      else
        value
      end
    end
      
  end
end