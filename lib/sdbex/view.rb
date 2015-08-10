require_relative 'view/credential'
require_relative 'view/domain'
require_relative 'view/item'
require_relative 'view/logger'

module SdbEx
  module View
    class Window

      def initialize data
        @data = data
        
        root = TkRoot.new(
          title: 'SdbEx',
          minsize: [900,600]
        )
        TkGrid.columnconfigure root, 0, :weight => 1
        TkGrid.rowconfigure root, 0, :weight => 1
        
        # panes and main frames
        h_pane = Ttk::Panedwindow.new(root,
          orient: 'horizontal'
        ).pack(expand: true, fill: 'both')
        
        left_frame = Ttk::Frame.new(h_pane,
          borderwidth: 2,
          relief: 'groove'
        )
        h_pane.add(left_frame)
        v_pane = Ttk::Panedwindow.new(h_pane,
          orient: 'vertical'
        )
        h_pane.add(v_pane, weight: 1)
        item_frame = Ttk::Frame.new(v_pane,
          borderwidth: 2,
          relief: 'groove'          
        )
        v_pane.add(item_frame, weight: 5)                
        log_frame = Ttk::Frame.new(v_pane,
          borderwidth: 2,
          relief: 'groove'          
        )
        v_pane.add(log_frame, weight: 1)        
        
        # logger
        @logger = Logger.new(log_frame)        
        @logger.frame.pack(expand: true, fill: 'both')
        
        # credential
        cred = Credential.new(left_frame, data, @logger)
        cred.frame.pack(side: 'top', fill: 'x')
        cred.on_aws_connected proc{ aws_connected }
        cred.on_sdb_write_permission_changed proc{|perm| sdb_write_permission_changed(perm)}

        # domain
        @domain = Domain.new(left_frame, data, @logger)
        @domain.frame.pack(expand: true, fill: 'both')
        @domain.on_changed proc{domain_changed}
        
        # item
        @item = Item.new(item_frame, data, @logger)
        @item.frame.pack(expand: true, fill: 'both')
      end
      
      def run        
        Tk.mainloop
      end
      
      def aws_connected
        @domain.reload
      end
      
      def domain_changed
        @item.change_domain
      end
      
      def sdb_write_permission_changed permission
        @domain.set_sdb_write_permission(permission)
        @item.set_sdb_write_permission(permission)
      end
            
    end
    
    
  end
end