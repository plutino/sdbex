require 'tk'
require 'tkextlib/tktable'

module SdbEx
  module View
    class Item

      QUERY_HISTORY_SIZE = 10

      attr_reader :frame

      def initialize parent, data, logger
        @callbacks = {}
        @data = data        
        @logger = logger
        @frame = Ttk::Frame.new(parent,
          padding: '5'
        )
        
        # query interface
        top_frame = Ttk::Frame.new(@frame).grid(row: 0, column: 0, columnspan: 2, sticky:'nwse')
        Ttk::Label.new(top_frame,
          text: 'SELECT'
        ).pack(side: 'left')
        @select = TkVariable.new
        Ttk::Entry.new(top_frame,
          width: 10,
          textvariable: @select,
        ).pack(side: 'left', expand: true, fill: 'x')
        Ttk::Label.new(top_frame,
          text: 'WHERE'
        ).pack(side: 'left')
        @where = TkVariable.new
        Ttk::Entry.new(top_frame,        
          width: 20,
          textvariable: @where
        ).pack(side: 'left', expand: true, fill: 'x')
        Ttk::Label.new(top_frame,
          text: 'ORDER BY'
        ).pack(side: 'left')
        @order_by = TkVariable.new
        Ttk::Entry.new(top_frame,        
          width: 10,
          textvariable: @order_by
        ).pack(side: 'left')
        @order = TkVariable.new
        Ttk::Combobox.new(top_frame,
          values: @data.item_orders,
          width: 5,
          textvariable: @order,
          state: :readonly
        ).pack(side: 'left').current = 0
        Ttk::Button.new(top_frame,
          text: 'Query',
          command: proc {do_query}
        ).pack
        
        # item view    
        @items = TkVariable.new_hash
        @item_tbl = Tk::TkTable.new(@frame,
          titlecols: 1,
          titlerows: 1,
          cols: 0,
          rows: 0,
          cache: true,
          font: TkFont.new(size: 14),
          #ellipsis: '...',
          justify: 'left',
          #multiline: false,
          colstretchmode: 'unset',
          drawmode: 'slow',
          #state: :disabled,
          selecttype: 'row',
          selectmode: 'extended',
          variable: @items,
          sparsearray: false,
        ).grid(row: 1, column: 0, sticky: 'nwse')
        @item_tbl.xscrollbar(Tk::Scrollbar.new(@frame).grid(row: 2, column: 0, sticky: 'nwse'))
        @item_tbl.yscrollbar(Tk::Scrollbar.new(@frame).grid(row: 1, column: 1, sticky: 'nwse'))
        TkGrid.columnconfigure @frame, 0, weight: 1
        TkGrid.rowconfigure @frame, 1, weight: 1
        
        @item_tbl.tag_configure('attribute', relief: :raised)
        @item_tbl.tag_configure('item_name', bg: 'yellow')
      end
      
      def set_sdb_write_permission perm
        @allow_sdb_write = perm
      end

      def change_domain
        @select.value = @data.query[:select]
        @where.value = @data.query[:where]
        @order_by.value = @data.query[:order_by]
        @order.value = @data.query[:order].upcase
        reload
      end
      
      def do_query
        opts = {}
        select = @select.value.strip
        opts[:select] = select unless select.empty?
        where = @where.value.strip
        opts[:where] = where unless where.empty?
        order_by = @order_by.value.strip
        opts[:order_by] = order_by unless order_by.empty?
        opts[:order] = @order.value.downcase
        st = @data.set_query **opts
        if st == true
          reload
          @logger.info "Items updated for new query."
        elsif st != false
          @logger.error st.message      
        end
      end
      
      private
      
      def reload        
        d = @data.items
        if d.empty?
          @item_tbl['cols'] = 0
          @item_tbl['rows'] = 0
        else
          @item_tbl['cols'] = d.first.count
          @item_tbl['rows'] = d.count
          d.each_with_index do |row, ridx|
            row.each_with_index do |v, cidx|
              @items[ridx, cidx] = v.nil? ? 'null' : v
            end
          end
        end        
      end
      
    end
  end
end