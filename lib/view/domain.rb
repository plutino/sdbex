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
        h_frame = Ttk::Frame.new(@frame,
          borderwidth: 0
        ).pack(side: 'left', expand: true, fill: 'both')
        @domain_list = TkVariable.new
        @list = Tk::Listbox.new(h_frame,
          borderwidth: 0,
          listvariable: @domain_list,
          selectmode: 'single',
          xscrollcommand: proc {|*args| @xscrollbar.set(*args)},          
          yscrollcommand: proc {|*args| @yscrollbar.set(*args)}          
        ).pack(side: 'top', expand: true, fill: 'both') 
        @xscrollbar = Ttk::Scrollbar.new(h_frame,
          orient: 'horizontal',
          command: proc {|*args| @list.xview(*args)}
        ).pack(fill: 'x')
        @yscrollbar = Ttk::Scrollbar.new(@frame,
          orient: 'vertical',
          command: proc {|*args| @list.yview(*args)}
        ).pack(side: 'right', fill: 'y')     
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