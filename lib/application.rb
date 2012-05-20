require "rubygems"
require "httparty"
require "sinatra"
require "omniauth-singly"

SINGLY_API_BASE = "https://api.singly.com"

enable :sessions

use OmniAuth::Builder do
  provider :singly, ENV['SINGLY_ID'], ENV['SINGLY_SECRET']
end

get "/" do
  if session[:access_token]
    @profiles = HTTParty.get(profiles_url, {
                  :query => {:access_token => session[:access_token]}
                }).parsed_response
  end
  erb :index
end

get "/auth/singly/callback" do
  auth = request.env["omniauth.auth"]
  session[:access_token] = auth.credentials.token
  redirect "/"
end

get "/logout" do
  session.clear
  redirect "/"
end

def profiles_url
  "#{SINGLY_API_BASE}/profiles"
end
