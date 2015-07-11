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
        
        h_pane = Ttk::Panedwindow.new(root,
          orient: 'horizontal'
        ).pack(expand: true, fill: 'both')
        
        left_frame = Ttk::Frame.new(h_pane,
          borderwidth: 2,
          relief: 'groove'
        )
        h_pane.add(left_frame)

        cred = Credential.new(left_frame, data)
        cred.frame.pack(side: 'top', fill: 'x')
        cred.on_connect(proc {on_aws_connect})

        @domain = Domain.new(left_frame, data)
        @domain.frame.pack(expand: true, fill: 'both')
        @domain.on_change(self.on_domain_change)
        
        v_pane = Ttk::Panedwindow.new(h_pane,
          orient: 'vertical'
        )
        h_pane.add(v_pane, weight: 1)
        
        item_frame = Ttk::Frame.new(v_pane,
          borderwidth: 2,
          relief: 'groove'          
        )
        Ttk::Label.new(item_frame,
          text: 'Place holder for items'
        ).pack(side: 'top', fill: 'both')
        v_pane.add(item_frame, weight: 3)        

        log_frame = Ttk::Frame.new(v_pane,
          borderwidth: 2,
          relief: 'groove'          
        )
        Ttk::Label.new(log_frame,
          text: 'Place holder for logs'
        ).pack(fill: 'both')
        v_pane.add(log_frame, weight: 1)        
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