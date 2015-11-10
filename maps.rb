require 'fileutils'
require 'net/http'
require 'pathname'
require 'uri'

require 'rmagick'

load 'mercator.rb'

class Maps
  include Magick
  attr_reader :path

  API_KEY = File.read(File.dirname(__FILE__) + '/token').strip
  LAT = 52.372052
  LON = 4.881190
  PIXELS = 640
  ZOOM = 10
  CROPPED_PIXELS = 600

  def initialize(name = 'my_project')
    @name = name
    @path = Pathname.new(File.dirname(__FILE__)).join('images', name)
    FileUtils.rm_rf(@path)
    FileUtils.mkdir_p(@path)
  end

  def self.url(center_lat = LAT, center_lon = LON)
    URI("https://maps.googleapis.com/maps/api/staticmap?zoom=#{ZOOM}&size=#{PIXELS}x#{PIXELS}" \
        "&maptype=satellite&center=#{center_lat},#{center_lon}&key=#{API_KEY}")
  end

  def download_image(center_lat = LAT, center_lon = LON)
    File.open(@path.join("part_#{center_lat}_#{center_lon}.png"), 'wb') do |file|
      file << Net::HTTP.get(self.class.url(center_lat, center_lon))
    end
  end

  def print_progress(header, done, total)
    width = 100
    percent = (done * 100.0) / total
    bar = ''
    bar += header + ': ' if header != ''
    bar = bar.ljust(20)
    bar += percent.round(1).to_s.rjust(5)
    bar += '% '
    bar += '['
    bar += ('=' * ((percent * width) / 100)).ljust(width)
    bar += "]\r"
    print bar
    $stdout.flush
  end

  def download_zone(north_lat = LAT, south_lat = LAT, left_lon = LON, right_lon = LON)
    corners = Mercator.corners(north_lat, left_lon, ZOOM, CROPPED_PIXELS, CROPPED_PIXELS)
    total = ((right_lon - left_lon) / (corners[:E] - corners[:W])).ceil * ((north_lat - south_lat) / (corners[:N] - corners[:S])).ceil
    done = 0
    images = []
    lat = north_lat
    while lat > south_lat
      lon = left_lon
      row = []
      while lon < right_lon
        row.push download_image(lat, lon)
        corners = Mercator.corners(lat, lon, ZOOM, CROPPED_PIXELS, CROPPED_PIXELS)
        lon += 2 * (lon - corners[:W])
        done += 1
        print_progress('Downloading', done, total)
      end
      images.push row
      lat -= 2 * (lat - corners[:S])
    end
    puts ''
    images
  end

  def self.single_image(name = 'project', north_lat = LAT, south_lat = LAT, left_lon = LON, right_lon = LON)
    maps = Maps.new name
    images = maps.download_zone(north_lat, south_lat, left_lon, right_lon)
    GC.start
    total = images.flatten.count
    done = 0
    big_image = ImageList.new
    images.each do |row|
      image_row = ImageList.new
      row.each do |image|
        done += 1
        Image.read(image.path).first.crop(CenterGravity, CROPPED_PIXELS, CROPPED_PIXELS).write(image.path)
        image_row.push(Image.read(image.path).first)
        maps.print_progress('Merging', done, total)
      end
      GC.start
      big_image.push(image_row.append(false))
    end
    puts ''
    big_image.append(true).write(maps.path.join('final.png'))
  end
end
