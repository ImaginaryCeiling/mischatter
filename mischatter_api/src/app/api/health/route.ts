import { chatStore } from '../../../lib/store';

export async function GET() {
  const stats = {
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    totalUsers: Array.from(chatStore['users'].values()).length,
    onlineUsers: chatStore.getOnlineUsers().length,
    totalRooms: chatStore.getRooms().length,
    version: process.env.npm_package_version || '1.0.0',
  };

  return Response.json(stats);
}