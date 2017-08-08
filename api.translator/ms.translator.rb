# coding: utf-8
#default library
require 'yaml'
require 'fileutils'
require 'rubygems'
require 'net/http'
require 'net/https'
require 'uri'
require 'openssl'
require 'json'
require 'nokogiri'
require 'optparse'

#Usin by Microsoft Translate API
class Translation

  #Constructor method
  def initialize(args = {})
    @cache = {} # hash type
    @token_uri = args[:token_uri]
    @token_key = args[:key]
    @api_uri = args[:api_uri]
    @proxy = args[:proxy]
  end

  def getAccessToken()
    res = nil
    uri = URI.parse(@token_uri)
    Net::HTTP.version_1_2
#    https = Net::HTTP::Proxy(PROXY_SERVER_URI, PROXY_PORT, PROXY_USER, PROXY_PASS).new(uri.host, uri.port)
    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    https.verify_mode = OpenSSL::SSL::VERIFY_NONE
    req = Net::HTTP::Post.new(uri.path)
    req['Ocp-Apim-Subscription-Key']=@token_key
    res = https.request(req) #request
    if res.message == "OK"
      @updateTime = Time.now
      @token = res.body #return json->hash type
    else
      raise "access token acquisition failure"
    end
  end

  def existsTransCache(word)
    @cache.has_key?(word)
  end

  def setTransCache(word, resultWord)
    @cache[word] = resultWord
  end

  def getTransCache(word)
    @cache[word]
  end

  def do(word, src, dest)
    return getTransCache(word) if existsTransCache(word)

    token = getAccessToken
    uri = URI.parse(@api_uri)
    Net::HTTP.version_1_2
    # http = Net::HTTP::Proxy(PROXY_SERVER_URI, PROXY_PORT, PROXY_USER, PROXY_PASS).new(uri.host, uri.port)
    https = Net::HTTP.new(uri.host, uri.port)
    params = {
      :text => word,
      :from => src,
      :to => dest
    }
    query_string = params.map{ |k,v|
      URI.encode(k.to_s) + "=" + URI.encode(v.to_s)
    }.join("&")
    req = Net::HTTP::Get.new(uri.path + "?" + query_string)
    req['Authorization'] = "Bearer #{token}"
    res = https.request(req)
    result = nil
    if res.message == "OK"
      doc = Nokogiri::XML.parse(res.body)
      result = doc.root.content
      setTransCache(word, result)
    end
    result
  end
end

class Hash
  def symbolize_keys!
    t=self.dup
    self.clear
    t.each_pair{|k,v| self[k.to_sym] = v}
    self
  end
end

stdargs = ARGV.getopts('kp', 'key:nil', 'proxy:nil')
config = YAML.load(File.read("config.yml"))
config.update(stdargs).symbolize_keys!
config[:dest].each do |dest|
  FileUtils.mkdir_p("dest\/" + dest)
  ms_api = Translation.new(config)
  p ms_api.do("Hello", config[:src], dest)
end
