export interface User {
  id: string;
  username: string;
  avatar?: string;
  phoneNumber?: string;
  deviceFingerprint?: string;
  authMethod?: 'phone' | 'device' | 'silent' | 'username';
  isOnline: boolean;
  joinedAt: Date;
}

export interface Message {
  id: string;
  content: string;
  userId: string;
  username: string;
  roomId: string;
  timestamp: Date;
  type: 'text' | 'image' | 'file' | 'system';
}

export interface Room {
  id: string;
  name: string;
  description?: string;
  createdBy: string;
  createdAt: Date;
  isPrivate: boolean;
  participants: string[];
  lastActivity: Date;
}

export interface SocketUser extends User {
  socketId: string;
  currentRooms: string[];
}

export interface ChatEventData {
  message: Message;
  user: User;
  room: Room;
}

export interface ServerToClientEvents {
  'message:new': (data: { message: Message; user: User }) => void;
  'user:joined': (data: { user: User; room: Room }) => void;
  'user:left': (data: { user: User; room: Room }) => void;
  'room:created': (data: { room: Room }) => void;
  'typing:start': (data: { userId: string; username: string; roomId: string }) => void;
  'typing:stop': (data: { userId: string; roomId: string }) => void;
  'error': (error: { message: string; code?: string }) => void;
}

export interface ClientToServerEvents {
  'message:send': (data: { content: string; roomId: string; type?: Message['type'] }) => void;
  'room:join': (data: { roomId: string }) => void;
  'room:leave': (data: { roomId: string }) => void;
  'room:create': (data: { name: string; description?: string; isPrivate?: boolean }) => void;
  'typing:start': (data: { roomId: string }) => void;
  'typing:stop': (data: { roomId: string }) => void;
}

export interface InterServerEvents {}

export interface SocketData {
  user: SocketUser;
}