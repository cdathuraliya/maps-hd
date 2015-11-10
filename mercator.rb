class Mercator
  TILE_SIZE = 256.0

  def self.pixels(latitude, longitude)
    siny = Math.sin(latitude * Math::PI / 180)
    siny = [[siny, -0.99].max, 0.99].min
    [TILE_SIZE * (0.5 + longitude / 360), TILE_SIZE * (0.5 - Math.log((1 + siny) / (1 - siny)) / (4 * Math::PI))]
  end

  def self.coordinates(pixels)
    [Math.asin(Math.tanh(2 * Math::PI * (0.5 - pixels[1] / TILE_SIZE))) * 180 / Math::PI, 360 * (pixels[0] / TILE_SIZE - 0.5)]
  end

  def self.corners(center_lat, center_lon, zoom, width, height)
    center = pixels(center_lat, center_lon)
    ne = coordinates [center[0] + width / (2.0 * 2**zoom), center[1] - height / (2.0 * 2**zoom)]
    sw = coordinates [center[0] - width / (2.0 * 2**zoom), center[1] + height / (2.0 * 2**zoom)]
    {
      'N': ne[0],
      'E': ne[1],
      'S': sw[0],
      'W': sw[1],
    }
  end
end
