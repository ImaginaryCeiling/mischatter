import { Server as NetServer } from 'http';
import { NextApiRequest, NextApiResponse } from 'next';
import { Server as SocketIOServer } from 'socket.io';
import { 
  ServerToClientEvents, 
  ClientToServerEvents, 
  InterServerEvents, 
  SocketData, 
  User, 
  Message, 
  SocketUser 
} from '../types/chat';
import { chatStore } from './store';
import { v4 as uuidv4 } from 'uuid';

export type NextApiResponseServerIO = NextApiResponse & {
  socket: {
    server: NetServer & {
      io: SocketIOServer<ClientToServerEvents, ServerToClientEvents, InterServerEvents, SocketData>;
    };
  };
};

export const config = {
  api: {
    bodyParser: false,
  },
};

export function initializeSocket(server: NetServer) {
  const io = new SocketIOServer<
    ClientToServerEvents,
    ServerToClientEvents,
    InterServerEvents,
    SocketData
  >(server, {
    path: '/api/socket',
    addTrailingSlash: false,
    cors: {
      origin: "*",
      methods: ["GET", "POST"]
    }
  });

  io.on('connection', (socket) => {
    console.log('User connected:', socket.id);

    socket.on('disconnect', () => {
      console.log('User disconnected:', socket.id);
      const socketUser = chatStore.getSocketUser(socket.id);
      
      if (socketUser) {
        // Update user offline status
        chatStore.updateUserOnlineStatus(socketUser.id, false);
        
        // Leave all rooms and notify other users
        socketUser.currentRooms.forEach(roomId => {
          socket.leave(roomId);
          socket.to(roomId).emit('user:left', { 
            user: socketUser, 
            room: chatStore.getRoom(roomId)! 
          });
          chatStore.removeUserFromRoom(socketUser.id, roomId);
        });
        
        // Remove socket user
        chatStore.removeSocketUser(socket.id);
      }
    });

    socket.on('room:join', async (data) => {
      try {
        const { roomId } = data;
        const room = chatStore.getRoom(roomId);
        
        if (!room) {
          socket.emit('error', { message: 'Room not found', code: 'ROOM_NOT_FOUND' });
          return;
        }

        // Get or create user (in a real app, this would come from authentication)
        let socketUser = chatStore.getSocketUser(socket.id);
        
        if (!socketUser) {
          // Create temporary user for demo purposes
          const tempUser: User = {
            id: uuidv4(),
            username: `User_${Math.random().toString(36).substr(2, 5)}`,
            isOnline: true,
            joinedAt: new Date(),
          };
          
          chatStore.addUser(tempUser);
          
          socketUser = {
            ...tempUser,
            socketId: socket.id,
            currentRooms: [],
          };
          
          chatStore.addSocketUser(socketUser);
        }

        // Join the room
        socket.join(roomId);
        socketUser.currentRooms.push(roomId);
        chatStore.addUserToRoom(socketUser.id, roomId);
        chatStore.updateUserOnlineStatus(socketUser.id, true);

        // Notify others in the room
        socket.to(roomId).emit('user:joined', { user: socketUser, room });
        
        console.log(`${socketUser.username} joined room ${room.name}`);
      } catch (error) {
        socket.emit('error', { message: 'Failed to join room' });
      }
    });

    socket.on('room:leave', async (data) => {
      try {
        const { roomId } = data;
        const socketUser = chatStore.getSocketUser(socket.id);
        const room = chatStore.getRoom(roomId);
        
        if (!socketUser || !room) {
          socket.emit('error', { message: 'Invalid room or user' });
          return;
        }

        // Leave the room
        socket.leave(roomId);
        const roomIndex = socketUser.currentRooms.indexOf(roomId);
        if (roomIndex > -1) {
          socketUser.currentRooms.splice(roomIndex, 1);
        }
        
        chatStore.removeUserFromRoom(socketUser.id, roomId);

        // Notify others in the room
        socket.to(roomId).emit('user:left', { user: socketUser, room });
        
        console.log(`${socketUser.username} left room ${room.name}`);
      } catch (error) {
        socket.emit('error', { message: 'Failed to leave room' });
      }
    });

    socket.on('room:create', async (data) => {
      try {
        const socketUser = chatStore.getSocketUser(socket.id);
        
        if (!socketUser) {
          socket.emit('error', { message: 'User not authenticated' });
          return;
        }

        const { name, description, isPrivate = false } = data;
        
        const room = chatStore.createRoom({
          name,
          description,
          createdBy: socketUser.id,
          isPrivate,
        });

        // Creator automatically joins the room
        socket.join(room.id);
        socketUser.currentRooms.push(room.id);
        chatStore.addUserToRoom(socketUser.id, room.id);

        // Broadcast new room to all users (except private rooms)
        if (!isPrivate) {
          io.emit('room:created', { room });
        } else {
          socket.emit('room:created', { room });
        }
        
        console.log(`Room ${room.name} created by ${socketUser.username}`);
      } catch (error) {
        socket.emit('error', { message: 'Failed to create room' });
      }
    });

    socket.on('message:send', async (data) => {
      try {
        const { content, roomId, type = 'text' } = data;
        const socketUser = chatStore.getSocketUser(socket.id);
        const room = chatStore.getRoom(roomId);
        
        if (!socketUser || !room) {
          socket.emit('error', { message: 'Invalid room or user' });
          return;
        }

        if (!socketUser.currentRooms.includes(roomId)) {
          socket.emit('error', { message: 'You are not in this room' });
          return;
        }

        const message: Message = {
          id: uuidv4(),
          content,
          userId: socketUser.id,
          username: socketUser.username,
          roomId,
          timestamp: new Date(),
          type,
        };

        // Save message
        chatStore.addMessage(message);

        // Broadcast to all users in the room
        io.to(roomId).emit('message:new', { message, user: socketUser });
        
        console.log(`Message from ${socketUser.username} in ${room.name}: ${content}`);
      } catch (error) {
        socket.emit('error', { message: 'Failed to send message' });
      }
    });

    socket.on('typing:start', (data) => {
      const { roomId } = data;
      const socketUser = chatStore.getSocketUser(socket.id);
      
      if (socketUser && socketUser.currentRooms.includes(roomId)) {
        socket.to(roomId).emit('typing:start', {
          userId: socketUser.id,
          username: socketUser.username,
          roomId,
        });
      }
    });

    socket.on('typing:stop', (data) => {
      const { roomId } = data;
      const socketUser = chatStore.getSocketUser(socket.id);
      
      if (socketUser && socketUser.currentRooms.includes(roomId)) {
        socket.to(roomId).emit('typing:stop', {
          userId: socketUser.id,
          roomId,
        });
      }
    });
  });

  // Cleanup job every 30 minutes
  setInterval(() => {
    chatStore.cleanup();
  }, 30 * 60 * 1000);

  return io;
}