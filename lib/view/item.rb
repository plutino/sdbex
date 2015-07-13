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
        
        @items = TkVariable.new_hash
        @item_tbl = Tk::TkTable.new(@frame,
          #borderwidth: 1,
          titlecols: 1,
          titlerows: 1,
          cache: true,
          font: TkFont.new(size: 14),
          colstretchmode: 'unset',
          cursor: 'top_left_arrow',
          drawmode: 'slow',
          flashmode: false,
          state: :disabled,
          selecttype: 'row',
          selectmode: 'extended',
          variable: @items,
        ).grid(row: 0, column: 0, sticky: 'nwse')
        @item_tbl.xscrollbar(Ttk::Scrollbar.new(@frame).grid(row: 1, column: 0, sticky: 'nwse'))
        @item_tbl.yscrollbar(Ttk::Scrollbar.new(@frame).grid(row: 0, column: 1, sticky: 'nwse'))
        TkGrid.columnconfigure @frame, 0, weight: 1
        TkGrid.rowconfigure @frame, 0, weight: 1
      end
      
      def reload
        d = @data.items
        @item_tbl['cols'] = @data.attr_ct + 1
        @item_tbl['rows'] = d.count

        unless d.empty?
          d.each_with_index do |row, ridx|
            row.each_with_index do |v, cidx|
              @items[ridx, cidx] = v unless v.nil?
            end
          end            
        end
        
      end
      
    end
  end
end