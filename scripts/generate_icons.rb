#!/usr/bin/env ruby
require 'json'
require 'fileutils'

# Paths
BASE_DIR = File.expand_path("..", __dir__)
SOURCE_DIR = File.join(BASE_DIR, "ikoner")
LIGHT_SRC = File.join(SOURCE_DIR, "lightmode.png")
DARK_SRC = File.join(SOURCE_DIR, "darkmode.png")
TINTED_SRC = File.join(SOURCE_DIR, "tinted.png")

APP_ICONSET_DIR = File.join(BASE_DIR, "WODrounds/Assets.xcassets/AppIcon.appiconset")
WATCH_ICONSET_DIR = File.join(BASE_DIR, "WODroundsWatch/Assets.xcassets/AppIcon.appiconset")
TVOS_BRANDASSETS_DIR = File.join(BASE_DIR, "WODrounds/Assets.xcassets/AppIcon.brandassets")

# Ensure base images exist
unless File.exist?(LIGHT_SRC)
  puts "Error: #{LIGHT_SRC} not found. A lightmode icon is required as the base."
  exit 1
end

has_dark = File.exist?(DARK_SRC)
has_tinted = File.exist?(TINTED_SRC)

# Make sure directories exist and are empty
[APP_ICONSET_DIR, WATCH_ICONSET_DIR].each do |dir|
  FileUtils.rm_rf(dir)
  FileUtils.mkdir_p(dir)
end
FileUtils.rm_rf(TVOS_BRANDASSETS_DIR)
FileUtils.mkdir_p(TVOS_BRANDASSETS_DIR)

# Helper function to resize using sips
def resize(src, dest, width, height=nil)
  height ||= width
  system("sips -z #{height} #{width} \"#{src}\" --out \"#{dest}\" > /dev/null")
end

# Helper function to crop/pad for tvOS (if the input is square)
# tvOS requires 400x240 and 1280x768. Since base is square, we'll crop the center.
def resize_crop(src, dest, width, height)
  # Simple approach: tell sips to crop to center
  system("sips --cropToHeightWidth #{height} #{width} \"#{src}\" --out \"#{dest}\" > /dev/null")
end

puts "Generating iOS / iPadOS / macOS icons..."

# Main App Iconset (Single size icon with variants in iOS 18+)
# Apple now recommends a single 1024x1024 icon that it scales down. 
# We'll provide "Any", "Dark", and "Tinted" appearances for the 1024x1024 iOS icon.
ios_contents = {
  "images" => [],
  "info" => { "author" => "xcode", "version" => 1 }
}

# Any Appearance
ios_any = "AppIcon-Any.png"
resize(LIGHT_SRC, File.join(APP_ICONSET_DIR, ios_any), 1024)
ios_contents["images"] << {
  "filename" => ios_any,
  "idiom" => "universal",
  "platform" => "ios",
  "size" => "1024x1024"
}

if has_dark
  ios_dark = "AppIcon-Dark.png"
  resize(DARK_SRC, File.join(APP_ICONSET_DIR, ios_dark), 1024)
  ios_contents["images"] << {
    "appearances" => [{ "appearance" => "luminosity", "value" => "dark" }],
    "filename" => ios_dark,
    "idiom" => "universal",
    "platform" => "ios",
    "size" => "1024x1024"
  }
end

if has_tinted
  ios_tinted = "AppIcon-Tinted.png"
  resize(TINTED_SRC, File.join(APP_ICONSET_DIR, ios_tinted), 1024)
  ios_contents["images"] << {
    "appearances" => [{ "appearance" => "luminosity", "value" => "tinted" }],
    "filename" => ios_tinted,
    "idiom" => "universal",
    "platform" => "ios",
    "size" => "1024x1024"
  }
end

# macOS 1024x1024
mac_icon = "AppIcon-Mac.png"
resize(LIGHT_SRC, File.join(APP_ICONSET_DIR, mac_icon), 1024)
ios_contents["images"] << {
  "filename" => mac_icon,
  "idiom" => "mac",
  "scale" => "2x",
  "size" => "512x512"
}

File.write(File.join(APP_ICONSET_DIR, "Contents.json"), JSON.pretty_generate(ios_contents))

puts "Generating watchOS icons..."

