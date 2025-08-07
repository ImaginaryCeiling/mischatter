import { NextApiRequest, NextApiResponse } from 'next';
import { chatStore } from '../../../lib/store';
import { v4 as uuidv4 } from 'uuid';

export default function handler(req: NextApiRequest, res: NextApiResponse) {
  switch (req.method) {
    case 'GET':
      return getUsers(req, res);
    case 'POST':
      return createUser(req, res);
    default:
      res.setHeader('Allow', ['GET', 'POST']);
      res.status(405).json({ error: 'Method not allowed' });
  }
}

function getUsers(req: NextApiRequest, res: NextApiResponse) {
  try {
    const { online } = req.query;
    
    let users;
    if (online === 'true') {
      users = chatStore.getOnlineUsers();
    } else {
      users = Array.from(chatStore['users'].values());
    }
    
    res.status(200).json({ users });
  } catch (error) {
    res.status(500).json({ error: 'Failed to fetch users' });
  }
}

function createUser(req: NextApiRequest, res: NextApiResponse) {
  try {
    const { username, avatar } = req.body;

    if (!username) {
      return res.status(400).json({ error: 'Username is required' });
    }

    const user = {
      id: uuidv4(),
      username,
      avatar,
      isOnline: false,
      joinedAt: new Date(),
    };

    chatStore.addUser(user);
    res.status(201).json({ user });
  } catch (error) {
    res.status(500).json({ error: 'Failed to create user' });
  }
}