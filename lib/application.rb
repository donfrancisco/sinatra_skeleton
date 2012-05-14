require "sinatra"
require "haml"
require "httparty"

SINGLY_API_BASE = "https://api.singly.com"

enable :sessions

get "/" do
  if session[:access_token]
    @profiles = HTTParty.get(profiles_url, {
                  :query => {:access_token => session[:access_token]}
                }).parsed_response
  end
  haml :index
end

get "/auth_callback" do
  data = HTTParty.post(
    token_url,
    {:body => token_params(params[:code])}
  ).parsed_response
  puts data.inspect
  session[:access_token] = data['access_token']
  redirect "/"
end

get "/auth/:service" do
  redirect auth_url(params[:service])
end

get "/logout" do
  session.clear
  redirect "/"
end

def auth_params(service)
  {
    :client_id => ENV["SINGLY_ID"],
    :redirect_uri => callback_url,
    :service => service
  }.map {|key, value|
    "#{key}=#{value}"
  }.join("&")
end

def auth_url(servie)
  "#{SINGLY_API_BASE}/oauth/authorize?#{auth_params(params[:service])}"
end

def callback_url
  "http#{"s" if request.secure?}://#{request.host}:#{request.port}/auth_callback"
end

def profiles_url
  "#{SINGLY_API_BASE}/profiles"
end

def token_params(code)
  {
    :client_id => ENV["SINGLY_ID"],
    :client_secret => ENV["SINGLY_SECRET"],
    :code => code
  }
end

def token_url
  "#{SINGLY_API_BASE}/oauth/access_token"
end
