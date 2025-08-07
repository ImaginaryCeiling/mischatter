import { NextApiRequest, NextApiResponse } from 'next';
import { chatStore } from '../../../../../lib/store';

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'GET') {
    res.setHeader('Allow', ['GET']);
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { roomId } = req.query;

    if (typeof roomId !== 'string') {
      return res.status(400).json({ error: 'Invalid room ID' });
    }

    const room = chatStore.getRoom(roomId);
    if (!room) {
      return res.status(404).json({ error: 'Room not found' });
    }

    const participants = chatStore.getRoomParticipants(roomId);
    res.status(200).json({ participants, room });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch participants' });
  }
}