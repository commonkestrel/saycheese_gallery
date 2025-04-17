require 'norairrecord'

TABLE_NAME = "Grid View"
API_KEY = ENV['AIRTABLE_API_KEY']
BASE_ID = ENV['AIRTABLE_BASE_ID']

table = Norairrecord.table(API_KEY, BASE_ID, TABLE_NAME)
