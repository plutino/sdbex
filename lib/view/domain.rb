require 'tk'

module SDBMan
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
        @domains = TkVariable.new
        @domain_list = Tk::Listbox.new(@frame,
          borderwidth: 0,
          listvariable: @domains,
          selectmode: 'browse',
#          xscrollcommand: proc {|*args| @xscrollbar.set(*args)},          
#          yscrollcommand: proc {|*args| @yscrollbar.set(*args)}          
        ).grid(row: 0, column: 0, sticky: 'nwse')
        @domain_list.xscrollbar(Ttk::Scrollbar.new(@frame).grid(row: 1, column: 0, sticky: 'nwse'))
        @domain_list.yscrollbar(Ttk::Scrollbar.new(@frame).grid(row: 0, column: 1, sticky: 'nwse'))        
#        @xscrollbar = Ttk::Scrollbar.new(@frame,
#          orient: 'horizontal',
#          command: proc {|*args| @list.xview(*args)}
#        ).grid(row: 1, column: 0, sticky: 'nwse')
#        @yscrollbar = Ttk::Scrollbar.new(@frame,
#          orient: 'vertical',
#          command: proc {|*args| @list.yview(*args)}
#        ).grid(row: 0, column: 1, sticky: 'nwse')
        TkGrid.columnconfigure @frame, 0, weight: 1
        TkGrid.rowconfigure @frame, 0, weight: 1
        
        @domain_list.bind '<ListboxSelect>', proc { domain_selected }
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
      
      def domain_selected
        selected_domain = @domains.value.split[@domain_list.curselection.first]
        if selected_domain != @data.active_domain
          @data.set_domain(selected_domain)
          @callbacks[:domain_changed].call unless @callbacks[:domain_changed].nil?
          @logger.info "Switched to domain #{@data.active_domain}."
        end
      end
      
      def on_change callback
        @callbacks[:domain_changed] = callback
      end
      
    end
  end
end