# MisChatter API Documentation

## Overview
Real-time chat API built with Next.js and Socket.io for seamless integration with Swift applications.

**Base URL:** `http://localhost:3000` (development)  
**WebSocket URL:** `ws://localhost:3000/api/socket`

## Authentication

### Login
**POST** `/api/auth/login`

Create or authenticate a user.

```json
{
  "username": "john_doe",
  "avatar": "https://example.com/avatar.jpg" // optional
}
```

**Response:**
```json
{
  "user": {
    "id": "uuid-here",
    "username": "john_doe",
    "avatar": "https://example.com/avatar.jpg",
    "isOnline": true,
    "joinedAt": "2024-01-01T00:00:00.000Z"
  },
  "token": "base64-encoded-token",
  "message": "Login successful"
}
```

### Validate Token
**POST** `/api/auth/validate`

Validate user token and refresh online status.

```json
{
  "token": "base64-encoded-token"
}
```

## REST API Endpoints

### Health Check
**GET** `/api/health`

Get server health and statistics.

**Response:**
```json
{
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "uptime": 12345,
  "totalUsers": 10,
  "onlineUsers": 5,
  "totalRooms": 3,
  "version": "1.0.0"
}
```

### Rooms

#### Get All Rooms
**GET** `/api/chat/rooms`

**Response:**
```json
{
  "rooms": [
    {
      "id": "general",
      "name": "General",
      "description": "Default chat room",
      "createdBy": "system",
      "createdAt": "2024-01-01T00:00:00.000Z",
      "isPrivate": false,
      "participants": ["user1", "user2"],
      "lastActivity": "2024-01-01T12:00:00.000Z"
    }
  ]
}
```

#### Create Room
**POST** `/api/chat/rooms`

```json
{
  "name": "My Room",
  "description": "A private room for friends",
  "isPrivate": false,
  "createdBy": "user-id"
}
```

#### Get Room Messages
**GET** `/api/chat/rooms/[roomId]/messages?limit=50&offset=0`

**Response:**
```json
{
  "messages": [
    {
      "id": "msg-uuid",
      "content": "Hello world!",
      "userId": "user-id",
      "username": "john_doe",
      "roomId": "room-id",
      "timestamp": "2024-01-01T12:00:00.000Z",
      "type": "text"
    }
  ],
  "room": { /* room object */ }
}
```

#### Get Room Participants
**GET** `/api/chat/rooms/[roomId]/participants`

**Response:**
```json
{
  "participants": [
    {
      "id": "user-id",
      "username": "john_doe",
      "avatar": "avatar-url",
      "isOnline": true,
      "joinedAt": "2024-01-01T00:00:00.000Z"
    }
  ],
  "room": { /* room object */ }
}
```

### Users

#### Get Users
**GET** `/api/chat/users?online=true`

**Response:**
```json
{
  "users": [
    {
      "id": "user-id",
      "username": "john_doe",
      "avatar": "avatar-url",
      "isOnline": true,
      "joinedAt": "2024-01-01T00:00:00.000Z"
    }
  ]
}
```

#### Create User
**POST** `/api/chat/users`

```json
{
  "username": "jane_doe",
  "avatar": "https://example.com/avatar.jpg"
}
```

## WebSocket Events

### Connection
Connect to: `ws://localhost:3000/api/socket`

### Client → Server Events

#### Join Room
```json
{
  "event": "room:join",
  "data": {
    "roomId": "room-id"
  }
}
```

#### Leave Room
```json
{
  "event": "room:leave",
  "data": {
    "roomId": "room-id"
  }
}
```

#### Create Room
```json
{
  "event": "room:create",
  "data": {
    "name": "New Room",
    "description": "Room description",
    "isPrivate": false
  }
}
```

#### Send Message
```json
{
  "event": "message:send",
  "data": {
    "content": "Hello everyone!",
    "roomId": "room-id",
    "type": "text"
  }
}
```

#### Typing Indicators
```json
{
  "event": "typing:start",
  "data": {
    "roomId": "room-id"
  }
}
```

```json
{
  "event": "typing:stop",
  "data": {
    "roomId": "room-id"
  }
}
```

### Server → Client Events

