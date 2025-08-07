import { NextApiRequest, NextApiResponse } from 'next';
import { chatStore } from '../../../lib/store';
import crypto from 'crypto';

interface DeviceAuthRequest {
  deviceFingerprint: string;
  phoneNumber?: string;
  biometricVerified?: boolean;
}

interface DeviceTrustData {
  phoneNumber: string;
  deviceFingerprint: string;
  timestamp: string;
  appVersion: string;
  trusted: boolean;
}

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', ['POST']);
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { deviceFingerprint, phoneNumber, biometricVerified }: DeviceAuthRequest = req.body;

    if (!deviceFingerprint) {
      return res.status(400).json({ error: 'Device fingerprint is required' });
    }

    // Initialize device trust store
    global.deviceTrustStore = global.deviceTrustStore || new Map();

    // Check if device is trusted
    const trustKey = deviceFingerprint;
    const deviceTrust: DeviceTrustData = global.deviceTrustStore.get(trustKey);

    if (deviceTrust && phoneNumber && deviceTrust.phoneNumber === phoneNumber) {
      // Device is trusted for this phone number
      if (biometricVerified) {
        // Generate user ID and authenticate
        const userID = generateUserID(phoneNumber, deviceFingerprint);
        let user = chatStore.getUser(userID);

        if (!user) {
          // Create user if doesn't exist
          user = {
            id: userID,
            username: `User ${phoneNumber.slice(-4)}`,
            phoneNumber: phoneNumber,
            deviceFingerprint: deviceFingerprint,
            isOnline: true,
            joinedAt: new Date(),
            authMethod: 'device'
          };
          chatStore.addUser(user);
        } else {
          user.isOnline = true;
        }

        // Generate token
        const tokenData = {
          userId: user.id,
          username: user.username,
          phoneNumber: user.phoneNumber,
          authMethod: 'device',
          deviceFingerprint: user.deviceFingerprint
        };

        const token = Buffer.from(JSON.stringify(tokenData)).toString('base64');

        return res.status(200).json({
          success: true,
          user,
          token,
          deviceTrusted: true,
          message: 'Device authentication successful'
        });
      } else {
        return res.status(401).json({
          error: 'Biometric verification required',
          deviceTrusted: true,
          requiresBiometric: true
        });
      }
    } else {
      // Device not trusted
      return res.status(401).json({
        error: 'Device not trusted',
        deviceTrusted: false,
        requiresPhoneVerification: true
      });
    }

  } catch (error) {
    console.error('Device authentication error:', error);
    res.status(500).json({ error: 'Device authentication failed' });
  }
}

function generateUserID(phoneNumber: string, deviceFingerprint: string): string {
  const combined = phoneNumber + deviceFingerprint;
  const hash = crypto.createHash('sha256').update(combined).digest('hex');
  return 'user_' + hash.substring(0, 16);
}