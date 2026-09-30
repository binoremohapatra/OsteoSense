'use strict';

const mongoose = require('mongoose');

const { Schema } = mongoose;

const villageAssignmentSchema = new Schema(
  {
    village: {
      type: String,
      required: true,
      trim: true,
      unique: true,
    },
    location: {
      type: String,
      required: true,
      trim: true,
    },
    assignedHealthWorkerId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
    toJSON: {
      transform: (_doc, ret) => {
        const idStr = ret._id ? ret._id.toString() : '';
        ret.id = idStr;
        ret._id = idStr;
        delete ret.__v;
        return ret;
      },
    },
  }
);

villageAssignmentSchema.index({ village: 1, isActive: 1 });
villageAssignmentSchema.index({ location: 1, isActive: 1 });
villageAssignmentSchema.index({ assignedHealthWorkerId: 1, isActive: 1 });

module.exports = mongoose.model('VillageAssignment', villageAssignmentSchema);
