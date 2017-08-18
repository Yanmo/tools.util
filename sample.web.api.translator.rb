#! ruby -Ku
# coding: utf-8

require './tools.web.api/web.api.translator.rb'
require './tools.xml/tools.xml.ms.rb'

# proxy format:xxx.xxx.xxx:yyyy
stdargs = ARGV.getopts('kpc', 'key:nil', 'proxy:nil', 'config:tools.web.api/config.yml', 'format:text', 'timeout:10', 'in:nil', 'out:dest').symbolize_keys!
config = YAML.load(File.read(stdargs[:config])).symbolize_keys!
config.update(stdargs)
ms_api = WebAPI::MSTranslator.new(config)

doc = Msxml.open(config[:in])

#doc.xpath("//phrase").each do |element|
#    p element.text
#end

skip_elem=["command", "informalfigure", "table", "caution", "systemitem", "xref", "inlinegraphic", "keycap", "superscript"]
skip_type=[Msxml::NODE_ENTITY, Msxml::NODE_PROCESSING_INSTRUCTION, Msxml::NODE_COMMENT, Msxml::NODE_ENTITY_REFERENCE]
skip_attr=["English", "JA"]

FileUtils.mkdir_p(config[:out])
config[:dest].each do |dest|
    paragraphes = doc.selectNodes("//*[name() = 'phrase' or name() = 'para']")
    cnt = 1.0
    paragraphes.each do |element| 
        print "processing...." + dest + sprintf("\t\t%.1f%",(cnt/paragraphes.length)*100.0) + "\r"
        element.childNodes.each do |child|
            if skip_type.include?(child.nodeType) then next; end
            if skip_elem.include?(child.nodeName) then next; end
            if child.nodeType == Msxml::NODE_ELEMENT and skip_attr.include?(child.getAttribute("arch")) then next end
            child.text = ms_api.do(child.text, config[:src], dest)
        end
        cnt+=1
    end
    FileUtils.mkdir_p(config[:out]+"\/"+dest)
    doc.save(config[:out]+"\/"+dest+"\/"+config[:in].split("\\").last)
    ms_api.clearTransCache
    print "processing complete.. " + dest + "\n"
end

