import { NextApiRequest, NextApiResponse } from 'next';
import { chatStore } from '../../../lib/store';

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', ['POST']);
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({ error: 'Token is required' });
    }

    // Simple token validation (decode base64)
    let decoded;
    try {
      decoded = JSON.parse(Buffer.from(token, 'base64').toString());
    } catch {
      return res.status(401).json({ error: 'Invalid token' });
    }

    const { userId, username } = decoded;
    const user = chatStore.getUser(userId);

    if (!user) {
      return res.status(401).json({ error: 'User not found' });
    }

    // Update online status
    chatStore.updateUserOnlineStatus(userId, true);

    res.status(200).json({ 
      user,
      valid: true,
      message: 'Token is valid' 
    });
  } catch (error) {
    res.status(500).json({ error: 'Token validation failed' });
  }
}