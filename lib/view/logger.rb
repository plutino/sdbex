require 'tk'

module SDBMan
  module View
    class Logger

      attr_reader :frame

      def initialize parent
        @frame = Ttk::Frame.new(parent,
          borderwidth: 0,
          padding: '5'
        )
        @log_list = Tk::Listbox.new(@frame,
          height: 4,
          borderwidth: 0,
          selectmode: 'browse',
          xscrollcommand: proc {|*args| @xscrollbar.set(*args)},          
          yscrollcommand: proc {|*args| @yscrollbar.set(*args)}          
        ).grid(row: 0, column: 0, sticky: 'nwse')
        @xscrollbar = Ttk::Scrollbar.new(@frame,
          orient: 'horizontal',
          command: proc {|*args| @log_list.xview(*args)}
        ).grid(row: 1, column: 0, sticky: 'nwse')
        @yscrollbar = Ttk::Scrollbar.new(@frame,
          orient: 'vertical',
          command: proc {|*args| @log_list.yview(*args)}
        ).grid(row: 0, column: 1, sticky: 'nwse')
        TkGrid.columnconfigure @frame, 0, weight: 1
        TkGrid.rowconfigure @frame, 0, weight: 1
      end
            
      [:error, :warn, :info].each do |meth|
        define_method(meth) {|msg| log(meth, msg)}
      end
      
      private 
      
      def log level, msg
        @log_list.insert(0, "[#{Time.now.strftime('%FT%T.%L%:z')}] #{msg}")
        unless level == :info
          @log_list.itemconfigure(0, fg: (level == :error ? 'red' : 'blue'))
        end
      end      
    end
  end
end