#! ruby -Ku
# coding: utf-8

require './tools.web.api/web.api.translator.rb'

# proxy format:xxx.xxx.xxx:yyyy
stdargs = ARGV.getopts('kpc', 'key:nil', 'proxy:nil', 'config:tools.web.api/config.yml', 'format:text', 'timeout:5').symbolize_keys!
config = YAML.load(File.read(stdargs[:config])).symbolize_keys!
config.update(stdargs)
ms_api = WebAPI::MSTranslator.new(config)

config[:dest].each do |dest|
    FileUtils.mkdir_p("dest\/" + dest)
    p ms_api.do("Hello, Good Morning.", config[:src], dest)
    ms_api.clearTransCache
end
