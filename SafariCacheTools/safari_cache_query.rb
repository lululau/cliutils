#!/usr/bin/env ruby

require "rubygems"
require "active_record"


exit 1 unless ARGV.length == 1

exit(1) unless ARGV[0] =~ /^http:\/\//

FILE_URL = ARGV[0]

SAFARI_CACHE_DB_FILE = "#{ENV["HOME"]}/Library/Caches/com.apple.Safari/Cache.db"

ActiveRecord::Base.establish_connection(
		:adapter => "sqlite3",
		:database => SAFARI_CACHE_DB_FILE
	)

class CfurlCacheResponse < ActiveRecord::Base
	set_table_name :cfurl_cache_response
end	

class CfurlCacheReceiverData < ActiveRecord::Base
	set_table_name :cfurl_cache_receiver_data
end

entry_ID = CfurlCacheResponse.where(:request_key => FILE_URL).first.entry_ID
receiver_data = CfurlCacheReceiverData.where(:entry_ID => entry_ID).first

print receiver_data.receiver_data