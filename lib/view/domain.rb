require 'tk'

module SdbEx
  module View
    class Domain

      attr_reader :frame

      def initialize parent, data, logger
        @callbacks = {}
        @data = data        
        @logger = logger
        @frame = Ttk::LabelFrame.new(parent,
          text: 'Domains:',
          borderwidth: 0,
          padding: '5 0 5 5'
        )
        
        # domains list
        @domains = TkVariable.new
        @domain_list = Tk::Listbox.new(@frame,
          borderwidth: 0,
          listvariable: @domains,
          selectmode: 'single',
        ).grid(row: 0, column: 0, sticky: 'nwse')
        @domain_list.xscrollbar(Ttk::Scrollbar.new(@frame).grid(row: 1, column: 0, sticky: 'nwse'))
        @domain_list.yscrollbar(Ttk::Scrollbar.new(@frame).grid(row: 0, column: 1, sticky: 'nwse'))        
        TkGrid.columnconfigure @frame, 0, weight: 1
        TkGrid.rowconfigure @frame, 0, weight: 1
        
        @domain_list.bind 'Double-1', proc { |x,y| activate_domain(x,y) }, "%X %Y"
        @domain_list.bind '2', proc { |x,y| popup_menu(x,y) }, "%X %Y"

        # popup menu
        @domain_menu = TkMenu.new(@domain_list)
        @domain_menu.add :command, label: 'Show items', command: proc { activate_domain }        
        @domain_menu.add :command, label: 'Delete domain', command: proc { delete_domain }
        @domain_menu.add :separator
        @domain_menu.add :command, label: 'Create domain', command: proc { create_domain }
        
      end
      
      def on_change callback
        @callbacks[:domain_changed] = callback
      end
            
      def reload 
        @domains.value = @data.domains

        #todo do we need this?
#        unless @data.active_domain.nil?
#          idx = @domain_list.split.find_index(@data.active_domain)
#          @list.see idx
#          @list.selection_set idx
#        end
      end
      
      def popup_menu x, y
        set_selected_domain x, y
        @domain_menu.popup x, y
      end
      
      def activate_domain x = nil, y = nil
        set_selected_domain(x, y)  unless x.nil? || y.nil?
        if @selected_domain != @data.active_domain
          @data.set_domain(@selected_domain)
          @callbacks[:domain_changed].call unless @callbacks[:domain_changed].nil?
          @logger.info "Switched to domain #{@selected_domain}."
        end
      end
      
      def create_domain
      end
      
      def delete_domain
        confirmation = Tk::messageBox(
          type: 'yesno',
          title: 'Domain deletion', 
          message: "Do you want to delete domain `#{@selected_domain}' and all items within it?", 
          icon: 'warning'
        )

        if confirmation == 'yes'
          @data.delete_domain(@selected_domain)
          reload
          @logger.warn "Domain `#{@selected_domain}' deleted and all items within it purged."
        end
      end
            
      private
      
      def set_selected_domain x,y
        idx = "@#{x-@domain_list.winfo_rootx},#{y-@domain_list.winfo_rooty}"
        @domain_list.selection_clear 0, 'end'
        @domain_list.selection_set idx
        @selected_domain = @domain_list.get(idx)
      end
            
    end
  end
end