#### New Message
```json
{
  "event": "message:new",
  "data": {
    "message": {
      "id": "msg-uuid",
      "content": "Hello!",
      "userId": "user-id",
      "username": "john_doe",
      "roomId": "room-id",
      "timestamp": "2024-01-01T12:00:00.000Z",
      "type": "text"
    },
    "user": { /* user object */ }
  }
}
```

#### User Joined
```json
{
  "event": "user:joined",
  "data": {
    "user": { /* user object */ },
    "room": { /* room object */ }
  }
}
```

#### User Left
```json
{
  "event": "user:left",
  "data": {
    "user": { /* user object */ },
    "room": { /* room object */ }
  }
}
```

#### Room Created
```json
{
  "event": "room:created",
  "data": {
    "room": { /* room object */ }
  }
}
```

#### Typing Events
```json
{
  "event": "typing:start",
  "data": {
    "userId": "user-id",
    "username": "john_doe",
    "roomId": "room-id"
  }
}
```

#### Error
```json
{
  "event": "error",
  "data": {
    "message": "Error description",
    "code": "ERROR_CODE"
  }
}
```

## Swift Integration Guide

### 1. Install Dependencies
```swift
// Add to Package.swift
.package(url: "https://github.com/socketio/socket.io-client-swift", from: "16.0.0")
```

### 2. Create Socket Manager
```swift
import SocketIO

class ChatSocketManager: ObservableObject {
    private var manager: SocketManager
    private var socket: SocketIOClient
    
    @Published var messages: [Message] = []
    @Published var users: [User] = []
    @Published var isConnected = false
    
    init() {
        manager = SocketManager(socketURL: URL(string: "http://localhost:3000")!, config: [.log(true), .compress])
        socket = manager.defaultSocket
        setupSocketEvents()
    }
    
    func connect() {
        socket.connect()
    }
    
    func disconnect() {
        socket.disconnect()
    }
    
    private func setupSocketEvents() {
        socket.on(clientEvent: .connect) { data, ack in
            self.isConnected = true
        }
        
        socket.on("message:new") { data, ack in
            // Handle new message
        }
        
        // Add more event handlers...
    }
    
    func sendMessage(content: String, roomId: String) {
        socket.emit("message:send", ["content": content, "roomId": roomId])
    }
    
    func joinRoom(roomId: String) {
        socket.emit("room:join", ["roomId": roomId])
    }
}
```

### 3. Data Models
```swift
struct User: Codable, Identifiable {
    let id: String
    let username: String
    let avatar: String?
    let isOnline: Bool
    let joinedAt: Date
}

struct Message: Codable, Identifiable {
    let id: String
    let content: String
    let userId: String
    let username: String
    let roomId: String
    let timestamp: Date
    let type: MessageType
}

enum MessageType: String, Codable {
    case text, image, file, system
}

struct Room: Codable, Identifiable {
    let id: String
    let name: String
    let description: String?
    let createdBy: String
    let createdAt: Date
    let isPrivate: Bool
    let participants: [String]
    let lastActivity: Date
}
```

### 4. HTTP Client
```swift
class ChatAPIClient {
    private let baseURL = "http://localhost:3000/api"
    
    func login(username: String) async throws -> LoginResponse {
        // Implement HTTP login
    }
    
    func getRooms() async throws -> [Room] {
        // Implement get rooms
    }
    
    func getMessages(roomId: String) async throws -> [Message] {
        // Implement get messages
    }
}
```

## Message Types
- `text`: Regular text message
- `image`: Image message (content contains image URL)
- `file`: File message (content contains file URL)
- `system`: System notification

## Error Codes
- `ROOM_NOT_FOUND`: Room doesn't exist
- `USER_NOT_AUTHENTICATED`: User not logged in
- `INVALID_TOKEN`: Token is invalid or expired
- `PERMISSION_DENIED`: User lacks permission

## Development

### Start Server
```bash
cd mischatter_api
npm run dev
```

Server runs on `http://localhost:3000`

### Test WebSocket Connection
Use any WebSocket client to connect to `ws://localhost:3000/api/socket`

## Production Considerations
1. Replace in-memory storage with Redis/Database
2. Implement proper JWT authentication
3. Add rate limiting
4. Add message encryption
5. Implement file upload handling
6. Add push notifications
7. Scale with Redis adapter for multiple server instances