require 'yaml'

require 'sdbex/data'
require 'sdbex/view'

aws_opts = YAML.load_file(File.expand_path('../config/aws_options.yml', __FILE__))

$console_logger = Logger.new($stdout)
$console_logger.level = Logger::DEBUG
aws_opts[:logger] = $console_logger
aws_opts[:log_level] = :debug

wnd = SdbEx::View::Window.new SdbEx::Data.new(**aws_opts)
wnd.run
