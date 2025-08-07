import { NextApiRequest, NextApiResponse } from 'next';
import { chatStore } from '../../../../../lib/store';

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'GET') {
    res.setHeader('Allow', ['GET']);
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { roomId } = req.query;
    const { limit = '50', offset = '0' } = req.query;

    if (typeof roomId !== 'string') {
      return res.status(400).json({ error: 'Invalid room ID' });
    }

    const room = chatStore.getRoom(roomId);
    if (!room) {
      return res.status(404).json({ error: 'Room not found' });
    }

    const parsedLimit = parseInt(limit as string, 10);
    const parsedOffset = parseInt(offset as string, 10);

    if (isNaN(parsedLimit) || isNaN(parsedOffset) || parsedLimit < 0 || parsedOffset < 0) {
      return res.status(400).json({ error: 'Invalid limit or offset' });
    }

    const messages = chatStore.getMessages(roomId, parsedLimit, parsedOffset);
    res.status(200).json({ messages, room });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch messages' });
  }
}