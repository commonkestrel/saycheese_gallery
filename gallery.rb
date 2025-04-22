require 'base64'
require 'down'
require 'fileutils'
require 'norairrecord'

TABLE_NAME = "YSWS Project Submission"
TABLE_VIEW = "Grid View"
API_KEY = ENV['AIRTABLE_API_KEY']
BASE_ID = ENV['AIRTABLE_BASE_ID']
directory = ARGV[0]
ARGV.replace []
directory = directory.nil? ? "." : directory

table = Norairrecord.table(API_KEY, BASE_ID, TABLE_NAME)
records = table.records(filter: "status = \"accepted\"", view: TABLE_VIEW).reverse

submissions = []

records.each do |rec|
  name = rec['project_name']
  author = rec['gallery_attribution']

  os = rec['os']
  arch = rec['architecture']
  description = rec['Description']
  repo = rec['Code URL']

  puts "This project is '#{name}', by #{author}. What should the project be called?"
  project_name = gets.strip

  FileUtils.mkdir_p "#{directory}/#{project_name}"

  qr_url = rec['qr_code'][0]['url']
  qr_remote = Down.open(qr_url, rewindable: false)
  qr_extension = qr_remote.data[:headers]["Content-Type"].split("/").last
  qr_path = "#{directory}/#{project_name}/qr.#{qr_extension}"

  qr_file = open(qr_path, "w")
  qr_remote.each_chunk { |chunk| qr_file.write chunk }
  qr_file.close

  project_url = `zbarimg -q --raw #{qr_path}`

  ty = if project_url.start_with?("data:text")
         "Url"
       elsif project_url.start_with?("<")
         project_url = "data:text/html;base64," + Base64.encode64(project_url)
         "Url"
       else
         project_url = "data:application/octet-stream;base64," + Base64.encode64(project_url)
         "Url"
       end

  demo_url = rec['Screenshot'][0]['url']
  demo_remote = Down.open(demo_url, rewindable: false)
  demo_extension = demo_remote.data[:headers]["Content-Type"].split("/").last
  demo_path = "#{directory}/#{project_name}/demo.#{demo_extension}"

  demo_file = open(demo_path, "w")
  demo_remote.each_chunk { |chunk| demo_file.write chunk }
  demo_file.close

  data = {
    :name => name,
    :author => author,
    :qr => {
      :image => "qr.#{qr_extension}",
      :type => ty,
      :url => project_url
    },
    :demo => "demo.#{demo_extension}",
    :os => os,
    :arch => arch,
    :description => description,
    :repo => repo
  }
  json = JSON.pretty_generate data

  proj_file = open("#{directory}/#{project_name}/proj.json", "w")
  proj_file.write json.to_s
  proj_file.close

  submissions = submissions.push project_name
end

json = JSON.pretty_generate submissions: submissions
sub_file = open("#{directory}/submissions.json", "w")
sub_file.write json.to_s
sub_file.close
