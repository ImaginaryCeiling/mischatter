import { NextApiRequest, NextApiResponse } from 'next';

interface DeviceTrustRequest {
  phoneNumber: string;
  deviceFingerprint: string;
  appVersion?: string;
  establishTrust?: boolean;
}

interface DeviceTrustData {
  phoneNumber: string;
  deviceFingerprint: string;
  timestamp: string;
  appVersion: string;
  trusted: boolean;
}

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  if (req.method === 'POST') {
    return handleEstablishTrust(req, res);
  } else if (req.method === 'GET') {
    return handleCheckTrust(req, res);
  } else {
    res.setHeader('Allow', ['POST', 'GET']);
    return res.status(405).json({ error: 'Method not allowed' });
  }
}

function handleEstablishTrust(req: NextApiRequest, res: NextApiResponse) {
  try {
    const { phoneNumber, deviceFingerprint, appVersion }: DeviceTrustRequest = req.body;

    if (!phoneNumber || !deviceFingerprint) {
      return res.status(400).json({ error: 'Phone number and device fingerprint are required' });
    }

    // Initialize device trust store
    global.deviceTrustStore = global.deviceTrustStore || new Map();

    const trustData: DeviceTrustData = {
      phoneNumber,
      deviceFingerprint,
      timestamp: new Date().toISOString(),
      appVersion: appVersion || '1.0',
      trusted: true
    };

    // Store device trust
    const trustKey = deviceFingerprint;
    global.deviceTrustStore.set(trustKey, trustData);

    res.status(200).json({
      success: true,
      message: 'Device trust established',
      trustData: {
        deviceFingerprint,
        phoneNumber,
        trusted: true,
        timestamp: trustData.timestamp
      }
    });

  } catch (error) {
    console.error('Device trust establishment error:', error);
    res.status(500).json({ error: 'Device trust establishment failed' });
  }
}

function handleCheckTrust(req: NextApiRequest, res: NextApiResponse) {
  try {
    const { deviceFingerprint, phoneNumber } = req.query;

    if (!deviceFingerprint) {
      return res.status(400).json({ error: 'Device fingerprint is required' });
    }

    // Initialize device trust store
    global.deviceTrustStore = global.deviceTrustStore || new Map();

    const trustKey = deviceFingerprint as string;
    const deviceTrust: DeviceTrustData = global.deviceTrustStore.get(trustKey);

    if (deviceTrust) {
      const isValidForPhone = !phoneNumber || deviceTrust.phoneNumber === phoneNumber;
      
      res.status(200).json({
        trusted: deviceTrust.trusted && isValidForPhone,
        deviceFingerprint: deviceTrust.deviceFingerprint,
        phoneNumber: deviceTrust.phoneNumber,
        timestamp: deviceTrust.timestamp,
        appVersion: deviceTrust.appVersion,
        matchesPhone: isValidForPhone
      });
    } else {
      res.status(404).json({
        trusted: false,
        message: 'Device not found in trust store'
      });
    }

  } catch (error) {
    console.error('Device trust check error:', error);
    res.status(500).json({ error: 'Device trust check failed' });
  }
}