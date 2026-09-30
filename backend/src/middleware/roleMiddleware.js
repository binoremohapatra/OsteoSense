'use strict';

const ApiError = require('../utils/ApiError');

/**
 * Middleware factory for role-based authorization.
 * Accepts one or more roles (e.g. 'admin', 'agent').
 * Throws 403 Forbidden if req.user does not match any of the allowed roles.
 */
function requireRole(...allowedRoles) {
  return (req, _res, next) => {
    if (!req.user) {
      throw ApiError.unauthorized('Authentication required');
    }
    if (!allowedRoles.includes(req.user.role)) {
      throw ApiError.forbidden(
        `Access denied: Requires role [${allowedRoles.join(', ')}]. Current role: ${req.user.role}`
      );
    }
    next();
  };
}

module.exports = {
  requireRole,
  requireAdmin: requireRole('admin'),
  requireAgent: requireRole('agent'),
  requireStaff: requireRole('admin', 'agent'),
};
