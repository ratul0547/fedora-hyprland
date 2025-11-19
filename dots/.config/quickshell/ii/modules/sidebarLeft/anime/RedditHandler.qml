pragma Singleton
import QtQuick

/**
 * Reddit-specific handler for the Booru system
 */
QtObject {
    id: root

    // Parse Reddit commands and return structured data
    function parseRedditCommand(inputText) {
        const parts = inputText.trim().split(/\s+/);

        // Check for /s (search) command
        if (parts[0] === "/s") {
            return parseSearchCommand(parts.slice(1), "");
        }

        // Check for r/subreddit followed by /s (search in subreddit)
        if (parts[0].startsWith("r/") && parts.length > 1 && parts[1] === "/s") {
            const subreddit = parts[0].substring(2);
            return parseSearchCommand(parts.slice(2), subreddit);
        }

        // Check for direct subreddit or user (show posts)
        if (parts[0].startsWith("r/") || parts[0].startsWith("u/")) {
            return parseShowCommand(parts);
        }

        return null;
    }

    function parseShowCommand(args) {
        if (args.length === 0) return null;

        let sort = "new";
        let time = "week";
        let target = "";
        let isUser = false;

        // Parse arguments
        let i = 0;

        // First, get target (r/subreddit or u/username) - it should be the first argument
        if (args[i].startsWith("r/")) {
            target = args[i].substring(2);
            i++;
        } else if (args[i].startsWith("u/")) {
            target = args[i].substring(2);
            isUser = true;
            sort = "new"; // Users default to recent
            i++;
        }

        // Now check for sort modifiers that come after the subreddit
        // These can be: /top, /new, /best, /hot
        if (i < args.length) {
            if (args[i] === "/top") {
                sort = "top";
                i++;
                // Check for time parameter after /top
                if (i < args.length && ["day", "week", "month", "year", "all"].includes(args[i])) {
                    time = args[i];
                    i++;
                }
            } else if (args[i] === "/new") {
                sort = "new";
                i++;
            } else if (args[i] === "/best") {
                sort = "best";
                i++;
            } else if (args[i] === "/hot") {
                sort = "hot";
                i++;
            }
        }

        return {
            type: "show",
            sort: sort,
            time: time,
            target: target,
            isUser: isUser
        };
    }

    function parseSearchCommand(args, subreddit) {
        if (args.length === 0) return null;

        let sort = "relevance"; // Default sort for search
        let time = "all";
        let query = [];

        let i = 0;

        // Parse arguments to find sort modifiers and query
        while (i < args.length) {
            // Check for /top modifier with optional time
            if (args[i] === "/top") {
                sort = "top";
                i++;
                // Check if next argument is a time filter
                if (i < args.length && ["day", "week", "month", "year", "all"].includes(args[i])) {
                    time = args[i];
                    i++;
                }
            }
            // Check for /new modifier
            else if (args[i] === "/new") {
                sort = "new";
                i++;
            }
            // Check for /hot modifier
            else if (args[i] === "/hot") {
                sort = "hot";
                i++;
            }
            // Check for /best modifier (note: Reddit search doesn't support best, fallback to relevance)
            else if (args[i] === "/best") {
                sort = "relevance";
                i++;
            }
            // Otherwise it's part of the query
            else {
                query.push(args[i]);
                i++;
            }
        }

        return {
            type: "search",
            subreddit: subreddit,
            query: query.join(" "),
            sort: sort,
            time: time
        };
    }

    // Construct Reddit API URL based on parsed command
    function constructRedditUrl(parsedCommand, nsfw, limit, afterToken) {
        const after = afterToken ? `&after=${afterToken}` : "";
        // Include over_18 parameter to get NSFW content
        const over18Param = nsfw ? "&include_over_18=on" : "";

        if (parsedCommand.type === "show") {
            if (parsedCommand.isUser) {
                // User posts: /user/{username}/submitted.json
                return `https://www.reddit.com/user/${parsedCommand.target}/submitted.json?limit=${limit}${after}${over18Param}&raw_json=1`;
            } else {
                // Subreddit posts: /r/{subreddit}/{sort}.json
                const timeParam = parsedCommand.sort === "top" ? `&t=${parsedCommand.time}` : "";
                return `https://www.reddit.com/r/${parsedCommand.target}/${parsedCommand.sort}.json?limit=${limit}${timeParam}${after}${over18Param}&raw_json=1`;
            }
        } else if (parsedCommand.type === "search") {
            // Search: /search.json or /r/{subreddit}/search.json
            const subredditPath = parsedCommand.subreddit ? `/r/${parsedCommand.subreddit}` : "";
            const restrictSr = parsedCommand.subreddit ? "&restrict_sr=1" : "";
            const sortParam = `&sort=${parsedCommand.sort}`;
            const timeParam = parsedCommand.sort === "top" ? `&t=${parsedCommand.time}` : "";
            return `https://www.reddit.com${subredditPath}/search.json?q=${encodeURIComponent(parsedCommand.query)}${restrictSr}${sortParam}${timeParam}&limit=${limit}${after}${over18Param}&raw_json=1`;
        }

        return "";
    }

    // Parse Reddit JSON response and extract image posts
    function parseRedditResponse(response, allowNsfw) {
        if (!response.data || !response.data.children) {
            return [];
        }

        const posts = response.data.children;
        const images = [];

        for (let i = 0; i < posts.length; i++) {
            const post = posts[i].data;

            // Skip non-image posts
            if (!post.post_hint || post.post_hint !== "image") {
                continue;
            }

            // NSFW filtering for Reddit: strict separation
            // If NSFW mode is enabled, show only NSFW content
            // If NSFW mode is disabled, show only SFW content
            if (allowNsfw) {
                // NSFW mode: only show NSFW posts
                if (!post.over_18) {
                    continue;
                }
            } else {
                // SFW mode: only show SFW posts
                if (post.over_18) {
                    continue;
                }
            }

            // Extract image data
            let imageUrl = post.url;
            let previewUrl = post.thumbnail;

            // Try to get better preview from preview object
            if (post.preview && post.preview.images && post.preview.images.length > 0) {
                const preview = post.preview.images[0];
                if (preview.resolutions && preview.resolutions.length > 0) {
                    previewUrl = preview.resolutions[preview.resolutions.length - 1].url.replace(/&amp;/g, '&');
                }
                if (preview.source) {
                    imageUrl = preview.source.url.replace(/&amp;/g, '&');
                }
            }

            // Get dimensions
            let width = 1000;
            let height = 1000;
            if (post.preview && post.preview.images && post.preview.images[0] && post.preview.images[0].source) {
                width = post.preview.images[0].source.width;
                height = post.preview.images[0].source.height;
            }

            images.push({
                id: post.id,
                width: width,
                height: height,
                aspect_ratio: width / height,
                tags: `r/${post.subreddit}`,
                rating: post.over_18 ? "e" : "s",
                is_nsfw: post.over_18,
                md5: post.id,
                preview_url: previewUrl,
                sample_url: imageUrl,
                file_url: imageUrl,
                file_ext: imageUrl.split('.').pop().split('?')[0],
                        source: `https://www.reddit.com${post.permalink}`,
                        title: post.title
            });
        }

        return images;
    }
}
