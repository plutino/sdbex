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
        @active_domain = nil
        @item_data = nil
        domains
      rescue Exception => ex
        @sdb = nil
        return ex
      end
      true
    end
  
    # domain operations
  
    def domains
      return [] if @sdb.nil?
      @sdb.domains.map(&:name).sort
    end

    def set_domain domain
      unless @sdb.nil? || @active_domain == domain
        @active_domain = domain
        @query = { select: '*', order: 'asc'}
        @item_data = nil
      end
    end
    
    def delete_domain domain
      @sdb.domains[domain].delete!
      if @active_domain == domain
        @active_domain = nil
        @item_data = nil
      end
    end

    def create_domain domain
      @sdb.domains.create domain
    end
    
    # query method
    
    def set_query select: '*', where: nil, order_by: nil, order: 'asc'
      return false if @sdb.nil? || @active_domain.nil?
      new_query= {
        select: select == '*' ? '*' : select.split(/[\s,]+/),
        where: where,
        order_by: order_by,
        order: order
      }
      begin 
        new_items = get_items(new_query)
      rescue Exception => ex
        return ex
      end
      @query = new_query
      @item_data = new_items
      true
    end
      
    # item operations
      
    def reload_items
      @item_data = nil
    end
      
    def attrs
      @item_data ||= @active_domain.nil? ? {} : get_items(@query)
      @item_data[:attrs]
    end
      
    def items
      @item_data ||= @active_domain.nil? ? {} : get_items(@query)
      @item_data[:items]
    end
    
    def deleted_item? idx
      items[idx][:status] == :deleted
    end
    
    def new_item? idx
      items[idx][:status] == :new
    end
    
    def modified_item? idx
      items[idx][:status] == :changed
    end
    
    def modified_attrs idx
      items[idx][:changed_attrs]
    end
    
    # following methods modify items data in cache
    # these methods assume @item_data is already loaded
    
    def add_item item_name
      return false if @item_data[:items].map{|i| i[:name]}.include? item_name
      item = {
        name: item_name,
        status: :new,
        data: [nil] * @item_data[:attrs].count 
      }
      @item_data[:items] << item
      true      
    end
    
    def delete_items indices
      res = {}
      res[:deleted] = []
      res[:marked] = []
      indices.sort.reverse.each do |idx|
        item = @item_data[:items][idx]
        if item[:status] == :new
          res[:deleted] << item[:name]
          @item_data[:items].delete_at(idx)
        elsif item[:status] != :deleted
          res[:marked] << item[:name]
          item[:status] = :deleted
        end        
      end
      res
    end
    
    def add_attr attr_name
      return false if @item_data[:attrs].include? attr_name
      @item_data[:attrs] << attr_name
      @item_data[:items].each {|item| item[:data] << nil}
      true
    end
    
    private
    
    def get_items query
      coll = @sdb.domains[@active_domain].items.select(query[:select])
      coll = coll.where(query[:where]) unless query[:where].nil?
      coll = coll.order(query[:order_by], query[:order]) unless query[:order_by].nil?
      
      header = []
      items = []
      coll.each do |item|
        data = []
        attrs = item.attributes.dup
        data += header.map { |key| strip_value(attrs.delete(key)) } 
        attrs.each do |k, v| 
          header << k
          data << strip_value(v)
        end
        items<< {
          name: item.name,
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