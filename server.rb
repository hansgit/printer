require "rubygems"
require "bundler/setup"
require "sinatra"
require 'sinatra/base'
require "resque"

$LOAD_PATH.unshift "lib"
require "jobs"
require "sudoku"
require "weather"
Weather.api_key = ENV["WUNDERGROUND_API_KEY"].strip

class WeePrinterServer < Sinatra::Base
  helpers do
    def period_of_day
      case Time.now.hour
      when 8..11
        "morning"
      when 12..14
        "lunch"
      when 15..18
        "afternoon"
      else
        "evening"
      end
    end
  end

  get "/" do
    @sudoku_data = random_sudoku
    @forecast = Weather.new.daily_report
    erb :index
  end

  get "/message" do
    erb :message
  end

  get "/preview/show/:preview_id" do
    @image_url = "/previews/#{params['preview_id']}.png"
    erb :preview
  end

  get "/preview/pending/:preview_id" do
    image_job = Resque.reserve(Jobs::PreviewReady.queue(params['preview_id']))
    if image_job
      redirect "/preview/show/#{params['preview_id']}"
    else
      erb :preview_pending
    end
  end

  get "/preview" do
    preview_id = (0..16).map { |x| rand(16).to_s(16) }.join
    Resque.enqueue(Jobs::Preview, preview_id, params['url'] || env['HTTP_REFERER'])
    redirect "/preview/pending/#{preview_id}"
  end

  get "/print_from_page/:printer_id" do
    Resque.enqueue(Jobs::PreparePage, params['printer_id'], params['url'] || env['HTTP_REFERER'])
    redirect env['HTTP_REFERER']
  end

  get "/printer/:printer_id" do
    image_job = Resque.reserve(Jobs::Print.queue(params['printer_id']))
    if image_job
      klass = Resque::Job.constantize(image_job.payload['class'])
      klass.data_for_printer(*image_job.payload['args'])
    end
  end

  get "/test/fixed/:length" do
    "#" * params['length'].to_i
  end

  get "/test/between/:min/:max" do
    min = params['min'].to_i
    max = params['max'].to_i
    length = rand(max-min) + min
    "#" * length
  end

  get "/test/maybe" do
    if rand(10) > 7
      "#" * (rand(100000) + 20000)
    end
  end
end