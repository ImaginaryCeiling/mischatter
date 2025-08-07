import { NextApiRequest, NextApiResponse } from 'next';
import { chatStore } from '../../../lib/store';
import crypto from 'crypto';

interface PhoneRegisterRequest {
  phoneNumber: string;
  deviceFingerprint?: string;
}

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', ['POST']);
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { phoneNumber, deviceFingerprint }: PhoneRegisterRequest = req.body;

    if (!phoneNumber || phoneNumber.trim().length === 0) {
      return res.status(400).json({ error: 'Phone number is required' });
    }

    // Validate phone number format (basic validation)
    const cleanPhone = phoneNumber.replace(/[^\d]/g, '');
    if (cleanPhone.length < 10 || cleanPhone.length > 15) {
      return res.status(400).json({ error: 'Invalid phone number format' });
    }

    // Generate user ID from phone number (same logic as phone app)
    const userID = generateUserID(cleanPhone, deviceFingerprint);
    
    // Check if user already exists
    let existingUser = chatStore.getUser(userID);
    
    if (existingUser) {
      // User exists, send OTP for verification
      const otpCode = generateOTP();
      
      // In production, send actual OTP via SMS
      console.log(`OTP for ${phoneNumber}: ${otpCode}`);
      
      // Store OTP temporarily (in production, use Redis or similar)
      global.otpStore = global.otpStore || new Map();
      global.otpStore.set(phoneNumber, {
        code: otpCode,
        userId: userID,
        expires: Date.now() + 5 * 60 * 1000, // 5 minutes
      });

      return res.status(200).json({
        success: true,
        message: 'OTP sent to your phone number',
        userExists: true,
        userId: userID
      });
    }

    // New user registration
    const otpCode = generateOTP();
    
    // In production, send actual OTP via SMS
    console.log(`Registration OTP for ${phoneNumber}: ${otpCode}`);
    
    // Store OTP temporarily
    global.otpStore = global.otpStore || new Map();
    global.otpStore.set(phoneNumber, {
      code: otpCode,
      userId: userID,
      expires: Date.now() + 5 * 60 * 1000, // 5 minutes
      isNewUser: true,
      deviceFingerprint
    });

    res.status(200).json({
      success: true,
      message: 'Registration OTP sent to your phone number',
      userExists: false,
      userId: userID
    });

  } catch (error) {
    console.error('Phone registration error:', error);
    res.status(500).json({ error: 'Phone registration failed' });
  }
}

function generateUserID(phoneNumber: string, deviceFingerprint?: string): string {
  const combined = deviceFingerprint ? phoneNumber + deviceFingerprint : phoneNumber;
  const hash = crypto.createHash('sha256').update(combined).digest('hex');
  return 'user_' + hash.substring(0, 16);
}

function generateOTP(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}