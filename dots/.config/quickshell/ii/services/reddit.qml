pragma Singleton
import QtQuick

/**
 * Reddit SFW (Safe-for-Work) subreddit sources
 * This file contains curated safe-for-work subreddits and users for wallpaper fetching
 */
QtObject {
    // List of safe-for-work subreddits
    property var subreddits: [
        "wallpaper",
        "wallpapers",
        "EarthPorn",
        "MinimalWallpaper",
        "wallpaperdump",
        "Amoledbackgrounds",
        "WidescreenWallpaper",
        "multiwall",
        "backgroundart",
        "MinimalWallpapers",
        "DesktopDetective",
        "aestheticwallpapers",
        "ImaginaryLandscapes",
        "CozyPlaces",
        "ruralporn",
        "CityPorn",
        "SkyPorn",
        "spaceporn",
        "SeaPorn",
        "winterporn"
    ]
    
    // List of Reddit users known for quality wallpaper posts
    property var users: [
        // Add user sources in format "u/username" if needed
    ]
}
