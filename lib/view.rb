require_relative 'view/credential'
require_relative 'view/domain'

module SDBMan
  module View
    class Window

      def initialize data
        @data = data
        
        root = TkRoot.new(
          title: 'SDBMan',
          minsize: [600,400]
        )
        TkGrid.columnconfigure root, 0, :weight => 1
        TkGrid.rowconfigure root, 0, :weight => 1
        
        left_frame = Ttk::Frame.new(root).pack(side: 'left', fill: 'y')

        cred = Credential.new(left_frame, data)
        cred.frame.pack(side: 'top', expand: false, fill: 'x')
        cred.on_connect(proc {on_aws_connect})

        @domain = Domain.new(left_frame, data)
        @domain.frame.pack(expand: true, fill: 'both')
        @domain.on_change(self.on_domain_change)
        
      end
      
      def run
        Tk.mainloop
      end
      
      def on_aws_connect
        @domain.reload
      end
      
      def on_domain_change
      end
            
    end
    
    
  end
end