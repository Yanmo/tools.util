require 'win32ole'

class WIN32OLE
  include Enumerable
  @const_defined = Hash.new
  def WIN32OLE.new_with_const(prog_id, const_name_space)
    result = WIN32OLE.new(prog_id)
    unless @const_defined[const_name_space] then
      WIN32OLE.const_load(result, const_name_space)
      @const_defined[const_name_space] = true
    end
    return result
  end
end

#common functions
def getAbsolutePath filename
  fso = WIN32OLE.new('Scripting.FileSystemObject')
  fso.GetAbsolutePathName(filename)
end

#must define, if use utf-8 text on win32ole!
WIN32OLE.codepage = WIN32OLE::CP_UTF8

module Msxml
  class ParseError < StandardError
  end

  def Msxml.new
    return WIN32OLE.new_with_const('MSXML2.DOMDocument.4.0', Msxml)
  end

  def Msxml.handle_error(doc, path)
    error = doc.parseError
    if error.errorCode != 0 then
      docpos = ""
      if error.line != 0 then
        docpos = sprintf(":%d:%d", error.line, error.linepos)
      end
      msg = sprintf("\n%s%s: %s", path, docpos, error.reason.gsub(/\r/, "")).tosjis
      raise ParseError, msg
    end
  end

  def Msxml.open(path)
    doc = new
    doc.setProperty 'SelectionLanguage', 'XPath'
    doc.async = false
    doc.preserveWhiteSpace = true
    doc.resolveExternals = true
    doc.validateOnParse = false
    doc.load(path)
    begin
      handle_error(doc, path)
    rescue ParseError
      raise $!.type, $!.message, caller
    end
    return doc
  end

end
