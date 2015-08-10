require 'yaml'
require 'tk'

module SdbEx
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
          values: @data.aws_regions,
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

        btn_frame = Ttk::Frame.new(@frame
        ).grid(row: 3, column: 0, columnspan: 2, sticky: 'wes')
        
        # connect buttons
        Ttk::Button.new(btn_frame,
          text: 'Connect',
          command: proc {aws_connect}
        ).pack(side: 'right')

        # allow_sdb_write check button
        @allow_sdb_write = TkVariable.new
        Ttk::CheckButton.new(btn_frame,
          text: 'Allow SimpleDB writes',
          variable: @allow_sdb_write,
          command: proc { change_write_permission }
        ).pack(side: 'left')
        
        # default cred to fill in when app starts
        if File.exist("#{ENV['HOME']}/.sbdex/aws_credentials.yml")          
          default_cred = YAML.load_file("#{ENV['HOME']}/.sbdex/aws_credentials.yml")
          @aws_key.value = default_cred['key']
          @aws_secret.value = default_cred['secret']
        end
      end
      
      def on_aws_connected callback
        @callbacks[:aws_connected] = callback
      end
      
      def on_sdb_write_permission_changed callback
        @callbacks[:write_permission_changed] = callback
      end
      
      def change_write_permission
        if @allow_sdb_write.value == '1'
          confirmation = Tk::messageBox(
            type: 'yesno',
            title: 'Database access mode', 
            message: "Do you want to allow write operations to database?", 
            icon: 'question'
          )
          if confirmation == 'yes'
            @logger.warn 'Enable write operations to database.'
            @callbacks[:write_permission_changed].call(true) unless @callbacks[:write_permission_changed].nil?
          else
            @allow_sdb_write.value = false
          end
        else
          confirmation = Tk::messageBox(
            type: 'yesno',
            title: 'Database access mode', 
            message: "Do you want to disallow write operations to database? All pending changes will be discarded.", 
            icon: 'question'
          )
          if confirmation == 'yes'
            @logger.warn 'Disable write operations to database.'
            @callbacks[:write_permission_changed].call(false) unless @callbacks[:write_permission_changed].nil?
          else
            @allow_sdb_write.value = true
          end          
        end
      end
      
      def aws_connect
        st = @data.connect(key: @aws_key.value, secret: @aws_secret.value, region: @aws_region.value)
        if st
          @callbacks[:aws_connected].call unless @callbacks[:aws_connected].nil?
          if st == true
            @logger.warn 'Connect to database.'
          else
            @logger.error "Failed to connect to database, Error: #{st.message}" 
          end
        else
          @logger.info 'Already connected to database.'
        end
      end
      
    end
    
    
  end
end