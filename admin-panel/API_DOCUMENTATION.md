# Zenfoo Admin Panel API Documentation

## Delivery Boy APIs

### Order Priority Management

#### Update Order Priority
**Endpoint:** `POST /api/delivery-boy/update-order-priority`

**Authentication:** Required (Delivery Boy)

**Request Body:**
```json
{
  "orders_priority": 0
}
```

**Priority Values:**
- `0` - Both (Food+Grocery and Multi Orders)
- `1` - Food + Grocery only
- `2` - Multi Orders only (contains sweets, foods, etc.)

**Response:**
```json
{
  "error": false,
  "message": "Order priority updated successfully",
  "data": {
    "orders_priority": 0,
    "priority_name": "Both"
  }
}
```

#### Get Order Priority
**Endpoint:** `GET /api/delivery-boy/get-order-priority`

**Authentication:** Required (Delivery Boy)

**Response:**
```json
{
  "error": false,
  "message": "Order priority retrieved successfully",
  "data": {
    "orders_priority": 1,
    "priority_name": "Food + Grocery"
  }
}
```

### Gig Session Management

#### Start Session
**Endpoint:** `POST /api/delivery-boy/gig/start-session`

**Authentication:** Required (Delivery Boy)

**Request Body:**
```json
{
  "latitude": 12.9716,
  "longitude": 77.5946
}
```

**Notes:**
- Automatically finds the delivery boy's booking for today
- Validates that a slot is booked for today
- Checks if current time is within allowed range (30 minutes before slot start to slot end time)
- Preserves original `started_at` timestamp if session is restarted
- Booking must be in 'booked' or 'active' status

**Response:**
```json
{
  "error": false,
  "message": "Session started successfully",
  "data": {
    "session": {
      "id": 123,
      "delivery_boy_id": 45,
      "gig_booking_id": 67,
      "started_at": "2026-01-03T10:30:00.000000Z",
      "ended_at": null,
      "status": "active",
      "start_latitude": "12.9716",
      "start_longitude": "77.5946"
    },
    "booking": {
      "id": 67,
      "booking_status": "active",
      "slot_date": "2026-01-03",
      "start_time": "11:00:00",
      "end_time": "18:00:00"
    }
  }
}
```

**Error Responses:**
- `"No active booking found for today. Please book a slot first."` - No booking exists for today
- `"Your slot starts at {time}. You can start the session 30 minutes before."` - Too early
- `"Slot time has ended. Cannot start session."` - Too late

#### End Session
**Endpoint:** `POST /api/delivery-boy/gig/end-session`

**Authentication:** Required (Delivery Boy)

**Request Body:**
```json
{
  "latitude": 12.9716,
  "longitude": 77.5946
}
```

**Notes:**
- Automatically completes the booking if slot end time has passed
- Updates session status to 'ended'
- Records end location coordinates

**Response:**
```json
{
  "error": false,
  "message": "Session ended successfully",
  "data": {
    "session": {
      "id": 123,
      "delivery_boy_id": 45,
      "gig_booking_id": 67,
      "started_at": "2026-01-03T10:30:00.000000Z",
      "ended_at": "2026-01-03T18:00:00.000000Z",
      "status": "ended",
      "end_latitude": "12.9716",
      "end_longitude": "77.5946"
    },
    "booking_completed": true,
    "message": "Booking marked as completed as slot time has ended"
  }
}
```

---

## Learning Management APIs

### Admin APIs (Authentication Required)

#### Learning Topics

##### Get All Topics
**Endpoint:** `GET /api/learning_topics`

**Query Parameters:**
- `status` (optional) - Filter by status (0 or 1)
- `search` (optional) - Search by name

