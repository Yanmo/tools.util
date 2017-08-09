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

class Hash
    def symbolize_keys!
        t=self.dup
        self.clear
        t.each_pair{|k,v| self[k.to_sym] = v}
        self
    end
end

module WebAPI

    class MSTranslator
        def initialize(args = {})
            @cache = {}
            @token_uri = URI.parse(args[:token_uri]) if args[:token_uri] != nil
            @api_uri = URI.parse(args[:api_uri]) if args[:api_uri] != nil
            @proxy = URI.parse(args[:proxy]) if args[:proxy] != nil
            @token_key = args[:key]
        end

        def getAccessToken()
            res = nil
            Net::HTTP.version_1_2

            https = (@proxy == nil ? Net::HTTP.new(@token_uri.host, @token_uri.port) : Net::HTTP::Proxy(@proxy.host, @proxy.port, @proxy.user, @proxy.password).new(@token_uri.host, @token_uri.port))
            https.use_ssl = true
            https.verify_mode = OpenSSL::SSL::VERIFY_NONE
            https.open_timeout = 3
            https.read_timeout = 5
            
            req = Net::HTTP::Post.new(@token_uri.path)
            req.add_field("Content-Length", 2048)
            req.add_field("Content-Type", "application/json")
            req.add_field("Accept", "application/jwt")
            req.add_field("Ocp-Apim-Subscription-Key", @token_key)

            begin 
                res = https.request(req)
                if res.message == "OK"
                    @updateTime = Time.now
                    @token = res.body
                else
                    raise "access token acquisition failure"
                end
            rescue Timeout::Error
                raise "connection error, and timeout error."
            rescue e
                raise "fatal error."
            end
        end

        def do(word, src, dest)
            return getTransCache(word) if existsTransCache(word)
            res = nil
            translated = nil
            token = getAccessToken

            Net::HTTP.version_1_2
            https = (@proxy == nil ? Net::HTTP.new(@api_uri.host, @api_uri.port) : Net::HTTP::Proxy(@proxy.host, @proxy.port, @proxy.user, @proxy.password).new(@api_uri.host, @api_uri.port))
            https.open_timeout = 3
            https.read_timeout = 5
            params = { :text => word, :from => src, :to => dest }
            query_string = params.map{ |k,v| URI.encode(k.to_s) + "=" + URI.encode(v.to_s) }.join("&")
            req = Net::HTTP::Get.new(uri.path + "?" + query_string)
            req['Authorization'] = "Bearer #{token}"

            begin 
                res = https.request(req)
                if res.message == "OK"
                    translated = Nokogiri::XML.parse(res.body).root.content
                    setTransCache(word, translated)
                end
                return translated
            rescue Timeout::Error
                raise "connection and timeout error."
            rescue e
                raise "fatal error."
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

    end

end