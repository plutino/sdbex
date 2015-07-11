require 'yaml'
require 'tk'

module SDBMan
  module View
    class Credential

      attr_reader :frame

      def initialize parent, data, logger
        @callbacks = {}
        @data = data        
        @logger = logger
        @frame = Ttk::Frame.new(parent,
          padding: '5 5 5 5'
        )
        
        # region combobox
        Ttk::Label.new(@frame,
          text: 'Region: '
        ).grid(row: 0, column: 0, sticky: 'nw')
        @aws_region = TkVariable.new
        region = Ttk::Combobox.new(@frame,
          values: @data.region_list,
          textvariable: @aws_region,
          state: 'readonly'
        ).grid(row: 0, column: 1, sticky: 'new')
        region.current = 0

        # access_key_id entry
        Ttk::Label.new(@frame, 
          text: 'Key ID: '
        ).grid(row: 1, column: 0, sticky: 'w')
        @aws_key = TkVariable.new
        Ttk::Entry.new(@frame, 
          textvariable: @aws_key
        ).grid(row: 1, column: 1, sticky: 'we')
        
        # secret_access_key entry
        Ttk::Label.new(@frame, 
          text: 'Secret: '
        ).grid(row: 2, column: 0, sticky: 'w')
        @aws_secret = TkVariable.new
        Ttk::Entry.new(@frame, 
          show: '*', 
          textvariable: @aws_secret
        ).grid(row: 2, column: 1, sticky: 'we')

        TkGrid.columnconfigure @frame, 1, weight: 1

        # connect buttons
        Ttk::Button.new(@frame,
          text: 'Connect',
          command: proc {aws_connect}
        ).grid(row: 3, column: 1, sticky: 'se')
        
        # temporary default cred to help development
        default_cred = YAML.load_file(File.expand_path('../../../credential.yml', __FILE__))
        @aws_key.value = default_cred['key']
        @aws_secret.value = default_cred['secret']
      end
      
      def on_connect callback
        @callbacks[:aws_connect] = callback
      end
      
      def aws_connect
        st = @data.connect(key: @aws_key.value, secret: @aws_secret.value, region: @aws_region.value)
        if st
          @callbacks[:aws_connect].call unless @callbacks[:aws_connect].nil?
          @logger.error "Failed to connect to SimpleDB, Error: #{st.message}" unless st == true
        end
      end
      
    end
    
    
  end
end