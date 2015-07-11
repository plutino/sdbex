require 'tk'

module SDBMan
  module View
    
    class Window

      def initialize data
        @data = data
        
        root = TkRoot.new
        root[:geometry] = '300x300+500+500'
        TkGrid.columnconfigure root, 0, :weight => 1
        TkGrid.rowconfigure root, 0, :weight => 1
        left_frame = Ttk::Frame.new(root).pack(side: 'left')
        cred_frame = Ttk::Frame.new(left_frame).pack(side: 'top')

        # region combobox
        Ttk::Label.new(cred_frame,
          text: 'Region: '
        ).grid(row: 1, column: 1, sticky: 'nw')
        @aws_region = TkVariable.new
        region = Ttk::Combobox.new(cred_frame,
          width: 18,
          values: @data.region_list,
          textvariable: @aws_region,
          state: 'readonly'
        ).grid(row: 1, column: 2, sticky: 'ne')
        region.current = 0

        # access_key_id entry
        Ttk::Label.new(cred_frame, 
          text: 'Key ID: '
        ).grid(row: 2, column: 1, sticky: 'w')
        @aws_key = TkVariable.new
        Ttk::Entry.new(cred_frame, 
          width: 20, 
          textvariable: @aws_key
        ).grid(row: 2, column: 2, sticky: 'e')
        
        # secret_access_key entry
        Ttk::Label.new(cred_frame, 
          text: 'Secret: '
        ).grid(row: 3, column: 1, sticky: 'w')
        @aws_secret = TkVariable.new
        Ttk::Entry.new(cred_frame, 
          width: 20, 
          show: '*', 
          textvariable: @aws_secret
        ).grid(row: 3, column: 2, sticky: 'e')

        # connect buttons
        Ttk::Button.new(cred_frame,
          text: 'Connect',
          command: proc {self.aws_connect}
        ).grid(row: 4, column: 2, sticky: 'se')
      end
      
      def run
        Tk.mainloop
      end
      
      def reload
      end
      
      def aws_connect
        if @data.connect(key: @aws_key.value, secret: @aws_secret.value, region: @aws_region.value)
          reload
        end
      end
      
    end
    
    
  end
end