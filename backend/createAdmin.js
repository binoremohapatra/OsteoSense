const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const User = require('./src/models/User');
const Admin = require('./src/models/Admin');
require('dotenv').config();

async function createAdmin() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const passwordHash = await bcrypt.hash('admin123', 12);

    // Check if admin user already exists
    let admin = await User.findOne({ phoneNumber: '9999999999' }).select('+passwordHash');
    if (admin) {
      console.log('Admin user exists. Resetting password and updating role to admin...');
      admin.role = 'admin';
      admin.isActive = true;
      admin.passwordHash = passwordHash;
      await admin.save();
    } else {
      admin = await User.create({
        fullName: 'System Administrator',
        phoneNumber: '9999999999',
        passwordHash,
        role: 'admin',
        isActive: true,
      });
      console.log('Admin user created successfully.');
    }

    let adminDoc = await Admin.findOne({ user: admin._id });
    if (!adminDoc) {
      await Admin.create({
        user: admin._id,
        fullName: admin.fullName,
        phoneNumber: admin.phoneNumber,
        adminRole: 'superadmin',
        department: 'District Public Health Administration',
        jurisdiction: 'All Districts & Primary Health Centers',
      });
      console.log('Admin database section created.');
    }

    console.log('Admin user ready:');
    console.log('Phone: 9999999999');
    console.log('Password: admin123');
    console.log('Role: admin (superadmin)');

    process.exit(0);
  } catch (error) {
    console.error('Error creating admin:', error);
    process.exit(1);
  }
}

createAdmin();