require 'tk'

module SDBMan
  module View
    
    class Credential

      attr_reader :frame

      def initialize parent, data
        @callbacks = {}
        @data = data        
        @frame = Ttk::Frame.new(parent,
          padding: '5 5 5 5'
        )
        
        # region combobox
        Ttk::Label.new(@frame,
          text: 'Region: '
        ).grid(row: 0, column: 0, sticky: 'nw')
        @aws_region = TkVariable.new
        region = Ttk::Combobox.new(@frame,
          width: 23,
          values: @data.region_list,
          textvariable: @aws_region,
          state: 'readonly'
        ).grid(row: 0, column: 1, sticky: 'ne')
        region.current = 0

        # access_key_id entry
        Ttk::Label.new(@frame, 
          text: 'Key ID: '
        ).grid(row: 1, column: 0, sticky: 'w')
        @aws_key = TkVariable.new
        Ttk::Entry.new(@frame, 
          width: 25, 
          textvariable: @aws_key
        ).grid(row: 1, column: 1, sticky: 'e')
        
        # secret_access_key entry
        Ttk::Label.new(@frame, 
          text: 'Secret: '
        ).grid(row: 2, column: 0, sticky: 'w')
        @aws_secret = TkVariable.new
        Ttk::Entry.new(@frame, 
          width: 25, 
          show: '*', 
          textvariable: @aws_secret
        ).grid(row: 2, column: 1, sticky: 'e')

        # connect buttons
        Ttk::Button.new(@frame,
          text: 'Connect',
          command: proc {self.aws_connect}
        ).grid(row: 3, column: 1, sticky: 'se')
        
      end
      
      def on_connect callback
        @callbacks[:aws_connect] = callback
      end
      
      def aws_connect
        if @data.connect(key: @aws_key.value, secret: @aws_secret.value, region: @aws_region.value)
          @callbacks[:aws_connect].call unless @callbacks[:aws_connect].nil?
        end
      end
      
    end
    
    
  end
end