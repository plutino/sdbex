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
      
    # clear current data cache and download data from sdb on next read
    def reload_items
      @item_data = nil
    end
      
    EMPTY_ITEM_DATA = {
      attrs: [],
      items: []
    }
  
    # attributes for current domain and query, 
    # return [] if no active domain is set or if no data available
    def attrs
      @item_data ||= @active_domain.nil? ? EMPTY_ITEM_DATA : get_items(@query)
      @item_data[:attrs]
    end
      
    # items for current domain and query
    # return [] if no active domain is set or if no data available
    def items
      @item_data ||= @active_domain.nil? ? EMPTY_ITEM_DATA : get_items(@query)
      @item_data[:items]
    end
    
    # true if current item list is modified
    def modified?
      @item_data[:items].any?{|item| item_modified?(0, item: item)}
    end
    
    # true if item marked for deletion
    def item_deleted? idx
      @item_data[:items][idx][:status] == :deleted
    end
    
    # true if item is newly created
    def item_new? idx
      @item_data[:items][idx][:status] == :new
    end
    
    # true if item is modified
    def item_modified? idx, item: nil
      item ||= @item_data[:items][idx]
      item.has_key?(:ori_data) || item[:status] == :deleted
    end
    
    # true if attribute of an item is modified
    def attr_modified? item_idx, attr_idx
      item = @item_data[:items][item_idx]
      (item.has_key?(:ori_data) && item[:data][attr_idx] != item[:ori_data][attr_idx]) ||
        (item[:status] == :new && !item[:data][attr_idx].nil?)
    end
    
    # following methods modify items data in cache
    # these methods assume @item_data is already loaded

    def add_attr attr_name
      return false if @item_data[:attrs].include? attr_name
      @item_data[:attrs] << attr_name
      @item_data[:items].each {|item| item[:data] << nil}
      true
    end
    
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
    
    def update_attr item_idx, attr_idx, val
      item = @item_data[:items][item_idx]
      if item.has_key?(:ori_data)
        item[:data][attr_idx] = val
        if item[:data] == item[:ori_data]
          item.delete(:ori_dta) 
        end
      else
        item[:ori_data] = item[:data].dup
        item[:data][attr_idx] = val
      end        
    end
    
    def reset_attr item_idx, attr_idx
      item = @item_data[:items][item_idx]
      if item.has_key?(:ori_data)
        item[:data][attr_idx] = item[:ori_data][attr_idx]
        if item[:data] == item[:ori_data]
          item.delete(:ori_data) 
        end
      end
    end

    def reset_item item_idx, item: nil
      item ||= @item_data[:items][item_idx]
      if item[:status] == :deleted
        item.delete(:status)
      elsif item.has_key?(:ori_data)
        item[:data] = item[:ori_data]
        item.delete(:ori_data)
      end      
    end
    
    def reset_all_items 
      @item_data[:items].each do |item|
        reset_item(0, item: item)
      end
    end
    
    def save_items
      $console_logger.info 'Data#save_items'
      sdb_items = @sdb.domains[@active_domain].items
      deleted_items = []
      $console_logger.debug "  @item_data[:items]: #{@item_data[:items].inspect}"      
      @item_data[:items].each_with_index do |item, idx|
        if item[:status] == :deleted
          yield item[:name], :delete, :all
          $console_logger.debug "  delete item #{item}"
          sdb_items[item[:name]].attributes.delete @item_data[:attrs]
          item.delete(:status)
          deleted_items << idx
        elsif item.has_key?(:ori_data)
          changed_attrs = {}
          deleted_attrs = []
          item[:data].each_with_index do |attrib, idx|
            if attrib != item[:ori_data][idx]
              if attrib.nil?
                deleted_attrs << @item_data[:attrs][idx]
              else
                changed_attrs[@item_data[:attrs][idx]] = attrib
              end
            end
          end
          $console_logger.debug "  update item #{item}"          
          unless changed_attrs.empty?            
            yield item[:name], (item[:status] == :new ? :new : :update), changed_attrs.keys
            sdb_items[item[:name]].attributes.set changed_attrs 
          end
          unless deleted_attrs.empty?
            yield item[:name], :delete, deleted_attrs
            sdb_items[item[:name]].attributes.delete deleted_attrs 
          end
          item.delete(:ori_data)
          item.delete(:status)
        end
      end
      $console_logger.debug "deleted_items: #{deleted_items.inspect}"
      deleted_items.sort.reverse.each do |idx|
        @item_data[:items].delete_at idx
      end
      $console_logger.debug "@item_data[:items]: #{@item_data[:items].inspect}"
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