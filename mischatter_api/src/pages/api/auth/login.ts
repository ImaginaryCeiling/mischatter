import { NextApiRequest, NextApiResponse } from 'next';
import { chatStore } from '../../../lib/store';
import { v4 as uuidv4 } from 'uuid';

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', ['POST']);
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { username, avatar } = req.body;

    if (!username || username.trim().length === 0) {
      return res.status(400).json({ error: 'Username is required' });
    }

    if (username.length > 50) {
      return res.status(400).json({ error: 'Username must be less than 50 characters' });
    }

    // Simple authentication - create or get user
    const user = {
      id: uuidv4(),
      username: username.trim(),
      avatar: avatar || undefined,
      isOnline: true,
      joinedAt: new Date(),
    };

    chatStore.addUser(user);

    // In a real app, you'd generate a JWT token here
    const token = Buffer.from(JSON.stringify({ userId: user.id, username: user.username })).toString('base64');

    res.status(200).json({ 
      user, 
      token,
      message: 'Login successful' 
    });
  } catch (error) {
    res.status(500).json({ error: 'Authentication failed' });
  }
}