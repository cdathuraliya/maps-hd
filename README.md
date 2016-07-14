# maps-hd

Download a portion of the earth with Google's satellite images

## Installation

You need to have [bundler](http://bundler.io/) installed, just run `bundle` to install dependencies.

You'll also need to have a Google Static Maps API key, go to https://console.developers.google.com, create a project, enable Google Static Maps API, get your server key and paste it in a file `token` in this repo's folder.

## Usage

Start a Ruby console with `irb`, you'll then need to run

```ruby
load 'maps.rb'
Maps.single_image('project', north_latitude, south_latitude, west_longitude, east_longitude, zoom_level)
```

This will download several images of the zone you asked for and combine them into a big one afterwards. All images will be in the `images/project` folder.
`zoom_level` is a integer between 1 and 21, 21 being the best resolution.
