#! ruby -Ku
# coding: utf-8

require 'fileutils'
require 'optparse'
require './tools.xml.ms.rb'

class Hash
    def symbolize_keys!
        t=self.dup
        self.clear
        t.each_pair{|k,v| self[k.to_sym] = v}
        self
    end
end

# proxy format:xxx.xxx.xxx:yyyy

config = Hash.new
stdargs = ARGV.getopts('', 'ext:html', 'in:nil', "t:./template.html").symbolize_keys!
config.update(stdargs)

ext = config[:ext]
dir = config[:in].gsub("\\", "/")
files = Dir.glob(dir + "/" + "*." + ext)
template = config[:t].gsub("\\", "/")
index = Msxml.open(template)
div = index.selectNodes("//div[@class='index-links']").item(0)
ul = index.createNode(Msxml::NODE_ELEMENT, "ul", "")

for file in files
    name = file.split("/").last
    print "generate index anchor -> " + name + "\n"
    li = index.createNode(Msxml::NODE_ELEMENT, "li", "")
    anchor = index.createNode(Msxml::NODE_ELEMENT, "a", "")
    anchor.setAttribute("href", name)
    anchor.text = name
    li.appendChild(anchor)
    ul.appendChild(li)
end
div.appendChild(ul)
index.save(dir + "/" + "index." + ext)