**Response:**
```json
{
  "error": false,
  "data": [
    {
      "id": 1,
      "name": "Getting Started",
      "description": "Introduction to the platform",
      "image": "learning/topics/abc123.jpg",
      "image_url": "https://example.com/storage/learning/topics/abc123.jpg",
      "sort_order": 0,
      "status": 1,
      "videos_count": 5,
      "created_at": "2026-01-03T10:00:00.000000Z",
      "updated_at": "2026-01-03T10:00:00.000000Z"
    }
  ],
  "total": 1
}
```

##### Create Topic
**Endpoint:** `POST /api/learning_topics/save`

**Content-Type:** `multipart/form-data`

**Request Body:**
```
name: "Getting Started"
description: "Introduction to the platform"
image: [File]
sort_order: 0
status: 1
```

**Response:**
```json
{
  "error": false,
  "data": {
    "topic": {
      "id": 1,
      "name": "Getting Started",
      "description": "Introduction to the platform",
      "image_url": "https://example.com/storage/learning/topics/abc123.jpg",
      "sort_order": 0,
      "status": 1
    },
    "message": "Learning topic created successfully"
  }
}
```

##### Update Topic
**Endpoint:** `POST /api/learning_topics/update`

**Content-Type:** `multipart/form-data`

**Request Body:**
```
id: 1
name: "Updated Topic Name"
description: "Updated description"
image: [File] (optional)
sort_order: 1
status: 1
```

##### Delete Topic
**Endpoint:** `POST /api/learning_topics/delete`

**Request Body:**
```json
{
  "id": 1
}
```

##### Update Topic Status
**Endpoint:** `POST /api/learning_topics/update-status`

**Request Body:**
```json
{
  "id": 1,
  "status": 1
}
```

#### Learning Videos

##### Get All Videos
**Endpoint:** `GET /api/learning_videos`

**Query Parameters:**
- `topic_id` (optional) - Filter by topic
- `status` (optional) - Filter by status (0 or 1)
- `search` (optional) - Search by title

**Response:**
```json
{
  "error": false,
  "data": [
    {
      "id": 1,
      "topic_id": 1,
      "topic_name": "Getting Started",
      "title": "Introduction Video",
      "description": "Learn the basics",
      "video_url": "https://example.com/storage/learning/videos/video.mp4",
      "video_type": "upload",
      "thumbnail": "learning/thumbnails/thumb.jpg",
      "thumbnail_url": "https://example.com/storage/learning/thumbnails/thumb.jpg",
      "duration": 120,
      "formatted_duration": "02:00",
      "sort_order": 0,
      "status": 1,
      "created_at": "2026-01-03T10:00:00.000000Z",
      "updated_at": "2026-01-03T10:00:00.000000Z"
    }
  ],
  "total": 1
}
```

##### Create Video
**Endpoint:** `POST /api/learning_videos/save`

**Content-Type:** `multipart/form-data`

**Request Body:**
```
topic_id: 1
title: "Introduction Video"
description: "Learn the basics"
video_type: "upload" (upload, youtube, or vimeo)
video: [File] (required if video_type is 'upload', max 100MB)
video_url: "https://youtube.com/watch?v=..." (required if video_type is youtube/vimeo)
thumbnail: [File] (optional)
duration: 120 (optional, auto-extracted for uploads)
sort_order: 0
status: 1
```

**Supported Video Formats:** mp4, mov, avi, wmv, flv, mkv

**Notes:**
- For uploaded videos, duration is automatically extracted using getID3
- For YouTube videos, thumbnail is automatically fetched from YouTube
- Maximum upload size: 100MB

**Response:**
```json
{
  "error": false,
  "data": {
    "video": {
      "id": 1,
      "topic_id": 1,
      "title": "Introduction Video",
      "description": "Learn the basics",
      "video_url": "https://example.com/storage/learning/videos/video.mp4",
      "video_type": "upload",
      "thumbnail_url": "https://example.com/storage/learning/thumbnails/thumb.jpg",
      "duration": 120,
      "formatted_duration": "02:00",
      "sort_order": 0,
      "status": 1
    },
    "message": "Learning video created successfully"
  }
}
```

