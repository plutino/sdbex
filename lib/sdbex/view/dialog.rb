require 'tk'

module SdbEx
  module View

    class Dialog
      
      def initialize parent, title: nil
        @parent = parent
        parent_wnd = parent.winfo_toplevel
        @window = TkToplevel.new(parent_wnd)
        @window.transient parent_wnd
        @window.title = title unless title.nil?

        @window.grab_set
        @window.protocol('WM_DELETE_WINDOW', proc{cancel})
        @window.geometry "+#{(parent.winfo_rootx + 50).to_s}+#{(parent.winfo_rooty + 50).to_s}"

        v_frame = Ttk::Frame.new(@window).pack
        @frame = Ttk::Frame.new(v_frame).pack(side: 'top', padx: 5, pady: 5)
        btn_frame = Ttk::Frame.new(v_frame).pack(side: 'top', padx: 5, pady: 5)
        pack_buttons(btn_frame)

        @initial_focus = @frame
        @result = false
      end
      
      # block should return the widget to be focused when the dialog is created
      def build
        @initial_focus = yield @frame
      end
      
      def run
        #@initial_focus.focus_set
        @window.wait_window
        @result
      end

      private
      
      def pack_buttons(frame)        
        Ttk::Button.new(frame,
          text: 'Cancel',
          width: 10,
          command: proc{ cancel },
        ).pack(side: 'right', padx: 5)
        Ttk::Button.new(frame,
          text: 'OK',
          width: 10,
          command: proc{ ok },
          default: 'active'
        ).pack(side: 'right', padx: 5)      
        @window.bind('<Return>', proc{ok})
        @window.bind('<Escape>', proc{cancel})  
      end
      
      def ok
        @result = true
        cancel
      end
      
      def cancel
        #@parent.focus_set
        @window.destroy
      end
      
    end

  end
end