import { User, Message, Room, SocketUser } from '../types/chat';
import { v4 as uuidv4 } from 'uuid';

class ChatStore {
  private users = new Map<string, User>();
  private socketUsers = new Map<string, SocketUser>();
  private messages = new Map<string, Message[]>();
  private rooms = new Map<string, Room>();
  private userSocketMap = new Map<string, string>();

  constructor() {
    this.createDefaultRoom();
  }

  private createDefaultRoom() {
    const defaultRoom: Room = {
      id: 'general',
      name: 'General',
      description: 'Default chat room for everyone',
      createdBy: 'system',
      createdAt: new Date(),
      isPrivate: false,
      participants: [],
      lastActivity: new Date(),
    };
    this.rooms.set(defaultRoom.id, defaultRoom);
    this.messages.set(defaultRoom.id, []);
  }

  addUser(user: User): User {
    this.users.set(user.id, user);
    return user;
  }

  getUser(userId: string): User | undefined {
    return this.users.get(userId);
  }

  addSocketUser(socketUser: SocketUser): SocketUser {
    this.socketUsers.set(socketUser.socketId, socketUser);
    this.userSocketMap.set(socketUser.id, socketUser.socketId);
    return socketUser;
  }

  getSocketUser(socketId: string): SocketUser | undefined {
    return this.socketUsers.get(socketId);
  }

  getSocketUserByUserId(userId: string): SocketUser | undefined {
    const socketId = this.userSocketMap.get(userId);
    return socketId ? this.socketUsers.get(socketId) : undefined;
  }

  removeSocketUser(socketId: string): void {
    const socketUser = this.socketUsers.get(socketId);
    if (socketUser) {
      this.userSocketMap.delete(socketUser.id);
      this.socketUsers.delete(socketId);
    }
  }

  updateUserOnlineStatus(userId: string, isOnline: boolean): void {
    const user = this.users.get(userId);
    if (user) {
      user.isOnline = isOnline;
    }
  }

  addMessage(message: Message): Message {
    const roomMessages = this.messages.get(message.roomId) || [];
    roomMessages.push(message);
    this.messages.set(message.roomId, roomMessages);

    const room = this.rooms.get(message.roomId);
    if (room) {
      room.lastActivity = new Date();
      if (!room.participants.includes(message.userId)) {
        room.participants.push(message.userId);
      }
    }

    return message;
  }

  getMessages(roomId: string, limit = 50, offset = 0): Message[] {
    const roomMessages = this.messages.get(roomId) || [];
    return roomMessages
      .sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime())
      .slice(offset, offset + limit)
      .reverse();
  }

  createRoom(room: Omit<Room, 'id' | 'createdAt' | 'lastActivity' | 'participants'>): Room {
    const newRoom: Room = {
      ...room,
      id: uuidv4(),
      createdAt: new Date(),
      lastActivity: new Date(),
      participants: [],
    };
    
    this.rooms.set(newRoom.id, newRoom);
    this.messages.set(newRoom.id, []);
    
    return newRoom;
  }

  getRoom(roomId: string): Room | undefined {
    return this.rooms.get(roomId);
  }

  getRooms(): Room[] {
    return Array.from(this.rooms.values()).sort((a, b) => 
      b.lastActivity.getTime() - a.lastActivity.getTime()
    );
  }

  addUserToRoom(userId: string, roomId: string): boolean {
    const room = this.rooms.get(roomId);
    if (room && !room.participants.includes(userId)) {
      room.participants.push(userId);
      return true;
    }
    return false;
  }

  removeUserFromRoom(userId: string, roomId: string): boolean {
    const room = this.rooms.get(roomId);
    if (room) {
      const index = room.participants.indexOf(userId);
      if (index > -1) {
        room.participants.splice(index, 1);
        return true;
      }
    }
    return false;
  }

  getRoomParticipants(roomId: string): User[] {
    const room = this.rooms.get(roomId);
    if (!room) return [];

    return room.participants
      .map(userId => this.users.get(userId))
      .filter((user): user is User => user !== undefined);
  }

  getOnlineUsers(): User[] {
    return Array.from(this.users.values()).filter(user => user.isOnline);
  }

  cleanup(): void {
    // Remove old messages (keep last 1000 per room)
    for (const [roomId, messages] of this.messages.entries()) {
      if (messages.length > 1000) {
        const sortedMessages = messages.sort((a, b) => b.timestamp.getTime() - a.timestamp.getTime());
        this.messages.set(roomId, sortedMessages.slice(0, 1000));
      }
    }
  }
}

export const chatStore = new ChatStore();