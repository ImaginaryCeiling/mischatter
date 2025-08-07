import { NextApiRequest, NextApiResponse } from 'next';
import { chatStore } from '../../../lib/store';

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  switch (req.method) {
    case 'GET':
      return getRooms(req, res);
    case 'POST':
      return createRoom(req, res);
    default:
      res.setHeader('Allow', ['GET', 'POST']);
      res.status(405).json({ error: 'Method not allowed' });
  }
}

function getRooms(req: NextApiRequest, res: NextApiResponse) {
  try {
    const rooms = chatStore.getRooms();
    res.status(200).json({ rooms });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch rooms' });
  }
}

function createRoom(req: NextApiRequest, res: NextApiResponse) {
  try {
    const { name, description, isPrivate = false, createdBy } = req.body;

    if (!name || !createdBy) {
      return res.status(400).json({ error: 'Name and createdBy are required' });
    }

    const room = chatStore.createRoom({
      name,
      description,
      createdBy,
      isPrivate,
    });

    res.status(201).json({ room });
  } catch (error) {
    res.status(500).json({ error: 'Failed to create room' });
  }
}