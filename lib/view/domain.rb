require 'tk'

module SDBMan
  module View
    class Domain

      attr_reader :frame

      def initialize parent, data
        @callbacks = {}
        @data = data        
        @frame = Ttk::LabelFrame.new(parent,
          text: 'Domains:',
          borderwidth: 2,
          padding: '5 0 5 5'
        )
        @domain_list = TkVariable.new
        @list = Tk::Listbox.new(@frame,
          borderwidth: 0,
          listvariable: @domain_list,
          selectmode: 'single',
          xscrollcommand: proc {|*args| @xscrollbar.set(*args)},          
          yscrollcommand: proc {|*args| @yscrollbar.set(*args)}          
        ).grid(row: 0, column: 0, sticky: 'nwse')
        @xscrollbar = Ttk::Scrollbar.new(@frame,
          orient: 'horizontal',
          command: proc {|*args| @list.xview(*args)}
        ).grid(row: 1, column: 0, sticky: 'nwse')
        @yscrollbar = Ttk::Scrollbar.new(@frame,
          orient: 'vertical',
          command: proc {|*args| @list.yview(*args)}
        ).grid(row: 0, column: 1, sticky: 'nwse')
        TkGrid.columnconfigure @frame, 0, weight: 1
        TkGrid.rowconfigure @frame, 0, weight: 1
      end
      
      def reload 
        @domain_list.value = @data.domains
      end
      
      def on_change callback
        @callbacks[:domain_changed] = callback
      end
      
    end
  end
end