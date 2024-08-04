{ pkgs, ... }:
{
  # exclude default GNOME Packages
  environment.gnome.excludePackages = (with pkgs; [
    gnome-photos
    gnome-tour
    # gedit # Text Editor
    gnome-text-editor # Text Editor
  ]) ++ (with pkgs.gnome; [
    gnome-calendar
    gnome-contacts
    gnome-music
    gnome-weather
    cheese # Webcam / Camera App
    epiphany # Web Browser
    evince # Document Viewer
    geary # Email Client
    seahorse # Password Manager
    totem # Video Player
    yelp # Help Viewer
  ]);
}