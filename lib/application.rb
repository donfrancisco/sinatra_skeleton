require "sinatra"
require "httparty"
require "json"

SINGLY_API_BASE = "https://carealot.singly.com"

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
  token = HTTParty.post(token_url, {:body => token_params(params[:code])}).body
  session[:access_token] = JSON.parse(token)["access_token"]
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

__END__

@@layout
!!!
%html
  = yield

@@index
%h1 Singly OAuth Example
%h2
  - if @profiles
    Nice to see you again!
  - else
    Please connect a service
- if @profiles
  %p
    Your Singly ID is
    = @profiles["id"]
    \.
    %a(href="/logout") Log out
%ul
  - %w[facebook twitter].each do |service|
    %li
      = service.capitalize
      - if @profiles && @profiles[service]
        is connected as
        = @profiles[service]
      - else
        is not connected.
        %a(href="/auth/#{service}") Connect
