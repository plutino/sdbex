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
        query_frame = Ttk::Frame.new(@frame).grid(row: 0, column: 0, columnspan: 2, sticky:'nwse')
        build_query_interface(query_frame)
        
        # item view    
        @items = TkVariable.new_hash        
        @item_tbl = Tk::TkTable.new(@frame,
          titlecols: 1,
          titlerows: 1,
          cols: 0,
          rows: 0,
          font: TkFont.new(size: 14),
          #ellipsis: '...',
          justify: 'left',
          #multiline: false,
          colstretchmode: 'unset',
          drawmode: 'slow',
          state: 'disabled',
          selecttype: 'row',
          selectmode: 'extended',
          selecttitle: true,
          variable: @items,
          sparsearray: false,
        ).grid(row: 1, column: 0, sticky: 'nwse')
        @item_tbl.xscrollbar(Tk::Scrollbar.new(@frame).grid(row: 2, column: 0, sticky: 'nwse'))
        @item_tbl.yscrollbar(Tk::Scrollbar.new(@frame).grid(row: 1, column: 1, sticky: 'nwse'))
        TkGrid.columnconfigure @frame, 0, weight: 1
        TkGrid.rowconfigure @frame, 1, weight: 1
        
        @item_tbl.bind '2', proc { |x,y| popup_menu(x,y) }, "%X %Y"   
        
        @item_tbl.tag_configure('deleted_item', state: 'disabled', bg: '#ff9999')
        @item_tbl.tag_configure('changed_item', bg: 'cyan')
        
        # popup menu
        build_menu @item_tbl
        
        @allow_sdb_write = false
        @item_data = nil
                 
      end
      
      def set_sdb_write_permission perm
        @allow_sdb_write = perm
        build_menu @item_tbl
        @item_tbl['state'] = perm ? 'normal' : 'disabled'
      end

      def change_domain
        @select.value = @data.query[:select]
        @where.value = @data.query[:where]
        @order_by.value = @data.query[:order_by]
        @order.value = @data.query[:order].upcase
        reload
      end
      
      def popup_menu x, y
        @item_menu.popup x, y
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
      
      def add_item
        dialog = Dialog.new(@item_tbl, title: 'Add Item')
        item_name = TkVariable.new
        dialog.build do |parent|
          Ttk::Label.new(parent,
            text: 'Item name: '
          ).pack(side: 'left')
          Ttk::Entry.new(parent,
            textvariable: item_name,
            width: 15
          ).pack(side: 'left')
        end
        
        if dialog.run && !item_name.value.empty? 
          if @item_data[:items].keys.include? item_name.value
            Tk.messageBox(
              type: 'ok',
              title: 'Duplicate item',
              message: 'Item name already exist in the domain.',
              icon: 'warning'
            )
          else
            @item_tbl.insert_rows 'end', 1
            item = {}
            item[:status] = :new
            item[:data] = [nil] * @item_data[:attrs].count            
            @item_data[:items][item_name.value] = item
            @items[@item_data[:items].count, 0] = item_name.value        
            @item_tbl.update   
            @logger.info "New item #{item_name.value} is queued to be added."       
          end
        end        
      end
      
      def delete_items
        if @item_tbl.curselection.empty?
          Tk.messageBox(
            type: 'ok',
            title: 'Empty selection',
            message: 'No item is selected for deletion.',
            icon: 'warning'
          )
        else
          rows = @item_tbl.curselection.map{|loc| loc.split(',').first.to_i}.uniq
          rows.each do |ridx|
            item_name = @items[ridx, 0]
            item = @item_data[:items][item_name]
            if item[:status] == :new
              @item_data[:items].delete item_name
              @item_tbl.delete_rows ridx, 1
              @logger.info "New item #{item_name} is deleted."
            else
              @item_tbl.tag_row 'deleted_item', ridx
              item[:status] = :deleted
              @logger.info "Item #{item_name} is marked for deletion."
            end
          end
          @item_tbl.selection_clear 'origin', 'end'
          @item_tbl.update
        end
      end
      
      private
      
      def reload        
        @item_data = @data.items
        redraw
      end
      
      def redraw
        if @item_data.nil? || @item_data.empty?
          @item_tbl['cols'] = 0
          @item_tbl['rows'] = 0
        else
          @item_tbl['cols'] = @item_data[:attrs].count + 1
          @item_tbl['rows'] = @item_data[:items].count + 1
          @items[0,0] = 'Item'
          @item_data[:attrs].each_with_index { |v, idx| @items[0, idx+1] = v}
          ridx = 1
          @item_data[:items].each do |name, item|
            @items[ridx, 0] = name
            item[:data].each_with_index do |v, idx| 
              @items[ridx, idx+1] = v.nil? ? 'null' : v
            end
            if item[:status] == :deleted
              @item_tbl.tag_row 'deleted_items', ridx
            else
              @item_tbl.tag_row '{}', ridx
            end
            ridx += 1
          end
        end        
      end
      
      # build query interface
      def build_query_interface(frame)
        Ttk::Label.new(frame,
          text: 'SELECT'
        ).pack(side: 'left')
        @select = TkVariable.new
        Ttk::Entry.new(frame,
          width: 10,
          textvariable: @select,
        ).pack(side: 'left', expand: true, fill: 'x')
        Ttk::Label.new(frame,
          text: 'WHERE'
        ).pack(side: 'left')
        @where = TkVariable.new
        Ttk::Entry.new(frame,        
          width: 20,
          textvariable: @where
        ).pack(side: 'left', expand: true, fill: 'x')
        Ttk::Label.new(frame,
          text: 'ORDER BY'
        ).pack(side: 'left')
        @order_by = TkVariable.new
        Ttk::Entry.new(frame,        
          width: 10,
          textvariable: @order_by
        ).pack(side: 'left')
        @order = TkVariable.new
        Ttk::Combobox.new(frame,
          values: @data.item_orders,
          width: 5,
          textvariable: @order,
          state: :readonly
        ).pack(side: 'left').current = 0
        Ttk::Button.new(frame,
          text: 'Query',
          command: proc {do_query}
        ).pack        
      end
      
      # build popup menu
      def build_menu(parent)
        @item_menu = TkMenu.new(parent)
        @item_menu.add :command, label: 'Refresh', command: proc { refresh }  
        if @allow_sdb_write      
          @item_menu.add :separator
#          @item_menu.add :command, label: 'Add attribute', command: proc{ add_attr }
          @item_menu.add :command, label: 'Add item', command: proc{ add_item }
          @item_menu.add :command, label: 'Delete selected items', command: proc{ delete_items }
#          @item_menu.add :command, label: 'Reset attribute', command: proc { reset_attr }
#          @item_menu.add :command, label: 'Reset item', command: proc { reset_item }
#          @item_menu.add :command, label: 'Reset all changes', command: proc { reset_all }
          @item_menu.add :separator
          @item_menu.add :command, label: 'Save changes', command: proc { save_items}
        end
      end
      
      
    end
  end
end