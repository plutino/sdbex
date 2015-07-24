require 'aws-sdk-v1'

module SdbEx
  class Data
    
    AWS_REGIONS=['us-east-1', 'us-west-1', 'us-west-2']
    ITEM_ORDER_TYPE=['ASC', 'DESC']
  
    attr_reader :active_domain, :query
  
    def initialize **options
      @page_size = options.delete(:page_size) || 100
      @aws_opts = options || {}
      @sdb = nil
      @active_domain = nil  
      @query = {}
    end

    def aws_regions
      AWS_REGIONS
    end
    
    def item_orders
      ITEM_ORDER_TYPE
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
      unless @sdb.nil? || @active_domain == domain
        @active_domain = domain
        @query = { select: '*', order: 'asc'}
        @items = nil
      end
    end
    
    def delete_domain domain
      @sdb.domains[domain].delete!
      @active_domain = nil if @active_domain == domain
    end

    def create_domain domain
      @sdb.domains.create domain
    end
    
    def set_query select: '*', where: nil, order_by: nil, order: 'asc'
      return false if @sdb.nil? || @active_domain.nil?
      new_query= {
        select: select == '*' ? '*' : select.split(/[\s,]+/),
        where: where,
        order_by: order_by,
        order: order
      }
      begin 
        items = get_items(new_query)
      rescue Exception => ex
        return ex
      end
      @query = new_query
      @items = items
      true
    end
      
    def items 
      return [] if @active_domain.nil? 
      @items ||= get_items(@query)       
    end
    
    private
    
    def get_items query
      coll = @sdb.domains[@active_domain].items.select(query[:select])
      coll = coll.where(query[:where]) unless query[:where].nil?
      coll = coll.order(query[:order_by], query[:order]) unless query[:order_by].nil?
      
      header = []
      items = {}
      coll.each do |item|
        data = []
        attrs = item.attributes.dup
        data += header.map { |key| strip_value(attrs.delete(key)) } 
        attrs.each do |k, v| 
          header << k
          data << strip_value(v)
        end
        items[item.name] = {
          data: data
        }
      end
      return {} if items.empty?
      {
        attrs: header,
        items: items
      }
    end
          
    def strip_value value
      if !value.nil? && value.size == 1
        value.first
      else
        value
      end
    end
      
  end
end