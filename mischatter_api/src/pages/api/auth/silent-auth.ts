import { NextApiRequest, NextApiResponse } from 'next';
import { chatStore } from '../../../lib/store';
import crypto from 'crypto';

interface SilentAuthRequest {
  deviceFingerprint: string;
}

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', ['POST']);
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { deviceFingerprint }: SilentAuthRequest = req.body;

    if (!deviceFingerprint) {
      return res.status(400).json({ error: 'Device fingerprint is required' });
    }

    // Generate user ID from device fingerprint
    const userID = 'user_' + deviceFingerprint.substring(0, 16);

    // Check if user already exists
    let user = chatStore.getUser(userID);

    if (!user) {
      // Create new anonymous user
      user = {
        id: userID,
        username: `Anonymous ${deviceFingerprint.substring(0, 8)}`,
        deviceFingerprint: deviceFingerprint,
        isOnline: true,
        joinedAt: new Date(),
        authMethod: 'silent'
      };

      chatStore.addUser(user);
    } else {
      // Update existing user online status
      user.isOnline = true;
    }

    // Generate token
    const tokenData = {
      userId: user.id,
      username: user.username,
      authMethod: 'silent',
      deviceFingerprint: user.deviceFingerprint
    };

    const token = Buffer.from(JSON.stringify(tokenData)).toString('base64');

    res.status(200).json({
      success: true,
      user,
      token,
      message: user.joinedAt.getTime() === new Date().getTime() ? 'New user created' : 'User authenticated'
    });

  } catch (error) {
    console.error('Silent authentication error:', error);
    res.status(500).json({ error: 'Silent authentication failed' });
  }
}