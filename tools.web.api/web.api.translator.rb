#! ruby -Ku
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
            @token_uri = URI.parse(args[:token_uri])
            @api_uri = URI.parse(args[:api_uri])
            @proxy = URI.parse(args[:proxy])
            @token_key = args[:key]
            @timeout = args[:timeout].to_i
        end

        def getAccessToken()
            res = nil
            Net::HTTP.version_1_2

            https = (@proxy == nil ? Net::HTTP.new(@token_uri.host, @token_uri.port) : Net::HTTP::Proxy(@proxy.host, @proxy.port, @proxy.user, @proxy.password).new(@token_uri.host, @token_uri.port))
            https.use_ssl = true
            https.verify_mode = OpenSSL::SSL::VERIFY_NONE
            https.open_timeout = @timeout
            https.read_timeout = @timeout

            header = {
                "Content-Length" => "2048",
                "Content-Type" => "application/json",
                "Accept" => "application/jwt",
                "Ocp-Apim-Subscription-Key" => @token_key
            }

            begin
                res = https.request_post(@token_uri.path, "", header)
                if res.message == "OK"
                    @updateTime = Time.now
                    @token = res.body
                else
                    raise "access token acquisition failure"
                end
            rescue Timeout::Error, Exception => e
                p e.message
                raise "do not connect and timeout error."
            end
        end

        def do(word, src, dest)
            return getTransCache(word) if existsTransCache(word)
            res = nil
            translated = nil
            token = getAccessToken

            Net::HTTP.version_1_2
            https = (@proxy == nil ? Net::HTTP.new(@api_uri.host, @api_uri.port) : Net::HTTP::Proxy(@proxy.host, @proxy.port, @proxy.user, @proxy.password).new(@api_uri.host, @api_uri.port))
            https.open_timeout = @timeout
            https.read_timeout = @timeout
            params = { :text => word, :from => src, :to => dest }
            query_string = params.map{ |k,v| URI.encode(k.to_s) + "=" + URI.encode(v.to_s) }.join("&")
            req = Net::HTTP::Get.new(@api_uri.path + "?" + query_string)
            req['Authorization'] = "Bearer #{token}"

            begin
                res = https.request(req)
                if res.message == "OK"
                    translated = Nokogiri::XML.parse(res.body).root.content
                    setTransCache(word, translated)
                end
                return translated
            rescue Timeout::Error, Exception => e
                p e.message
                raise "do not connect and timeout error."
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

        def clearTransCache()
            @cache.clear
        end

    end

end
