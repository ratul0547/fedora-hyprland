import QtQuick

/**
 * Reddit NSFW (Not-Safe-for-Work) subreddit sources
 * This file contains NSFW subreddits and users for wallpaper fetching
 * Only used when NSFW mode is enabled in the sidebar
 */
QtObject {
    // List of NSFW subreddits - top 20 image-based NSFW subreddits
    property var subreddits: [
        "NSFW_Wallpapers",
        "nsfwwallpapers",
        "NSFWFunny",
        "NSFW_GIF",
        "gonewild",
        "RealGirls",
        "adorableporn",
        "BustyPetite",
        "LegalTeens",
        "nsfw",
        "collegesluts",
        "Nude_Selfie",
        "boobs",
        "OnOff",
        "fitgirls",
        "pussy",
        "Amateur",
        "TikTokNudes",
        "bodyperfection",
        "ass",
        "celebnsfw"
    ]
    
    // List of Reddit users known for NSFW content
    property var users: [
        // Add user sources in format "u/username" if needed
    ]
}
