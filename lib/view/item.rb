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
        
        top_frame = Ttk::Frame.new(@frame).grid(row: 0, column: 0, columnspan: 2, sticky:'nwse')
        @query = TkVariable.new
        @query_history = []
        @query_box = Ttk::Combobox.new(top_frame,
          textvariable: @query,
#          postcommand: proc {update_query_history}
        ).pack(side: 'left', expand: true, fill: 'x')
        Ttk::Button.new(top_frame,
          text: 'Query',
          command: proc {query}
        ).pack
                        
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
              @items[ridx, cidx] = v unless v.nil?
            end
          end
        end
        
      end
      
      def query
        q = @query.value.strip
        @query_history.delete(q) if @query_history.include?(q) 
        @query_history.unshift(q)
        @query_history.shift while @query_history.count > QUERY_HISTORY_SIZE
        @query_box['values'] = @query_history
        @data.set_query q
        reload
      end
      
#      def update_query_history
#        puts @query_history.inspect
#        @query_box['values'] = @query_history unless @query_history.empty?
#      end
      
    end
  end
end