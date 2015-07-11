require 'tk'
require 'tkextlib/tktable'

module SDBMan
  module View
    class Item

      attr_reader :frame

      def initialize parent, data, logger
        @callbacks = {}
        @data = data        
        @logger = logger
        @frame = Ttk::Frame.new(parent,
          borderwidth: 0,
          padding: '5'
        )
        
        @item_tbl = Tk::TkTable.new(@frame,
          borderwidth: 0,
          xscrollcommand: proc {|*args| @xscrollbar.set(*args)},          
          yscrollcommand: proc {|*args| @yscrollbar.set(*args)}          
        ).grid(row: 0, column: 0, sticky: 'nwse')
        @xscrollbar = Ttk::Scrollbar.new(@frame,
          orient: 'horizontal',
          command: proc {|*args| @item_tbl.xview(*args)}
        ).grid(row: 1, column: 0, sticky: 'nwse')
        @yscrollbar = Ttk::Scrollbar.new(@frame,
          orient: 'vertical',
          command: proc {|*args| @item_tbl.yview(*args)}
        ).grid(row: 0, column: 1, sticky: 'nwse')
        TkGrid.columnconfigure @frame, 0, weight: 1
        TkGrid.rowconfigure @frame, 0, weight: 1
      end
      
      def reload
        d = @data.items
        @item_tbl['cols'] = @data.attr_ct
        @item_tbl['rows'] = d.count + 1
      end
      
    end
  end
end