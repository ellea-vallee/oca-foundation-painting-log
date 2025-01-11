require 'nokogiri'
require 'reverse_markdown'
require 'fileutils'
require 'date'

# Create necessary directories
FileUtils.mkdir_p('_posts')
FileUtils.mkdir_p('assets/images')

# Path to WordPress export file - change this to match your file name
WORDPRESS_XML = 'foundationpaintinglogbyella.WordPress.2025-01-11.xml'

puts "Starting WordPress import from #{WORDPRESS_XML}"

# Read and parse the WordPress XML
begin
  doc = File.open(WORDPRESS_XML) { |f| Nokogiri::XML(f) }
  puts "Successfully loaded XML file"
rescue => e
  puts "Error loading XML file: #{e.message}"
  exit 1
end

# Counter for posts
post_count = 0

# Process each item
doc.xpath('//item').each do |item|
  # Skip if not a post or not published
  next unless item.at_xpath('wp:post_type').text == 'post'
  next unless item.at_xpath('wp:status').text == 'publish'

  begin
    # Get post details
    title = item.at_xpath('title').text.strip
    date = DateTime.parse(item.at_xpath('pubDate').text)
    content = item.at_xpath('content:encoded').text
    
    # Convert categories and tags
    categories = item.xpath('category[@domain="category"]').map(&:text).join(', ')
    tags = item.xpath('category[@domain="post_tag"]').map(&:text).join(', ')

    # Create filename
    filename = "_posts/#{date.strftime('%Y-%m-%d')}-#{title.downcase.gsub(/[^a-z0-9]+/, '-')}.md"

    # Convert HTML to Markdown
    markdown_content = ReverseMarkdown.convert(content, github_flavored: true)

    # Create front matter
    front_matter = <<~FRONT_MATTER
      ---
      layout: post
      title: "#{title}"
      date: #{date.strftime('%Y-%m-%d %H:%M:%S %z')}
      categories: [#{categories}]
      tags: [#{tags}]
      ---
    FRONT_MATTER

    # Write the post file
    File.write(filename, front_matter + "\n" + markdown_content)
    puts "Created: #{filename}"
    post_count += 1
  rescue => e
    puts "Error processing post '#{title}': #{e.message}"
  end
end

puts "Import complete! Processed #{post_count} posts"
