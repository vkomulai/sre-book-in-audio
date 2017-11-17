#!/usr/bin/env ruby -wKU
#
# by Kelan Champagne
# http://yeahrightkeller.com
#
# A script to generate a personal podcast feed, hosted on Dropbox
#
# Inspired by http://hints.macworld.com/article.php?story=20100421153627718
#
# Simply put this, and some .mp3 or .m4a files in a sub-dir under your Dropbox
# Public folder, update the config values below, and run the script.  To get
# the public_url_base value, you can right click on a file in that folder
# in Finder, then go to Dropbox > Copy Public Link, and then remove the
# filename.
#
# Notes:
#  * You'll need to re-run it after adding new files to the dir, or you can
#    set up Folder Actions as suggested by the above hint (sample AppleScript
#    in comments at the bottom of this file).
#  * This script uses `mdls` to get the title and summary of the podcast
#    from the Spotlight metadata, which requires it to be run on a Mac. But,
#    the rest of the script should be cross-platform compatible.

require 'date'


# Config values
podcast_title = "Site Reliability Engineering: How Google Runs Production Systems"
podcast_description = "The overwhelming majority of a software system’s lifespan is spent in use, not in design or implementation. So, why does conventional wisdom insist that software engineers focus primarily on the design and development of large-scale computing systems?

In this collection of essays and articles, key members of Google’s Site Reliability Team explain how and why their commitment to the entire lifecycle has enabled the company to successfully build, deploy, monitor, and maintain some of the largest software systems in the world. You’ll learn the principles and practices that enable Google engineers to make systems more scalable, reliable, and efficient—lessons directly applicable to your organization."
public_url_base = "https://github.com/vkomulai/sre-book-in-audio/blob/master/output/"


# Generated values
date_format = '%a, %d %b %Y %H:%M:%S %z'
podcast_pub_date = DateTime.now.strftime(date_format)

# Build the items
items_content = ""
Dir.entries('.').each do |file|
    next if file =~ /^\./  # ignore invisible files
    next unless file =~ /\.(mp3|m4a)$/  # only use audio files

    puts "adding file: #{file}"

    item_size_in_bytes = File.size(file).to_s
    item_pub_date = File.mtime(file).strftime(date_format)
    item_title = `mdls --name kMDItemFSName "#{file}"`.sub(/^.*? = "/, '').sub(/"$/, '').chomp
    item_subtitle = `mdls --name kMDItemAuthors "#{file}"`.sub(/^.*? = \(\n\s*/, '').sub(/\n\s*\)$/, '').sub(/.*null\)/, '').chomp
    item_summary = `mdls --name kMDItemDisplayName "#{file}"`.sub(/^.*? = "/, '').sub(/"$/, '').sub(/.*null\)/, '').chomp
    item_url = "#{public_url_base}/#{file}"
    item_content = <<-HTML
        <item>
            <title>#{item_title}</title>
            <itunes:subtitle>#{item_subtitle}</itunes:subtitle>
            <itunes:summary>#{item_summary}</itunes:summary>
            <enclosure url="#{item_url}" length="#{item_size_in_bytes}" type="audio/mpeg" />
            <pubDate>#{item_pub_date}</pubDate>
            <guid>#{item_url}#{podcast_pub_date}</guid>
        </item>
HTML

    items_content << item_content
end

# Build the whole file
content = <<-HTML
<?xml version="1.0" encoding="ISO-8859-1"?>
<rss xmlns:itunes="http://www.itunes.com/dtds/podcast-1.0.dtd" version="2.0">
    <channel>
        <title>#{podcast_title}</title>
        <description>#{podcast_description}</description>
        <pubDate>#{podcast_pub_date}</pubDate>
#{items_content}
    </channel>
</rss>
HTML

# write it out
output_file = File.new("podcast.rss", 'w')
output_file.write(content)
output_file.close

# = Sample AppleScript to auto-run this script. = 
# This AppleScript also touches the new file so that it's modification 
# date (and thus the pubDate in the podcast) are the date/time that you 
# put it in the folder.
#
# To install:
# - Open AppleScript Editor and copy-paste the below code (minus #'s)
# - Save the script to "/Library/Scripts/Folder Action Scripts"
# - Control-click the podcast folder, "Services > Folder Actions Setup"
#   and choose your script 
#
#on adding folder items to this_folder after receiving added_items
# 	set the_folder to POSIX path of this_folder
# 	set the_folder_quoted to (the quoted form of the_folder as string)
# 	
# 	repeat with this_item in added_items
# 		set the_item to POSIX path of this_item
# 		set the_item_quoted to (the quoted form of the_item as string)
# 		do shell script "touch " & the_item_quoted
# 	end repeat
# 	
# 	tell application "Finder"
# 		display dialog "cd " & the_folder_quoted & ";./generate_personal_podcast.rb"
# 		do shell script "cd " & the_folder_quoted & ";./generate_personal_podcast.rb"
# 	end tell
# 	
# end adding folder items to