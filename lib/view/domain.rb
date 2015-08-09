require 'tk'
require_relative 'dialog'

module SdbEx
  module View
    class Domain

      attr_reader :frame

      def initialize parent, data, logger
        @callbacks = {}
        @data = data        
        @logger = logger   
        
        @allow_sdb_write = false        
             
        @frame = Ttk::LabelFrame.new(parent,
          text: 'Domains:',
          borderwidth: 0,
          padding: '5 0 5 5'
        )
        
        # domains list
        build_domain_list
      end
      
      def on_changed callback
        @callbacks[:domain_changed] = callback
      end
      
      def set_sdb_write_permission perm
        @allow_sdb_write = perm
      end
            
      def reload 
        @domains.value = @data.domains
        fgc = @domain_list.cget('fg')
        bgc = @domain_list.cget('bg')
        @domain_list.size.times {|idx| @domain_list.itemconfigure idx, fg: fgc, bg: bgc}

        unless @data.active_domain.nil?
          idx = @domains.value.split.find_index(@data.active_domain)
          @domain_list.itemconfigure idx, fg: 'blue', bg: 'yellow'
        end
      end
      
      def popup_menu x, y
        set_selection x, y
        @domain_list.update
        build_menu.popup x, y
      end
      
      def activate_domain x = nil, y = nil        
        set_selection x,y unless x.nil?       
        selection = @domain_list.curselection
        unless selection.empty? || (selected_domain = @domain_list.get(selection)) == @data.active_domain
          unless @data.active_domain.nil?
            curselect = @domains.value.split.find_index(@data.active_domain)
            @domain_list.itemconfigure(curselect, fg: @domain_list.cget('fg'), bg: @domain_list.cget('bg'))
          end
          @domain_list.itemconfigure(selection.first, fg: 'blue', bg: 'yellow')
          @logger.info "Switch to domain `#{selected_domain}'."
          set_active_domain selected_domain
        end
      end
      
      def create_domain
        dialog = Dialog.new(@frame, title: 'Create Domain')
        domain_name = TkVariable.new
        dialog.build do |parent|
          Ttk::Label.new(parent,
            text: 'Domain Name: '
          ).pack(side: 'left')
          Ttk::Entry.new(parent,
            textvariable: domain_name,
            width: 15
          ).pack(side: 'left')
        end
        if dialog.run
          @logger.warn "Create new domain `#{domain_name.value}'."
          @data.create_domain(domain_name.value) 
          reload
        end
      end
      
      def delete_domain
        $console_logger.info 'Domain#delet_domain'
        selected_domain = @domain_list.get(@domain_list.curselection)
        $console_logger.debug "  selected_domain: #{selected_domain}"
        confirmation = Tk::messageBox(
          type: 'yesno',
          title: 'Domain deletion', 
          message: "Do you want to delete domain `#{selected_domain}' and all items within it?", 
          icon: 'warning'
        )

        if confirmation == 'yes'
          @logger.warn "Delete domain `#{selected_domain}' and purge all items within it."
          @data.delete_domain(selected_domain)
          reload
        end
      end
      
      def refresh_domain
        @logger.info "Refresh domain list."
        set_active_domain nil
        reload
      end
            
      private
      
      # build domain list
      def build_domain_list
        @domains = TkVariable.new
        @domain_list = Tk::Listbox.new(@frame,
          borderwidth: 0,
          listvariable: @domains,
          selectmode: 'browse',
          exportselection: false,
          activestyle: 'none'
        ).grid(row: 0, column: 0, sticky: 'nwse')
        @domain_list.xscrollbar(Ttk::Scrollbar.new(@frame).grid(row: 1, column: 0, sticky: 'nwse'))
        @domain_list.yscrollbar(Ttk::Scrollbar.new(@frame).grid(row: 0, column: 1, sticky: 'nwse'))        
        TkGrid.columnconfigure @frame, 0, weight: 1
        TkGrid.rowconfigure @frame, 0, weight: 1
        
        @domain_list.bind 'Double-1', proc { |x,y| activate_domain(x,y) }, "%X %Y"
        @domain_list.bind '2', proc { |x,y| popup_menu(x,y) }, "%X %Y"        
      end
      
      # build popup menu
      def build_menu
        no_selected_domain = @domain_list.curselection.empty?
        menu = TkMenu.new(@domain_list)
        menu.add(:command,
          label: 'Show items',
          command: proc { activate_domain },
          state: no_selected_domain ? 'disabled' : 'normal'
        )
        menu.add(:command, 
          label: 'Refresh', 
          command: proc { refresh_domain } 
        ) 
        if @allow_sdb_write  
          menu.add :separator    
          menu.add(:command, 
            label: 'Create domain', 
            command: proc { create_domain }
          )
          menu.add(:command,
            label: 'Delete domain',
            command: proc { delete_domain },
            state: no_selected_domain ? 'disabled' : 'normal'
          )
        end
        menu
      end

      def set_selection x,y
        @domain_list.selection_clear 0, 'end'
        x_off = x-@domain_list.winfo_rootx
        y_off = y-@domain_list.winfo_rooty
        last_bbox = @domain_list.bbox('end')
        if last_bbox.empty? || last_bbox[1] + last_bbox[3] > y_off
          @domain_list.selection_set "@#{x_off},#{y_off}"
        end        
      end

      def set_active_domain domain
        @data.set_domain domain
        @callbacks[:domain_changed].call unless @callbacks[:domain_changed].nil?
      end
                    
    end
  end
end