-- 1. Identifying Active Users: Users who posted, liked, or sent messages
SELECT DISTINCT u.user_id, u.username  -- using DISTINCT to count only users with unique user ID and avoid duplicates
FROM users u
LEFT JOIN posts p ON u.user_id = p.user_id
LEFT JOIN likes l ON u.user_id = l.user_id
LEFT JOIN messages m ON u.user_id = m.sender_id
WHERE p.post_id IS NOT NULL OR l.like_id IS NOT NULL OR m.message_id IS NOT NULL;

-- 2. Posts Without Engagement: Posts without any likes
SELECT p.post_id, p.content, u.username
FROM posts p
LEFT JOIN likes l ON p.post_id = l.post_id
JOIN users u ON p.user_id = u.user_id
WHERE l.like_id IS NULL; -- where like ID is null means theres no like or engagement

-- 3. First-Time Liker: First like per user with the corresponding post
SELECT l.user_id, u.username, l.post_id, l.liked_at
FROM likes l
JOIN (
  SELECT user_id, MIN(liked_at) AS first_like_date
  FROM likes
  GROUP BY user_id
) fl ON l.user_id = fl.user_id AND l.liked_at = fl.first_like_date
JOIN users u ON l.user_id = u.user_id;

-- 4. Top Engaged Posts: Top 5 posts with most likes and creator usernames
SELECT p.post_id, COUNT(l.like_id) AS like_count, u.username
FROM posts p
LEFT JOIN likes l ON p.post_id = l.post_id
JOIN users u ON p.user_id = u.user_id
GROUP BY p.post_id, u.username
ORDER BY like_count DESC
LIMIT 5;

-- 5. Cross-Platform Influencers: Users with many likes but no messages sent/received
SELECT u.user_id, u.username, COUNT(l.like_id) AS total_likes
FROM users u
JOIN posts p ON u.user_id = p.user_id
LEFT JOIN likes l ON p.post_id = l.post_id
LEFT JOIN messages m1 ON u.user_id = m1.sender_id  -- m1 is for sender
LEFT JOIN messages m2 ON u.user_id = m2.receiver_id -- m2 is for receiver as we are tracking activity and not the count of messages
WHERE (m1.message_id IS NULL AND m2.message_id IS NULL)
GROUP BY u.user_id, u.username
HAVING total_likes >= 5;

-- 6. User Pair Insights: Pairs exchanging messages more than 3 times
SELECT m.sender_id, m.receiver_id, COUNT(*) AS message_count
FROM messages m
GROUP BY m.sender_id, m.receiver_id
HAVING message_count > 3;
-- no Users exchanged messages more than 3 times

-- 8. User Contribution Score: Ranking users by contribution (Assigning 2 points for post, 1 point for like and 1 point for message)
SELECT u.user_id, u.username,
  (2 * COUNT(DISTINCT p.post_id)) + COUNT(DISTINCT l.like_id) + COUNT(DISTINCT m.message_id) AS contribution_score
FROM users u
LEFT JOIN posts p ON u.user_id = p.user_id
LEFT JOIN likes l ON u.user_id = l.user_id
LEFT JOIN messages m ON u.user_id = m.sender_id
GROUP BY u.user_id, u.username
ORDER BY contribution_score DESC;

-- 9. Sentiment Analysis Pipeline: Extract messages with sentiment keywords after Jan 2023
SELECT m.message_id, m.sender_id, m.receiver_id, m.content, m.sent_at
FROM messages m
WHERE (m.content LIKE '%great%' OR m.content LIKE '%happy%' OR m.content LIKE '%excited%')
AND m.sent_at >= '2023-01-01';

-- Identifying Inactive Users
-- Management wants to find users who have never interacted with the platform (no likes, posts, or messages).
-- Flawed Query:
SELECT user_id
FROM users_table
WHERE user_id NOT IN (
 SELECT DISTINCT user_id FROM likes_table
 UNION ALL
 SELECT DISTINCT sender_id FROM messages_table
 UNION ALL
 SELECT DISTINCT user_id FROM posts_table
);
-- UNION ALL retains duplicates, which is unnecessary here. So we are using UNION which avoids duplicates and provides accurate no of users.
-- We have also changed the table names as we saved in the database  
SELECT user_id
FROM users
WHERE user_id NOT IN (
  SELECT DISTINCT user_id FROM likes
  UNION
  SELECT DISTINCT sender_id FROM messages
  UNION
  SELECT DISTINCT receiver_id FROM messages
  UNION
  SELECT DISTINCT user_id FROM posts
);

-- Weekly Activity Report:
-- The analytics team needs a report showing the number of posts created and the total likes received weekly. Focus only on weeks where more than 50 posts were created.

SELECT
 WEEK(created_at) AS week_number,
 COUNT(post_id) AS total_posts,
     (SELECT COUNT(*) FROM likes_table) AS total_likes 
FROM posts_table
GROUP BY WEEK(created_at)
HAVING total_posts > 50;
 
-- Correct query
SELECT 
  DATE_FORMAT(p.created_at, '%Y-%u') AS week, -- Year-Week format
  COUNT(p.post_id) AS total_posts,
  COUNT(l.like_id) AS total_likes
FROM posts p
LEFT JOIN likes l ON p.post_id = l.post_id
GROUP BY week
HAVING total_posts > 50
ORDER BY week;
-- Changed table names as per our data base, and used year week format for date so that the week numbers are counted correctly per year. 