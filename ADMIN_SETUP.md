# Admin User Setup Guide

## Overview

The JointSaathi application now includes admin authentication functionality in the web dashboard. Admin users can view all patients and screenings across the system, while regular agents can only see their own assigned patients and screenings.

## Admin User Creation

### Using the Seed Script

The easiest way to create an admin user is to use the provided seed script:

```bash
cd backend
npm run seed:admin
```

This will create an admin user with the following credentials:
- **Phone Number:** 9999999999
- **Password:** admin123
- **Role:** admin

### Manual Creation

Alternatively, you can use the existing `createAdmin.js` script:

```bash
cd backend
node createAdmin.js
```

**Important:** In production, change the default admin password immediately after first login.

## Admin Login

### Web Dashboard

1. Start the web dashboard:
   ```bash
   cd web-dashboard
   npm run dev
   ```

2. Navigate to the login screen (http://localhost:5173/login)
3. Enter the admin credentials:
   - Phone: 9999999999
   - Password: admin123
4. Click "Sign In"

After successful login as admin, you will be able to:
- View all patients in the system (not just your own)
- View all screenings across all agents
- Access complete patient records
- See admin-specific labels in the UI

### API Testing

You can test admin functionality using curl or Postman:

```bash
# Login as admin
curl -X POST http://localhost:5000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "phoneNumber": "9999999999",
    "password": "admin123"
  }'

# Use the returned token to access all patients
curl -X GET http://localhost:5000/api/v1/patients?allPatients=true \
  -H "Authorization: Bearer YOUR_TOKEN"

# Use the returned token to access all screenings
curl -X GET http://localhost:5000/api/v1/screenings?allScreenings=true \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## How It Works

### Backend Changes

1. **User Model:** The User model already supports three roles: 'agent', 'admin', and 'user'
2. **Patient Controller:** The `listPatients` function checks for admin role and skips the `agentId` filter if the user is an admin
3. **Screening Controller:** The `listScreenings` function similarly checks for admin role
4. **Admin Detection:** Admin users are detected either by:
   - Having `role: 'admin'` in their user document
   - Passing `allPatients=true` or `allScreenings=true` query parameters

### Web Dashboard Changes

1. **Auth Context:** Added `isAdmin` getter to detect admin role from user data
2. **API Services:** Added `listAll` methods for patients and screenings APIs
3. **Patients Page:** Updated to use admin APIs when user is admin
4. **Screenings Page:** Updated to use admin APIs when user is admin
5. **UI Indicators:** Admin users see "(Admin view)" labels in page descriptions

## Security Considerations

1. **Change Default Password:** Always change the default admin password in production
2. **Use Strong JWT Secrets:** Ensure your JWT secrets are at least 32 characters long
3. **Environment Variables:** Never commit `.env` files to version control
4. **Role-Based Access:** The backend enforces role-based access on all sensitive endpoints
5. **Token Validation:** All API endpoints validate JWT tokens and user roles

## Troubleshooting

### Admin Not Seeing All Patients

1. Verify the user has `role: 'admin'` in the database
2. Check that the JWT token is being sent correctly in the Authorization header
3. Ensure the backend is running the latest code with admin support
4. Check the backend logs for any authentication errors
5. Verify the web dashboard is using the correct API base URL

### Login Fails

1. Verify the phone number and password are correct
2. Check that the MongoDB connection is working
3. Ensure the admin user exists in the database
4. Check backend logs for specific error messages
5. Verify the web dashboard can reach the backend API

### Web Dashboard Issues

1. Check browser console for JavaScript errors
2. Verify the VITE_API_BASE_URL is set correctly in .env
3. Ensure the backend is running and accessible
4. Clear browser cache and localStorage
5. Check network tab in browser dev tools for API errors

## Additional Admin Features

Future enhancements could include:
- Admin dashboard with analytics and statistics
- User management capabilities
- Health center assignment and management
- System configuration and settings
- Audit logs and activity tracking
- Bulk data export functionality
