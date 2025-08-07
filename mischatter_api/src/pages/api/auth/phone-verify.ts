import { NextApiRequest, NextApiResponse } from 'next';
import { chatStore } from '../../../lib/store';
import crypto from 'crypto';

interface PhoneVerifyRequest {
  phoneNumber: string;
  otp: string;
  deviceFingerprint?: string;
}

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', ['POST']);
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { phoneNumber, otp, deviceFingerprint }: PhoneVerifyRequest = req.body;

    if (!phoneNumber || !otp) {
      return res.status(400).json({ error: 'Phone number and OTP are required' });
    }

    // Check OTP
    global.otpStore = global.otpStore || new Map();
    const otpData = global.otpStore.get(phoneNumber);

    if (!otpData) {
      return res.status(400).json({ error: 'OTP not found or expired' });
    }

    if (Date.now() > otpData.expires) {
      global.otpStore.delete(phoneNumber);
      return res.status(400).json({ error: 'OTP has expired' });
    }

    if (otpData.code !== otp) {
      return res.status(400).json({ error: 'Invalid OTP' });
    }

    // OTP is valid, clear it
    global.otpStore.delete(phoneNumber);

    const cleanPhone = phoneNumber.replace(/[^\d]/g, '');
    const userID = otpData.userId;

    let user = chatStore.getUser(userID);

    if (otpData.isNewUser || !user) {
      // Create new user
      user = {
        id: userID,
        username: `User ${cleanPhone.slice(-4)}`, // Default username
        phoneNumber: cleanPhone,
        deviceFingerprint: deviceFingerprint || otpData.deviceFingerprint,
        isOnline: true,
        joinedAt: new Date(),
        authMethod: 'phone'
      };

      chatStore.addUser(user);
    } else {
      // Update existing user
      user.isOnline = true;
      if (deviceFingerprint) {
        user.deviceFingerprint = deviceFingerprint;
      }
    }

    // Generate token
    const tokenData = {
      userId: user.id,
      username: user.username,
      phoneNumber: user.phoneNumber,
      authMethod: 'phone',
      deviceFingerprint: user.deviceFingerprint
    };

    const token = Buffer.from(JSON.stringify(tokenData)).toString('base64');

    res.status(200).json({
      success: true,
      user,
      token,
      message: otpData.isNewUser ? 'Registration successful' : 'Login successful'
    });

  } catch (error) {
    console.error('Phone verification error:', error);
    res.status(500).json({ error: 'Phone verification failed' });
  }
}