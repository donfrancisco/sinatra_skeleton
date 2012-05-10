require "sinatra"
require "httparty"
require "json"

SINGLY_API_BASE = "https://carealot.singly.com"

enable :sessions

get "/" do
  haml :index
end

get "/auth/callback" do
  token = HTTParty.post(token_url, {:body => token_params(params[:code])}).body
  session[:access_token] = JSON.parse(token)["access_token"]
  redirect "/"
end

get "/auth/:service" do
  redirect auth_url(params[:service])
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
  "http#{"s" if request.secure?}://#{request.host}:#{request.port}/auth/callback"
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

__END__

@@layout
!!!
%html
  =yield

@@index
%h1 Singly OAuth Example
%h2
  - if session[:access_token]
    Nice to see you again!
  - else
    Please connect a service
%ul
  - %w[facebook twitter].each do |service|
    %li
      %a(href="/auth/#{service}")= service.capitalize