##### Update Video
**Endpoint:** `POST /api/learning_videos/update`

**Content-Type:** `multipart/form-data`

**Request Body:**
```
id: 1
topic_id: 1
title: "Updated Video Title"
description: "Updated description"
video_type: "upload"
video: [File] (optional)
video_url: "URL" (optional)
thumbnail: [File] (optional)
duration: 150
sort_order: 1
status: 1
```

##### Delete Video
**Endpoint:** `POST /api/learning_videos/delete`

**Request Body:**
```json
{
  "id": 1
}
```

**Notes:**
- Deletes associated video file (if uploaded)
- Deletes associated thumbnail file

##### Update Video Status
**Endpoint:** `POST /api/learning_videos/update-status`

**Request Body:**
```json
{
  "id": 1,
  "status": 1
}
```

### Public Learning APIs (No Authentication Required)

#### Get Topics
**Endpoint:** `GET /api/learning/topics`

**Response:**
```json
{
  "error": false,
  "data": [
    {
      "id": 1,
      "name": "Getting Started",
      "description": "Introduction to the platform",
      "image_url": "https://example.com/storage/learning/topics/abc123.jpg",
      "videos_count": 5
    }
  ],
  "total": 1
}
```

**Notes:**
- Returns only active topics (status = 1)
- Ordered by sort_order

#### Get Topic Details
**Endpoint:** `GET /api/learning/topic/{id}`

**Response:**
```json
{
  "error": false,
  "data": {
    "id": 1,
    "name": "Getting Started",
    "description": "Introduction to the platform",
    "image_url": "https://example.com/storage/learning/topics/abc123.jpg",
    "videos_count": 3,
    "videos": [
      {
        "id": 1,
        "title": "Introduction Video",
        "description": "Learn the basics",
        "video_url": "https://example.com/storage/learning/videos/video.mp4",
        "video_type": "upload",
        "thumbnail_url": "https://example.com/storage/learning/thumbnails/thumb.jpg",
        "duration": 120,
        "formatted_duration": "02:00"
      }
    ]
  }
}
```

**Notes:**
- Returns only active videos (status = 1)
- Videos ordered by sort_order

#### Get All Videos
**Endpoint:** `GET /api/learning/videos`

**Query Parameters:**
- `topic_id` (optional) - Filter by specific topic

**Response:**
```json
{
  "error": false,
  "data": [
    {
      "id": 1,
      "topic_id": 1,
      "topic_name": "Getting Started",
      "title": "Introduction Video",
      "description": "Learn the basics",
      "video_url": "https://example.com/storage/learning/videos/video.mp4",
      "video_type": "upload",
      "thumbnail_url": "https://example.com/storage/learning/thumbnails/thumb.jpg",
      "duration": 120,
      "formatted_duration": "02:00"
    }
  ],
  "total": 1
}
```

**Notes:**
- Returns only active videos (status = 1)
- Ordered by sort_order

#### Get Video Details
**Endpoint:** `GET /api/learning/video/{id}`

**Response:**
```json
{
  "error": false,
  "data": {
    "id": 1,
    "topic_id": 1,
    "topic_name": "Getting Started",
    "title": "Introduction Video",
    "description": "Learn the basics",
    "video_url": "https://example.com/storage/learning/videos/video.mp4",
    "video_type": "upload",
    "thumbnail_url": "https://example.com/storage/learning/thumbnails/thumb.jpg",
    "duration": 120,
    "formatted_duration": "02:00"
  }
}
```

---

## Common Response Format

### Success Response
```json
{
  "error": false,
  "data": { ... },
  "message": "Success message",
  "total": 10
}
```

### Error Response
```json
{
  "error": true,
  "message": "Error message",
  "data": null
}
```

## Authentication

All admin APIs require authentication using Laravel Passport. Include the access token in the Authorization header:

```
Authorization: Bearer {access_token}
```

Delivery boy APIs use the delivery boy authentication system with their specific tokens.
