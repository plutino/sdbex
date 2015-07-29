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
#        @items = TkVariable.new_hash        
        @item_tbl = Tk::TkTable.new(@frame,
          titlecols: 1,
          titlerows: 1,
          cols: 0,
          rows: 0,
          font: TkFont.new(size: 14),
#          ellipsis: '...',
          justify: 'left',
          multiline: true,
          colstretchmode: 'unset',
          drawmode: 'slow',
          state: 'disabled',
          selecttype: 'row',
          selectmode: 'extended',
#          selecttitle: true,
#          exportselection: false,
#          variable: @items,
          sparsearray: false,
          usecommand: true,
          command: [ proc{|r, c| set_cell_value(r, c)}, "%r %c"],
          validate: true,
          validatecommand: [ proc{|r, c, val| attr_changed(r, c, val) }, "%r %c %S"],
          rowtagcommand: proc{ |r| set_row_style(r) },
        ).grid(row: 1, column: 0, sticky: 'nwse')
        @item_tbl.xscrollbar(Tk::Scrollbar.new(@frame).grid(row: 2, column: 0, sticky: 'nwse'))
        @item_tbl.yscrollbar(Tk::Scrollbar.new(@frame).grid(row: 1, column: 1, sticky: 'nwse'))
        TkGrid.columnconfigure @frame, 0, weight: 1
        TkGrid.rowconfigure @frame, 1, weight: 1
        
        @item_tbl.bind '2', proc { |x,y| popup_menu(x,y) }, "%X %Y" 
        
        @item_tbl.tag_configure('deleted_item', state: 'disabled', bg: '#ff9999')
        @item_tbl.tag_configure('modified_attr', bg: 'cyan')
        @item_tbl.tag_raise 'modified_attr'
        @item_tbl.tag_raise 'deleted_item'
        
        # popup menu
        build_menu @item_tbl
        
        @allow_sdb_write = false
      end
      
      # public callables
          
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
        redraw
      end
      
      # widget callbacks
      
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
          redraw
          @logger.info "Items updated for new query."
        elsif st != false
          @logger.error st.message      
        end
      end
      
      def set_row_style row
        r = row.to_i
        if @data.item_deleted?(r - 1)
          'deleted_item'
        else
          '{}'
        end
      end
      
      def set_cell_value r, c
#        $console_logger.debug "set_cell_value (#{r}, #{c})"
        if r == 0
          c == 0 ? 'Item' : @data.attrs[c-1]
        elsif r > @data.items.count
          nil
        else
          if c == 0 
            @data.items[r-1][:name] 
          else
            tag = @data.attr_modified?(r-1, c-1) ? 'modified_attr' : '{}'
            @item_tbl.tag_cell tag, "#{r},#{c}"            
            @data.items[r-1][:data][c-1]
          end
        end        
        
      end
      
      def attr_changed r, c, val
        val = val.to_s
        @data.update_attr(r-1, c-1, val.empty? ? nil : val)     
        tag = @data.attr_modified?(r-1, c-1) ? 'modified_attr' : '{}'
        @item_tbl.tag_cell tag, "#{r},#{c}"               
        true
      end
      
      def add_attr
        dialog = Dialog.new(@item_tbl, title: 'Add Attribute')
        attr_name = TkVariable.new
        dialog.build do |parent|
          Ttk::Label.new(parent,
            text: 'Attribute name: '
          ).pack(side: 'left')
          Ttk::Entry.new(parent,
            textvariable: attr_name,
            width: 15
          ).pack(side: 'left')
        end
        
        if dialog.run && !(attr_n = attr_name.value).empty? 
          if @data.add_attr(attr_n)
            @item_tbl['cols'] = @data.attrs.count + 1
            @logger.info "New attribute #{attr_n} is queued to be added."       
          else
            Tk.messageBox(
              type: 'ok',
              title: 'Duplicate attribute',
              message: "Attribute #{attr_n} already exists in the domain.",
              icon: 'warning'
            )
          end
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
                
        if dialog.run && !(item_n = item_name.value).empty? 
          if @data.add_item(item_n)
            @item_tbl['rows'] = @data.items.count + 1
            @logger.info "New item #{item_n} is queued to be added."       
          else
            Tk.messageBox(
              type: 'ok',
              title: 'Duplicate item',
              message: "Item #{item_n} already exists in the domain.",
              icon: 'warning'
            )
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
          indices = @item_tbl.curselection.map{|loc| loc.split(',').first.to_i - 1}.uniq          
          res = @data.delete_items(indices)
          unless res[:deleted].empty?            
            @logger.info "New item(s) deleted: #{res[:deleted].join(', ')}." 
            @item_tbl['rows'] = @data.items.count + 1
          end
          @logger.info "Item(s) marked for deletion: #{res[:marked].join(', ')}" unless res[:marked].empty?
          @item_tbl.selection_clear 'origin', 'end'
        end
      end
      
      def refresh_data
        @data.reload_items
        redraw
      end
      
      private
      
      def redraw
        if @data.items.nil?
          @item_tbl['cols'] = 0
          @item_tbl['rows'] = 0
        else
          @item_tbl['cols'] = @data.attrs.count + 1
          @item_tbl['rows'] = @data.items.count + 1
        end
        @item_tbl.update
      end
      
#      def redraw
#        if @item_data.nil? || @item_data.empty?
#          @item_tbl['cols'] = 0
#          @item_tbl['rows'] = 0
#        else
#          @item_tbl['cols'] = @item_data[:attrs].count + 1
#          @item_tbl['rows'] = @item_data[:items].count + 1
#          @items[0,0] = 'Item'
#          @item_data[:attrs].each_with_index { |v, idx| @items[0, idx+1] = v}
#          @item_data[:items].each_with_index do |item, idx|
#            ridx = idx + 1
#            @items[ridx, 0] = item[:name]
#            item[:data].each_with_index do |v, attr_idx| 
#              @items[ridx, attr_idx+1] = v
#            end
#            if item[:status] == :deleted
#              @item_tbl.tag_row 'deleted_item', ridx
#            else
#              @item_tbl.tag_row_reset ridx
#            end
#            if item[:status] == :changed
#              item[:changed_attrs].each {|attr_idx| @item_tbl.tag 'changed_attr', [ridx, attr_idx+1]}
#            end
#          end
#        end        
#      end
      
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
        @item_menu.add :command, label: 'Refresh', command: proc { refresh_data }  
        if @allow_sdb_write      
          @item_menu.add :separator
          @item_menu.add :command, label: 'Add attribute', command: proc{ add_attr }
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