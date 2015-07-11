require 'aws-sdk-v1'

module SDBMan
  class Data
  
    attr_reader :active_domain
  
    def initialize **options
      @opts = options || {}
      @sdb = nil
      @active_domain = nil          
    end

    def region_list
      ['us-east-1', 'us-west-1', 'us-west-2']
    end

    # return true if connection changed
    # return false if nothing changed
    # return exception if throws
    def connect key:, secret:, region: 'us-east-1'
      unless @sdb.nil?
        return false if key == @opts[:access_key_id] && secret == @opts[:secret_access_key] && region == @opts[:region]
      end
    
      @opts.merge!({
        access_key_id: key,
        secret_access_key: secret,
        region: region
      }) 
    
      begin
        @sdb = AWS::SimpleDB.new @opts
        domains
      rescue Exception => ex
        @sdb = nil
        @active_domain = nil
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
  
    def items
      return [] if @active_domain.nil?
    end

  end
end