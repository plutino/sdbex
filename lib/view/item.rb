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
          borderwidth: 0,
          cols: 0,
          rows: 0,
          font: TkFont.new(size: 14),
#          ellipsis: '...',
          justify: 'left',
          multiline: true,
          colstretchmode: 'unset',
#          rowstretchmode: 'unset',
          drawmode: 'slow',
          state: 'disabled',
          selecttype: 'row',
          selectmode: 'extended',
          selecttitle: true,
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
                
        @item_tbl.tag_configure('even_row', bg: '#e0e0e0')
        @item_tbl.tag_configure('deleted_item', state: 'disabled', bg: '#ff9f9f', font: TkFont.new(overstrike: 1))
        @item_tbl.tag_configure('modified_attr', bg: 'cyan')
        @item_tbl.tag_configure('active', relief: 'sunken', bg: '#ffffcc', borderwidth: 1)
        @item_tbl.tag_configure('title', bg: '#3f3f3f', relief: 'raised', borderwidth: 1)
        @item_tbl.tag_raise 'modified_attr'
        @item_tbl.tag_raise 'deleted_item'
        @item_tbl.tag_raise 'active'
        
        @allow_sdb_write = false
      end
      
      # public callables
          
      def set_sdb_write_permission perm
        @allow_sdb_write = perm
        @item_tbl['state'] = perm ? 'normal' : 'disabled'
        @data.reload_items
        redraw
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
        build_menu(x, y).popup(x, y) unless @data.active_domain.nil?
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
        elsif r.even?
          'even_row'
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
            @logger.info "New attribute `#{attr_n}' is queued to be added."       
          else
            Tk.messageBox(
              type: 'ok',
              title: 'Duplicate attribute',
              message: "Attribute `#{attr_n}' already exists in the domain.",
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
            @logger.info "New item `#{item_n}' is queued to be added."       
          else
            Tk.messageBox(
              type: 'ok',
              title: 'Duplicate item',
              message: "Item `#{item_n}' already exists in the domain.",
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
      
      def reset_attr        
        r, c = @item_tbl.index('active').split(',').map(&:to_i)
        i_idx = r-1
        a_idx = c-1
        @data.reset_attr(i_idx, a_idx)
        @logger.info "Undo changes on `#{@data.items[i_idx][:name]}.#{@data.attrs[a_idx]}'."
      end
      
      def reset_items
        rows = @item_tbl.curselection.map{|loc| loc.split(',').first.to_i - 1}.uniq          
        rows.each do |r|
          @data.reset_item r-1
          @item_tbl.tag_row r.even? ? 'even_row' : '{}', r
        end  
        @logger.info "Undo changes on item(s): #{rows.map{|r| @data.items[r-1][:name]}.join(', ')}."   
      end

      def reset_all
        @data.reset_all_items
        @item_tbl.update
        @logger.info "Undo all changes."
      end
      
      # only called if there are pending changes
      def save_items
        confirmation = Tk::messageBox(
          type: 'yesno',
          title: 'Database write', 
          message: "Do you want to write all pending changes to database?", 
          icon: 'question'
        )
        if confirmation == 'yes'
          @logger.warn 'Write pending changes to database.'          
          @data.save_items do |item, op, attrs|
            if op == :new
              @logger.info "Create new item `#{item}' with attribute(s): #{attrs.join(', ')}."
            elsif op == :update
              @logger.info "Update attributes for item `#{item}': #{attrs.join(', ')}."
            elsif op == :delete
              if attrs == :all
                @logger.info "Delete all attributes for item `#{item}'."
              else
                @logger.info "Delete attributes of item `#{item}': #{attrs.join(', ')}."
              end
            end
          end
          redraw
        end
        
      end
      
      def refresh_data
        if @allow_sdb_write && @data.modified?
          confirmation = Tk::messageBox(
            type: 'yesno',
            title: 'Data reload', 
            message: "There are pending changes. Do you want to discard all changes and reload items from database?", 
            icon: 'question'
          )
          return if confirmation == 'no'
        end
        @data.reload_items
        redraw
        @logger.info 'Items reloaded from SimpleDB'
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
      def build_menu(x, y)
        menu = TkMenu.new(@item_tbl)
        menu.add(:command, 
          label: 'Refresh', 
          command: proc { refresh_data }  
        )
        if @allow_sdb_write      
          @item_tbl.activate "@#{x-@item_tbl.winfo_rootx},#{y-@item_tbl.winfo_rooty}"
          @item_tbl.update
          selected_items = @item_tbl.curselection.map{|loc| loc.split(',').first.to_i - 1}.uniq 
          selection_modified = selected_items.any?{|item| @data.item_modified?(item)}
          selection_deleted = selected_items.all?{|item| @data.item_deleted?(item)}
          modified = @data.modified?
          i_idx, a_idx = @item_tbl.index('active').split(',').map{|i| i.to_i - 1}
          attr_modified = @data.attr_modified? i_idx, a_idx
          item_deleted = @data.item_deleted? i_idx

          menu.add :separator
          menu.add(:command, 
            label: 'Add attribute', 
            command: proc{ add_attr }
          )
          menu.add(:command, 
            label: 'Add item', 
            command: proc{ add_item }
          )
          menu.add(:command, 
            label: 'Delete selected items', 
            command: proc{ delete_items },
            state: selected_items.empty? || selection_deleted ? 'disable' : 'normal'
          )
          menu.add :separator
          menu.add(:command, 
            label: 'Reset attribute', 
            command: proc { reset_attr },
            state: attr_modified && ! item_deleted ? 'normal' : 'disable'
          )
          menu.add(:command, 
            label: 'Reset selected items', 
            command: proc { reset_items },
            state: selection_modified ? 'normal' : 'disable'
          )
          menu.add(:command, 
            label: 'Reset all changes',
            command: proc { reset_all },
            state: modified ? 'normal' : 'disable'
          )
          menu.add :separator
          menu.add(:command, 
            label: 'Save changes', 
            command: proc { save_items },
            state: modified ? 'normal' : 'disable'            
          )
        end
        menu
      end
            
    end
  end
end