# Watch Iconset (needs many specific sizes)
# Standard watchOS required sizes: 48 (24@2x), 55 (27.5@2x), 58 (29@2x), 87 (29@3x), 80 (40@2x), 88 (44@2x), 100 (50@2x), 108 (54@2x), 172 (86@2x), 196 (98@2x), 216 (108@2x), 258 (129@2x), 1024 (marketing)
watch_sizes = [
  { "size" => "24x24", "scale" => "2x", "role" => "notificationCenter", "subtype" => "38mm", "px" => 48 },
  { "size" => "27.5x27.5", "scale" => "2x", "role" => "notificationCenter", "subtype" => "42mm", "px" => 55 },
  { "size" => "33x33", "scale" => "2x", "role" => "notificationCenter", "subtype" => "45mm", "px" => 66 },
  { "size" => "29x29", "scale" => "2x", "role" => "companionSettings", "px" => 58 },
  { "size" => "29x29", "scale" => "3x", "role" => "companionSettings", "px" => 87 },
  { "size" => "40x40", "scale" => "2x", "role" => "appLauncher", "subtype" => "38mm", "px" => 80 },
  { "size" => "44x44", "scale" => "2x", "role" => "appLauncher", "subtype" => "40mm", "px" => 88 },
  { "size" => "46x46", "scale" => "2x", "role" => "appLauncher", "subtype" => "41mm", "px" => 92 },
  { "size" => "50x50", "scale" => "2x", "role" => "appLauncher", "subtype" => "44mm", "px" => 100 },
  { "size" => "51x51", "scale" => "2x", "role" => "appLauncher", "subtype" => "45mm", "px" => 102 },
  { "size" => "54x54", "scale" => "2x", "role" => "appLauncher", "subtype" => "49mm", "px" => 108 },
  { "size" => "86x86", "scale" => "2x", "role" => "quickLook", "subtype" => "38mm", "px" => 172 },
  { "size" => "98x98", "scale" => "2x", "role" => "quickLook", "subtype" => "42mm", "px" => 196 },
  { "size" => "108x108", "scale" => "2x", "role" => "quickLook", "subtype" => "44mm", "px" => 216 },
  { "size" => "117x117", "scale" => "2x", "role" => "quickLook", "subtype" => "45mm", "px" => 234 },
  { "size" => "129x129", "scale" => "2x", "role" => "quickLook", "subtype" => "49mm", "px" => 258 },
  { "size" => "1024x1024", "scale" => "1x", "role" => "watchMarketing", "px" => 1024 }
]

watch_contents = {
  "images" => [],
  "info" => { "author" => "xcode", "version" => 1 }
}

# The user might provide a logo with transparency. watchOS REJECTS transparency and alpha channels.
# Use sips to flatten onto a black background and remove alpha.
def resize_watch(src, dest, px)
  # -i ensures it maps out the alpha channel if we use sips, but ImageMagick is safer.
  # Let's use sips to pad/crop then remove alpha:
  # Actually, sips removes alpha if we convert to jpeg then back, but let's assume the user provided an opaque one.
  # If we need to safely remove alpha via sips:
  system("sips -z #{px} #{px} -s format bmp \"#{src}\" --out \"#{dest}.bmp\" > /dev/null")
  system("sips -s format png \"#{dest}.bmp\" --out \"#{dest}\" > /dev/null")
  File.delete("#{dest}.bmp") if File.exist?("#{dest}.bmp")
end

watch_sizes.each do |w|
  filename = "watch-#{w["px"]}.png"
  resize_watch(LIGHT_SRC, File.join(WATCH_ICONSET_DIR, filename), w["px"])
  
  if w["role"] == "watchMarketing"
    img_hash = {
      "filename" => filename,
      "idiom" => "watch-marketing",
      "scale" => w["scale"],
      "size" => w["size"]
    }
  else
    img_hash = {
      "filename" => filename,
      "idiom" => "watch",
      "role" => w["role"],
      "scale" => w["scale"],
      "size" => w["size"]
    }
    img_hash["subtype"] = w["subtype"] if w["subtype"]
  end
  watch_contents["images"] << img_hash
end

File.write(File.join(WATCH_ICONSET_DIR, "Contents.json"), JSON.pretty_generate(watch_contents))

puts "Generating tvOS icons..."

# tvOS brand assets
# Front layer (400x240 and 1280x768)
TVOS_IMAGELAYER_S = File.join(TVOS_BRANDASSETS_DIR, "App Icon - Small.imagestack")
TVOS_IMAGELAYER_L = File.join(TVOS_BRANDASSETS_DIR, "App Icon - Large.imagestack")
FileUtils.mkdir_p(TVOS_IMAGELAYER_S)
FileUtils.mkdir_p(TVOS_IMAGELAYER_L)

# tvOS Top Shelf (1920x720) 
TVOS_TOPSHELF = File.join(TVOS_BRANDASSETS_DIR, "Top Shelf Image.imageset")
FileUtils.mkdir_p(TVOS_TOPSHELF)
topshelf_img = "topshelf.png"
resize_crop(LIGHT_SRC, File.join(TVOS_TOPSHELF, topshelf_img), 1920, 720)
File.write(File.join(TVOS_TOPSHELF, "Contents.json"), JSON.pretty_generate({
  "images" => [{"filename" => topshelf_img, "idiom" => "tv", "scale" => "1x"}],
  "info" => { "author" => "xcode", "version" => 1 }
}))

# App Icon - Small (400x240)
layer_s = File.join(TVOS_IMAGELAYER_S, "Front.imagestacklayer")
FileUtils.mkdir_p(layer_s)
front_s = "front_small.png"
resize_crop(LIGHT_SRC, File.join(layer_s, front_s), 400, 240)
File.write(File.join(layer_s, "Contents.json"), JSON.pretty_generate({
  "images" => [{"filename" => front_s, "idiom" => "tv", "scale" => "1x", "size" => "400x240"}],
  "info" => { "author" => "xcode", "version" => 1 }
}))

layer_s_back = File.join(TVOS_IMAGELAYER_S, "Back.imagestacklayer")
FileUtils.mkdir_p(layer_s_back)
back_s = "back_small.png"
resize_crop(has_dark ? DARK_SRC : LIGHT_SRC, File.join(layer_s_back, back_s), 400, 240)
File.write(File.join(layer_s_back, "Contents.json"), JSON.pretty_generate({
  "images" => [{"filename" => back_s, "idiom" => "tv", "scale" => "1x", "size" => "400x240"}],
  "info" => { "author" => "xcode", "version" => 1 }
}))

File.write(File.join(TVOS_IMAGELAYER_S, "Contents.json"), JSON.pretty_generate({
  "layers" => [
    {"filename" => "Back.imagestacklayer"},
    {"filename" => "Front.imagestacklayer"}
  ],
  "info" => { "author" => "xcode", "version" => 1 }
}))

# App Icon - Large (1280x768)
layer_l = File.join(TVOS_IMAGELAYER_L, "Front.imagestacklayer")
FileUtils.mkdir_p(layer_l)
front_l = "front_large.png"
resize_crop(LIGHT_SRC, File.join(layer_l, front_l), 1280, 768)
File.write(File.join(layer_l, "Contents.json"), JSON.pretty_generate({
  "images" => [{"filename" => front_l, "idiom" => "tv", "scale" => "1x", "size" => "1280x768"}],
  "info" => { "author" => "xcode", "version" => 1 }
}))

layer_l_back = File.join(TVOS_IMAGELAYER_L, "Back.imagestacklayer")
FileUtils.mkdir_p(layer_l_back)
back_l = "back_large.png"
resize_crop(has_dark ? DARK_SRC : LIGHT_SRC, File.join(layer_l_back, back_l), 1280, 768)
File.write(File.join(layer_l_back, "Contents.json"), JSON.pretty_generate({
  "images" => [{"filename" => back_l, "idiom" => "tv", "scale" => "1x", "size" => "1280x768"}],
  "info" => { "author" => "xcode", "version" => 1 }
}))

File.write(File.join(TVOS_IMAGELAYER_L, "Contents.json"), JSON.pretty_generate({
  "layers" => [
    {"filename" => "Back.imagestacklayer"},
    {"filename" => "Front.imagestacklayer"}
  ],
  "info" => { "author" => "xcode", "version" => 1 }
}))

brand_contents = {
  "assets" => [
    { "filename" => "App Icon - Large.imagestack", "idiom" => "tv", "role" => "primary-app-icon", "size" => "1280x768" },
    { "filename" => "App Icon - Small.imagestack", "idiom" => "tv", "role" => "primary-app-icon", "size" => "400x240" },
    { "filename" => "Top Shelf Image.imageset", "idiom" => "tv", "role" => "top-shelf-image" }
  ],
  "info" => { "author" => "xcode", "version" => 1 }
}
File.write(File.join(TVOS_BRANDASSETS_DIR, "Contents.json"), JSON.pretty_generate(brand_contents))

puts "Done!"
